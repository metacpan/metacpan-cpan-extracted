#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;
use MY::Tests;

use MY::Class::TypeTiny;

MY::Tests::test_accessors(
    MY::Class::TypeTiny->new(medint=>15, regular=>'hello')
);

MY::Tests::test_accessors(
    MY::Class::TypeTiny->new(medint=>15, regular=>'hello'),
    1
);

MY::Tests::test_construction 'MY::Class::TypeTiny';

done_testing();
