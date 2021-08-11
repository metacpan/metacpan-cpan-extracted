=head1 NAME

AnyEvent::SOCKS::Client - AnyEvent-based SOCKS client!

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Constructs function which behave like AnyEvent::Socket::tcp_connect

    use AnyEvent::SOCKS::Client qw/tcp_connect_via/;

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
use AnyEvent::Socket qw/tcp_connect format_ipv4 format_ipv6/;
use AnyEvent::Handle ;
use AnyEvent::Log ;

require Exporter;
our $VERSION = '0.02';
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/tcp_connect_via/;

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
		return {v => $1, login => $2, password => $3, host => $4, port => $5};
	}
	undef ;
}
# returns tcp_connect compatible function
sub tcp_connect_via{
	my(@chain) = @_ ; 
	return sub{
		my $con = bless { chain => [ map _parse_uri($_), @chain ] }, __PACKAGE__ ;
		$con->connect( @_ ) ;
		guard { undef $con } ;
	};
}

sub connect{
	my( $self, $dst_host, $dst_port, $c_cb, $pre_cb ) = @_ ;
	unless( @{ $self->{chain} } ){
		AE::log "error" => "No socks were given, abort"; 
		return $c_cb->();	
	}
	if( $self->{c_cb}){
		AE::log "error" => "It's one-off object, create another instance.."; 
		return $c_cb->();
	}
	$self->{dst_host} = $dst_host; 
	$self->{dst_port} = $dst_port;
	$self->{c_cb} = $c_cb ;
	$self->{pre_cb} = $pre_cb ;
	
	# tcp connect to first socks
	my $that = $self->{chain}->[0] ;
	return tcp_connect $that->{host}, $that->{port}, sub{
		my $fh = shift ;
		return $c_cb->() unless($fh);
		$self->{hd} = new AnyEvent::Handle( fh => $fh ) ;
		$self->{hd}->on_error(sub{
			my ($hd, $fatal, $msg) = @_;
				AE::log "error" => ( $fatal ? "Fatal " : "" ) . $msg ; 
				$hd->destroy;
				undef $self ;
				$c_cb->();
		});
		$self->handshake;
	}; 
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
				undef $self ;
				return  ;
			}
			$self->auth($method) ; 
	 });
}

sub auth{
	my( $self, $method ) = @_; 
	
	unless( $method ){
		$self->connect_cmd ;
		return ;
	}
	
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
	undef $self; 
}

sub connect_cmd{
	my( $self ) = @_ ; 
	my $next = $self->{chain}->[1] ;
	my( $host, $port ) = $next 
		? ( $next->{host}, $next->{port} )
		: ( $self->{dst_host}, $self->{dst_port} ) ;
				
	$self->{hd}->push_write( 
		pack('CCCCC', 5, CMD_CONNECT, 0, TYPE_FQDN , length $host ) . $host . pack( 'n', $port)
	);
	
	$self->{hd}->push_read( chunk => 4, sub{ 
		my( $status, $type ) = unpack( 'xCxC', $_[1] );
		unless( $status == 0 ){
			AE::log "error" => "Connect cmd rejected: status is $status" ;
			undef $self ;	
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
		#read 1 byte (fqdn len)
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
		undef $self ;
	}
}

sub socks_connect_done{ 
	my( $self, $bind_host, $bind_port ) = @_; 
	
	my $that = shift @{ $self->{chain} }; # shift = move forward in chain
	AE::log "debug" => "Done with server $that->{host}:$that->{port} , bound to $bind_host:$bind_port";
	
	if( @{ $self->{chain} } ){
		$self->handshake ;
		return ;
	} 
	
	my $fh = $self->{hd}->fh ;
	AE::log "debug" => "Giving up fh and returning to void...";
	$self->{c_cb}->($fh);
	$self->{c_cb} = sub{};
	undef $self; 
}

sub DESTROY {
	my $self = shift ;
	if($self->{hd}){ $self->{hd}->destroy ; }
	if($self->{c_cb}){ $self->{c_cb}->(); }
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
