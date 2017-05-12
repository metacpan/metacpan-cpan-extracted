package Crypt::Elijah;

use Carp;

our $VERSION = '0.11';

sub _rand {
    return sprintf( '%04X', int( rand(0xFFFF) ) );
}

sub init {
    croak()
      if ( !defined( $_[0] ) || ref( $_[0] ) || ( length( $_[0] ) < 12 ) );
    my ( @k, @s, $a, $b, $c, $d, $e, $i, $pc );

    $_[0] .= "\0" x 16;
    @k = unpack( 'C16', $_[0] );

    $pc = 21;
    for ( $i = 360 ; $i > 0 ; $i-- ) {
        $a  = $i % 256;
        $b  = $a % 16;
        $c  = ( $b + 1 ) * ( $b + 1 );
        $d  = ( $c + $a ) % 256;
        $e  = ( $d + $k[$b] + $pc ) % 256;
        $pc = $e;
        push( @s, $e );
    }
    for ( $i = 359 ; $i > -1 ; $i-- ) {
        $a = ( $i + 2 ) % 360;
        $s[$i] = ( $s[$i] + $s[$a] ) % 256;
    }

    return \@s;
}

sub enc {
    croak()
      if ( !defined( $_[0] )
        || !defined( $_[1] )
        || ref( $_[0] )
        || !ref( $_[1] ) );
    my ( @t, @salt, $s, $pc, $i );

    @t    = unpack( 'C*', $_[0] );
    @salt = unpack( 'C4', _rand() );
    unshift( @t, @salt );
    $s  = $_[1];
    $pc = $$s[359];

    for ( $i = 0 ; $i <= $#t ; $i++ ) {
        $t[$i] = ( $t[$i] + $pc ) % 256;
        $t[$i] ^= $$s[ $i % 360 ];
        $pc = ( $t[$i] + $i ) % 256;
    }
    $_[0] = pack( 'C*', @t );
}

sub dec {
    croak()
      if ( !defined( $_[0] )
        || !defined( $_[1] )
        || ref( $_[0] )
        || !ref( $_[1] ) );
    my ( @t, $s, $pc, $i, $a );

    @t  = unpack( 'C*', $_[0] );
    $s  = $_[1];
    $pc = $$s[359];

    for ( $i = 0 ; $i <= $#t ; $i++ ) {
        $a = $t[$i];
        $t[$i] ^= $$s[ $i % 360 ];
        $t[$i] = ( $t[$i] - $pc ) % 256;
        $pc = ( $a + $i ) % 256;
    }

    splice( @t, 0, 4 );
    $_[0] = pack( 'C*', @t );
}

1;

=head1 NAME

Crypt::Elijah - cipher module 

=head1 SYNOPSIS

    use Crypt::Elijah;

    $text = 'secretive';
    $key = '0123456789abcdef'; 
    $keyref = Crypt::Elijah::init($key);
    Crypt::Elijah::enc($text, $keyref);
    Crypt::Elijah::dec($text, $keyref);

=head1 DESCRIPTION

This module provides a pure Perl implementation of the Elijah cipher.

Call init() to prepare the encryption key.
This function takes a single argument: a packed string containing your key.
The key must be at least 12 bytes long.
Keys longer than 16 bytes are truncated.
This function returns a reference to the prepared key.

Call enc() and dec() to process your data.
These functions take the same parameters.
The first argument is a string containing your data.
The second argument is a reference returned by init().
Salt is added to your data; ciphertext will always be larger than the 
corresponding plaintext.

=head1 BUGS

This module is not intended for bulk encryption.
It would be more sensible to use an XS encryption module for processing large 
amounts of data.

It is a good idea to remove redundancy from your data prior to encryption (e.g. 
using compression); this module has no built-in mechanism for achieving this.
Redundancy in your data may allow information to be discovered from the 
ciphertext.

This module is experimental software and should be used with caution.
Please report any bugs to the author.

=head1 AUTHOR

Michael W. Bombardieri <bombardierix@gmail.com>

=head1 COPYRIGHT

Copyright 2007, 2008 Michael W. Bombardieri.

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 DEDICATION

This software is dedicated to Elijah DePiazza.

=cut
