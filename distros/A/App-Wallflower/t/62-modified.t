use strict;
use warnings;
use TAP::Parser;
use Path::Tiny ();
use Test::More;

my @cmd = (
    $^X,
    '-I' => Path::Tiny->new('lib'),
    Path::Tiny->new( bin => 'wallflower' ),
    '--application' => Path::Tiny->new( t => 'test.psgi' ),
    '--destination' => Path::Tiny->tempdir,
    '--tap',
);

my $run = 0;
for ( 1 .. 2 ) {
    my $tap = TAP::Parser->new(
        {
            exec      => \@cmd,
            callbacks => {
                ALL => sub { print "    ", shift->as_string, "\n"; }
            },
        }
    );
    $tap->run;
    ok( !$tap->has_problems, "run " . ( $run + 1 ) );
    if ( !$run ) {    # first run
        ok( !$tap->skipped, 'no skip' );
    }
    else {
        ok( $tap->skipped > 0, 'skipped some' );
    }
}
continue {
    $run++;
}

done_testing;
