package Bar;
use strict;
use parent 'Foo';
use Class::Property;

property(
    'price_bar' => { 'get' => undef, 'set' => 'default' }            # default setter and getter
    , 'price_bar_ro' => { 'get' => undef }                           # default setter and getter
    , 'price_bar_wo' => { 'set' => 'default' }                       # default setter and getter
);


1;
