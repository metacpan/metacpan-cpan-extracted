package Convert::TLI;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	encode_tli decode_tli detect_tli	
);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %opts  = @_;
    
    my $self = {
    	%opts
    };
    
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

sub initialize {
    my $self = shift;
    my $val  = shift;
    $self->{prefix} = $self->{prefix} || "0x0002";
    $self->{nulls} = $self->{nulls} || "";
}


sub encode_tli {
	my $self = shift;
	my $host_to_encode = shift;
	my $port_to_encode = shift;
	
	my @hosts = split '.', $host_to_encode; 

    my $ip = $self->_get_ip_address( $host_to_encode, 'hex');
    
    my $hexport = sprintf("%4.4x", $port_to_encode);
    
    return  $self->{prefix}."$hexport$ip".$self->{nulls};
} 

sub decode_tli {
	my $self = shift;
    my $to_decode = shift;
	
	my $rsl = eval {
		hex(substr($to_decode, 10, 2))
	};
	
	return if $@;
	
	my ( @arr ) = (
	   hex(substr($to_decode, 10, 2)),	
	   hex(substr($to_decode, 12, 2)),	
	   hex(substr($to_decode, 14, 2)),	
	   hex(substr($to_decode, 16, 2))
	);
	
	my $port = hex(substr($to_decode, 6, 4));
	my $ip = join('.', @arr);
	
	return ( $ip, $port );
} 

sub detect_tli {
	my $self = shift;
    my $str  = shift;
    
    return ( $str =~ /0x/ ) ? '1' : '0';
    
}


sub _get_ip_address {
	my $self = shift;
    my ($host, $mode) = @_;
    my ($name, $aliases, $addrtype, $length, @addrs) = gethostbyname($host);
    
    my $mask = join('.', unpack('C4', $addrs[0]));
    
    if ($mode eq 'hex')
    {
        $mask = sprintf("%2.2x%2.2x%2.2x%2.2x", split(/\./, $mask));
    }

    return $mask;
}

1;
__END__

=head1 NAME

Convert::TLI - Encoding and decoding of TLI style strings
TLI is Transport Layer Interface

subase/interfaces file:

    my_server
    master tli tcp /dev/tcp 0x0002333337f00001
    query tli tcp /dev/tcp 0x0002333337f00001



=head1 SYNOPSIS

	use Convert::TLI;
	my $tli = Convert::TLI->new();
	my ($ip, $port) = $tli->decode_tli('0x0002333337f00001');
	print "Server $ip @ $port";
	my $decoded =  $tli->encode_tli($ip,$port);
	print "Got encoded: $decoded";
  
=head1 DESCRIPTION

This module provides functions to convert strings to/from the TLI style encoding
as described L<infocenter.sybase.com|http://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc35823.1572/doc/html/san1334282782407.html>

=head1 FUNCTIONS

=over 4

=item *

C<new>

    my $encoded = Convert::TLI->new();

    Create Convert::TLI object.
    
    Possible options:
    C<prefix> and C<nulls> 
     It will be the prefix and suffix for encripted line only
     
     my $encoded = Convert::TLI->new( prefix=>'XXXX', nulls=>'000' );
     my $decoded =  $tli_decoded->encode_tli($ip,$port);
     print "Got encoded: $decoded";
     XXXX....000

=item *

C<encode_tli>

    my $encoded = encode_tli("192.168.0.1", "3100");

Encode a string of bytes into its TLI representation.

=item *

C<decode_tli>

    my  ( $ip, $port ) = decode_tli("0x0002333337f00001");

Decode a TLI string into a string of bytes.

=item *

C<detect_tli>

    my $decoded = ( detect_tli("0x0002333337f00001") ) 
                    ? 'You have TLI style' 
                    : 'Regular IP style';

Detect is string TLI styled

=back


=head1 AUTHOR

Alex Mazur (aka NEONOX) E<lt>alex@emuwebmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Oleksandr Mazur

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut