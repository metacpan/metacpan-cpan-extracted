use Test::More tests => 56;

use DT;
use DateTime::Duration;

my $tests = eval do { local $/ = undef; <DATA> }
    or die "Can't read DATA: $@";

for my $test ( @$tests ) {
    my $input = $test->{input};
    my $method = $test->{method};
    my $args = $test->{args};
    my $want = $test->{want};
    
    my $dt = DT->new($test->{input});
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
    # Arbitrarily chosen date, nothing special
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'America/Los_Angeles',
    },
    method => 'add',
    args => { months => 1 },
    want => "2018-03-08T19:07:53-08:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'America/Chicago',
    },
    method => 'add_duration',
    args => DateTime::Duration->new({ days => 7 }),
    want => "2018-02-15T19:07:53-06:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'America/New_York',
    },
    method => 'subtract',
    args => { years => 10 },
    want => "2008-02-08T19:07:53-05:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'America/Halifax',
    },
    method => 'subtract_duration',
    args => DateTime::Duration->new({ seconds => 10 }),
    want => "2018-02-08T19:07:43-04:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Africa/Casablanca',
    },
    method => 'truncate',
    args => { to => 'day' },
    want => "2018-02-08T00:00:00+00:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Europe/Madrid',
    },
    method => 'set',
    args => { day => 28 },
    want => "2018-02-28T19:07:53+01:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Europe/Moscow',
    },
    method => 'set_time_zone',
    args => 'America/Chicago',
    want => "2018-02-08T10:07:53-06:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Yekaterinburg',
    },
    method => 'set_year',
    args => 2016,
    want => "2016-02-08T19:07:53+05:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Omsk',
    },
    method => 'set_month',
    args => 5,
    want => "2018-05-08T19:07:53+06:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Novosibirsk',
    },
    method => 'set_day',
    args => 1,
    want => "2018-02-01T19:07:53+07:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Irkutsk',
    },
    method => 'set_hour',
    args => 23,
    want => "2018-02-08T23:07:53+08:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Yakutsk',
    },
    method => 'set_minute',
    args => 38,
    want => "2018-02-08T19:38:53+09:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Vladivostok',
    },
    method => 'set_second',
    args => 42,
    want => "2018-02-08T19:07:42+10:00",
}, {
    input => {
        year => 2018,
        month => 2,
        day => 8,
        hour => 19,
        minute => 7,
        second => 53,
        time_zone => 'Asia/Magadan',
    },
    method => 'set_nanosecond',
    args => 33,
    want => "2018-02-08T19:07:53.3e-08+11:00",
}]
