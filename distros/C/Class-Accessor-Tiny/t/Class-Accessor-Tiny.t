# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-Accessor-Tiny.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
#use ExtUtils::testlib;

use Test::More tests => 10;
{
    package ABC;
    use constant CLASS => 'Class::Accessor::Tiny';
    BEGIN { *use_ok = \&Test::More::use_ok; };
    BEGIN { use_ok('Class::Accessor::Tiny') };
    use_ok( CLASS, 'new');
    use_ok( CLASS, 'attr');
}
use constant CLASS => 'ABC';

can_ok( 'ABC', 'new');
can_ok( 'ABC', 'get_attr');
can_ok( 'ABC', 'set_attr');

isa_ok( my $obj= CLASS->new, CLASS );

is( $obj->get_attr, undef, "get_attr");
is( $obj->set_attr(10), $obj, "set_attr" );
is( $obj->get_attr, 10, "get_attr 10");


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

