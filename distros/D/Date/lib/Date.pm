package Date;
use 5.012;
use Date::Rel;
use XS::Framework;
use XS::Install::Payload;

our $VERSION = '5.2.10';

XS::Loader::bootstrap();

__init__();

sub __init__ {
    my $dir = XS::Install::Payload::payload_dir('Date');
    tzembededdir("$dir/zoneinfo");
    use_embed_timezones() unless tzsysdir(); # use embed zones by default where system zones are unavailable
    *Date::errc:: = *Date::Error::;
}

Export::XS::Auto->import(
    SEC          => rdate_const("1s"),
    MIN          => rdate_const("1m"),
    HOUR         => rdate_const("1h"),
    DAY          => rdate_const("1D"),
    WEEK         => rdate_const("1W"),
    MONTH        => rdate_const("1M"),
    YEAR         => rdate_const("1Y"),
);

use overload
    '""'     => \&_op_str,
    'bool'   => \&to_bool,
    '0+'     => \&to_number,
    '<=>'    => \&compare,
    'cmp'    => \&compare,
    '+'      => \&sum,
    '+='     => \&add,
    '-'      => \&difference,
    '-='     => \&subtract,
    '='      => \&Date::__assign_stub,
    fallback => 1,
;

1;
