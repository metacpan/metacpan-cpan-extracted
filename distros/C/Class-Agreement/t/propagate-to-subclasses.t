#!perl

use strict;
use warnings;

#
# Make sure that our contracts are enforced on subclasses, no matter whether
# the subclass overrides the method or not. Also make sure that other classes
# and methods aren't affected.
#

use Test::More tests => 36;
use Test::Exception;

{

    package TheBase;
    use Class::Agreement;
    precondition method_with_contract  => sub { not $_[1] % 2 };
    postcondition method_with_contract => sub { not result % 3 };
    sub new { bless {}, shift }
    sub method_with_contract { $_[1] }
    sub unaffected_method    { $_[1] }

    package InheritedClassA;
    use base 'TheBase';

    package InheritedClassB;
    use base 'InheritedClassA';

    package OverriddenClassA;
    use base 'TheBase';
    sub method_with_contract { $_[1] }
    sub unaffected_method    { $_[1] }

    package OverriddenClassB;
    use base 'OverriddenClassA';
    sub method_with_contract { $_[1] }
    sub unaffected_method    { $_[1] }

}

foreach my $class (
    qw( TheBase InheritedClassA InheritedClassB OverriddenClassA OverriddenClassB )
    )
{

    my $a = 'method_with_contract';
    dies_ok  { $class->new->$a(2) } "$class\::$a, pre";
    dies_ok  { $class->new->$a(3) } "$class\::$a, post";
    lives_ok { $class->new->$a(6) } "$class\::$a, neither";

    my $b = 'unaffected_method';
    lives_ok { $class->new->$b(2) } "$class\::$b, no pre";
    lives_ok { $class->new->$b(3) } "$class\::$b, no post";
    lives_ok { $class->new->$b(6) } "$class\::$b, neither";
}

{

    package UnaffectedClass;
    sub new { bless {}, shift }
    sub some_method { $_[1] }

    package UnaffectedOverriddenClass;
    sub new { bless {}, shift }
    sub some_method { $_[1] }
}

foreach my $class (qw( UnaffectedClass UnaffectedOverriddenClass )) {
    my $a = 'some_method';
    lives_ok { $class->new->$a(2) } "$class\::$a, no pre";
    lives_ok { $class->new->$a(3) } "$class\::$a, no post";
    lives_ok { $class->new->$a(6) } "$class\::$a, neither";
}

