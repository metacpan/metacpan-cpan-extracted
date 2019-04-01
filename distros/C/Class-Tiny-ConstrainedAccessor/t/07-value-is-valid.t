#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;
use MY::Tests;

use MY::Class::ValueIsValid;

MY::Tests::test_accessors(
    MY::Class::ValueIsValid->new(medint=>15, regular=>'hello')
);

MY::Tests::test_accessors(
    MY::Class::ValueIsValid->new(medint=>15, regular=>'hello'),
    1
);

MY::Tests::test_construction 'MY::Class::ValueIsValid';

done_testing();
