use Test::More tests => 56;

use DT;
use DateTime::Duration;

my $tests = eval do { local $/ = undef; <DATA> }
    or die "Can't read DATA: $@";

for my $test ( @$tests ) {
    my $method = $test->{method};
    my $args = $test->{args};
    my $want = $test->{want};
    
    # Arbitrarily chosen date, nothing special
    my $dt = DT->new({
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'America/Los_Angeles',
    });
    
    my $orig = "$dt";
    
    my $dt_copy = eval { $dt->$method($args) };
    
    is $@, '', "$method no exception";
    isa_ok $dt_copy, 'DT';
    
    my $have = "$dt_copy";
    
    is $have, $want, "$method return value";
    is "$dt", $orig, "$method original date not mutated";
}

__DATA__
[{
    method => 'add',
    args => { months => 1 },
    want => "2018-03-08T19:07:53",
}, {
    method => 'add_duration',
    args => DateTime::Duration->new({ days => 7 }),
    want => "2018-02-15T19:07:53",
}, {
    method => 'subtract',
    args => { years => 10 },
    want => "2008-02-08T19:07:53",
}, {
    method => 'subtract_duration',
    args => DateTime::Duration->new({ seconds => 10 }),
    want => "2018-02-08T19:07:43",
}, {
    method => 'truncate',
    args => { to => 'day' },
    want => "2018-02-08T00:00:00",
}, {
    method => 'set',
    args => { day => 28 },
    want => "2018-02-28T19:07:53",
}, {
    method => 'set_time_zone',
    args => 'America/Chicago',
    want => "2018-02-08T21:07:53",
}, {
    method => 'set_year',
    args => 2016,
    want => "2016-02-08T19:07:53",
}, {
    method => 'set_month',
    args => 5,
    want => "2018-05-08T19:07:53",
}, {
    method => 'set_day',
    args => 1,
    want => "2018-02-01T19:07:53",
}, {
    method => 'set_hour',
    args => 23,
    want => "2018-02-08T23:07:53",
}, {
    method => 'set_minute',
    args => 38,
    want => "2018-02-08T19:38:53",
}, {
    method => 'set_second',
    args => 42,
    want => "2018-02-08T19:07:42",
}, {
    method => 'set_nanosecond',
    args => 33,
    want => "2018-02-08T19:07:53",
}]
