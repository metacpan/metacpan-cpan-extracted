use strict;
use warnings;
use Test::More tests => 33;

BEGIN {
    use_ok('Data::Queue::Persistent');
};

our $testdb = 'test.db';

my $skip;
eval "use DBD::SQLite; 1;" or $skip = 1;

SKIP: {
    skip "Can't run tests without SQLite", 32 if $skip;
    test();
    unlink $testdb;
}

sub test {
    unlink $testdb if -e $testdb;

    # run tests
    {
        my $q1 = Data::Queue::Persistent->new(
            dsn => "dbi:SQLite:dbname=$testdb",
            id  => 'test',
            max_size => 15,
            );

        ok($q1->table_exists, "Created persistent queue with sqlite backend");

        run_tests($q1, 0);
    }

    # test caching
    {
        my $q2 = Data::Queue::Persistent->new(
            dsn   => "dbi:SQLite:dbname=$testdb",
            id    => 'test',
            max_size => 15,
            cache => 1,
            );

        ok($q2->table_exists, "Created persistent queue with sqlite backend, using caching");

        run_tests($q2, 1);
    }
}

sub run_tests {
    my $q = shift;
    my $caching = shift;

    # make sure queue is empty (in case it loaded data from a previous test)
    $q->empty;

    # add to queue
    my @vals = ('a', 'b', 'c', 'lol', 'dongs');
    $q->add(@vals);
    is_deeply([$q->all], \@vals, 'unshift');

    is($q->shift, 'a', 'shift');

    $q->add(1, 2, 3);

    is($q->get(0, 1), 'b', 'get');
    is(scalar $q->get(1), 'c', 'get');
    is_deeply([$q->get(2,2)], ['lol', 'dongs'], 'get');

    is($q->length, 7, "length");

    is_deeply([$q->shift(3)], ['b', 'c', 'lol'], 'multiple shift');

    is_deeply([$q->shift(4)], ['dongs', 1, 2, 3], 'multiple shift');

    $q->add(7, 9, 11);

    is_deeply([$q->get(0, 2, reverse => 1)], [11, 9], 'get reverse');

    # load a new queue, make sure data is the same
    my $other_q = Data::Queue::Persistent->new(
                                               dsn => "dbi:SQLite:dbname=$testdb",
                                               id  => 'test',
                                               cache => $caching,
                                               );

    is(scalar $other_q->all, 3, "loaded queue from db");
    is_deeply([$other_q->all], [$q->all], "loaded queue from db");

    $q->empty;
    is($q->length, 0, "empty");

    if ($caching) {
        # since other instance is cached, shouldn't be affected
        is_deeply([$other_q->all], [7, 9, 11], "empty");
    } else {
        is_deeply([$other_q->all], [], "empty");
    }


    $q->add(map { $_ } 1..20);
    is($q->length, 15, 'max_size');
    is_deeply([$q->all], [6..20], "max_size");

    $q->empty;
}
