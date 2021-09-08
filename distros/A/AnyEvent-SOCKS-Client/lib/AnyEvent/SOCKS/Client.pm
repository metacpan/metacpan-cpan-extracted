=head1 NAME

AnyEvent::SOCKS::Client - AnyEvent-based SOCKS client!

=head1 VERSION

Version 0.051

=cut

=head1 SYNOPSIS

Constructs function which behave like AnyEvent::Socket::tcp_connect

    use AnyEvent::SOCKS::Client qw/tcp_connect_via/;

    $AnyEvent::SOCKS::Client::TIMEOUT = 30;
    # used only if prepare_cb NOT passed to proxied function
    # e.g. AE::HTTP on_prepare callback is not present

    my @chain = qw/socks5://user:pass@192.0.2.100:1080 socks5://198.51.100.200:9080/;
    tcp_connect_via( @chain )->( 'example.com', 80, sub{
        my ($fh) = @_ or die "Connect failed $!";
        ...
    }); 

SOCKS client for AnyEvent::HTTP

    http_get "http://example.com/foo",
        tcp_connect => tcp_connect_via('socks5://198.51.100.200:9080'),
        sub{
            my( $data, $header) = @_ ;
            ...
        };

=head1 SECURITY

By default resolves names on SOCKS server. No DNS leaks.

=head1 SUBROUTINES/METHODS 

=head2 $sub = tcp_connect_via( @proxy_uris )

Function accepts proxy list and return proxied tcp_connect function. See AnyEvent::Socket docs for more information about its semantics. 

=cut

=head1 Errors and logging

Module uses AE::log for error reporting. You can use "error" or "debug" levels to get more information about errors. 

=cut

package AnyEvent::SOCKS::Client;

use 5.006;
use strict ;

use AnyEvent;
use AnyEvent::Util qw/guard/;
use AnyEvent::Socket qw/tcp_connect parse_ipv4 format_ipv4 parse_ipv6 format_ipv6/;
use AnyEvent::Handle ;
use AnyEvent::Log ;

use Scalar::Util qw/weaken/;

require Exporter;
our $VERSION = '0.051';
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/tcp_connect_via/;

our $TIMEOUT = 300;

use constant {
	TYPE_IP4 => 1,
	TYPE_IP6 => 4,
	TYPE_FQDN => 3,
	
	AUTH_ANON => 0,
	AUTH_GSSAPI => 1,
	AUTH_LOGIN => 2,
	AUTH_GTFO => 255,
	
	CMD_CONNECT => 1 ,
	CMD_BIND => 2, 
	CMD_UDP_ASSOC => 3,
};

sub _parse_uri{
	my $re = qr!socks(4|4a|5)://(?:([^\s:]+):([^\s@]*)@)?(\[[0-9a-f:.]+\]|[^\s:]+):(\d+)!i ;
	if( $_[0] =~ m/$re/gi ){
		my $p = {v => $1, login => $2, password => $3, host => $4, port => $5};
		$p->{host} =~ s/^\[|\]$//g;
		return $p;
	}
	undef ;
}
# returns tcp_connect compatible function
sub tcp_connect_via{
	my(@chain) = @_ ;

	unless( @chain ){
		AE::log "error" => "No socks were given, abort"; 
		return sub{ $_[2]->() };
	}
	my @parsed;
	for(@chain){
		if( my $p = _parse_uri($_) ){
			push @parsed, $p; next;
		}
		AE::log "error" => "Invalid socks uri: $_";
		return sub{ $_[2]->() };
	}

	return sub{
		my( $dst_host, $dst_port, $c_cb, $pre_cb ) = @_ ;
		my $con = bless {
			chain => \@parsed,
			dst_host => $dst_host,
			dst_port => $dst_port,
			c_cb => $c_cb,
			pre_cb => $pre_cb,
		}, __PACKAGE__ ;
		$con->connect;

		if( defined wantarray ){ # not void
			weaken( $con );
			return guard{
				AE::log "debug" => "Guard triggered" ;
				if( ref $con eq __PACKAGE__ ){
					undef $con->{c_cb};
					$con->DESTROY;
				}
			};
		}
		undef;
	};
}

sub connect{
	my( $self ) = @_ ;
	# tcp connect to first socks
	my $that = $self->{chain}->[0] ;
	$self->{_guard} = tcp_connect $that->{host}, $that->{port}, sub{
		my $fh = shift ;
		unless($fh){
			AE::log "error" => "$that->{host}:$that->{port} connect failed: $!";
			return;
		}

		$self->{hd} = new AnyEvent::Handle(
			fh => $fh,
			on_error => sub{
				my ($hd, $fatal, $msg) = @_;
				AE::log "error" => ( $fatal ? "Fatal " : "" ) . $msg ;
				$hd->destroy unless( $hd->destroyed );
				return;
			}
		);
		if($that->{v} =~ /4a?/){
			$self->connect_socks4;
			return;
		}
		$self->handshake;
	}, $self->{pre_cb} || sub{ $TIMEOUT };
}

sub connect_socks4{
	my( $self ) = @_;
	my( $that, $next ) = @{ $self->{chain} } ;
	my( $host, $port ) = $next 
		? ( $next->{host}, $next->{port} )
		: ( $self->{dst_host}, $self->{dst_port} ) ;

	my $ip4 = parse_ipv4($host);
	if( $that->{v} eq '4' and not $ip4 ){
		AE::log "error" => "SOCKS4 is only support IPv4 addresses: $host given";
		return;
	}

	if( $host =~ /:/ ){
		AE::log "error" => "SOCKS4/4a doesn't support IPv6 addresses: $host given";
		return;
	}
	AE::log "debug" => "SOCKS4 connect to $host:$port";
	$self->{hd}->push_write( $ip4 
		? pack('CCnA4A2', 4, CMD_CONNECT, $port, $ip4, "X\0" )
		: pack('CCnCCCCA*', 4, CMD_CONNECT, $port, 0,0,0,7 , "X\0$host\0" )
	);
	$self->{hd}->push_read( chunk => 8, sub{
		my($code, $dst_port, $dst_ip) = unpack('xCna4', $_[1]);
		unless( $code == 90 ){
			AE::log "error" => "SOCKS4/4a request rejected: code is $code";
			return;
		}
		$self->socks_connect_done( format_ipv4( $dst_ip ), $dst_port );
	});
}

sub handshake{
	my( $self ) = @_;
	my $that = $self->{chain}->[0] ;
	my @auth_methods = 0 ;
	if($that->{login} and $that->{password}){
		push @auth_methods, AUTH_LOGIN ;
	}
	$self->{hd}->push_write( 
		pack('CC', 5, scalar @auth_methods ) . join( "", map( pack( 'C', $_ ), @auth_methods ))
	);
	$self->{hd}->push_read( chunk => 2 , sub{
		my $method = unpack( 'xC', $_[1] ); 
		AE::log "debug" => "Server want auth method $method" ;
		if($method == AUTH_GTFO ){
			AE::log "error" => "Server: no suitable auth method";
			return ;
		}

		if( $method ) {
			$self->auth($method);
		}
		else {
			$self->connect_cmd ;
		}
	 });
}

sub auth{
	my( $self, $method ) = @_;
	my $that = $self->{chain}->[0] ;
	if( $method == AUTH_LOGIN and $that->{login} and $that->{password}){
		$self->{hd}->push_write( 
			pack('CC', 5, length $that->{login} ) . $that->{login} 
			. pack('C', length $that->{password}) . $that->{password} 
		);
		$self->{hd}->push_read( chunk => 2, sub{
			my $status = unpack('xC', $_[1]) ;
			if( $status == 0 ){
				$self->connect_cmd ;
				return ;
			}
			AE::log "error" => "Bad login or password";
		});
		return ;
	}
	AE::log "error" => "Auth method $method not implemented!";
}

sub connect_cmd{
	my( $self ) = @_ ; 
	my $next = $self->{chain}->[1] ;
	my( $host, $port ) = $next 
		? ( $next->{host}, $next->{port} )
		: ( $self->{dst_host}, $self->{dst_port} ) ;

	my ($cmd, $ip );
	if( $ip = parse_ipv4($host) ){
		AE::log "debug" => "Connect IPv4: $host";
		$cmd = pack('CCCCA4n', 5, CMD_CONNECT, 0, TYPE_IP4, $ip, $port);
	}
	elsif( $ip = parse_ipv6($host) ){
		AE::log "debug" => "Connect IPv6: $host";
		$cmd = pack('CCCCA16n', 5, CMD_CONNECT, 0, TYPE_IP6, $ip, $port);
	}
	else{
		AE::log "debug" => "Connect hostname: $host";
		$cmd = pack('CCCCCA*n', 5, CMD_CONNECT, 0, TYPE_FQDN , length $host, $host, $port);
	}

	$self->{hd}->push_write( $cmd );
	$self->{hd}->push_read( chunk => 4, sub{
		my( $status, $type ) = unpack( 'xCxC', $_[1] );
		unless( $status == 0 ){
			AE::log "error" => "Connect cmd rejected: status is $status" ;
			return ;
		}
		$self->connect_cmd_finalize( $type ); 
	});
}

sub connect_cmd_finalize{ 
	my( $self, $type ) = @_ ;

	AE::log "debug" => "Connect cmd done, bind atype is $type"; 

	if($type == TYPE_IP4){
		$self->{hd}->push_read( chunk => 6, sub{
			my( $host, $port) = unpack( "a4n", $_[1] );
			$self->socks_connect_done( format_ipv4( $host ), $port );
		}); 
	}
	elsif($type == TYPE_IP6){
		$self->{hd}->push_read( chunk => 18, sub{
			my( $host, $port) = unpack( "a16n", $_[1] );
			$self->socks_connect_done( format_ipv6( $host ) , $port );
		});
	}
	elsif($type == TYPE_FQDN){
		# read 1 byte (fqdn len)
		# then read fqdn and port
		$self->{hd}->push_read( chunk => 1, sub{
			my $fqdn_len = unpack( 'C', $_[1] ) ;
			$self->{hd}->push_read( chunk => $fqdn_len + 2 , sub{
				my $host = substr( $_[1], 0, $fqdn_len ) ;
				my $port = unpack('n', substr( $_[1], -2) );
				$self->socks_connect_done( $host, $port );
			});
		});
	}
	else{
		AE::log "error" => "Unknown atype $type";
	}
}

sub socks_connect_done{ 
	my( $self, $bind_host, $bind_port ) = @_; 

	my $that = shift @{ $self->{chain} }; # shift = move forward in chain
	AE::log "debug" => "Done with server socks$that->{v}://$that->{host}:$that->{port} , bound to $bind_host:$bind_port";

	if( @{ $self->{chain} } ){
		$self->handshake ;
		return ;
	}

	AE::log "debug" => "Giving up fh and returning to void...";
	my( $fh, $c_cb ) = ( $self->{hd}->fh, delete $self->{c_cb} );
	$self->DESTROY;
	$c_cb->( $fh );
}

sub DESTROY {
	my $self = shift ;
	AE::log "debug" => "Kitten saver called";
	undef $self->{_guard};
	$self->{hd}->destroy	if( $self->{hd} and not $self->{hd}->destroyed );
	$self->{c_cb}->()		if( $self->{c_cb} );
	undef %$self;
	bless $self, __PACKAGE__ . '::destroyed';
}


=head1 AUTHOR

Zlobus, C<< <zlobus at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-socks-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-SOCKS-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::SOCKS::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-SOCKS-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-SOCKS-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-SOCKS-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-SOCKS-Client/>

=back


=head1 ACKNOWLEDGEMENTS

URI parser copied from AnyEvent::HTTP::Socks


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Zlobus.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of AnyEvent::SOCKS::Client
