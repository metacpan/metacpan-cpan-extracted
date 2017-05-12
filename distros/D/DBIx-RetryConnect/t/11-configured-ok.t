#!/usr/bin/env perl

use Test::Most;
use Time::HiRes qw(time);

use lib 't/lib';

my $config_coderef_called;

use DBIx::RetryConnect NoConnect => sub {
    my ($drh, $dsn, $user, $password, $attrib) = @_;

    ++$config_coderef_called;

    ok ref $drh, 'got drh';
    is $drh->{Name}, 'NoConnect', 'got right drh';
    is $dsn, 'driverdsn', 'got right driver dsn';
    is $user, 'u', 'got username';
    is $password, 'p', 'got password';
    is ref $attrib, 'HASH', 'got attribs';

    is $drh->err, 42, 'err is set';

    return {};
};

sub duration_of(&) {
    my $start_time = time;
    shift->();
    return time - $start_time;
}


cmp_ok duration_of {
    ok(DBI->connect('dbi:NoConnect:driverdsn', 'u', 'p', { no_connect => { countdown => 0 }}), 'connect worked');
}, '<', 2, 'is fast with no connection failures';
is $config_coderef_called, undef, 'config code ref should not be called if no failure';

cmp_ok duration_of {
    ok(DBI->connect('dbi:NoConnect:driverdsn', 'u', 'p', { no_connect => { countdown => 6 }}), 'connect worked');
}, '>', 4, 'is slow with no connection failures';
is $config_coderef_called, 1, 'config code ref should be called once';


done_testing();
