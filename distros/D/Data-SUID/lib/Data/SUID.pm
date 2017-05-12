use strict;
use warnings;

package Data::SUID;
our $VERSION = '2.0.3'; # VERSION
use Crypt::Random          ( 'makerandom' );
use Exporter               ();
use Net::Address::Ethernet ( 'get_address' );
use Math::BigInt try => 'GMP';
use MIME::Base64;
use Readonly;
use namespace::clean;
use overload '""' => 'hex';

our @ISA         = ( 'Exporter' );
our @EXPORT_OK   = ( 'suid' );
our %EXPORT_TAGS = ( all => \@EXPORT_OK, ALL => \@EXPORT_OK );

sub hex
{
    my ( $self ) = @_;
    $self = &new unless ref( $self );
    return $$self;
}

sub dec
{
    my ( $self ) = @_;
    $self = &new unless ref( $self );
    return Math::BigInt->new( '0x' . $$self );
}

sub uuencode
{
    use bytes;
    my ( $self ) = @_;
    $self = &new unless ref( $self );
    return pack( 'u', pack( 'H*', $$self ) );
}

sub binary
{
    use bytes;
    my ( $self ) = @_;
    $self = &new unless ref( $self );
    return pack( 'H*', $$self );
}

sub base64
{
    use bytes;
    my ( $self ) = @_;
    $self = &new unless ref( $self );
    return encode_base64( pack( 'H*', $$self ), '');
}

sub suid { __PACKAGE__->new( @_ ) }

sub new
{
    my ( $class ) = @_;
    $class = ref( $class ) || __PACKAGE__;
    my $host  = &_machine_ident;
    my $count = &_count;
    my $time  = sprintf('%08x', time);
    my $pid   = sprintf('%05x', $$);
    Readonly my $id => $time . $host . $pid . $count;
    return bless( \$id, $class );
}

{
    my @ident;
    my $ident;

    sub _machine_ident
    {
        my ($class, @bytes) = @_;
        @ident = map 0 + ( $_ || 0 ), @bytes[ 0, 1, 3 ]
            if @_;
        @ident = +( map 0 + ( $_ || 0 ), get_address() )[ 3, 4, 5 ]
            unless @ident;
        $ident = sprintf( '%02x%02x%02x', @ident )
            unless $ident;
        return wantarray ? @ident : $ident;
    }
}

{
    my $count_width  = 20;
    my $count_mask   = 2 ** $count_width - 1;
    my $count_format = '%0' . int( $count_width / 4 ) . 'x';
    my $count        = undef;

    sub _reset_count
    {
        my ( $class, $value ) = @_;
        $count = $count_mask & ( 0 + abs( $value ) )
            if defined $value;
        unless ( defined $count ) {
            $count = makerandom( 
                Strength => 1, 
                Uniform  => 1,
                Size     => $count_width
            );
        }
        return $class;
    }

    sub _count
    {
        &_reset_count unless defined $count;
        my $result = sprintf( $count_format, $count );
        $count = $count_mask & ( 1 + $count );
        return $result;
    }
}

1;

=pod

=encoding utf-8

=head1 NAME

Data::SUID - Generates sequential unique ids

=head1 VERSION

version 2.0.3

=head1 SYNOPSIS

    use Data::SUID 'suid';              # Or use ':all' tag
    use Data::Dumper;

    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse  = 1;

    my $suid = suid();                  # Old school, or ...
    my $suid = Data::SUID->new();       # Do it OOP style

    print $suid->dec                    # 26574773684474770905501261996
    print $suid->hex                    # 55de233819d51b1a8a67e0ac
    print $suid->uuencode               # ,5=XC.!G5&QJ*9^"L
    print $suid->base64                 # Vyyx3wAAAAElgAAB
    print $suid->binary                 # 12 bytes of unreadable gibberish
    print $suid                         # 55de233819d51b1a8a67e0ac

    # Use the hex, dec, uuencode and binary methods as fire-and-forget
    # constructors, if you prefer:

    my $suid_hex = suid->hex;           # If you just want the goodies

=head1 DESCRIPTION

Use this package to generate 12-byte sequential unique ids modeled upon 
Mongo's BSON ObjectId. Unlike traditional GUIDs, these are somewhat more 
index-friendly and reasonably suited for use as primary keys within database 
tables. They are guaranteed to have a high level of uniqueness, given that
they contain a timestamp, a host identifier and an incremented sequence
number.

=head1 METHODS

=head2 new

    $suid = Data::SUID->new();

Generates a new SUID object.

=head2 hex

    $string = $suid->hex();
    $string = Data::SUID->hex();
    $string = suid->hex();
    
Returns the SUID value as a 24-character hexadecimal string.

    $string = "$suid";

The SUID object's stringification operation has been overloaded to give this
value, too.

=head2 dec

    $string = $suid->dec();
    $string = Data::SUID->dec();
    $string = suid->dec();

Returns the SUID value as a big integer.

=head2 uuencode

    $string = $suid->uuencode();
    $string = Data::SUID->uuencode();
    $string = suid->uuencode();

Returns the SUID value as a UUENCODED string.

=head2 binary

    $binstr = $suid->binary();
    $binstr = Data::SUID->binary();
    $binstr = suid->binary();

Returns the SUID value as 12 bytes of binary data.

=head2 base64

    $base64 = $suid->base64();
    $base64 = Data::SUID->base64();
    $base64 = suid->base64();

Returns the SUID value as a 16-byte Base64 encoded string.

=head1 EXPORTED FUNCTIONS

=head2 suid

    my $suid = suid();

Generates a new SUID object.

=pod

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/Data-SUID|https://github.com/cpanic/Data-SUID>

=item * L<http://search.cpan.org/dist/Data-SUID/lib/Data/SUID.pm|http://search.cpan.org/dist/Data-SUID/lib/Data/SUID.pm>

=back

=head1 BUG REPORTS

Please report any bugs to L<http://rt.cpan.org/>

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014-2016 by Iain Campbell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
