use strict;
use warnings;

package App::HTTP_Proxy_IMP::IMP;

use Net::Inspect::Debug qw(:DEFAULT $DEBUG);
use Net::IMP::Debug var => \$DEBUG, sub => \&debug;
use Net::IMP qw(:DEFAULT :log);
use Net::IMP::HTTP;
use Scalar::Util 'weaken';
use Hash::Util 'lock_ref_keys';
use Compress::Raw::Zlib;
no warnings 'experimental'; # smartmatch
use Carp;

my %METHODS_RFC2616 = map { ($_,1) } qw( GET HEAD POST PUT DELETE OPTIONS CONNECT TRACE );
my %METHODS_WITHOUT_RQBODY = map { ($_,1) } qw( GET HEAD DELETE CONNECT );
my %METHODS_WITH_RQBODY = map { ($_,1) } qw( POST PUT );
my %CODE_WITHOUT_RPBODY = map { ($_,1) } qw(204 205 304);
my %METHODS_WITHOUT_RPBODY = map { ($_,1) } qw(HEAD);

# we want plugins to suppport the HTTP Request innterface
my $interface = [
    IMP_DATA_HTTPRQ,
    [ 
	IMP_PASS,
	IMP_PREPASS,
	IMP_REPLACE,
	IMP_TOSENDER,
	IMP_DENY,
	IMP_LOG,
	IMP_ACCTFIELD,
	IMP_PAUSE,
	IMP_CONTINUE,
	IMP_FATAL,
    ]
];

sub can_modify {
    return shift->{can_modify};
}

# create a new factory object
sub new_factory {
    my ($class,%args) = @_;
    my @factory;
    for my $module (@{ delete $args{mod} || [] }) {
	if ( ref($module)) {
	    # assume it is already an IMP factory object
	    push @factory, $module;
	    next;
	}

	# --filter mod=args
	my ($mod,$args) = $module =~m{^([a-z][\w:]*)(?:=(.*))?$}i
	    or die "invalid module $module";
	eval "require $mod" or die "cannot load $mod args=$args: $@";
	my %args = $mod->str2cfg($args//'');
	my $factory = $mod->new_factory(%args) 
	    or croak("cannot create Net::IMP factory for $mod");
	$factory = 
	    $factory->get_interface( $interface ) &&
	    $factory->set_interface( $interface )
	    or croak("$mod does not implement the interface supported by us");
	push @factory,$factory;
    }

    @factory or return;
    if (@factory>1) {
	# for cascading filters we need Net::IMP::Cascade
	require Net::IMP::Cascade;
	my $cascade = Net::IMP::Cascade->new_factory( parts => [ @factory ]) 
	    or croak("cannot create Net::IMP::Cascade factory");
	$cascade = $cascade->set_interface( $interface ) or 
	    croak("cascade does not implement the interface supported by us");
	@factory = $cascade;
    }
    my $factory = $factory[0];

    my $self = bless {
	%args,
	imp => $factory, # IMP factory object
	can_modify => 0, # does interface support IMP_REPLACE, IMP_TOSENDER
    }, $class;
    lock_ref_keys($self);

    # update can_modify
    CHKIF: for my $if ( $factory->get_interface ) {
	my ($dt,$rt) = @$if;
	for (@$rt) {
	    $_ ~~ [ IMP_REPLACE, IMP_TOSENDER ] or next;
	    $self->{can_modify} =1;
	    last CHKIF;
	}
    }
	
    return $self;
}

# create a new analyzer based on the factory
sub new_analyzer {
    my ($factory,$request,$meta) = @_;

    my %meta = %$meta;
    # IMP uses different *addr than Net::Inspect, translate
    # [s]ource -> [c]lient, [d]estination -> [s]erver
    $meta{caddr} = delete $meta{saddr};
    $meta{cport} = delete $meta{sport};
    $meta{saddr} = delete $meta{daddr};
    $meta{sport} = delete $meta{dport};

    my $analyzer = $factory->{imp}->new_analyzer( meta => \%meta );

    my $self = bless {
	request => $request, # App::HTTP_Proxy_IMP::Request object
	imp => $analyzer,
	# incoming data, put into analyzer
	# \@list of [ buf_base,buf,type,callback,$cb_arg ] per dir 
	ibuf => [ 
	    [ [0,''] ],
	    [ [0,''] ],
	],  
	pass => [0,0],      # pass allowed up to given offset (per dir)
	prepass => [0,0],   # prepass allowed up to given offset (per dir)
	fixup_header => [], # sub to fixup content-length in header once known
	eof => [0,0],       # got eof in dir ?
	decode => undef,    # decoder for content-encoding decode{type}[dir]
	pass_encoded => undef, # pass body encoded (analyzer will not change body)
	method => undef,    # request method
	logsub => $factory->{logsub},  # how to log IMP_OG
    }, ref($factory);
    lock_ref_keys($self);
    weaken($self->{request});

    # set callback, this might trigger callback immediately if there are 
    # results pending
    weaken( my $wself = $self );
    $analyzer->set_callback( sub { _imp_callback($wself,@_) } );
    return $self;
}


sub request_header {
    my ($self,$hdr,$xhdr,@callback) = @_;
    my $clen = $xhdr->{content_length};

    # new body might change content-length info in request header
    # need to defer sending header until body length is known
    if ( ! $METHODS_WITHOUT_RQBODY{$xhdr->{method}} ) {
	if ( ! defined $clen and $xhdr->{method} ne 'CONNECT') {
	    # length not known -> chunking
	    die "FIXME: chunking request body not yet supported";
	}

	my $hlen = length($hdr);
	$self->{fixup_header}[0] = sub {
	    my ($self,$hdr,%args) = @_;
	    my $size = $args{content};
	    goto fix_clen if defined $size;

	    if ( my $pass = $self->{pass}[0] ) {
		if ( $pass == IMP_MAXOFFSET or $pass >= $hlen + $clen ) {
		    # will not change body
		    goto fix_clen;
		}
	    }
	    if ( my $prepass = $self->{prepass}[0] ) {
		if ( $prepass == IMP_MAXOFFSET or $prepass >= $hlen + $clen ) {
		    # will not change body
		    goto fix_clen;
		}
	    }
	    if ($self->{ibuf}[0][0][0] >= $hlen + $clen) { # ibuf[client].base
		# everything passed thru ibuf
		goto fix_clen;
	    }

	    # need to defer header until all of the body is passed
	    # or replaced, then we know the size
	    return;

	    fix_clen:

	    if (!defined $size) {
		# bytes in ibuf and outstanding bytes will not be changed, so:
		# new_content_length = 
		#  ( orig_clen + orig_hlen - received ) # not yet received
		#  + ( received - ibuf.base )           # still in ibuf
		#  + defered_body.length                # ready to forward
		#  --->
		#  orig_clen + orig_hlen - ibuf.base + defered_body.length
		$size = $clen + $hlen                   # orig_clen + orig_hlen
		    - $self->{ibuf}[0][0][0]            # ibuf.base
		    + $args{defered};                   # defered_body.length
	    }

	    $DEBUG && $self->{request}->xdebug("fixup header with clen=%d",$size);
	    # replace or add content-length header
	    $$hdr =~s{^(Content-length:[ \t]*)(\d+)}{$1$size}mi
		|| $$hdr =~s{(\n)}{$1Content-length: $size\r\n};
	    return 1;
	};
    }


    # send data to analyzer. 
    # will call back into request on processed data
    _imp_data($self,0,$hdr,0,IMP_DATA_HTTPRQ_HEADER,
	\&_request_header_imp,[ $xhdr,@callback ]);
}


############################################################################
# callback from IMP after passing/replacing the HTTP request header
# will reparse the header if changed and continue in @callback from request
############################################################################
sub _request_header_imp {
    my ($self,$hdr,$changed,$args) = @_;
    my ($xhdr,$callback,@cb_args) = @$args;

    if ( $changed ) {
	# we need to parse the header again and update xhdr
	my ($met,$url,$version,$fields) = $hdr =~m{ \A
	    (\S+)[\040\t]+
	    (\S+)[\040\t]+
	    HTTP/(1\.[01])[\040\t]*
	    \r?\n
	    (.*?\n)
	    \r?\n\Z
	}isx;

	# internal URL are not accepted by the client itself, only from
	# plugin. Set xhdr.internal_url if we see, that IMP plugin rewrote
	# url to internal one and strip internal:// again so that original
	# URL could be logged
	my $internal = $met ne 'CONNECT'
	    && $xhdr->{url} !~m{^internal://}i
	    && $url =~s{^internal://}{}i;

	my %kv;
	my $bad = _parse_hdrfields($fields,\%kv);
	$xhdr = {
	    method => uc($met),
	    version => $version,
	    url => $url,
	    fields => \%kv,
	    $bad ? ( junk => $bad ) :(),
	    $internal ? ( internal_url => 1 ):(),
	};
    }

    # we don't know the content length yet, unless it can be determined by the
    # request method. If we got a (pre)pass until the end of the request body
    # fixup_header will know it and adjust the header
    $xhdr->{content_length} = 
	$METHODS_WITHOUT_RQBODY{$xhdr->{method}} ? 0:undef;

    $self->{method} = $xhdr->{method};
    return $callback->(@cb_args,$hdr,$xhdr);
}

############################################################################
# fix request header by setting correct content-length
# returns true if header could be fixed
############################################################################
sub fixup_request_header {
    my ($self,$hdr_ref,%args) = @_;
    my $sub = $self->{fixup_header}[0] or return 1;
    my $ok = $sub->($self,$hdr_ref,%args);
    $self->{fixup_header}[0] = undef if $ok;
    return $ok;
}


############################################################################
# process request body data
# just feed to analyzer and call back into request once done
############################################################################
sub request_body {
    my ($self,$data,@callback) = @_;

    # feed data into IMP
    $self->{eof}[0] = 1 if $data eq '';
    _imp_data($self,0,$data,0,IMP_DATA_HTTPRQ_CONTENT,
	\&_request_body_imp,\@callback );
}

sub _request_body_imp {
    my ($self,$data,$changed,$args) = @_;
    my ($callback,@cb_args) = @$args;
    my $eof = _check_eof($self,0);
    $callback->(@cb_args,$data,$eof) if $data ne '' || $eof;
}

############################################################################
# process response header
############################################################################
sub response_header {
    my ($self,$hdr,$xhdr,@callback) = @_;

    # if content is encoded we need to decode it in order to analyze
    # it. For now only set decode to the encoding method, this will
    # be changed to a decoding function once we need it in the body
    if ( my $ce = $xhdr->{fields}{'content-encoding'} ) {
	# the right way would be to extract all encodings and then complain, if
	# there is an encoding we don't support. Instead we just look for the
	# encodings we support
	my %ce = map { lc($_) => 1 } map { m{\b(?:x-)?(gzip|deflate)\b}ig } @$ce;
	$self->{decode}{IMP_DATA_HTTPRQ_CONTENT+0}[1] = join(", ",keys %ce)
	    if %ce;
    }

    # header length is needed in callback
    $xhdr->{header_length} = length($hdr);
    _imp_data($self,1,$hdr,0,IMP_DATA_HTTPRQ_HEADER,
	\&_response_header_imp,[$xhdr,@callback] );
}


############################################################################
# callback after passing/replacing the HTTP response header
# will reparse the header if changed and continue in the request via
# callback
############################################################################
sub _response_header_imp {
    my ($self,$hdr,$changed,$args) = @_;
    my ($xhdr,$callback,@cb_args) = @$args;

    my $orig_clen = $xhdr->{content_length};
    my $orig_hlen = $xhdr->{header_length};

    if ( $changed ) {
	# we need to parse the header again and update xhdr
	my ($version,$code,$reason,$fields) = $hdr =~m{ \A
	    HTTP/(1\.[01])[\040\t]+
	    (\d\d\d)
	    (?:[\040\t]+([^\r\n]*))?
	    \r?\n
	    (.*?\n)
	    \r?\n\Z
	}isx;

	my %kv;
	my $bad = _parse_hdrfields($fields,\%kv);
	$xhdr = {
	    code => $code,
	    version => $version,
	    reason => $reason,
	    fields => \%kv,
	    $bad ? ( junk => $bad ) :(),
	};
    }

    # except for some codes or request methods we don't know the 
    # content-length of the body yet
    # in these cases we try in this order
    # - check if we got a (pre)pass for the whole body already
    # - use chunked encoding if client speaks HTTP/1.1
    # - don't specify content-length and close request with connection close

    # we don't change $hdr here because it will be rebuild from fields anyway
    if ( $CODE_WITHOUT_RPBODY{$xhdr->{code}} or $xhdr->{code} < 200 ) {
	$xhdr->{content_length} = 0;
	# better remove them
	delete @{ $xhdr->{fields} }{ qw/ content-length transfer-encoding / };
	goto callback;
    }

    if ( $METHODS_WITHOUT_RPBODY{ $self->{method} } ) {
	$xhdr->{content_length} = 0;
	# keep content-length etc, client might want to peek into it using HEAD
	goto callback;
    }
    
    # reset infos about content-length
    $xhdr->{content_length} = $xhdr->{chunked} = undef;
    delete @{ $xhdr->{fields} }{ qw/ content-length transfer-encoding / };

    # if we have read the whole body already or at least know, that we will
    # not change anymore data, we could compute the new content-length
    my $clen;
    my $nochange;
    while ( defined $orig_clen ) {
	my $rpsize = $orig_hlen + $orig_clen;

	if ( my $pass = $self->{pass}[1] ) {
	    if ( $pass == IMP_MAXOFFSET or $pass >= $rpsize ) {
		# will not look at and not change body
		$nochange = 1;
		goto compute_clen;
	    }
	}
	if ( my $prepass = $self->{prepass}[1] ) {
	    if ( $prepass == IMP_MAXOFFSET or $prepass >= $rpsize ) {
		# will not change body
		$nochange = 1;
		goto compute_clen;
	    }
	}
	if ($self->{ibuf}[1][0][0] >= $rpsize) { # ibuf[server].base
	    # everything passed thru ibuf
	    goto compute_clen;
	}

	# we still don't know final size
	last;

	compute_clen:
	# bytes in ibuf and outstanding bytes will not be changed, so:
	# new_content_length = 
	#  ( total_size - received )             # not yet received
	#  + ( received - ibuf.base )            # still in ibuf
	#  --->
	#  total_size - ibuf.base
	$clen = $rpsize - $self->{ibuf}[1][0][0];

	last;
    }

    if ( $self->{decode}{IMP_DATA_HTTPRQ_CONTENT+0}[1] ) {
	if ( $nochange ) {
	    # we will pass encoded stuff, either no decoding needs to
	    # be done (pass) or we will decode only for the analyzer (prepass)
	    # which will only watch at the content, but not change it
	    $self->{pass_encoded}[1] = 1;

	    my $pass = $self->{pass}[1];
	    if ( $pass and defined $orig_clen and ( 
		$pass == IMP_MAXOFFSET or 
		$pass >= $orig_clen + $orig_hlen )) {
		# no need to decode body
		$self->{decode}{IMP_DATA_HTTPRQ_CONTENT+0}[1] = undef;
	    }
	} else {
	    # content is encoded and inspection wants to see decoded stuff,
	    # which we then will forward too 
	    # but decoding might change length
	    $clen = undef;
	    # the content will be delivered decoded
	    delete $xhdr->{fields}{'content-encoding'}
	}
    }
    if ( defined $clen ) {
	$xhdr->{fields}{'content-length'} = [ $clen ];
	$xhdr->{content_length} = $clen;
    }

    callback:
    $callback->(@cb_args,$hdr,$xhdr);
}



############################################################################
# handle response body data
############################################################################
sub response_body {
    my ($self,$data,@callback) = @_;

    # forward to IMP analyzer
    $self->{eof}[1] = 1 if $data eq '';
    _imp_data($self,1,$data,0,IMP_DATA_HTTPRQ_CONTENT,
	\&_response_body_imp,\@callback);
}

sub _response_body_imp {
    my ($self,$data,$changed,$args) = @_;
    my ($callback,@cb_args) = @$args;
    my $eof = _check_eof($self,1);
    $callback->(@cb_args,$data,$eof) if $data ne '' || $eof;
}


sub _check_eof {
    my ($self,$dir) = @_;
    $DEBUG && $self->{request}->xdebug(
	"check eof[%d]  - eof=%d - %s - (pre)pass=%d/%d",
	$dir,$self->{eof}[$dir], _show_buf($self,$dir),
	$self->{prepass}[$dir],
	$self->{pass}[$dir]
    );
    return $self->{eof}[$dir]                    # received eof
	&& ! defined $self->{ibuf}[$dir][0][2]   # no more data in buf
	&& (                                     # (pre)pass til end ok
	    $self->{prepass}[$dir] == IMP_MAXOFFSET
	    || $self->{pass}[$dir] == IMP_MAXOFFSET
	);
}

sub _show_buf {
    my ($self,$dir) = @_;
    return join('|',
	map { ($_->[2]||'none')."($_->[0],+".length($_->[1]).")" } 
	@{ $self->{ibuf}[$dir] }
    );
}



############################################################################
# Websockets, TLS upgrades etc
# if not IMP the forwarding will be done inside this function, otherwise it
# will be done in _in_data_imp, which gets called by IMP callback
############################################################################
sub data {
    my ($self,$dir,$data,@callback) = @_;

    # forward to IMP analyzer
    $self->{eof}[$dir] = 1 if $data eq '';
    _imp_data($self,$dir,$data,0,IMP_DATA_HTTPRQ_CONTENT,
	\&_data_imp,[$dir,@callback]);
}

sub _data_imp {
    my ($self,$data,$changed,$args) = @_;
    my ($dir,$callback,@cb_args) = @$args;
    my $eof = $self->{eof}[$dir] &&          # got eof from server
	! defined $self->{ibuf}[$dir][0][2]; # no more data in ibuf[server]
    $callback->(@cb_args,$dir,$data,$eof) if $data ne '' || $eof;
}



############################################################################
# callback from IMP
# process return types and trigger type specific callbacks on (pre)pass/replace
############################################################################
sub _imp_callback {
    my $self = shift;

    my %fwd; # forwarded data, per dir
    for my $rv (@_) {

	# if the request got closed in between just return
	my $request = $self->{request} or return;

	my $rtype = shift(@$rv);

        # deny further data 
        if ( $rtype == IMP_DENY ) {
            my ($impdir,$msg) = @$rv;
	    $DEBUG && $request->xdebug("got deny($impdir) $msg");
            return $request->deny($msg // 'closed by imp');
	}

        # log some data
        if ( $rtype == IMP_LOG ) {
            my ($impdir,$offset,$len,$level,$msg) = @$rv;
	    $DEBUG && $request->xdebug("got log($impdir,$level) $msg");
	    if ( my $sub = $self->{logsub} ) {
		$sub->($level,$msg,$impdir,$offset,$len)
	    }
	    next;
	}

        # set accounting field
        if ( $rtype == IMP_ACCTFIELD ) {
            my ($key,$value) = @$rv;
	    $DEBUG && $request->xdebug("got acct $key => $value");
            $request->{acct}{$key} = $value;
	    next;
	}

        # (pre)pass data up to offset
        if ( $rtype ~~ [ IMP_PASS, IMP_PREPASS ]) {
	    my ($dir,$offset) = @$rv;
	    $DEBUG && $request->xdebug("got $rtype($dir) off=$offset "._show_buf($self,$dir));

	    if ( $rtype == IMP_PASS ) {
		# ignore pass if it's not better than a previous pass
		if ( $self->{pass}[$dir] == IMP_MAXOFFSET ) {
		    # there is no better thing than IMP_MAXOFFSET
		    next;
		} elsif ( $offset == IMP_MAXOFFSET 
		    or $offset > $self->{ibuf}[$dir][0][0] ) {
		    # we can pass new data
		    $self->{pass}[$dir] = $offset;
		} else {
		    # offset is no better than previous pass
		    next;
		}

	    } else { # IMP_PREPASS
		# ignore prepass if it's not better than a previous pass
		# and a previous prepaself->{ibuf}[1][0]
		if ( $self->{pass}[$dir] == IMP_MAXOFFSET
		    or $self->{prepass}[$dir] == IMP_MAXOFFSET ) {
		    # there is no better thing than IMP_MAXOFFSET
		    $DEBUG && debug("new off $offset no better than existing (pre)pass=max");
		    next;
		} elsif ( $offset == IMP_MAXOFFSET
		    or $offset > $self->{ibuf}[$dir][0][0] ) {
		    # we can prepass new data
		    $self->{prepass}[$dir] = $offset;
		    $DEBUG && debug("update prepass with new off $offset");
		} else {
		    # offset is no better than previous pass
		    $DEBUG && debug(
			"new off $offset no better than existing $self->{ibuf}[$dir][0][0]");
		    next;
		}
	    }

	    # collect data up to offset for forwarding
	    # list of [ changed,data,callback,cbarg ]
	    my $fwd  = $fwd{$dir} ||= []; 

	    my $ibuf = $self->{ibuf}[$dir];
	    my $ib0; # top of ibuf, e.g. ibuf[0]

	    while ( @$ibuf ) {
		$ib0 = shift(@$ibuf);
		defined $ib0->[2] or last; # dummy entry with no type

		if ( $offset == IMP_MAXOFFSET ) {
		    # forward this buf and maybe more
		    push @$fwd, [ 0, @{$ib0}[1,3,4] ];
		} else {
		    my $pass = $offset - $ib0->[0];
		    my $len0 = length($ib0->[1]);
		    if ( $pass > $len0 ) {
			# forward this buf and maybe more
			push @$fwd, [ 0, @{$ib0}[1,3,4] ];
		    } elsif ( $pass == $len0 ) {
			# forward this buf, but not more
			push @$fwd, [ 0, @{$ib0}[1,3,4] ];

			# add empty buf if this was the last, this will also
			# trigger resetting pass,prepass below
			if ( @$ibuf ) { # still data in buffer
			} elsif (  $ib0->[2] < 0 ) {
			    # no eof yet and no further data in ibuf 
			    # we might get a replacement at the end of the 
			    # buffer so put emptied buffer back
			    $ib0->[1] = '';
			    push @$ibuf, $ib0;
			} else {
			    push @$ibuf, [ $offset,'' ];
			}
			last;
		    } elsif ( $ib0->[2] < 0 ) {
			# streaming type: 
			# forward part of buf 
			push @$fwd, [
			    0,                            # not changed
			    substr($ib0->[1],0,$pass,''), # data
			    $ib0->[3],                    # callback
			    $ib0->[4],                    # args
			];
			# keep rest in ibuf
			unshift @$ibuf,$ib0;
			$ib0->[0] += $pass;
			last; # nothing more to forward
		    } else {
			# packet type: they need to be processed in total
			return $request->fatal("partial $rtype for $ib0->[2]");
		    }
		}
	    }

	    if ( @$ibuf ) {
		# there are still data in ibuf which cannot get passed,
		# so reset pass, prepass
		$self->{pass}[$dir] = $self->{prepass}[$dir] = 0;
	    } else {
		# add empty buffer containing only current offset based on
		# what we last removed from ibuf
		push @$ibuf, [ $ib0->[0] + length($ib0->[1]),'' ];
	    }

	    next;
	}


        # replace data up to offset
        if ( $rtype ==  IMP_REPLACE ) {
	    my ($dir,$offset,$newdata) = @$rv;
	    $DEBUG && $request->xdebug("got replace($dir) off=$offset data.len=".
		length($newdata));
	    my $ibuf = $self->{ibuf}[$dir];
	    @$ibuf or die "no ibuf";

	    # if there is an active pass|prepass (e.g. pointing to future data)
	    # the data cannot be replaced
	    return $request->fatal(
		"cannot replace data which are said to be passed")
		if $self->{pass}[$dir] or $self->{prepass}[$dir];

	    # we cannot replace future data
	    return $request->fatal('IMP', "cannot use replace with maxoffset")
		if $offset == IMP_MAXOFFSET;

	    # data to replace cannot span different types, so they must be in
	    # the first ibuf
	    my $ib0  = $ibuf->[0];
	    my $rlen = $offset - $ib0->[0];
	    my $len0 = length($ib0->[1]);

	    # some sanity checks
	    if ( $rlen < 0 ) {
		return $request->fatal("cannot replace already passed data");
	    } elsif ( $rlen > $len0 ) {
		return $request->fatal(
		    "replacement cannot span multiple data types") 
		    if @$ibuf>1 or $ib0->[2]>0;
		return $request->fatal("cannot replace future data ($rlen>$len0)");
	    } elsif ( $rlen < $len0 ) {
		# replace part of buffer
		return $request->fatal("cannot replace part of packet type")
		    if $ib0->[2]>0;

		# keep rest and update position
		substr( $ib0->[1],0,$rlen,'' ) if $rlen;
		$ib0->[0] += $rlen;
	    } else {
		# remove complete buffer
		if ( @$ibuf>1 ) { # still data in buffer
		} elsif (  $ib0->[2] < 0 ) {
		    # no eof yet and no further data in ibuf 
		    # we might get a replacement at the end of the 
		    # buffer so put emptied buffer back
		    $ib0->[0] += $len0;
		    $ib0->[1] = '';
		} else {
		    # replace with empty
		    @$ibuf = [ $offset,'' ];
		}
	    }

	    push @{$fwd{$dir}}, [
		1,          # changed
		$newdata,   # new data
		$ib0->[3],  # callback
		$ib0->[4],  # cbargs
	    ];

	    next;
	}
        if ( $rtype ~~ [ IMP_PAUSE, IMP_CONTINUE ] ) {
	    my $dir = shift(@$rv);
	    my $relay = $self->{request}{conn}{relay};
	    if ( $relay and my $fo = $relay->fd($dir)) {
		$fo->mask( r => ($rtype == IMP_PAUSE ? 0:1));
	    }
	    next;
	}

	if ( $rtype == IMP_FATAL ) {
	    $request->fatal(shift(@$rv));
	    next;
	}

	return $request->fatal("unsupported IMP return type: $rtype");
    }

    %fwd or return; # no passes/replacements...

    while ( my ($dir,$fwd) = each %fwd ) {
	while ( my $fw = shift(@$fwd)) {
	    #warn Dumper($fw); use Data::Dumper;
	    my ($changed,$data,$callback,$args) = @$fw;
	    $callback->($self,$data,$changed,$args);
	}
    }
}

############################################################################
# send data to IMP analyzer
# if we had a previous (pre)pass some data can be forwarded immediatly, for
# others we have to wait for the analyzer callback
# returns how many bytes of data are waiting for callback, e.g. 0 if we
# we can pass everything immediately
############################################################################
sub _imp_data {
    my ($self,$dir,$data,$offset,$type,$callback,$args) = @_;
    my $ibuf = $self->{ibuf}[$dir];
    my $eobuf = $ibuf->[-1][0] + length($ibuf->[-1][1]);

    my $encoded_data;
    if ( my $decode = $self->{decode}{$type+0}[$dir] ) {
	# set up decoder if not set up yet
	if ( ! ref($decode)) {
	    # create function to decode content
	    $self->{decode}{$type+0}[$dir] = $decode = _create_decoder($decode)
		|| return $self->{request}->fatal(
		"cannot decode content-encoding $decode");
	}

	# offsets relates to original stream, but we put the decoded stream
	# into ibuf. And offset>0 means, that we have a gap in the input,
	# which is not allowed, when decoding a stream.
	die "cannot use content decoder with gap in data" if $offset;

	$encoded_data = $data if $self->{pass_encoded}[$dir];
	defined( $data = $decode->($data) )
	    or return $self->{request}->fatal("decoding content failed");
    }

    if ( $offset ) {
	die "offset($offset)<eobuf($eobuf)" if $offset < $eobuf;
	$offset = 0 if $offset == $eobuf;
    }

    my $fwd; # what gets send to analyzer

    my $dlen = length($data);
    my $pass =  $self->{pass}[$dir];
    if ( $pass ) {
	# if pass is set there should be no data in ibuf, e.g. everything
	# before should have been passed
	! $ibuf->[0][2] or die "unexpected data in ibuf";

	if ( $pass == IMP_MAXOFFSET ) {
	    # pass thru w/o analyzing
	    $ibuf->[0][0] += $dlen;
	    $DEBUG && $self->{request}->xdebug("can pass($dir) infinite");
	    return $callback->($self,$encoded_data // $data,0,$args);
	}

	my $canpass = $pass - ( $offset||$eobuf );
	if ( $canpass <= 0 ) {
	    # cannot pass anything, pass should have been reset already
	    die "pass($dir,$pass) must be point into future ($canpass)";
	} elsif ( $canpass >= $dlen) {
	    # can pass everything
	    $ibuf->[0][0] += $dlen;
	    if ( $data eq '' ) {
		# forward eof to analyzer
		$fwd = $data;
		$DEBUG && $self->{request}->xdebug("pass($dir) eof");
		goto SEND2IMP;
	    }
	    $DEBUG && $self->{request}->xdebug(
		"can pass($dir) all: pass($canpass)>=data.len($dlen)");
	    return $callback->($self,$encoded_data // $data,0,$args);
	} elsif ( $type < 0 ) {
	    # can pass part of data, only for streaming types
	    # remove from data what can be passed 
	    die "body might change" if $self->{pass_encoded}[$dir];
	    $ibuf->[0][0] += $canpass;
	    my $passed_data = substr($data,0,$canpass,'');
	    $eobuf += $canpass;
	    $dlen = length($data);
	    $DEBUG && $self->{request}->xdebug(
		"can pass($dir) part: pass($canpass)<data.len($dlen)");
	    $callback->($self,$passed_data,0,$args); # callback but continue
	}
    }

    $fwd = $data; # this must be forwarded to analyzer

    my $prepass = $self->{prepass}[$dir];
    if ( $prepass ) {
	# if prepass is set there should be no data in ibuf, e.g. everything
	# before should have been passed
	! $ibuf->[0][2] or die "unexpected data in ibuf";
	if ( $prepass == IMP_MAXOFFSET ) {
	    # prepass everything
	    $ibuf->[0][0] += $dlen;
	    $DEBUG && $self->{request}->xdebug("can prepass($dir) infinite");
	    $callback->($self,$encoded_data // $data,0,$args); # callback but continue
	    goto SEND2IMP;
	}

	my $canprepass = $prepass - ( $offset||$eobuf );
	if ( $canprepass <= 0 ) {
	    # cannot prepass anything, prepass should have been reset already
	    die "prepass must be point into future";
	} elsif ( $canprepass >= $dlen) {
	    # can prepass everything
	    $ibuf->[0][0] += $dlen;
	    $callback->($self,$encoded_data // $data,0,$args); # callback but continue
	    $DEBUG && $self->{request}->xdebug(
		"can prepass($dir) all: pass($canprepass)>=data.len($dlen)");
	    goto SEND2IMP;
	} elsif ( $type < 0 ) {
	    # can prepass part of data, only for streaming types
	    # remove from data what can be prepassed
	    die "body might change" if $self->{pass_encoded}[$dir];
	    $ibuf->[0][0] += $canprepass;
	    my $passed_data = substr($data,0,$canprepass,'');
	    $eobuf += $canprepass;
	    $dlen = length($data);
	    $DEBUG && $self->{request}->xdebug(
		"can prepass($dir) part: prepass($canprepass)<data.len($dlen)");
	    $callback->($self,$passed_data,0,$args); # callback but continue
	}
    }

    # everything else in $data must be added to buffer
   
    # there can be no gaps inside ibuf because caller is only allowed to
    # pass data which we explicitly allowed
    if ( $offset && $offset > $eobuf ) {
	defined $ibuf->[0][2] and       # we have still data in ibuf!
	    die "there can be no gaps in ibuf";
    }
    if ( ! defined $ibuf->[-1][2] ) {
	# replace buf, because it was empty
	$ibuf->[-1] = [ $offset||$eobuf,$data,$type,$callback,$args ];
    } elsif ( $type < 0 
	and $type == $ibuf->[-1][2] 
	and $callback == $ibuf->[-1][3]
    ) {
	# streaming data, concatinate to existing buf of same type
	$ibuf->[-1][1] .= $data;
    } else {
	# different type or non-streaming data, add new buf
	push @$ibuf,[ $offset||$eobuf,$data,$type,$callback,$args ];
    }
    $DEBUG && $self->{request}->xdebug( "ibuf.length=%d", 
	$ibuf->[-1][0] + length($ibuf->[-1][1]) - $ibuf->[0][0]);

    SEND2IMP:
    $DEBUG && $self->{request}->xdebug("forward(%d) %d bytes type=%s off=%d to analyzer",
	$dir,length($fwd),$type,$offset);
    $self->{imp}->data($dir,$fwd,$offset,$type);
    return length($fwd);
}

#####################################################################
# parse header fields
# taken from Net::Inspect::L7::HTTP (where it got put in by myself)
#####################################################################
my $token = qr{[^()<>@,;:\\"/\[\]?={}\x00-\x20\x7f-\xff]+};
my $token_value_cont = qr{
    ($token):                      # key:
    [\040\t]*([^\r\n]*?)[\040\t]*  # <space>value<space>
    ((?:\r?\n[\040\t][^\r\n]*)*)   # continuation lines
    \r?\n                          # (CR)LF
}x;
sub _parse_hdrfields {
    my ($hdr,$fields) = @_;
    my $bad = '';
    parse:
    while ( $hdr =~m{\G$token_value_cont}gc ) {
        if ($3 eq '') {
            # no continuation line
            push @{$fields->{ lc($1) }},$2;
        } else {
            # with continuation line
            my ($k,$v) = ($1,$2.$3);
            # <space>value-part<space> -> ' ' + value-part
            $v =~s{[\r\n]+[ \t](.*?)[ \t]*}{ $1}g;
            push @{$fields->{ lc($k) }},$v;
        }
    }
    if (pos($hdr)//0 != length($hdr)) {
        # bad line inside
        substr($hdr,0,pos($hdr),'');
        $bad .= $1 if $hdr =~s{\A([^\n]*)\n}{};
        goto parse;
    }
    return $bad;
}

#####################################################################
# create decoder function for gzip|deflate content-encoding
#####################################################################
sub _create_decoder {
    my $typ = shift;
    $typ ~~ [ 'gzip','deflate' ] or return; # not supported

    my $gzip_csum;
    my $buf = '';
    my $inflate;

    return sub {
	my $data = shift;
	$buf .= $data;

	goto inflate if defined $inflate;

	# read gzip|deflate header
	my $wb;
	my $more = $data eq '' ? undef:''; # need more data if possible
	if ( $typ eq 'gzip' ) {
	    my $hdr_len = 10; # minimum gzip header

	    return $more if length($buf) < $hdr_len; 
	    my ($magic,$method,$flags) = unpack('vCC',$buf);
	    if ( $magic != 0x8b1f or $method != Z_DEFLATED or $flags & 0xe0 ) {
		$DEBUG && debug("no valid gzip header. assuming plain text");
		$inflate = ''; # defined but false
		goto inflate;
	    }
	    if ( $flags & 4 ) {
		# skip extra section
		return $more if length($buf) < ($hdr_len+=2);
		$hdr_len += unpack('x10v',$buf);
		return $more if length($buf) < $hdr_len;
	    }
	    if ( $flags & 8 ) {
		# skip filename
		my $o = index($buf,"\0",$hdr_len);
		return $more if $o == -1; # end of filename not found
		$hdr_len = $o+1;
	    }
	    if ( $flags & 16 ) {
		# skip comment
		my $o = index($buf,"\0",$hdr_len);
		return $more if $o == -1; # end of comment not found
		$hdr_len = $o+1;
	    }
	    if ( $flags & 2 ) {
		# skip CRC
		return $more if length($buf) < ($hdr_len+=2);
	    }

	    # remove header
	    substr($buf,0,$hdr_len,'');
	    $gzip_csum = 8; # 8 byte Adler CRC at end
	    $wb = -MAX_WBITS(); # see Compress::Raw::Zlib

	} else { 
	    # deflate
	    # according to RFC it should be zlib, but due to the encoding name
	    # often real deflate is used instead 
	    # check magic bytes to decide

	    # lets see if it looks like a zlib header
	    # check for CM=8, CMID<=7 in first byte and valid FCHECK in
	    # seconds byte
	    return $more if length($buf)<2;
	    my $magic = unpack('C',substr($buf,0,1));
	    if (
		( $magic & 0b1111 ) == 8                   # CM = 8
		and $magic >> 4 <= 7                       # CMID <= 7
		and unpack('n',substr($buf,0,2)) % 31 == 0 # valid FCHECK
	    ) {
		# looks like zlib header
		$wb = +MAX_WBITS(); # see Compress::Raw::Zlib
	    } else {
		# assume deflate
		$wb = -MAX_WBITS(); # see Compress::Raw::Zlib
	    }
	}

	$inflate = Compress::Raw::Zlib::Inflate->new(
	    -WindowBits => $wb,
	    -AppendOutput => 1,
	    -ConsumeInput => 1
	) or die "cannot create inflation stream";

	inflate:

	return '' if $buf eq '';

	if ( ! $inflate ) {
	    # wrong gzip header: sometimes servers claim to use gzip
	    # if confronted with "Accept-Encoding: identity" but in reality
	    # they send plain text
	    # so consider it plain text and don't decode
	    my $out = $buf;
	    $buf = '';
	    return $out
	}

	my $out = '';
	my $stat = $inflate->inflate(\$buf,\$out);
	if ( $stat == Z_STREAM_END ) {
	    if ( $gzip_csum and length($buf) >= $gzip_csum ) {
		# TODO - check checksum - but what would it help?
		substr($buf,0,$gzip_csum,'');
		$gzip_csum = 0;
	    }
	} elsif ( $stat != Z_OK ) {
	    $DEBUG && debug("decode failed: $stat");
	    return; # error
	}
	return $out 
    };
}

1;
