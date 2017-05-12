use Test::More tests => 42;

use strict;
use warnings;

BEGIN { use_ok('Class::Accessor::Class'); }

can_ok('Class::Accessor::Class', 'mk_class_accessors');

package Robot;
	@Robot::ISA = qw(Class::Accessor::Class);
	Robot->mk_class_accessors(qw(robots_online));
	Robot->robots_online(1);

	sub new { my $class = shift; bless {@_} => $class }
	sub do_something {
		my $self = shift;
		return $self->robots_online ? 1 : 0;
	}
package main;

ok(1, "set up Robot package");
can_ok('Robot', 'robots_online');

my $whiz = Robot->new(name => 'Whiz');
isa_ok($whiz,        'Robot', 'Whiz');
    is($whiz->{name}, 'Whiz', 'name set properly');

my $iris = Robot->new(name => 'Iris');
isa_ok($iris,        'Robot', 'Iris');
    is($iris->{name}, 'Iris', 'name set properly');

cmp_ok(Robot->robots_online, '==', 1, "robots online by default");
    is($Robot::robots_online, undef,  "package variable untouched");
cmp_ok($whiz->robots_online, '==', 1, "robots online (via instance whiz)");
cmp_ok($iris->robots_online, '==', 1, "robots online (via instance iris)");
cmp_ok($whiz->do_something,  '==', 1, "robots online: whiz can do something");
cmp_ok($iris->do_something,  '==', 1, "robots online: iris can do something");

cmp_ok(Robot->robots_online(0), '==', 0, "robots taken offline");

cmp_ok(Robot->robots_online, '==', 0, "robots now offline");
    is($Robot::robots_online, undef,  "package variable untouched");
cmp_ok($whiz->robots_online, '==', 0, "robots offline (via instance whiz)");
cmp_ok($iris->robots_online, '==', 0, "robots offline (via instance iris)");
cmp_ok($whiz->do_something,  '==', 0, "robots offline: whiz can do nothing");
cmp_ok($iris->do_something,  '==', 0, "robots offline: iris can do nothing");

cmp_ok(Robot->robots_online(2), '==', 2, "robots brought online");

cmp_ok(Robot->robots_online, '==', 2, "robots now online");
    is($Robot::robots_online, undef,  "package variable untouched");
cmp_ok($whiz->robots_online, '==', 2, "robots online (via instance whiz)");
cmp_ok($iris->robots_online, '==', 2, "robots online (via instance iris)");
cmp_ok($whiz->do_something,  '==', 1, "robots online: whiz can do something");
cmp_ok($iris->do_something,  '==', 1, "robots online: iris can do something");

cmp_ok($whiz->robots_online(0), '==', 0, "robots taken offline whiz");

cmp_ok(Robot->robots_online, '==', 0, "robots now offline");
    is($Robot::robots_online, undef,  "package variable untouched");
cmp_ok($whiz->robots_online, '==', 0, "robots offline (via instance whiz)");
cmp_ok($iris->robots_online, '==', 0, "robots offline (via instance iris)");
cmp_ok($whiz->do_something,  '==', 0, "robots offline: whiz can do nothing");
cmp_ok($iris->do_something,  '==', 0, "robots offline: iris can do nothing");

cmp_ok($iris->robots_online(3), '==', 3, "robots brought online via iris");

cmp_ok(Robot->robots_online, '==', 3, "robots now online");
    is($Robot::robots_online, undef,  "package variable untouched");
cmp_ok($whiz->robots_online, '==', 3, "robots online (via instance whiz)");
cmp_ok($iris->robots_online, '==', 3, "robots online (via instance iris)");
cmp_ok($whiz->do_something,  '==', 1, "robots online: whiz can do something");
cmp_ok($iris->do_something,  '==', 1, "robots online: iris can do something");
