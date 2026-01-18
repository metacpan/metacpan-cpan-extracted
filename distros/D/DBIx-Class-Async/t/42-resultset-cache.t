#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use File::Temp qw(tempfile);
use DBIx::Class::Async::Schema;

use lib 't/lib';
use TestSchema;

my $loop = IO::Async::Loop->new;
my ($fh, $db_file) = tempfile(UNLINK => 1);

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef, undef, { RaiseError => 1 },
    { workers => 1, schema_class => 'TestSchema', loop => $loop }
);

{
    my $rs = $schema->resultset('User')->search({ id => 1 });

    # 1. Create a "fake" row that doesn't exist in the DB
    my $fake_user = $rs->new_result({ id => 999, name => "Ghost" });

    # 2. Manually set the cache
    $rs->set_cache([ $fake_user ]);

    # 3. 'all' should return the fake user without hitting the DB
    my $results = $rs->all->get;
    is(scalar @$results, 1, "Got 1 result from RS cache");
    is($results->[0]->name, "Ghost", "Result came from set_cache, not DB");

    # 4. clear_cache should empty it
    $rs->clear_cache;
    ok(!defined $rs->get_cache, "Cache is now empty");
}

done_testing();
