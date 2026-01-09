#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Future;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use lib 'lib';
use lib 't/lib';
use TestSchema;
use DBIx::Class::Async::Schema;

my $dbfile = 't/test_rel.db';
unlink $dbfile if -e $dbfile;

my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile", undef, undef, { RaiseError => 1 });
$schema->deploy;

my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile", undef, undef, {},
    { workers => 2, schema_class => 'TestSchema' }
);

my $user = $schema->resultset('User')->create({
    name  => 'Buyer',
    email => 'buyer@example.com',
});

$user->create_related('orders', { amount => 10 });
$user->create_related('orders', { amount => 2  });
$user->create_related('orders', { amount => 15 });

my $user_rs = $async_schema->resultset('User')->search({ email => 'buyer@example.com' });

subtest 'search_related_rs (Scalar Context)' => sub {
    # This should trigger the metadata path
    my $rs_only = $user_rs->search_related_rs('orders');

    isa_ok($rs_only, 'DBIx::Class::Async::ResultSet');
    is($rs_only->{source_name}, 'Order', 'Pivoted to Orders source');
};

subtest 'search_related (List Context)' => sub {
    # Assigning to an array forces list context
    my @results = $user_rs->search_related('orders');

    isa_ok($results[0], 'Future', 'In list context, returns a Future for the results');

    my @orders = $results[0]->get;
    is(scalar @orders, 1, 'Resolved Future contains 1 order');
};

done_testing();

END {
    unlink $dbfile if -e $dbfile;
}
