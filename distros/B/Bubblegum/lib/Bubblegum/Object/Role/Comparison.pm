package Bubblegum::Object::Role::Comparison;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'requires', 'with';

with 'Bubblegum::Object::Role::Item';

our $VERSION = '0.45'; # VERSION

requires 'eq';
requires 'eqtv';
requires 'gt';
requires 'gte';
requires 'lt';
requires 'lte';
requires 'ne';

sub equal {
    goto &eq;
}

sub equal_type_and_value {
    goto &eqtv;
}

sub greater {
    goto &gt;
}

sub greater_or_equal {
    goto &gte;
}

sub lesser {
    goto &lt
}

sub lesser_or_equal {
    goto &lte
}

sub not_equal {
    goto &ne;
}

1;
