use strict;
use warnings;

use Test::More tests => 2;

=pod

This tests the successful handling of a next::method call from within an
anonymous subroutine.

=cut

{
    package ClassA;
    use Class::C3;

    sub foo {
      return 'ClassA::foo';
    }

    sub bar {
      return 'ClassA::bar';
    }
}

{
    package ClassB;
    BEGIN { our @ISA = ('ClassA'); }
    use Class::C3;

    sub foo {
      my $code = sub {
        return 'ClassB::foo => ' . (shift)->next::method();
      };
      return (shift)->$code;
    }

    sub bar {
      my $code1 = sub {
        my $code2 = sub {
          return 'ClassB::bar => ' . (shift)->next::method();
        };
        return (shift)->$code2;
      };
      return (shift)->$code1;
    }
}

Class::C3::initialize();

is(ClassB->foo, "ClassB::foo => ClassA::foo",
   'method resolved inside anonymous sub');

is(ClassB->bar, "ClassB::bar => ClassA::bar",
   'method resolved inside nested anonymous subs');


