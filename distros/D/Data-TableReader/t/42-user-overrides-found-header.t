#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP', filter => 'warn';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

# In this scenario, the user asks to find the best header, but then runs their own logic to
# choose a header row they like better.  The table Iterator should run with whatever candicdate
# they put in ->table_search_results->{found}

my $tr= new_ok( 'Data::TableReader', [
		fields => [
			{ name => 'prod_num' },
			{ name => 'description', required => 0 },
			{ name => 'weight', required => 0 },
		],
		input => [
			[ qw( a b c ) ],
			[ qw( d e f ) ],
			[ qw( g h i ) ],
		],
		col_map => [ 'prod_num' ],
		on_unknown_columns => 'error', # causes it to scan all rows
		log => \my @messages,
	], 'TableReader' );

ok( !$tr->find_table, 'didn\'t find table' ) or note explain \@messages;
is( scalar @{$tr->table_search_results->{candidates}}, 3, '3 candidates' );
ok( !defined $tr->table_search_results->{found}, 'not found' );
$tr->table_search_results->{found}= $tr->table_search_results->{candidates}[1];
# override col_map
$tr->table_search_results->{found}{col_map}[2]= $tr->fields->[2];

my $i= $tr->iterator;
is_deeply( $i->(), { prod_num => 'g', weight => 'i' }, 'row2 is header, row3 is data' );
is( $i->(), undef, 'eof' );

done_testing;
