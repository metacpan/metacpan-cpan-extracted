#!/usr/bin/perl -w

use strict;

use Test::More;

$| = 1;

my @classes = qw(
    Biblio::COUNTER
    Biblio::COUNTER::Report
    Biblio::COUNTER::Report::Release2::DatabaseReport1
    Biblio::COUNTER::Report::Release2::DatabaseReport2
    Biblio::COUNTER::Report::Release2::DatabaseReport3
    Biblio::COUNTER::Report::Release2::JournalReport1
    Biblio::COUNTER::Report::Release2::JournalReport1a
    Biblio::COUNTER::Report::Release2::JournalReport2
    Biblio::COUNTER::Processor
    Biblio::COUNTER::Processor::Atomize
    Biblio::COUNTER::Processor::Simple
    Biblio::COUNTER::Processor::Validate
);

plan 'tests' => scalar(@classes);

foreach my $cls (@classes) {
    use_ok( $cls );
}
