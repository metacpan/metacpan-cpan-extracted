use strict;
use warnings;
use TAP::Parser;
use Path::Tiny ();
use Test::More;

my @URL = map {
    ( my $file = Path::Tiny->tempfile )->spew("/$_.txt\n");
    $file;
} 1 .. 25;

my @cmd = (
    $^X,
    '-I' => Path::Tiny->new('lib'),
    Path::Tiny->new( bin => 'wallflower' ),
    '--application' => Path::Tiny->new( t => 'plain.psgi' ),
    '--destination' => Path::Tiny->tempdir,
    '--parallel' => 4,
    '--tap',
    '--filter', @URL,
);

my $tap = TAP::Parser->new(
    {
        exec      => \@cmd,
        callbacks => {
            ALL => sub { print "    ", shift->as_string, "\n"; }
        },
    }
);
$tap->run;
ok( !$tap->has_problems, 'valid TAP, all tests passed' );
ok( !$tap->skipped,      'no test skipped' );
is( $tap->tests_run, scalar @URL, 'All URL visited' );

done_testing;
