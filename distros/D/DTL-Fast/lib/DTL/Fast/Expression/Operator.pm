package DTL::Fast::Expression::Operator;
use strict;
use utf8;
use warnings FATAL => 'all';

our $VERSION = '1.00';

use DTL::Fast qw(register_operator);

register_operator(
    or       => [ 0, 'DTL::Fast::Expression::Operator::Binary::Or' ],

    and      => [ 1, 'DTL::Fast::Expression::Operator::Binary::And' ],

    '=='     => [ 2, 'DTL::Fast::Expression::Operator::Binary::Eq' ],
    '!='     => [ 2, 'DTL::Fast::Expression::Operator::Binary::Ne' ],
    '<>'     => [ 2, 'DTL::Fast::Expression::Operator::Binary::Ne' ],
    '<'      => [ 2, 'DTL::Fast::Expression::Operator::Binary::Lt' ],
    '>'      => [ 2, 'DTL::Fast::Expression::Operator::Binary::Gt' ],
    '<='     => [ 2, 'DTL::Fast::Expression::Operator::Binary::Le' ],
    '>='     => [ 2, 'DTL::Fast::Expression::Operator::Binary::Ge' ],

    '+'      => [ 3, 'DTL::Fast::Expression::Operator::Binary::Plus' ],
    '-'      => [ 3, 'DTL::Fast::Expression::Operator::Binary::Minus' ],

    '*'      => [ 4, 'DTL::Fast::Expression::Operator::Binary::Mul' ],
    '/'      => [ 4, 'DTL::Fast::Expression::Operator::Binary::Div' ],
    '%'      => [ 4, 'DTL::Fast::Expression::Operator::Binary::Mod' ],
    mod      => [ 4, 'DTL::Fast::Expression::Operator::Binary::Mod' ],

    'not in' => [ 5, 'DTL::Fast::Expression::Operator::Binary::NotIn' ],
    in       => [ 5, 'DTL::Fast::Expression::Operator::Binary::In' ],

    not      => [ 6, 'DTL::Fast::Expression::Operator::Unary::Not' ],

    defined  => [ 7, 'DTL::Fast::Expression::Operator::Unary::Defined' ],

    '**'     => [ 8, 'DTL::Fast::Expression::Operator::Binary::Pow' ],
    pow      => [ 8, 'DTL::Fast::Expression::Operator::Binary::Pow' ],
);

1;