
############################################################################
# Request
############################################################################

use strict;
use warnings;

package App::HTTP_Proxy_IMP::Request;
use base 'Net::Inspect::Flow';
use fields (
    'conn',         # App::HTTP_Proxy_IMP::Connection object
    'meta',         # meta data
    'me_proxy',     # defined if I'm proxy, if true will be used for Via:
    'up_proxy',     # address of upstream proxy if any
    'acct',         # some accounting data
    'connected',    # false|CONN_HOST|CONN_INTERNAL

    'imp_analyzer', # App::HTTP_Proxy_IMP::IMP object
    'defer_rqhdr',  # deferred request header (wait until body length known)
    'defer_rqbody', # deferred request body (wait until header can be sent)

    'method',       # request method
    'rqhost',       # hostname from request
    'rq_version',   # version of request
    'rp_encoder',   # sub to encode response body (chunked)
    'keep_alive',   # do we use keep_alive in response
);

use App::HTTP_Proxy_IMP::Debug qw(debug $DEBUG debug_context);
use Scalar::Util 'weaken';
use Net::Inspect::Debug 'trace';
use Net::IMP qw(:DEFAULT :log);
use Net::IMP::HTTP; # constants
use Sys::Hostname 'hostname';

my $HOSTNAME = hostname();

# connected to host or do we fake the response internally
use constant CONN_HOST => 1;
use constant CONN_INTERNAL => 2;

sub DESTROY { 
    $DEBUG && debug("destroy request"); 
    #Devel::TrackObjects->show_tracked;
}
sub new_request {
    my ($factory,$meta,$conn) = @_;
    my $self = $factory->new;
    $DEBUG && $conn->xdebug("new request $self");

    $self->{meta} = $meta;
    weaken($self->{conn} = $conn);
    $self->{defer_rqhdr} = $self->{defer_rqbody} = '';

    $self->{acct} = { %$meta, Id => $self->id };
    if ( my $f = $conn->{imp_factory} ) {
	$self->{imp_analyzer} = $f->new_analyzer($self,$meta);
    }

    $self->{me_proxy} = $HOSTNAME;
    $self->{up_proxy} = $meta->{upstream};

    return $self;
}

sub xdebug {
    my $self = shift;
    my $ctx = debug_context( id => $self->id );
    goto &debug;
}

sub id {
    my $self = shift;
    $self->{conn} or return '';
    return $$.'.'.$self->{conn}{connid}.'.'.$self->{meta}{reqid}
}

sub fatal {
    my ($self,$reason) = @_;
    warn "[fatal] ".$self->id." $reason\n";
    if ( my $conn = $self->{conn} ) {
        my $relay =  $conn->{relay};
        $relay->account('fatal');
        $relay->close;
    }
}

sub deny {
    my ($self,$reason) = @_;
    warn "[deny] ".$self->id." $reason\n";
    if ( my $relay = $self->{conn} && $self->{conn}{relay} ) {
        $relay->account('deny', status => 'DENIED', reason => $reason );
	$relay->forward(1,0,"HTTP/1.0 403 $reason\r\n\r\n") 
	   if ! $self->{acct}{code};
	$relay->close;
    }
}

sub xtrace {
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{conn}{connid}.$self->{meta}{reqid} $msg";
    unshift @_,$msg;
    goto &trace;
}


############################################################################
# process HTTP request header
# called from HTTP connection object
# if IMP plugin is configured it will send the received header to the plugin
# and continue from the IMP callback to _request_header_after_imp.
# if no IMP is configured it will immediatly go there
############################################################################

my %default_port = ( http => 80, ftp => 21, https => 443 );
sub in_request_header {
    my ($self,$hdr,$time,$xhdr) = @_;
    my $conn = $self->{conn} or return;
    if ( $conn->{spool} ) {
	# we have an active request, spool this new one (pipelining)
	$DEBUG && $self->xdebug("spool new request");
	push @{$conn->{spool}}, [ \&in_request_header, @_ ];
	return;
    }

    my $relay = $conn->{relay} or return;
    $relay->acctinfo($self->{acct});
    $conn->{spool} = []; # mark connection as processing request

    $DEBUG && $self->xdebug("incoming request header ".$hdr);

    $self->{method} = $xhdr->{method};
    $self->{rq_version} = $xhdr->{version};

    if ( my $imp = $self->{imp_analyzer} ) {
	# pass thru IMP
	my $debug = $DEBUG && debug_context( id => $self->id);
	$imp->request_header($hdr,$xhdr,
	    \&_request_header_after_imp,$self);
    } else {
	# pass directly
	_request_header_after_imp($self,$hdr,$xhdr);
    }
}


############################################################################
# process HTTP request header, which might have been modified by IMP
# if not IMP is used this is called directly from in_request_header, else
# via callback from IMP
############################################################################
sub _request_header_after_imp {
    my ($self,$hdr,$xhdr) = @_;
    my $conn  = $self->{conn}  or return;
    my $relay = $conn->{relay} or return;

    # with IMP method should not change
    my $met = $self->{method};
    die "method should not change in IMP plugin" 
	if $met ne $xhdr->{method};

    # work with original client version
    my $version = $self->{rq_version};
    my $url = $xhdr->{url};

    my $head = $xhdr->{fields};
    $xhdr->{junk} and $relay->error( 
	"Bad request header lines: $xhdr->{junk}");

    my ($proto,$host,$port,$path);
    if ( $met eq 'CONNECT' ) {
	# only possible if we work as proxy
	return $self->fatal("connect request only allowed on proxy")
	    if ! defined $self->{me_proxy};
	return $self->fatal("connect request not allowed inside ssl tunnel")
	    if $conn->{intunnel};

	# url should be host[:port]
	$url =~m{^(?:\[([\w\-.:]+)\]|([\w\-.]+))(?::(\d+))$} or
	    return $self->fatal("invalid host[:port] in connect: $url");
	$proto = 'https';
	$host = lc($1||$2);
	$port = $3 || $default_port{$proto};
	$path = '';
	$url = ( $host =~m{:} ? "[$host]":$host ) . ":$port";

    } else {
	if ( $url =~m{^(\w+)://(?:\[([\w\-.:]+)\]|([\w\-.]+))(?::(\d+))?(.+)?} ) {
	    # absolute url, valid for HTTP/1.1 or proxy requests
	    $proto = lc($1);
	    $host = lc($2||$3);
	    $port = $4;
	    $path = $5 // '/';

	} else {
	    # relativ url, needs Host header if we want to get target
	    # from request
	    $proto = 'http';
	    $path = $url;
	    if ( my $h = $head->{host} ) {
		$relay->error("Ignoring multiple host headers") if @$h>1;
		$h->[0] =~m{^(?:\[([\w\-.:]+)\]|([\w\-.]+))(?::(\d+))?$} or 
		    return $self->fatal("bad host line '$h->[0]'");
		$host = $1||$2;
		$port = $3;
	    } else {
		return $self->fatal("cannot determine target host");
	    }
	}

	$port //= $default_port{$proto};
	return $self->fatal("invalid port $port") 
	    if ! $port or $port > 2**16-1;

	$path !~m{^/} and return $self->fatal("invalid path $path ($url)");

	# set/replace host header with target from URL and normalize URL
	$host =~s{\.\.+}{.}g;
	my $hp = $host =~m{:} ? "[$host]":$host;
	$hp .= ":$port" if $default_port{$proto} != $port;
	$head->{host} = [ $hp ];
	$url = "$proto://$hp$path";
    }

    $self->{acct}{url} = $url;
    $self->{acct}{url} =~s{://}{s://} if $conn->{intunnel};
    $self->{acct}{method} = $met;
    $self->{acct}{reqid} = $self->{meta}{reqid};
    $self->{rqhost} = $host;

    if ( $met eq 'CONNECT' and ! $self->{up_proxy} ) {
	# just skip all the header manipulation and normalization, we don't
	# need your stinkin header!
	$hdr = '';
	goto SRVCON;
    }

    # do we want/support persistence?
    my %conn = map { lc($_) => 1 } grep { m{\b(close|keep-alive)\b}i } (
	@{ delete $head->{connection} || [] },
	defined($self->{me_proxy}) 
	    ? @{ delete $head->{'proxy-connection'} || [] } : ()
    );
    if ( keys %conn > 1 ) {
	# fall back to close
	$self->{keep_alive} = 0;
	$head->{connection} = [ 'close' ];
    } elsif ( $conn{close} ) {
	$self->{keep_alive} = 0;
	# default in 1.1 is keep-alive
	$head->{connection} = [ 'close' ] if $version eq '1.1';
    } elsif ( $conn{'keep-alive'} ) {
	$self->{keep_alive} = 1;
	# default in 1.0 is close
	$head->{connection} = [ 'keep-alive' ] if $version eq '1.0';
    } else {
	# use default of version
	$self->{keep_alive} = $version eq '1.1';
    }

    # if we are a proxy set a via tag
    if ( my $via = $self->{me_proxy} ) {
	push @{$head->{via}}, "$version $via";
    }

    # normalize header before forwarding it
    # sort keys, normalize case of keys etc
    $hdr = "$met ".( $self->{up_proxy} ? $url : $path )." HTTP/$version\r\n";
    for my $k ( sort keys %$head) {
	$hdr .= "\u$k: $_\r\n" for @{$head->{$k}};
    }
    $hdr .= "\r\n";

    SRVCON:

    if ( $xhdr->{internal_url} ) {
	# the IMP plugin rewrote the url to internal://smthg,
	# meaning, that the plugin will provide us with the real response
	$self->{acct}{internal} = 1;
	$self->{connected} = CONN_INTERNAL;
	$self->{keep_alive} = 0;

	# accept more body data
	_call_spooled_this($conn);
	$relay->mask(0,r=>1);

	# inject minimal response into Net::Inspect, which than can modify
	# it at will
	# IMP let us not change nothing (e.g. empty body) into something, so
	# we need to provide minimal content where content is expected
	$conn->in(1, 
	    $met eq 'HEAD' 
		? "HTTP/$version 200 Ok\r\n\r\n" 
		: "HTTP/$version 200 Ok\r\nContent-length: 1\r\n\r\n%",
	    1, # eof
	    0, # time
	);
	return;
    }

    if ( my $imp = $self->{imp_analyzer} ) {
	if ( defined( my $len = $xhdr->{content_length} )) {
	    # length is given, fix header
	    my $debug = $DEBUG && debug_context( id => $self->id);
	    $imp->fixup_request_header(\$hdr, content => $len);
	} else {
	    $self->{defer_rqhdr} = $hdr;
	}
    }

    if ( $conn->{intunnel} ) {
	_fwd_request_after_connect($self,$hdr);
    } else {
	$relay->connect( 1,
	    @{ $self->{up_proxy} || [ $host,$port ] },
	    sub { _fwd_request_after_connect($self,$hdr) }
	);
    }
}

sub _fwd_request_after_connect {
    my ($self,$hdr) = @_;
    $self->{connected} = CONN_HOST;

    if ($hdr eq '') {
	# no header, e.g we have a CONNECT to a non-proxy
	# put a fake response into Net::Inspect to keep state
	$self->{conn}->in(1,"HTTP/1.0 200 Connection established\r\n\r\n");
	return _call_spooled_this($self->{conn});
    }

    if ( my $imp = $self->{imp_analyzer} ) {
	my $debug = $DEBUG && debug_context( id => $self->id);
	if ( $imp->fixup_request_header(\$hdr, defered => 0) ) {
	    $self->{defer_rqhdr} = '';
	} else {
	    # keep deferring sending header, length not known
	    _call_spooled_this($self->{conn}); # any body already ?
	    return;
	}
    }

    my $relay = $self->{conn}{relay} or return;
    $relay->forward(0,1,$hdr) if $self->{connected} == CONN_HOST;
    _call_spooled_this($self->{conn}); # any body already ?
}

sub _call_spooled_this {
    my $conn = shift;

    # call spooled request_bodies, e.g. until we see a new request
    debug("check for spooled subs in this request");
    my $spool = $conn->{spool} or return;
    $conn->{spool} = undef;
    while (@$spool && ! $conn->{spool} ) {
	my ($sub,@arg) = @{ $spool->[0] };
	last if $sub == \&in_request_header;
	shift(@$spool);
	$DEBUG && debug("handle spooled event $sub");
	$sub->(@arg);
    }
    push @{ $conn->{spool}}, @$spool if @$spool; # put back
}

sub _call_spooled_next {
    my $conn = shift;

    # skip until we have a next request, then continue
    debug("check for spooled requests, ignoring subs for this");
    my $spool = $conn->{spool} or return;
    $conn->{spool} = undef;
    while (@$spool) {
	my ($sub,@arg) = @{ $spool->[0] };
	last if $sub == \&in_request_header;
	$DEBUG && debug("skip spooled event $sub");
	shift(@$spool);
    }
    while (@$spool && ! $conn->{spool} ) {
	my ($sub,@arg) = @{ $spool->[0] };
	$DEBUG && debug("handle spooled event $sub");
	$sub->(@arg);
    }
    push @{ $conn->{spool}}, @$spool if @$spool; # put back
}

############################################################################
# process request body data
# if IMP, we might need to wait for a callback to decide what to do with
# the data, otherwise the data are further send directly
# if IMP might modify the data, we need to defer sending the header to get
# the final content-length and fixup the header accordingly
############################################################################
sub in_request_body {
    my ($self,$data,$eof) = @_;
    my $conn  = $self->{conn}  or return;
    my $relay = $conn->{relay} or return;
    if ( ! $self->{connected} ) {
	# not connected yet
	$DEBUG && $self->xdebug("spool request body data");
	push @{$conn->{spool}}, [ \&in_request_body, @_ ];
	return;
    }
    
    $DEBUG && $self->xdebug("got request body data len=%d eof=%d",length($data),$eof);
    my $imp = $self->{imp_analyzer};
    if ( ! $imp ) {
	# fast path w/o imp
	$relay->forward(0,1,$data) if $data ne '' 
	    and $self->{connected} == CONN_HOST;
	return;
    }

    # feed data into IMP
    $DEBUG && $self->xdebug("fwd request body to IMP");
    my $debug = $DEBUG && debug_context( id => $self->id);
    $imp->request_body($data,\&_request_body_after_imp,$self) if $data ne '';
    $imp->request_body('',\&_request_body_after_imp,$self) if $eof;
}

############################################################################
# process request body data in case of IMP
# called from IMP callback working on request body data
############################################################################
sub _request_body_after_imp {
    my ($self,$data,$eof) = @_;
    my $conn  = $self->{conn}  or return;
    my $relay = $conn->{relay} or return;

    my $debug = $DEBUG && debug_context( id => $self->id);

    if ( $self->{defer_rqhdr} ne '') {
	$self->{defer_rqbody} .= $data;
	if ( not $self->{imp_analyzer}->fixup_request_header( 
	    \$self->{defer_rqhdr}, 
	    defered => length($self->{defer_rqbody}) 
	)) {
	    # body length still not known
	    $DEBUG && debug("request body length still unknown");
	    $self->{defer_rqbody} .= $data;
	    $eof or return;
	}

	$DEBUG && debug("forward %d bytes header + %d bytes body",
	    length($self->{defer_rqhdr}),
	    length($self->{defer_rqbody}));

	$relay->forward(0,1,$self->{defer_rqhdr}.$self->{defer_rqbody} )
	    if $self->{connected} == CONN_HOST;
	$self->{defer_rqhdr} = $self->{defer_rqbody} = '';

    } else {
	$DEBUG && debug("forward %d bytes body",length($data));
	$relay->forward( 0,1,$data ) if $self->{connected} == CONN_HOST;
    }
}

############################################################################
# process response header
# jumps to _response_header_after_imp, directly or from IMP 
############################################################################
sub in_response_header {
    my ($self,$hdr,$time,$xhdr) = @_;
    return if $xhdr->{code} == 100; # ignore preliminary response

    if ( my $imp = $self->{imp_analyzer} ) {
	my $debug = $DEBUG && debug_context( id => $self->id);
	$imp->response_header($hdr,$xhdr,
	    \&_response_header_after_imp,$self);
    } else {
	_response_header_after_imp($self,$hdr,$xhdr);
    }
}


############################################################################
# process response header, maybe it got manipulated by IMP
############################################################################
sub _response_header_after_imp {
    my ($self,$hdr,$xhdr) = @_;
    my $relay = $self->{conn}{relay} or return;

    my $version = $xhdr->{version};
    my $code    = $self->{acct}{code} = $xhdr->{code};
    my $clen    = $xhdr->{content_length};

    $DEBUG && $self->xdebug("input header: $hdr");
    my $status_line = "HTTP/$version $code $xhdr->{reason}\r\n"; # normalized

    my $head = $xhdr->{fields};
    #warn Dumper($head); use Data::Dumper;
    $xhdr->{junk} and $relay->error(
	"Bad response header lines: $xhdr->{junk}");

    # check if the response is chunked and strip any transfer-encoding header
    # it will be added, when we know, how we talk to the client
    if ( $xhdr->{chunked} ) {
	delete $head->{'transfer-encoding'};
	# if chunked is given content-length should be ignored
	# better strip, so that client will parse it correctly
	delete $head->{'content-length'};
    }

    # if we don't know the content_length we try chunked, but only if client
    # and server used version 1.1. Otherwise we will close connection
    # at request end.
    # if only client supports chunking we better don't change response header
    # to 1.1, because in the 1.0 response might contain 1.0 specific headers 
    # (Pragma...) which we don't know how to translate
    if ( defined $clen ) {
	$DEBUG && $self->xdebug("have content-length $clen");
    } elsif ( $self->{method} eq 'CONNECT' ) {
	$DEBUG && $self->xdebug("have connect request");
    } else {
	if  ( $version eq '1.1' and $self->{rq_version} eq '1.1' ) {
	    $head->{'transfer-encoding'} = [ 'chunked' ];
	    delete $head->{'content-length'};
	    $DEBUG && $self->xdebug("no clen known - use chunked encoding");
	    $self->{rp_encoder} = sub { 
		my $data = shift;
		sprintf("%x\r\n%s\r\n", length($data),$data) 
	    };
	} else {
	    # disable persistance, we will end with EOF
	    $DEBUG && $self->xdebug("no clen known - use eof to end response");
	    $self->{keep_alive} = 0;
	}
    }

    # set connection header if behavior is not default
    if ( $version eq '1.1' and ! $self->{keep_alive} ) {
	$head->{connection} = [ 'close' ];
    } elsif ( $version eq '1.0' and $self->{keep_alive} ) {
	$head->{connection} = [ 'keep-alive' ];
    } else {
	delete $head->{connection}
    }


    # create normalized header
    $hdr = $status_line;
    for my $k ( sort keys %$head) {
	$hdr .= "\u$k: $_\r\n" for @{$head->{$k}};
    }
    $hdr .= "\r\n";

    # forward header
    $DEBUG && $self->xdebug("output hdr: $hdr");
    $relay->forward(1,0,$hdr);

    if ( $self->{method} eq 'CONNECT' ) {
	# upgrade server side and client side with SSL, but intercept traffic.
	# need to be called outside the current event handler, because $hdr
	# will only be removed from rbuf after the current handler is done
	App::HTTP_Proxy_IMP->once( sub {
	    $relay->sslify(1,0,$self->{rqhost});
	});
    }
}


############################################################################
# handle response body data
# will be forwarded to _response_body_after_imp with data or '' (eof)
# maybe it will forwarded before to IMP analyzer
############################################################################
sub in_response_body {
    my ($self,$data,$eof) = @_;

    $self->xdebug("len=".length($data)." eof=$eof");
    if ( my $imp = $self->{imp_analyzer} ) {
	my $debug = $DEBUG && debug_context( id => $self->id);
	$data ne '' && $imp->response_body($data,
	    \&_response_body_after_imp,$self);
	$eof && $imp->response_body('',
	    \&_response_body_after_imp,$self); 
    } else {
	_response_body_after_imp($self,$data,$eof);
    }
}

sub _response_body_after_imp {
    my ($self,$data,$eof) = @_;
    $self->xdebug("len=".length($data)." eof=$eof");
    my $relay = $self->{conn}{relay} or return;

    # chunking, compression ...
    if ( my $encode = $self->{rp_encoder} ) {
	$data = $encode->($data) if $data ne '';
	$data.= $encode->('') if $eof;
    }
    if ( $data ne '' ) {
	$DEBUG && $self->xdebug("send ".length($data)." bytes to c");
	$relay->forward(1,0,$data);
    } 

    if ($eof) {
        $relay->account('request');
	if ( ! $self->{keep_alive} ) {
	    # close connection
	    $DEBUG && $self->xdebug("end of request: close");
	    return $relay->close;
	}

	# keep connection open
	# and continue with next request if we have one
	$DEBUG && $self->xdebug("end of request: keep-alive");
	_call_spooled_next( $self->{conn} );
    }
}

############################################################################
# Websockets, TLS upgrades etc
# if not IMP the forwarding will be done inside this function, otherwise it
# will be done in _in_data_imp, which gets called by IMP callback
############################################################################
sub in_data {
    my ($self,$dir,$data,$eof) = @_;

    if ( my $imp = $self->{imp_analyzer} ) {
	my $debug = $DEBUG && debug_context( id => $self->id);
	$data ne '' and $imp->data($dir,$data,\&_in_data_imp,$self);
	$eof and $imp->data($dir,'',\&_in_data_imp,$self);
    } else {
	my $relay = $self->{conn}{relay} or return;
	$DEBUG && $self->xdebug("got %d bytes from %d, eof=%d",length($data),$dir,$eof);
	if ( $data ne '' ) {
	    if ( $dir == 1 ) {
		$relay->forward(1,0,$data)
	    } else {
		$relay->forward(0,1,$data) if $self->{connected} == CONN_HOST;
	    }
	}
	$relay->account('upgrade') if $eof;
    }
}
sub _in_data_imp {
    my ($self,$dir,$data,$eof) = @_;
    my $relay = $self->{conn}{relay} or return;
    $DEBUG && $self->xdebug("imp got %d bytes from %d, eof=%d",length($data),$dir,$eof);
    if ( $data ne '' ) {
	if ( $dir == 1 ) {
	    $relay->forward(1,0,$data)
	} else {
	    $relay->forward(0,1,$data) if $self->{connected} == CONN_HOST;
	}
    }

    $relay->account('upgrade') if $eof;
}

############################################################################
# chunks and junk gets ignored
# - we decide ourself, when we will forward data chunked and do the
#   chunking ourself
# - junk data will not be forwarded
############################################################################

sub in_chunk_header {}
sub in_chunk_trailer {}
sub in_junk {}


1;

