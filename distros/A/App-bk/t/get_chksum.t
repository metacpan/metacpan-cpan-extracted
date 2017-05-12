#!perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use File::Which qw(which);
use FindBin qw($Bin);

my $result;

use_ok("App::bk");

chdir($Bin) || die 'Unable to change dir: ', $!;

$result = trap { App::bk::get_chksum(); };
is( $trap->stderr,  '',    'no stderr output' );
is( $trap->stdout,  '',    'no stdout output' );
is( $trap->exit,    undef, 'correct exit' );
is( $trap->leaveby, 'die', 'died correctly' );
like( $trap->die, qr/^No filename provided/, 'correct death output' );
is( $result, undef, 'got correct output' );

$result = trap { App::bk::get_chksum('file1.txt'); };
is( $trap->stderr,  '',       'no stderr output' );
is( $trap->stdout,  '',       'no stdout output' );
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'died correctly' );
is( $trap->die,     undef,    'no die message' );
like( $result, qr/^\w+$/, 'no binary returned' );

done_testing();
