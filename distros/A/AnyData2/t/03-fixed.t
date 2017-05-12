#!perl

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Cwd        ();
use FindBin    ();
use File::Spec ();

use_ok('AnyData2')                           || BAIL_OUT "Couldn't load AnyData2";
use_ok('AnyData2::Format::Fixed')            || BAIL_OUT "Couldn't load AnyData2::Format::Fixed";
use_ok('AnyData2::Storage::File::Blockwise') || BAIL_OUT "Couldn't load AnyData2::Storage::File::Linewise";

my $test_dir = Cwd::abs_path( File::Spec->catdir( $FindBin::Bin, "data" ) );

my $af = AnyData2->new(
    Fixed => {
        cols => [
            Id      => 3,
            Name    => 10,
            Color   => 7,
            Newline => 1
        ]
    },
    "File::Blockwise" => {
        filename  => File::Spec->catfile( $test_dir, "simple.blocks" ),
        blocksize => 3 + 10 + 7 + 1,
        filemode  => "<:raw"
    }
);

my $cols = $af->cols;
my @rows;

while ( my $row = $af->fetchrow )
{
    push @rows, $row;
}

is_deeply( $cols, [qw(Id Name Color Newline)], "Cols from fixed" );
is_deeply(
    \@rows,
    [
        [ "  1", "       red", "#ff0000", "\n" ],
        [ "  2", "     green", "#00ff00", "\n" ],
        [ "  3", "      blue", "#0000ff", "\n" ]
    ],
    "Rows from fixed"
);

done_testing;
