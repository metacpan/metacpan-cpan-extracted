#!/usr/bin/perl

use strict;

use Data::Dumper;

use Test::More qw(no_plan);

use DBI;

use Class::Easy;

BEGIN {
	
	use_ok 'DBI::Easy';
	
	use_ok 'DBD::SQLite';
	
	push @INC, 't', 't/DBI-Easy';
	require 'db-config.pl';
	
	my $dbh = &init_db;
};

my $values = {
	name  => 'aaa',
	pass  => 'bbb',
	meta => 'pam-pam'
};

my $a_record = record_for ('account');
my $a_collection = collection_for ('account');

ok try_to_use ('Local::DBI::Easy::Account::Collection');
ok ! try_to_use_inc ('Local::DBI::Easy::Account::Collection');

my $a_record_smf = record_for ('users', 'Forum');
my $a_collection_smf = collection_for ('users', 'Forum');

my $dbh = $a_record->dbh;

ok $dbh ne '0E0', $dbh;

my $test = $a_record->new ({name => 'aaa'});

my $table_name = $test->table_name;
ok $table_name eq 'account', 'table name';

my $sth = $dbh->column_info(
	undef, undef, $table_name, '%'
);

#$sth->execute;
#
#my $column_info_h = $sth->fetchall_arrayref ({});
#
#diag Dumper $column_info_h;
#
#$sth = $dbh->column_info(
#	undef, undef, $table_name, '%'
#);

DBI::Easy->dbh ($::dbh);
my $easy = DBI::Easy->new;

my $col_state = $a_record->columns;

my $col_count = scalar keys %$col_state;

ok $col_state->{account_id}->{nullable} == 0;
ok $col_state->{name}->{nullable} == 0;
ok $col_state->{pass}->{nullable} == 1;
# ok $col_state->{pass}->{default}  eq 'abracadabra';

ok ($col_count and ($col_count > 0));

my $column_info_array = $easy->fetch_arrayref ($sth);

ok scalar @$column_info_array == $col_count, "columns count by arrayref: " . scalar @$column_info_array;

TODO: { # 
	local $TODO = 'bug in DBD::SQLite or in DBI::Easy ???';
	
	my $column_info_hash = $easy->fetch_hashref ($sth, 'COLUMN_NAME');
	
	ok scalar keys %$column_info_hash == 4, "columns count by hashref: " . scalar keys %$column_info_hash;
	
	diag "column info for table $table_name ", Dumper $column_info_hash;
}

my $values_count = scalar keys %$values;

my $placeholders = $test->sql_range ($values_count);

$placeholders =~ s/[^?]//g;

ok length ($placeholders) eq $values_count;

my ($sql_part, $values_list) = $test->sql_where ({
	_test => 'like :test_value', ':test_value' => 'test_value_111'
});

my $q = $dbh->quote_identifier ('test');

ok $sql_part =~ /$q like ?/;
ok $values_list->[-1] eq 'test_value_111';

# diag $sql_part;
# diag join ', ', @$values_list;

($sql_part, $values_list) = $test->sql_where ($values);

# diag Dumper $values_list;


my @params_list = split (/\sand\s/, $sql_part);
foreach my $counter (0 .. $#params_list) {
	my $param = $params_list[$counter];
	$param =~ s/\s=\s\?$//;
	my ($unquoted_param) = grep {$dbh->quote_identifier ($_) eq $param} keys %$values;
	ok defined $unquoted_param, "unquoted: $unquoted_param";
	ok $values->{$unquoted_param} eq $values_list->[$counter],
		$values->{$unquoted_param} . ' != ' . $values_list->[$counter];
}

# diag $sql_part, " '", join ("', '", @$values_list), "'\n";

my ($ins_statement, $ins_bind_values) = $test->sql_insert ($values);

ok ($ins_statement =~ /insert into [^\s]+ \((?:\S+(?:, )?)+\) values \(\?/);

# diag $ins_statement, Dumper $ins_bind_values;

my ($up_statement, $up_bind_values) = $test->sql_update (set => $values);

ok (!defined ($up_statement), 'update_all');

#ok ($up_statement =~ /update \S+ set (?:\S+\s\=\s\?)+/);
#ok ($up_statement !~ /where/);

($up_statement, $up_bind_values) = $test->sql_update (set => $values, where => {active => 1});

# diag $up_statement;

ok ($up_statement =~ /update \S+ set (?:\S+\s\=\s\?)+/);
ok ($up_statement =~ /where \Sactive/);

($up_statement, $up_bind_values) = $test->sql_update (
	set => $values, where => {active => 1, option => [20, 30, 40]}
);

ok ($up_statement =~ /update \S+ set (?:\S+\s\=\s\?)+/);
ok ($up_statement =~ /where/);
ok ($up_statement =~ /option\S in \(\?, \?, \?\)/);
ok ($#$up_bind_values == 6);

# diag $up_statement, Dumper $up_bind_values;

my $test_smf = $a_record_smf->new ({name => 'aaa'});

($ins_statement, $ins_bind_values) = $test_smf->sql_insert ($values);

ok ($ins_statement =~ /insert into \Wsmf_users\W \((?:\S+(?:, )?)+\) values \(\?/);

&finish_db;

1;
