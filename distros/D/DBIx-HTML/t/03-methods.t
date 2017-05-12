#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use DBIx::HTML;
use Test::More;

eval "use DBD::CSV 0.48";
plan skip_all => "DBD::CSV 0.48 required" if $@;

plan tests => 20;

my @dbi_csv_args = (
    "dbi:CSV:", undef, undef, {
        f_ext      => ".csv/r",
        f_dir      => "t/data/",
        RaiseError => 1,
    }
);
my $table = DBIx::HTML
    ->connect( @dbi_csv_args )
    ->do( 'select * from test' )
;

ok $table->generate,                "generate";
ok $table->portrait,                "portrait";
ok $table->landscape,               "landscape";
ok $table->north,                   "north";
ok $table->east,                    "east";
ok $table->south,                   "south";
ok $table->west,                    "west";
ok $table->layout,                  "layout";
ok $table->handson,                 "handson";
ok $table->banner,                  "banner";
ok $table->calendar,                "calendar";
ok $table->sudoku( attempts => 0 ), "sudoku";
ok $table->checkers,                "checkers";
ok $table->beadwork,                "beadwork";
ok $table->calculator,              "calculator";
ok $table->conway,                  "conway";
ok $table->maze,                    "maze";
ok $table->chess,                   "chess";
ok $table->checkerboard,            "checkerboard";
ok $table->scroll,                  "scroll";
