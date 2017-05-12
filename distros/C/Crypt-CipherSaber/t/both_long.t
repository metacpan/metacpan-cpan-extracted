#!perl -w

# encrypt and decrypt a line greater than 256 characters long
# this tests for a subtle bug, ie, missing a modulo on $i

BEGIN
{
	chdir 't' if -d 't';
}

use strict;

use Test::More tests => 2;

use_ok('Crypt::CipherSaber');

my $cs        = Crypt::CipherSaber->new( 'first key' );
my $long_line = join( ' ', ( 1 .. 100 ) );
my $coded     = $cs->encrypt($long_line);
is( $cs->decrypt( $coded ), $long_line, 'round-tripping should work' );
