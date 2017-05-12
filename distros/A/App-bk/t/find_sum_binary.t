#!perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use File::Which qw(which);

my $result;

use_ok("App::bk");

local @ARGV = ();

$result = trap { App::bk::find_sum_binary(); };
is( $trap->stderr,  '',       'no stderr output' );
is( $trap->stdout,  '',       'no stdout output' );
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result, which('md5sum') || which('sum'),
    'got correct path: ' . $result );

local $ENV{PATH} = '';
$result = trap { App::bk::find_sum_binary(); };
is( $trap->stderr,  '',    'no stderr output' );
is( $trap->stdout,  '',    'no stdout output' );
is( $trap->exit,    undef, 'correct exit' );
is( $trap->leaveby, 'die', 'died correctly' );
like(
    $trap->die,
    qr/Unable to locate "md5sum" or "sum"/,
    'correct error message'
);
is( $result, undef, 'no binary returned' );

done_testing();
