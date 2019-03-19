#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;
use MY::Tests;

BEGIN {
    plan skip_all => 'Could not load MouseX::Types' unless
        eval { require MouseX::Types; 1; };
}

use MY::Class::MouseXTypes;

MY::Tests::test_accessors(
    MY::Class::MouseXTypes->new(medint=>15, regular=>'hello')
);

MY::Tests::test_accessors(
    MY::Class::MouseXTypes->new(medint=>15, regular=>'hello'),
    1
);

MY::Tests::test_construction 'MY::Class::MouseXTypes';

done_testing();
