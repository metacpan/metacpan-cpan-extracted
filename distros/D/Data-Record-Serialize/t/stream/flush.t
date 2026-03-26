#! perl

use Test2::V0;
use Test::Lib;

use Data::Record::Serialize;
use Test::TempDir::Tiny;
use Path::Tiny;

in_tempdir 'flush' => sub {

    my $s = Data::Record::Serialize->new(
        encode => '+My::Test::Encode::tsv',
        sink   => 'stream',
        output => 'foo.tsv',
        fields => [ 'a', 'b', 'c' ],
    );

    $s->send( { a => 1, b => 2, c => 3 } );
    $s->flush;

    is( path( 'foo.tsv' )->slurp, "1\t2\t3\n" );
};

done_testing;
