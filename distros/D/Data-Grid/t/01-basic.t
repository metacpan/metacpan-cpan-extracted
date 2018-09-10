#!perl -T

use strict;
use warnings;
use Test::More;
use Data::Dumper;

my @CONTENT = (
    [qw(first things phirst)],
    [qw("derp" is a,word)],
    [qw(over 9000 duhh)],
    [qw(magic fourth row)],
);

my @TEST = (
    [CSV   => qw(data-grid-sample.csv CSV::Table CSV::Row CSV::Cell)],
    [Excel => qw(data-grid-sample.xls Excel::Table Excel::Row Excel::Cell)],
    ['Excel::XLSX'
         => qw(data-grid-sample.xlsx Excel::Table Excel::Row Excel::Cell)],
);


plan tests => @TEST * 13 + 1;

use_ok('Data::Grid');

for my $testdata (@TEST) {
    my ($class, $file, $tclass, $rclass, $cclass) = @$testdata;

    my $full = "Data::Grid::$class";
    my $path = "t/$file";

    diag($path);
    my $grid = Data::Grid->parse($path);

    isa_ok($grid, $full, "$class instance");

    $grid = Data::Grid->parse(source => $path, checker => 'MimeInfo');
    isa_ok($grid, $full, "static check with mimeinfo");

    open my $fh, $path or die $!;

    $grid = Data::Grid->parse(source => $fh);
    isa_ok($grid, $full, 'content check, MMagic');

    $grid = Data::Grid->parse(source => $fh, checker => 'MimeInfo');
    isa_ok($grid, $full, 'content check, MimeInfo');

    my ($table) = my @tables = $grid->tables;

    is(scalar @tables, 1, 'one table in the test document');

    # my apologies to unix
    for my $i (0..7) {
        my %p = (header => $i & 1, start => $i >> 1 & 1, skip => $i >> 2 & 1);

        $grid = Data::Grid->parse(source => $path, %p);

        my ($table) = $grid->tables;

        my @keys = $p{header} ? @{$CONTENT[$p{start}]} : qw(col1 col2 col3);
        my @vals = @{$CONTENT[$p{header} + $p{start} + $p{skip}]};

        my %test;
        @test{@keys} = @vals;

        my %h = $table->first->as_hash(1);

        my $t = sprintf 'named record (header: %d start: %d skip: %d)',
            @p{qw(header start skip)};

        is_deeply(\%h, \%test, $t);
    }
}
