#!/usr/bin/env perl

use Test::Most;

use DBIx::RetryConnect qw(NullP);

sub is_not_delayed(&) {
    my $start_time = time;
    shift->();
    cmp_ok time - $start_time, '<=', 5, 'executed reasonably quickly';
}

is_not_delayed {
    ok(DBI->connect('dbi:NullP:'), 'connect worked');
};


done_testing();
