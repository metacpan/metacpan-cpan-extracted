#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

use DBI;

BEGIN {
	
	# logger('debug')->appender(*STDERR);
	
	use_ok 'DBI::Easy';
	use_ok 'DBD::SQLite';
	
	push @INC, 't', 't/DBI-Easy';
	require 'db-config.pl';
	
	my $dbh = &init_db;
	
};

my $rec_a = record_for ('account');
my $rec_c = record_for ('contact');

my $account = $rec_a->new ({name => 'apla', meta => 'pam-pam'});

my $table_name = $account->table_name;

ok ($table_name eq 'account');

ok ($account);
ok (ref $account eq $rec_a);

ok ($account->name eq 'apla'); 
ok ($account->meta eq 'pam-pam', 'table test finished');

$account->save;

# test for 'meta' field cleanup after save
ok ! defined $account->field_values;

ok $account->id;

$account->meta ('pam-pam-pam');

ok $account->save;

# test for 'meta' field cleanup after save
ok ! defined $account->field_values;

# test for account id change
my $acc_id = $account->id;

# warn Dumper $account->hash;

my $values_hash = $account->hash;

ok $values_hash->{id} == $acc_id;
ok $values_hash->{name} eq 'apla';
ok $values_hash->{meta} eq 'pam-pam-pam';

ok scalar keys %$values_hash == 3;

ok scalar keys %{$account->TO_JSON} == 3;
ok scalar keys %{$account->TO_XML} == 3;

$account->id (1000000);

ok $account->id == 1000000;

$account->_raw_id (1000001);

ok $account->id == 1000001;

$account->embed (xxx => 'yyy');

$values_hash = $account->hash;

ok $values_hash->{id} == 1000001;

ok $values_hash->{xxx} eq 'yyy';

# todo: date test

ok $account->_fetched_id eq $acc_id;

$account->update_by_pk;

my $db_account = ref($account)->fetch_by_id ($account->id);

ok $db_account->meta eq 'pam-pam-pam', 'update by pk test';

ok $db_account->delete_by_pk;

$db_account = ref($account)->fetch_by_id ($account->id);

ok !$db_account;

#my $test_view = $PKG_VIEW->new ({user => 'apla', param => 'pam-pam'});
#
#warn Dumper $test_view->columns;

my $contact = $rec_c->new ({type => 'email', value => 'apla@localhost', account_id => $account->id});

my $cols = $contact->columns;

ok (scalar keys %$cols);

ok ($contact->type eq 'email');
ok ($contact->value eq 'apla@localhost');

# now we insert record to db
ok $contact->create, 'inserted';

# must be not null
ok $contact->id, 'id updated after insert';

# but record not updated to actual data, changed only pk column value
ok ! $contact->active, 'but active field not updated';

# now we fetch by pk column;
my $contact_clone = $rec_c->fetch_by_id ($contact->id);

ok $contact_clone->active;

$contact_clone->value ('apla@local');

ok $contact->type eq 'email';

$contact_clone->save;

$contact = $rec_c->fetch_by_id ($contact->id, [qw(id value active)]);

ok $contact->active;

ok $contact->value eq 'apla@local', "contact value is: " . $contact->value;

ok ! $contact->type, 'type defined and exists, but not fetched';

# testing date conversion
my $time = time;

$account = $rec_a->new ({name => 'apla', meta => 'pam-pam', created_date => $time});

ok $account->save;

$db_account = ref($account)->fetch_by_id ($account->id);

SKIP: {
	skip "this database doesn't know about date types", 1
		unless $db_account->columns->{created_date}->{decoder};
	ok $db_account->column_values->{created_date} =~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, 'fetched from db: ' . $db_account->column_values->{created_date};
};

ok $db_account->created_date == $time, '... but when accessed: ' . $db_account->created_date;

$rec_a->new ({name => 'apla2', meta => 'pam-pam2', created_date => $time + 2})->save;
$rec_a->new ({name => 'apla3', meta => 'pam-pam3', created_date => $time + 3})->save;

my $coll_a = collection_for ('account')->new;

logger (default => *STDERR);

#use Data::Dumper;
my $records = $coll_a->records (where => {_created_date => {'>=', $time}});

#warn Dumper $records;

ok @$records == 3;

$records = $coll_a->records (where => {_created_date => {'>', $time}});

ok @$records == 2;

$records = $coll_a->records (where => {_created_date => {'<', $time + 1}});

ok @$records == 1;

# DEPRECATED
#make_accessor ($rec_c, 'dump_fields_include', default => [qw(value type id)]);
#ok scalar keys %{$contact->TO_JSON} eq 2;

#warn '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
#warn Dumper $contact->TO_JSON;
#warn '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';

&finish_db;
