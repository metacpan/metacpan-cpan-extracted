package AnyEvent::HTTP::Socks;

use strict;
use Socket;
use IO::Socket::Socks;
use AnyEvent::Socket;
use Errno;
use Carp;
use base 'Exporter';
require AnyEvent::HTTP;

our $VERSION = '0.05';

our @EXPORT = qw(
	http_get
	http_head
	http_post
	http_request
);

use constant {
	READ_WATCHER  => 1,
	WRITE_WATCHER => 2,
};

sub http_get($@) {
	unshift @_, 'GET';
	&http_request;
}

sub http_head($@) {
	unshift @_, 'HEAD';
	&http_request;
}

sub http_post($$@) {
	my $url = shift;
	unshift @_, 'POST', $url, 'body';
	&http_request;
}

sub http_request($$@) {
	my ($method, $url, $cb) = (shift, shift, pop);
	my %opts = @_;
	
	my $socks = delete $opts{socks};
	if ($socks) {
		my @chain;
		while ($socks =~ m!socks(4|4a|5)://(?:([^\s:]+):([^\s@]*)@)?(\[[0-9a-f:.]+\]|[^\s:]+):(\d+)!gi) {
			push @chain, {ver => $1, login => $2, pass => $3, host => $4, port => $5};
		}
		
		if (@chain) {
			$opts{tcp_connect} = sub {
				my ($cv, $watcher, $timer, $sock);
				my @tmp_chain = @chain; # copy: on redirect @tmp_chain will be already empty
				_socks_prepare_connection(\$cv, \$watcher, \$timer, $sock, \@tmp_chain, @_);
			};
		}
		else {
			croak 'unsupported socks address specified';
		}
	}
	
	AnyEvent::HTTP::http_request( $method, $url, %opts, $cb );
}

sub inject {
	my ($class, $where) = @_;
	$class->export($where, @EXPORT);
}

sub _socks_prepare_connection {
	my ($cv, $watcher, $timer, $sock, $chain, $c_host, $c_port, $c_cb, $p_cb) = @_;
	
	unless ($sock) { # first connection in the chain
		# XXX: need also support IPv6 when SOCKS host is a domain name, but this is not so easy
		socket(
			$sock,
			$chain->[0]{host} =~ /^\[.+\]$/ ? PF_INET6 : PF_INET,
			SOCK_STREAM,
			getprotobyname('tcp')
		)
		or return $c_cb->();
			
		my $timeout = $p_cb->($sock);
		$$timer = AnyEvent->timer(
			after => $timeout,
			cb => sub {
				undef $$watcher;
				undef $$cv;
				$! = Errno::ETIMEDOUT;
				$c_cb->();
			}
		);
		
		$_->{host} =~ s/^\[// and $_->{host} =~ s/\]$// for @$chain;
	}
	
	$$cv = AE::cv {
		_socks_connect($cv, $watcher, $timer, $sock, $chain, $c_host, $c_port, $c_cb);
	};
	
	$$cv->begin;
	
	$$cv->begin;
	inet_aton $chain->[0]{host}, sub {
		$chain->[0]{host} = format_address shift;
		$$cv->end if $$cv;
	};
	
	if (($chain->[0]{ver} == 5 &&  $IO::Socket::Socks::SOCKS5_RESOLVE == 0) ||
	    ($chain->[0]{ver} eq '4' && $IO::Socket::Socks::SOCKS4_RESOLVE == 0)) { # 4a = 4
		# resolving on the client side enabled
		my $host = @$chain > 1 ? \$chain->[1]{host} : \$c_host;
		$$cv->begin;
		
		inet_aton $$host, sub {
			$$host = format_address shift;
			$$cv->end if $$cv;
		}
	}
	
	$$cv->end;
	
	return $sock;
}

sub _socks_connect {
	my ($cv, $watcher, $timer, $sock, $chain, $c_host, $c_port, $c_cb) = @_;
	my $link = shift @$chain;
	
	my @specopts;
	if ($link->{ver} eq '4a') {
		$link->{ver} = 4;
		push @specopts, SocksResolve => 1;
	}
	
	if (defined $link->{login}) {
		push @specopts, Username => $link->{login};
		if ($link->{ver} == 5) {
			push @specopts, Password => $link->{pass}, AuthType => 'userpass';
		}
	}
	
	my ($host, $port) = @$chain ? ($chain->[0]{host}, $chain->[0]{port}) : ($c_host, $c_port);
	
	if (ref($sock) eq 'GLOB') {
		# not connected socket
		$sock = IO::Socket::Socks->new_from_socket(
			$sock,
			Blocking     => 0,
			ProxyAddr    => $link->{host},
			ProxyPort    => $link->{port},
			SocksVersion => $link->{ver},
			ConnectAddr  => $host,
			ConnectPort  => $port,
			@specopts
		) or return $c_cb->();
	}
	else {
		$sock->command(
			SocksVersion => $link->{ver},
			ConnectAddr  => $host,
			ConnectPort  => $port,
			@specopts
		) or return $c_cb->();
	}
	
	my ($poll, $w_type) = $SOCKS_ERROR == SOCKS_WANT_READ ?
	                                  ('r', READ_WATCHER) :
	                                  ('w', WRITE_WATCHER);
	
	$$watcher = AnyEvent->io(
		fh => $sock,
		poll => $poll,
		cb => sub { _socks_handshake($cv, $watcher, $w_type, $timer, $sock, $chain, $c_host, $c_port, $c_cb) }
	);
}

sub _socks_handshake {
	my ($cv, $watcher, $w_type, $timer, $sock, $chain, $c_host, $c_port, $c_cb) = @_;
	
	if ($sock->ready) {
		undef $$watcher;
		
		if (@$chain) {
			return _socks_prepare_connection($cv, $watcher, $timer, $sock, $chain, $c_host, $c_port, $c_cb);
		}
		
		undef $$timer;
		return $c_cb->($sock);
	}
	
	if ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
		if ($w_type != WRITE_WATCHER) {
			undef $$watcher;
			$$watcher = AnyEvent->io(
				fh => $sock,
				poll => 'w',
				cb => sub { _socks_handshake($cv, $watcher, WRITE_WATCHER, $timer, $sock, $chain, $c_host, $c_port, $c_cb) }
			);
		}
	}
	elsif ($SOCKS_ERROR == SOCKS_WANT_READ) {
		if ($w_type != READ_WATCHER) {
			undef $$watcher;
			$$watcher = AnyEvent->io(
				fh => $sock,
				poll => 'r',
				cb => sub { _socks_handshake($cv, $watcher, READ_WATCHER, $timer, $sock, $chain, $c_host, $c_port, $c_cb) }
			);
		}
	}
	else {
		# unknown error
		$@ = "IO::Socket::Socks: $SOCKS_ERROR";
		undef $$watcher;
		undef $$timer;
		$c_cb->();
	}
}

1;
__END__

=head1 NAME

AnyEvent::HTTP::Socks - Adds socks support for AnyEvent::HTTP 

=head1 SYNOPSIS

  use AnyEvent::HTTP;
  use AnyEvent::HTTP::Socks;
  
  http_get 'http://www.google.com/', socks => 'socks5://localhost:1080', sub {
      print $_[0];
  };

=head1 DESCRIPTION

This module adds new `socks' option to all http_* functions exported by AnyEvent::HTTP.
So you can specify socks proxy for HTTP requests.

This module uses IO::Socket::Socks as socks library, so any global variables like
$IO::Socket::Socks::SOCKS_DEBUG can be used to change the behavior.

Socks string structure is:

  scheme://login:password@host:port
  ^^^^^^   ^^^^^^^^^^^^^^ ^^^^ ^^^^
    1             2         3    4

1 - scheme can be one of the: socks4, socks4a, socks5

2 - "login:password@" part can be ommited if no authorization for socks proxy needed. For socks4
proxy "password" should be ommited, because this proxy type doesn't support login/password authentication,
login will be interpreted as userid.

3 - ip or hostname of the proxy server

4 - port of the proxy server

You can also make connection through a socks chain. Simply specify several socks proxies in the socks string
and devide them by tab(s) or space(s):

  "socks4://10.0.0.1:1080  socks5://root:123@10.0.0.2:1080  socks4a://85.224.100.1:9010"

If you want to specify socks host as IPv6 address you need to use square brackets:

  "socks5://[2a00:1450:400f:805::200e]:1080"

=head1 METHODS

=head2 AnyEvent::HTTP::Socks->inject('Package::Name')

Add socks support to some package based on AnyEvent::HTTP.

Example:

	use AnyEvent::HTTP;
	use AnyEvent::HTTP::Socks;
	use AnyEvent::Google::PageRank qw(rank_get);
	use strict;
	
	AnyEvent::HTTP::Socks->inject('AnyEvent::Google::PageRank');
	
	rank_get 'http://mail.com', socks => 'socks4://localhost:1080', sub {
		warn $_[0];
	};

=head1 NOTICE

You should load AnyEvent::HTTP::Socks after AnyEvent::HTTP, not before. Or simply load only AnyEvent::HTTP::Socks
and it will load AnyEvent::HTTP automatically.

=head1 SEE ALSO

L<AnyEvent::HTTP>, L<IO::Socket::Socks>

=head1 AUTHOR

Oleg G, E<lt>oleg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Oleg G

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
