#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

BEGIN {
	
	# logger('debug')->appender(*STDERR);
	
	use_ok 'DBI::Easy';
	use_ok 'DBD::SQLite';
	
	push @INC, 't', 't/DBI-Easy';
	require 'db-config.pl';
	
	my $dbh = &init_db;
	
};

my $rec_a = record_for ('account');
my $coll_a = collection_for ('account');

my $coll_c = collection_for ('contact');

$rec_a->is_related_to (
	'contacts', $coll_c
);

my $rec_p = record_for ('passport');

$rec_a->is_related_to (
	'passport', $rec_p
);

my $account = $rec_a->new ({name => 'apla'});

ok $account;

# $PKG->is_related_to ('records2', $COLL);

$account->create;

my $account2 = $rec_a->new ({name => 'gaddla'});

$account2->create;

my $collection = $account->contacts;

ok $collection;

ok $collection->filter->{'account_id'} == $account->id,
	'account id transferred to filter';

my $collection2 = $account2->contacts;

ok $collection2->filter->{'account_id'} == $account2->id;

my $count = $collection->count;
ok $count == 0, "items in collection = $count";

my $contact = $collection->new_record ({type => 'email', value => 'apla@flo.local'});

ok $contact->account_id == $account->id;

# diag Dumper $sub_record;

$contact->create;

$contact = $collection->new_record ({type => 'email', value => 'apla-subscriptions@flo.local'});

$contact->create;

$count = $collection->count;
ok $count == 2, "items in collection = $count";

# very funny
ok scalar @{$collection->records (sort_field => 'value', limit => 1)} == 1;

$collection->fieldset ([qw(type)]);

ok scalar @{$collection->records (group_by => 'type')} == 1;

$collection->fieldset ([qw(value)]);

my $emails = $collection->list ({type => 'email'});

ok !exists $emails->[0]->{type};

#$collection->register_fieldset ('emails', fields => [qw(email)]);
#
#$emails = $collection->list_emails ({type => 'email'});
#
#ok !exists $emails->[0]->{type};

$collection->fieldset ('*');

my $passport = $account->passport ({type => 'ABC', value => '123123123'});

ok $passport->account_id == $account->id;

use Class::Easy;

# $Class::Easy::DEBUG = 'immediately';

my $like_apla = $collection->list;

ok @$like_apla == 2;

$like_apla = $collection->list ("contact_value like 'apla\%'");

ok @$like_apla == 2, 'first like';

ok $collection->count ("contact_value like 'apla\%'") == 2;

$like_apla = $collection->list ("contact_value like ?", undef, ['apla%']);

ok @$like_apla == 2, 'second like';

ok $collection->count ("contact_value like ?", undef, ['apla%']) == 2;

my $collection3 = $coll_c->new;

ok @{$collection3->list} == 2;
ok $collection3->count == 2;

ok @{$collection3->list ({type => 'email'})} == 2;
ok $collection3->count ({type => 'email'}) == 2;

ok @{$collection->list ({_value => ' like ?'}, undef, ['apla%'])} == 2;

my $address_fields = {line => 'test str', city => 'usecase', country => 'testania'};

# WTF?
#ok $collection->update ({type => 'e-mail'}) == 2;
#ok $collection->count  ({type => 'e-mail'}) == 2;

$collection->natural_join ($rec_a);

# diag Dumper $collection->list;

my $paging = {page_size => 20, count => 1000, page_num => 1, pages_to_show => 8};

my $pager = $collection->pager ({%$paging, page_num => 1});
# diag '1 => ', join ', ', map {defined $_ ? $_ : '...'} @$pager;

$pager = $collection->pager ({%$paging, page_num => 10});
# diag '10 => ', join ', ', map {defined $_ ? $_ : '...'} @$pager;

$pager = $collection->pager ({%$paging, page_num => 3});
# diag '3 => ', join ', ', map {defined $_ ? $_ : '...'} @$pager;

$pager = $collection->pager ({%$paging, page_num => 5});
# diag '5 => ', join ', ', map {defined $_ ? $_ : '...'} @$pager;

# new, cleaner interfaces

ok $coll_a->count, "count";

ok $coll_a->new->count;

ok $#{$coll_a->list} == 1, 'simple list';

ok $#{$coll_a->list ({_name => 'like ' . $coll_a->quote ("apl%")})} == 0;

my $list_of_hashes = $coll_a->list_of_record_hashes ({
	_name => 'like ' . $coll_a->quote ("apl%")
});

# warn Dumper $list_of_hashes;

ok ref $list_of_hashes->[0] eq 'HASH';

#ok $list_of_hashes->[0]->{pass} eq 'abracadabra';

SKIP: {
	skip "some stupid db vendors called it 'feature'", 1
		if $coll_a->dbh_vendor eq 'mysql';
	# if you define single timestamp field in mysql, this field updated
	# every time when you are updating record
	ok keys %{$list_of_hashes->[0]} == 2;
};


ok $coll_a->count ({_name => 'like ' . $coll_a->quote ("apl%")}) == 1;

ok $coll_a->count (where => {_name => 'like ' . $coll_a->quote ("apl%")}) == 1;

# ok ! $collection->count ({contact_type => ''});

ok $coll_a->delete (where => {_name => 'like ' . $coll_a->quote ("apl%")}) == 1;

#my $items = $collection->

#my $address  = $account->addresses->new_record ($address_fields);
#$address->save;

#my $address2 = $account2->addresses->new_record ($address_fields);
#$address2->save;

&finish_db;
1;

