#!/usr/bin/perl -w
use strict;

use CPAN::Testers::WWW::Statistics::Excel;
use File::Path;
use Test::More tests => 3;

my @files = (
    { source => 't/samples/osmatrix-month-wide.html',   target => 't/results/osmatrix-month.xls' },
    { source => 't/samples/pmatrix-month-wide.html',    target => 't/results/pmatrix-month.xls',    author => 'Example Author',     comments => 'Example Comment' },
);


ok( my $obj = CPAN::Testers::WWW::Statistics::Excel->new( logclean => 1 ), "got object" );

for my $files (@files) {
    $obj->create( %$files );
    is(-f $files->{target}, 1 ,"found target file [$files->{target}]\n");
}

rmtree 't/results';
