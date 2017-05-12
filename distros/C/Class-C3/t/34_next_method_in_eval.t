use strict;
use warnings;

use Test::More tests => 1;

=pod

This tests the use of an eval{} block to wrap a next::method call.

=cut

{
    package ClassA;
    use Class::C3;

    sub foo {
      die 'ClassA::foo died';
      return 'ClassA::foo succeeded';
    }
}

{
    package ClassB;
    BEGIN { our @ISA = ('ClassA'); }
    use Class::C3;

    sub foo {
      eval {
        return 'ClassB::foo => ' . (shift)->next::method();
      };

      if ($@) {
        return $@;
      }
    }
}

Class::C3::initialize();

like(ClassB->foo,
   qr/^ClassA::foo died/,
   'method resolved inside eval{}');


