## no critic
use strict;
use warnings;
use Test::More 'tests' => 3;
use App::UnANSI;

my $app = App::UnANSI->new(
    'files' => ['t/corpus/perl-commit.txt'],
);

isa_ok( $app, 'App::UnANSI' );
can_ok( $app, 'run' );

SKIP: {
    eval { require Capture::Tiny; 1; }
        or skip 'Capture::Tiny needed for this test', 1;

    like(
        Capture::Tiny::capture_stdout( sub { $app->run(); } ),
        qr{1451f69 - regexes: make scanning for ANYOF faster \(31 hours ago\) <David Mitchell>},
        'Correct result',
    );
}
