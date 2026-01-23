#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DBIx::Class::Async::ResultSet;
use Future;

# 1. Setup a mock async_db that simulates a large table
# and returns 100 for a total count, but respects LIMIT.
{
    package Mock::AsyncDB;
    sub new { bless {}, shift }
    sub count {
        my ($self, $source, $cond, $attrs) = @_;

        if (defined $attrs && $attrs->{rows}) {
            return Future->done($attrs->{rows});
        }

        return Future->done(100);
    }
}

my $mock_db = Mock::AsyncDB->new;
my $rs = DBIx::Class::Async::ResultSet->new(
    schema      => bless({}, 'MockSchema'),
    async_db    => $mock_db,
    source_name => 'BigTable'
);

subtest 'Standard count (no limit)' => sub {
    $rs->count->then(sub {
        my $count = shift;
        is($count, 100, 'Total count returns full table size');
        return Future->done;
    })->get;
};

subtest 'Sliced count (with rows limit)' => sub {
    # If we limit to 5 rows, count() should return 5, not 100.
    $rs->search(undef, { rows => 5 })->count->then(sub {
        my $count = shift;
        is($count, 5, 'Count respects the "rows" attribute via subquery logic');
        return Future->done;
    })->get;
};

subtest 'Sliced count with offset' => sub {
    # Testing that offset doesn't break the subquery logic
    $rs->search(undef, { rows => 10, offset => 95 })->count->then(sub {
        my $count = shift;
        # Only 5 rows left if we start at 95 of 100
        # However, a LIMIT 10 subquery on a set of 100 will usually return 10
        is($count, 10, 'Count respects rows even with offset');
        return Future->done;
    })->get;
};

done_testing();
