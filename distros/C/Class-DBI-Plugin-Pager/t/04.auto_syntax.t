#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

# this represents a single page of results
my @dataset = qw( fee fi fo foo fum );

{
    package TestApp;
    use base 'Class::DBI';

    use Class::DBI::Plugin::Pager;

    sub count_search_where { 27 }

    # the '@_' appends the class name, SQL and bind values passed in from
    # search_where_limitable
    sub retrieve_from_sql { @dataset, @_ }

    sub __driver { 'InterBase' } # RowsTo syntax

}


my $where = { this => 'that' };
my $order_by = [ 'fig' ];
my $per_page = scalar( @dataset );
my $page = 3;

my $pager = TestApp->pager;

my @results = $pager->search_where( $where, $order_by, $per_page, $page );

is_deeply( [ @results ], [ @dataset, 'TestApp', '( this = ? ) ORDER BY fig ROWS 10 TO 15', 'that' ], 'expected results for RowsTo' );


#use YAML;
#warn Dump( $pager );
