#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;
use MY::Tests;

use MY::Class::TypeTinyBUILD;

ok(MY::Class::TypeTinyBUILD->can('_check_all_constraints'), '_check_all_constraints() exists');

MY::Tests::test_accessors(
    MY::Class::TypeTinyBUILD->new(medint=>15, regular=>'hello')
);

MY::Tests::test_accessors(
    MY::Class::TypeTinyBUILD->new(medint=>15, regular=>'hello'),
    1
);

MY::Tests::test_construction 'MY::Class::TypeTinyBUILD';

done_testing();
