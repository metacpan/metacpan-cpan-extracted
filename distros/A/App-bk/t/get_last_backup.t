#!perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use File::Which qw(which);
use FindBin qw($Bin);
use File::Copy;

my $result;

use_ok("App::bk");

chdir($Bin) || BAIL_OUT( 'Failed to cd into '. $Bin );
unlink <file1.txt.*>;

$result = trap { App::bk::get_last_backup(); };
is( $trap->stderr,  '',    'no stderr output' );
is( $trap->stdout,  '',    'no stdout output' );
is( $trap->exit,    undef, 'correct exit' );
is( $trap->leaveby, 'die', 'died correctly' );
like(
    $trap->die,
    qr/^Invalid save directory provided at/,
    'correct death output'
);
is( $result, undef, 'got correct output' );

$result = trap { App::bk::get_last_backup( $Bin, 'file1.txt' ); };
is( $trap->stderr,  '',       'no stderr output' );
is( $trap->stdout,  '',       'no stdout output' );
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'died correctly' );
is( $trap->die,     undef,    'no die message' );
is( $result,        undef,    'no backup file found' );

copy( 'file1.txt', 'file1.txt.12345678' );
$result = trap { App::bk::get_last_backup( $Bin, 'file1.txt' ); };
is( $trap->stderr,  '',                   'no stderr output' );
is( $trap->stdout,  '',                   'no stdout output' );
is( $trap->exit,    undef,                'correct exit' );
is( $trap->leaveby, 'return',             'died correctly' );
is( $trap->die,     undef,                'no die message' );
is( $result,        'file1.txt.12345678', 'correct backup file found' );

copy( 'file1.txt', 'file1.txt.87654321' );
$result = trap { App::bk::get_last_backup( $Bin, 'file1.txt' ); };
is( $trap->stderr,  '',                   'no stderr output' );
is( $trap->stdout,  '',                   'no stdout output' );
is( $trap->exit,    undef,                'correct exit' );
is( $trap->leaveby, 'return',             'died correctly' );
is( $trap->die,     undef,                'no die message' );
is( $result,        'file1.txt.87654321', 'correct backup file found' );

done_testing();
