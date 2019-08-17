package Date::Int;
use 5.012;
use Date;

use overload
    '""'     => \&to_string,
    'bool'   => \&to_bool,
    '0+'     => \&to_number,
    '<=>'    => \&compare, # for idates - based on duration
    'eq'     => \&is_same, # absolute matching (from == from and till == till)
    '+'      => \&sum,
    '+='     => \&add,
    '-'      => \&difference,
    '-='     => \&subtract,
    'neg'    => \&negated,
    '='      => \&Date::__assign_stub,
    fallback => 1,
;

1;