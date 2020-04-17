package Date::Rel;
use 5.012;
use Date();

use overload
    '""'     => \&_op_str,
    'bool'   => \&to_bool,
    '0+'     => \&to_number,
    'neg'    => \&negated,
    '<=>'    => \&compare, # based on to_sec()
    'eq'     => \&is_same, # based on full equality only
    '+'      => \&sum,
    '+='     => \&add,
    '-'      => \&difference,
    '-='     => \&subtract,
    '*'      => \&product,
    '*='     => \&multiply,
    '/'      => \&quotient,
    '/='     => \&divide,
    '='      => \&Date::__assign_stub,
    fallback => 1,
;

1;