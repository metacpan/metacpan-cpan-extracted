#!perl
use strict;
use 5.006;
use warnings;
use Test::More tests => 6;
use IPC::Run ();

my @command = (
    $^X,
    '-Mblib',
    '-MB::Lint::StrictOO',
    '-MO=Lint,oo',
        't/class_exists.pl'
);
diag( "@command" );

my ( $lint_stdout, $lint_stderr );
IPC::Run::run(
    \ @command,
    '>',  \ $lint_stdout,
    '2>', \ $lint_stderr )
  or die "@command\n$lint_stderr";
pass( "@command" );

like( $lint_stderr,   qr/^Class Bad::Class doesn't exist at .+ line 2$/m, 'Missing classes');
like( $lint_stderr,   qr/^Class Bad::Class doesn't exist at .+ line 3$/m, 'Missing classes');
like( $lint_stderr,   qr/^Class Maybe::Class doesn't exist at .+ line 4$/m, 'Partially missing classes' );
like( $lint_stderr,   qr/^Class Good::Class can't do method bad_method at .+ line 5$/m, 'Missing methods' );
unlike( $lint_stderr, qr/^Class constant/m, 'Ignore ' );
