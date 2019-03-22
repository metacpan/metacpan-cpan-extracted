#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;
use MY::Tests;

use MY::Class::TypeTinyNOBUILD;

ok(!MY::Class::TypeTinyNOBUILD->can('BUILD'), 'BUILD() does not exist');
ok(MY::Class::TypeTinyNOBUILD->can('_check_all_constraints'), '_check_all_constraints() exists');

MY::Tests::test_accessors(
    MY::Class::TypeTinyNOBUILD->new(medint=>15, regular=>'hello')
);

MY::Tests::test_accessors(
    MY::Class::TypeTinyNOBUILD->new(medint=>15, regular=>'hello'),
    1
);

# Constructor parameters should NOT be tested, since we specified NOBUILD.
# Therefore, these constraint-violating constructor calls should succeed.
lives_ok { MY::Class::TypeTinyNOBUILD->new(regular=>1, medint=>$_) }
    "medint=>$_ is not checked against constraint"
    foreach (9, 20, 'oops', '', \*STDOUT);

done_testing();
