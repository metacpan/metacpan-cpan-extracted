use strict;
use warnings;

package App::HTTP_Proxy_IMP::Relay;
use fields (
    'fds',      # file descriptors
    'conn',     # App::HTTP_Proxy_IMP::HTTPConn object
    'acct',     # collect accounting
);

use App::HTTP_Proxy_IMP::Debug;
use Scalar::Util 'weaken';
use IO::Socket::SSL;
use AnyEvent;
use POSIX '_exit';

# set if the child should destroy itself after last connection closed
my $exit_if_no_relays;
sub exit_if_no_relays { $exit_if_no_relays = pop; }

# active relay, inserted in new, removed in $idlet timer
my @relays;
sub relays { return grep { $_ } @relays }

# creates new relay and puts it into @relays as weak reference
sub new {
    my ($class,$cfd,$upstream,$conn) = @_;
    my $self = fields::new($class);
    debug("create relay $self");

    if ( $upstream && ! ref($upstream)) {
	$upstream =~m{\A(?:\[([a-f\d:.]+)\]|([\da-z_\-.]+)):(\d+)\Z} or
	    die "invalid upstream specification: $upstream";
	$upstream = [ $1||$2, $3 ];
    }

    my $cobj = $conn->new_connection({
	daddr => $cfd->sockhost,
	dport => $cfd->sockport,
	saddr => $cfd->peerhost,
	sport => $cfd->peerport,
	upstream => $upstream,
    },$self);

    #debug("create connection $cobj");
    $self->{conn} = $cobj;
    my $cfo = $self->{fds}[0] = App::HTTP_Proxy_IMP::Relay::FD->new(0,$cfd,$self,1);
    $cfo->mask( r => 1 ); # enable read 

    push @relays, $self;
    weaken($relays[-1]);

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->account('destroy');
    $self->xdebug("destroy relay $self");
    if ( $exit_if_no_relays && ! $self->relays ) {
	# der letzte macht das Licht aus
	debug("exit child $$ after last connection");
	_exit(0)
    }
}

sub acctinfo {
    my ($self,$acct) = @_;
    $self->{acct} = $acct;
}
sub account {
    my ($self,$what,%args) = @_;
    my $acct = $self->{acct};
    $acct = $acct ? { %$acct,%args } : \%args if %args;
    $acct or return;
    $self->{acct} = undef;
    if ( my $t = delete $acct->{start} ) {
	$acct->{duration} = AnyEvent->now - $t;
    }
    my @msg;
    for( sort keys %$acct ) {
	my $t;
	my $v = $acct->{$_};
	if ( ! defined $v ) {
	    next;
	} elsif ( ref($v) eq 'ARRAY') {
	    $t = "$_=[".join(',',map { _quote($_) } @$v)."]";
	} elsif ( defined $v ) {
	    $t = "$_="._quote($v);
	}
	push @msg,$t;
    }
    print STDERR "ACCT @msg\n";
}

sub _quote {
    my $text = shift;
    $text =~s{([\000-\037\\"\377-\777])}{ sprintf("\\%03o",ord($1)) }eg;
    return $text =~m{ } ? qq["$text"]:$text;
}

sub xdebug {
    my $self = shift;
    my $conn = $self->{conn};
    if ( my $xdebug = UNIVERSAL::can($conn,'xdebug') ) {
	unshift @_,$conn;
	goto &$xdebug;
    } else {
	goto &debug;
    }
}


# non-fatal problem
sub error {
    my ($self,$reason) = @_;
    warn "[error] ".( $self->{conn} && $self->{conn}->id || 'noid')." $reason\n";
    return 0;
}

# fatal problem - close connection
sub fatal {
    my ($self,$reason) = @_;
    warn "[fatal] ".( $self->{conn} && $self->{conn}->id || 'noid')." $reason\n";
    $self->close;
    return 0;
}

sub connect:method {
    my ($self,$to,$host,$port,$callback,$reconnect) = @_;
    my $fo = $self->{fds}[$to] ||= App::HTTP_Proxy_IMP::Relay::FD->new($to,undef,$self);
    $fo->connect($host,$port,$callback,$reconnect);
}

# masks/unmasks fd for dir, rw = r|w
sub mask {
    my ($self,$dir,$rw,$v) = @_;
    my $fd = $self->{fds}[$dir] or do {
	warn "fd dir=$dir does not exists\n";
	return;
    };
    $fd->mask($rw,$v);
}

sub fd {
    my ($self,$dir) = @_;
    return $self->{fds}[$dir];
}

# send some data via fd dir
sub forward {
    my ($self,$from,$to,$data) = @_;
    my $fo = $self->{fds}[$to] or return
	$self->fatal("cannot write to $to - no such fo");
    $self->xdebug("$from>$to - forward %d bytes",length($data));
    $fo->write($data,$from);
}

# ssl interception, e.g. upgrade both client and server to SSL sockets,
# where I can read/write unencrypted data
sub sslify {
    my ($self,$from,$to,$hostname,$callback) = @_;
    my $conn = $self->{conn} or return;
    my $mitm = $conn->{mitm} or return; # no MITM needed

    # destroy the current connection object and create a new obne
    $conn = $self->{conn} = $conn->clone;
    $conn->{intunnel} = 1;
    
    my $sfo = $self->{fds}[$from] or return
	$self->fatal("cannot startssl $from - no such fo");

    # stop handling all data
    $self->mask($to,r=>0);
    $self->mask($from,r=>0);
    weaken( my $wself = $self );

    my %sslargs = (
	SSL_verifycn_name => $hostname,
	SSL_verifycn_schema => 'http',
	SSL_hostname => $hostname, # SNI
	$conn->{capath} ? (
	    SSL_verify_mode => SSL_VERIFY_PEER,
	    ( -d $conn->{capath} ? 'SSL_ca_path' : 'SSL_ca_file' ), 
	    $conn->{capath}
	):( 
	    SSL_verify_mode => SSL_VERIFY_NONE 
	)
    );
    $sfo->startssl( %sslargs, sub {
	my $sfo = shift;
	my ($cert,$key) = $mitm->clone_cert($sfo->{fd}->peer_certificate);
	my $cfo = $wself->{fds}[$to] or return
	    $wself->fatal("cannot startssl $to - no such fo");
	$cfo->startssl(
	    SSL_server => 1,
	    SSL_cert => $cert,
	    SSL_key  => $key,
	    sub {
		# allow data again
		$self->mask($to,r=>1);
		$self->mask($from,r=>1);
		$callback->() if $callback;
	    }
	);
    });
}

# closes relay
sub close:method {
    my $self = shift;
    #debug("close $self");
    undef $self->{conn};
    @relays = grep { !$_ or $_ != $self } @relays;
    $_ && $_->close for @{$self->{fds}};
    @{$self->{fds}} = ();
}

# shutdown part of relay
sub shutdown:method {
    my ($self,$dir,$rw,$force) = @_;
    my $fo = $self->{fds}[$dir] or return;
    $fo->shutdown($rw,$force);
}

# check for condition, where we cannot transfer anymore data:
# - nowhere to read and no open requests
# - nowhere to write too
sub closeIfDone {
    my $self = shift;
    my $sink = my $drain = '';
    for my $fo (@{$self->{fds}}) {
	$fo && $fo->{fd} or next;
	return if $fo->{rbuf} ne ''; # has unprocessed data
	return if $fo->{wbuf} ne ''; # has unwritten data
	$drain .= $fo->{dir} if not $fo->{status} & 0b100; # not read-closed
	$sink  .= $fo->{dir} if not $fo->{status} & 0b010; # not write-closed
    }

    if ( $sink eq '' ) {      # nowhere to write
	$DEBUG && $self->xdebug( "close relay because all fd done sink='$sink' ");
	# close relay
	return $self->close;
    }

    if ( $drain ne '01' ) {  # no reading from both sides
	my $conn = $self->{conn};
	if ( ! $conn or ! $conn->open_requests ) {
	    # close relay
	    $DEBUG && $self->xdebug( "close relay because nothing to read and all done");
	    return $self->close;
	}
    }

    $DEBUG && $self->xdebug("drain=$drain sink=$sink rq=".$self->{conn}->open_requests." - keeping open");
    return;
}


# dump state to debug
sub dump_state {
    my $self = shift;
    my $conn = $self->{conn};
    my $msg = '';
    if ( my $fds = $self->{fds} ) {
        my @st;
        for( my $i=0;$i<@$fds;$i++) {
            push @st, sprintf("%d=%03b",$i,$fds->[$i]{status} || 0);
        }
	$msg .= " fd:".join(',',@st);
    }
    $msg = $conn->dump_state().$msg;
    return $msg if defined wantarray;
    debug($msg);
}


my $idlet = AnyEvent->timer( 
    after => 5, 
    interval => 5, cb => sub {
        @relays = grep { $_ } @relays or return;
        #debug("check timeouts for %d conn",+@relays);
        my $now = AnyEvent->now;
	RELAY: for my $r (@relays) {
	    # timeout depends on the state of the relay and child
	    # if there are active requests set it to 60, if not (e.g.
	    # idle keep-alive connections) to 30. If this is a forked
	    # child with no listener which should close after all
	    # requests are done close idle keep-alive connections faster,
	    # e.g. set timeout to 1
	    my $idle = ! $r->{conn}->open_requests;
	    my $timeout = 
		! $idle ? 60 :
		$exit_if_no_relays ? 1 :
		30;
	    for my $fo (@{$r->{fds}}) {
		next RELAY if $_->{didit} + $timeout > $now;
	    }
	    $r->xdebug("close because of timeout");
            $r->close
        }
    }
);

############################################################################
# Filehandle
############################################################################

package App::HTTP_Proxy_IMP::Relay::FD;
use Carp 'croak';
use Scalar::Util 'weaken';
use App::HTTP_Proxy_IMP::Debug;
use AnyEvent::Socket qw(tcp_connect format_address);
use IO::Socket::SSL;

use fields (
    'dir',        # direction 0,1
    'fd',         # file descriptor
    'host',       # destination hostname
    'status',     # bitmap of read_shutdown|write_shutdown|connected
    'relay',      # weak link to relay
    'didit',      # time of last activity (read/write)
    'rbuf',       # read buffer (read but not processed)
    'rsub',       # read handler
    'rwatch',     # AnyEvent watcher - undef if read is disabled
    'wbuf',       # write buffer (not yet written to socket)
    'wsub',       # write handler
    'wwatch',     # AnyEvent watcher - undef if write is disabled
    'wsrc',       # source of writes for stalled handling
);

sub new {
    my ($class,$dir,$fd,$relay,$connected) = @_;
    my $self = fields::new($class);
    $self->{dir} = $dir;
    $self->{fd} = $fd;
    $self->{status} = $connected ? 0b001 : 0;
    #weaken( $self->{relay} = $relay );
    $self->{relay} = $relay;
    $self->{rbuf} = $self->{wbuf} = '';
    return $self;
}

sub xdebug {
    my $self = shift;
    my $conn = $self->{relay}{conn};
    if ( my $xdebug = UNIVERSAL::can($conn,'xdebug') ) {
	my $msg = "[$self->{dir}] ".shift(@_);
	unshift @_,$conn,$msg;
	goto &$xdebug;
    } else {
	goto &debug;
    }
}

sub close:method { 
    my $self = shift;
    $self->xdebug("close");
    if ( $self->{fd} ) {
	$self->{fd} = undef;
	delete $self->{relay}{fds}[$self->{dir}];
	$self->{relay}->closeIfDone;
    }
    %$self = ();
}

sub reset {
    my $self = shift;
    $self->xdebug("reset");
    close($self->{fd}) if $self->{fd};
    $self->{fd} = 
	$self->{rwatch} = $self->{rsub} = 
	$self->{wwatch} = $self->{wsub} = 
	$self->{host} =
	$self->{wsrc} =
	undef;
    $self->{status} = $self->{didit} = 0;
    $self->{rbuf} = $self->{wbuf} = '';
    return 1;
}

# attempt to shutdown fd.
# don't shutdown(1) if wbuf ne '' && ! $force
sub shutdown:method {
    my ($self,$rw,$force) = @_;
    my $write = $rw eq 'r' ? 0 : $rw eq 'w' ? 1 : $rw;
    my $stat = $write ? 0b010 : 0b100;
    return if $self->{status} & $stat && ! $force; # no change

    $self->{status} |= $stat;
    if ( $write && $self->{wbuf} ne '' ) {
	$self->xdebug("called shutdown $rw fn=".fileno($self->{fd}).
	    " wbuf.len=".length($self->{wbuf}));
	return if ! $force; # will shutdown once all is written
	$self->{wbuf} = ''; # drop rest
	undef $self->{wsrc}; # don't re-enable, unclear state
	undef $self->{wwatch};
    }
	
    $self->xdebug("shutdown $rw fn=".fileno($self->{fd}));
    shutdown($self->{fd},$write);
    # shutdown on both sides -> close
    if (( $self->{status} & 0b110 ) == 0b110 ) {
	$self->xdebug( "close fn=".fileno($self->{fd})." because status $self->{status} done");
	$self->close;
    } elsif ( $write ) {
	undef $self->{wwatch};
    } else {
	undef $self->{rwatch};
    }

    # if all fd are closed, close the relay too
    $self->{relay}->closeIfDone;

    return 1;
}


sub mask {
    my ($self,$rw,$val) = @_;
    #debug("$self->{dir} $self->{fd} fn=".fileno($self->{fd})." $rw=>$val");
    if ( $rw eq 'r' ) {
	if ( ! $val ) {
	    # disable read
	    undef $self->{rwatch};
	} else {
	    $self->{status} & 0b100 and return 0; # read shutdown already
	    $self->{rsub} ||= sub { _read($self) }; 
	    $self->{rwatch} = AnyEvent->io(
		fh => $self->{fd},
		poll => 'r',
		cb => ref($val) ? $val : $self->{rsub}
	    );
	}
    } elsif ( $rw eq 'w' ) {
	if ( ! $val ) {
	    # disable write
	    undef $self->{wwatch};
	} else {
	    $self->{status} & 0b010 and return 0; # write shutdown already
	    $self->{wsub} ||= sub { _writebuf($self) }; 
	    $self->{wwatch} = AnyEvent->io(
		fh => $self->{fd},
		poll => 'w',
		cb => ref($val) ? $val : $self->{wsub}
	    );
	}
    } else {
	croak("cannot set mask for $rw");
    }
    return 1;
}

# write data, gets written from relay->send
sub write:method {
    my ($self,$data,$from) = @_;
    my $n = 0;
    if ( $self->{wbuf} eq '' ) {
	# no buffered data, set as buffer and try to write immediately
	$self->{wbuf} = $data;
	$n = _writebuf($self,$from) // return; # fatal?
    } else {
	# only append to buffer, will be written on write ready
	$self->{wbuf} .= $data;
    }

    if ( $self->{wbuf} ne '' 
	&& ! $self->{wsrc}{$from}++ ) {
	# newly stalled, disable reads on $from for now
	$self->{relay}->mask($from, r=>0);
    }
    return $n;
}

# gets called if wbuf is not empty, either from write or from callback
# when fd is writable again
sub _writebuf {
    my $self = shift;
    #debug("write $self fn=".fileno($self->{fd}));
    my $n = syswrite($self->{fd},$self->{wbuf});
    #debug("write(%s,%d) -> %s", $self->{dir},length($self->{wbuf}), (defined $n ? $n : $!));
    if ( ! defined $n ) {
        $self->{relay}->fatal("write($self->{dir}) failed: $!")
	    unless $!{EINTR} or $!{EAGAIN};
        return;
    }

    substr($self->{wbuf},0,$n,'');
    $self->{didit} = AnyEvent->now;

    if ( $self->{wbuf} eq '' ) {
        # wrote everything
        #debug("all written to $self->{dir}");
        undef $self->{wwatch};

	if ( $self->{status} & 0b100 ) {
	    # was marked for shutdown
	    shutdown($self->{fd},1);
	    # if all fd are closed, close the relay too
	    $self->{relay}->closeIfDone;
	}
        # enable read again on stalled fd
	if ( my $src = $self->{wsrc} ) {
	    $self->{relay}->mask($_, r=>1) for (keys %$src);
	}
    } else {
	# need to write more later
	#debug("need to write more");
	mask($self,w=>1);
    }
    return $n;
}

# gets called if data are available on the socket
# but only, if we don't have unsent data in wbuf
# reads data into rbuf and calls connection->in
sub _read:method {
    my $self = shift;
    #debug("read $self fn=".fileno($self->{fd}));
    my $n = sysread($self->{fd},$self->{rbuf},2**15,length($self->{rbuf}));
    #debug("read done: ". (defined $n ? $n : $!));
    if ( ! defined $n ) {
	if ( ! $!{EINTR} and ! $!{EAGAIN} ) {
	    # complain only if we are inside a request
	    # timeouts after inactivity are normal
	    return $self->{relay}->fatal("read($self->{dir}) failed: $!")
		if $self->{relay}{conn}->open_requests;

	    # close connection
	    $self->xdebug("closing relay because of read error on $self->{dir}");
	    return $self->{relay}->close;
	}
        return;
    }

    $self->{didit} = AnyEvent->now;
    my $bytes = $self->{relay}{conn}
	->in($self->{dir},$self->{rbuf},!$n,$self->{didit});

    # fd/relay closed from within in() ?
    defined $self->{fd} or return; 

    if ( $bytes ) {
	# connection accepted $bytes
	substr($self->{rbuf},0,$bytes,'');
    }

    return $self->{relay}->fatal(
	"connection should have taken all remaining bytes on eof")
	if !$n && $self->{rbuf} ne '';

    $self->shutdown('r') if ! $n;
}

sub connect:method {
    my ($self,$host,$port,$callback,$reconnect) = @_;

    # down existing connection if we should connect to another host
    $self->reset if $self->{fd} and 
	( $reconnect or $self->{host}||'' ne "$host.$port" );

    # if we have a connection already, keep it
    if ( $self->{status} & 0b001 ) { # already connected 
	$callback->();
	return 1;
    }

    # (re)connect
    $self->xdebug("connecting to $host.$port");
    # async dns lookup + connect
    App::HTTP_Proxy_IMP::Relay::DNS::lookup($host, sub {
	$self->{relay} or return; # relay already closed
	if ( my $addr = shift ) {
	    tcp_connect($addr,$port, sub {
		if ( my $fd = shift ) {
		    $self->{relay} or return; # relay already closed
		    $self->{fd} = $fd;
		    $self->{status} = 0b001;
		    $self->{host} = "$host.$port";
		    $self->xdebug("connect done");
		    $self->mask( r => 1 );
		    $callback->();
		} else {
		    App::HTTP_Proxy_IMP::Relay::DNS::uncache($host,$addr);
		    $self->{relay} or return; # relay already closed
		    $self->{relay}->fatal("connect to $host.$port failed: $!");
		}
	    });
	} else {
	    $self->{relay}->fatal(
		"connect to $host.$port failed: no such host (DNS)");
	}
    });
    return -1;
}

sub startssl {
    my $self = shift;
    $self->{rbuf} eq '' or return 
	$self->{relay}->fatal("read buf $self->{dir} not empty before starting SSL: '$self->{rbuf}'");
    $self->{wbuf} eq '' or return 
	$self->{relay}->fatal("write buf $self->{dir} not empty before starting SSL: '$self->{wbuf}'");

    my $callback = @_%2 ? pop(@_):undef;
    my %sslargs = @_;
    IO::Socket::SSL->start_SSL( $self->{fd},
	%sslargs,
	SSL_startHandshake => 0,
    ) or die "failed to upgrade socket to SSL";
    my $sub = $sslargs{SSL_server} 
	? \&IO::Socket::SSL::accept_SSL
	: \&IO::Socket::SSL::connect_SSL;
    _ssl($self,$sub,$callback,\%sslargs);
}

sub _ssl {
    my ($self,$sub,$cb,$sslargs) = @_;
    if ( $sub->($self->{fd}) ) {
	$self->xdebug("ssl handshake success");
	$cb->($self) if $cb;
    } elsif ( $!{EAGAIN} ) {
	# retry
	my $dir = 
	    $SSL_ERROR == SSL_WANT_READ ? 'r' :
	    $SSL_ERROR == SSL_WANT_WRITE ? 'w' :
	    return $self->{relay}->fatal( "unhandled $SSL_ERROR on EAGAIN" );
	$self->mask( $dir => sub { _ssl($self,$sub,$cb,$sslargs) });
    } elsif ( $sslargs->{SSL_server} ) {
	return $self->{relay}->fatal( "error on accept_SSL: $SSL_ERROR|$!" );
    } else {
	return $self->{relay}->fatal( 
	    "error on connect_SSL to $sslargs->{SSL_verifycn_name}: $SSL_ERROR|$!" );
    }
}


############################################################################
# DNS cache
############################################################################

package App::HTTP_Proxy_IMP::Relay::DNS;
use AnyEvent::DNS;
use Socket qw(AF_INET AF_INET6 inet_pton);

my %cache;
sub uncache {
    my ($host,$addr) = @_;
    my $e = $cache{lc($host)} or return;
    @$e = grep { $_ ne $addr } @$e;
    delete $cache{lc($host)} if !@$e;
}

sub lookup {
    my ($host,$cb) = @_;
    $host = lc($host);

    if ( my $e = $cache{$host} ) {
	return $cb->(@$e);
    } elsif ( inet_pton(AF_INET,$host) || inet_pton(AF_INET6,$host) ) {
	return $cb->($host);
    }

    AnyEvent::DNS::a($host,sub {
	if ( @_ ) {
	    $cache{$host} = [ @_ ];
	    return $cb->(@_);
	}

	# try AAAA
	AnyEvent::DNS::aaaa($host,sub {
	    $cache{$host} = [ @_ ] if @_;
	    return $cb->(@_);
	});
    });
}

1;
