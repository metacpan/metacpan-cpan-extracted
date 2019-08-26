package Date;
use 5.012;
use Time::XS;
use Date::Rel;
use Date::Int;

our $VERSION = '4.0.2';

XS::Loader::bootstrap();

Export::XS::Auto->import(
    E_OK         => 0,
    E_UNPARSABLE => 1,
    E_RANGE      => 2,
    SEC          => rdate_const("1s"),
    MIN          => rdate_const("1m"),
    HOUR         => rdate_const("1h"),
    DAY          => rdate_const("1D"),
    MONTH        => rdate_const("1M"),
    YEAR         => rdate_const("1Y"),
);

use overload
    '""'     => \&to_string,
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
