#!perl -w

# now do a bidirectional check with CS-2

BEGIN
{
	chdir 't' if -d 't';
}

use strict;
use Test::More tests => 2;

use_ok('Crypt::CipherSaber');

my $cs2       = Crypt::CipherSaber->new( 'second key', 5 );
my $long_line = join( ' ', ( 1 .. 100 ) );
my $coded     = $cs2->encrypt($long_line);
is( $cs2->decrypt($coded), $long_line,
	'CS-2 should work on texts longer than IV' );
