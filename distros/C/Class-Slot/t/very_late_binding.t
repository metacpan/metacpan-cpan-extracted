use Test2::V0;

my $pkg = q{
  package Foo;
  use Class::Slot -debug;
  slot 'bar';
  1;
};

eval $pkg;
my $err = $@;

my $warned = warning{ eval $pkg };

ok !$@, 'no errors'
  or diag $@;

ok !$warned, 'run-time eval of pkg importing Class::Slot does not generate "Too late to run INIT block" warning'
  or diag "warning triggered: $warned";

ok my $foo = Foo->new(bar => 42), 'ctor created';
is $foo->bar, 42, 'slot created';

done_testing;
