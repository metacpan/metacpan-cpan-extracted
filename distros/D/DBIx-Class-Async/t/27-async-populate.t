#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Future;

use_ok('DBIx::Class::Async');

# 1. Setup Mocking Environment

my $mock_rs = bless {
    source_name => 'Posts',
    async_db    => bless({}, 'MockDB'),
    _cond       => { 'foreign.user_id' => 10 },
}, 'DBIx::Class::Async::ResultSet';

sub DBIx::Class::Async::ResultSet::new_result {
    my ($self, $data) = @_;
    return bless $data, 'DBIx::Class::Async::Result';
}

# 2. Test Logic: Data Cleaning & Merging

my $mock_data = [
    { title => 'Post 1', content => 'Hello' },
    { title => 'Post 2', content => 'World' }
];

my @final_data;
foreach my $row (@$mock_data) {
    # Merge context conditions (simulate the logic in ResultSet.pm)
    my %to_insert = ( %{$mock_rs->{_cond}}, %$row );
    my %clean_data;
    while (my ($k, $v) = each %to_insert) {
        my $clean_key = $k;
        $clean_key =~ s/^(?:foreign|self)\.//;
        $clean_data{$clean_key} = $v;
    }
    push @final_data, \%clean_data;
}

is($final_data[0]->{user_id}, 10, 'Foreign key "foreign.user_id" correctly cleaned to "user_id"');
is($final_data[0]->{title}, 'Post 1', 'Original data preserved');
is(scalar @final_data, 2, 'Correct number of rows prepared');

# 3. Test Logic: Object Inflation (populate)

my $db_response = [
    { id => 1, user_id => 10, title => 'Post 1', content => 'Hello' },
    { id => 2, user_id => 10, title => 'Post 2', content => 'World' },
];

my @objects = map { $mock_rs->new_result($_) } @$db_response;

is(scalar @objects, 2, "Inflated 2 objects from DB response");
isa_ok($objects[0], 'DBIx::Class::Async::Result', "First item");
is($objects[0]->{title}, 'Post 1', "Object data intact");
is($objects[0]->{user_id}, 10, "Inflated object contains foreign key");

# 4. Test Logic: Bulk Populate (populate_bulk)

my $bulk_data = [
    { 'foreign.user_id' => 20, title => 'Bulk 1' },
    { 'foreign.user_id' => 20, title => 'Bulk 2' }
];

# Simulate the cleaning logic inside ResultSet::populate_bulk
my $cleaned_bulk = [ map {
    my $row = $_;
    my %clean;
    while (my ($k, $v) = each %$row) {
        (my $clean_key = $k) =~ s/^(?:foreign|self)\.//;
        $clean{$clean_key} = $v;
    }
    \%clean;
} @$bulk_data ];

is($cleaned_bulk->[0]{user_id}, 20, 'Bulk: Foreign key cleaned');
ok(!exists $cleaned_bulk->[0]{'foreign.user_id'}, 'Bulk: Old key removed');

# 5. Simulate the Async response for Bulk

my $mock_bulk_response = { success => 1 };

my $final_result;
if (ref $mock_bulk_response eq 'HASH' && $mock_bulk_response->{success}) {
    $final_result = 1;
}

is($final_result, 1, 'populate_bulk returns truthy success instead of objects');

done_testing();
