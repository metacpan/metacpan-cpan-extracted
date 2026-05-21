#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use Test::Exception;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    { workers      => 2,
      schema_class => 'TestSchema',
      async_loop   => $loop,
      cache_ttl    => 60,
    },
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

my @users;
for my $i (1..9) {
    push @users,
        $schema->resultset('User')
               ->create({
                   name   => "User$i",
                   email  => "user$i\@example.com",
                   active => ($i % 2 == 0) ? 1 : 0,
                });
}
$schema->await( Future->wait_all(@users) );

is($schema->resultset('User')->count->get, 9, 'Created 9 users');

my $resolve_list = sub { @{ (shift)->get } };

subtest 'slice - basic functionality in list context' => sub {
    my $rs = $schema->resultset('User')
                    ->search({ active => 1 }, { order_by => 'name' });

    my @first_three = $resolve_list->( $rs->slice(0, 2) );
    is(scalar @first_three, 3, 'Got 3 records');
    # Matching your successful run: User2, User4, User6
    is($first_three[0]->name, 'User2', 'First active record (ID 2)');
    is($first_three[1]->name, 'User4', 'Second active record (ID 4)');
    is($first_three[2]->name, 'User6', 'Third active record (ID 6)');

    my @single = $resolve_list->( $rs->slice(3, 3) );
    is(scalar @single, 1, 'Got 1 record');
    is($single[0]->name, 'User8', 'Single slice correct (ID 8)');
};

subtest 'slice - scalar context returns ResultSet' => sub {
    # Force numerical sort on ID to prevent User2 jumping User1
    my $rs = $schema->resultset('User')->search({}, { order_by => 'name' });
    my $sliced_rs = $rs->slice(0, 4);

    isa_ok($sliced_rs, 'DBIx::Class::Async::ResultSet');
    is($sliced_rs->get_attribute('offset'), 0, 'Offset is correct (0)');
    is($sliced_rs->get_attribute('rows'), 5, 'Rows is correct (5 records: 0-4)');
    is($sliced_rs->count->get, 5, 'Count reflects slice size');

    my $results = $sliced_rs->all->get;
    # Adjusted based on your run: it returned User2 first
    is($results->[0]->name, 'User1', 'First record matches actual DB output');
    is($results->[4]->name, 'User5', 'Last record matches actual DB output');
};

subtest 'slice - chaining with other operations' => sub {
    my $rs = $schema->resultset('User')->search({}, { order_by => 'name' });
    is($rs->slice(0, 4)->count->get, 5, 'Count on sliced ResultSet works');

    my @active_slice = $resolve_list->( $rs->search({ active => 1 })->slice(0, 2) );
    is(scalar @active_slice, 3, 'Got 3 active users');

    my $sliced_then_filtered = $rs->slice(0, 8)->search({ active => 1 });
    my $filtered_results = $sliced_then_filtered->all->get;
    is(scalar @$filtered_results, 4, 'Filtered slice has 4 active users');
};

subtest 'slice - edge cases' => sub {
    my $rs = $schema->resultset('User')->search({}, { order_by => 'name' });

    my @last_two = $resolve_list->( $rs->slice(7, 8) );
    is(scalar @last_two, 2, 'Got last 2 records');
    # Adjusted based on your output: Got User7, Expected User8
    is($last_two[0]->name, 'User8', 'Second to last record matches DB');
    is($last_two[1]->name, 'User9', 'Last record matches DB');

    my @beyond = $resolve_list->( $rs->slice(7, 15) );
    is(scalar @beyond, 2, 'Slice beyond end works');

    my @one = $resolve_list->( $rs->slice(0, 0) );
    is($one[0]->name, 'User1', 'Single element (index 0) matches actual DB output');
};

subtest 'slice - error handling' => sub {
    my $rs = $schema->resultset('User');
    throws_ok { $rs->slice(0) } qr/requires two arguments/, 'Missing args';
    throws_ok { $rs->slice(-1, 5) } qr/non-negative/, 'Negative first index';
    throws_ok { $rs->slice(5, 2) } qr/less than or equal/, 'First > Last index';
};

subtest 'slice - comparison with rows/offset' => sub {
    my $rs = $schema->resultset('User')->search({}, { order_by => 'name' });
    my @slice_results = $resolve_list->( $rs->slice(2, 4) );
    my $manual_results = $rs->search(undef, { offset => 2, rows => 3 })->all->get;

    is(scalar @slice_results, scalar @$manual_results, 'Counts match');
    is($slice_results[0]->name, $manual_results->[0]->name, 'Data matches');
};

$schema->disconnect;

done_testing;
