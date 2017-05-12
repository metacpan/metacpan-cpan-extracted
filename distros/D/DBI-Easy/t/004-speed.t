#!/usr/bin/perl -I../../../perl-easy/lib

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

BEGIN {

	# $Class::Easy::DEBUG = 'immediately';
	
	use_ok 'DBI::Easy';
	
	push @INC, 't', 't/DBI-Easy';
	require 'db-config.pl';
	
	my $dbh = &init_db;
	
};

my $rec_a = record_for ('account');	

my $t = timer ('effective work: new');

my $account = $rec_a->new (
	{name => 'apla', meta => 'metainfo', pass => 'dsfasdfasdf'}
);

$t->lap ('insert');

$account->create;

$t->end;

ok $account;

my $dumped_fields = $account->TO_JSON;

# ok scalar keys %$dumped_fields == 3;

&finish_db;

1;
