#!perl -w

BEGIN
{
	chdir 't' if -d 't';
}

use strict;

use Test::More 'no_plan'; # tests => 2;
use Test::Warn;

my $module = 'Crypt::CipherSaber';
use_ok( $module );

# first, try to create an object
my $cs = $module->new('first key');
isa_ok( $cs, $module );
is( $cs->[2], 1, 'new() should default to an N of 1 with none given' );

$cs    = $module->new('first key', 0);
is( $cs->[2], 1, '... or one given < 1' );

can_ok( $cs, 'crypt'   );
can_ok( $cs, 'encrypt' );
can_ok( $cs, 'decrypt' );

can_ok( $cs, 'fh_crypt' );
my $result;
warning_like { $result = $cs->fh_crypt() } qr/Non-filehandle/,
	'fh_crypt() should warn without a valid input filehandle';
is( $result, undef, '... returning nothing' );

warning_like { $result = $cs->fh_crypt( \*STDIN ) } qr/Non-filehandle/,
	'... and should warn without a valid output filehandle';
is( $result, undef, '... also returning nothing' );
