#!perl
use 5.010;
use strict;
use warnings;

use Test::More import => [ qw( is is_deeply plan use_ok ) ];

use lib './t/lib';

use Schema;

plan tests => 3;

use_ok('TestDB');

my $schema = TestDB->init();

my $books   = $schema->resultset('Book');
my @columns = $books->result_source->columns;

my @expected_columns = qw(
  id title author pub_date num_pages isbn
);
is_deeply( \@columns, \@expected_columns,
    'Book result set has expected column names' );

is( $books->count, 5, 'Test DB contains expected number of entries' );

# vim: expandtab shiftwidth=4
