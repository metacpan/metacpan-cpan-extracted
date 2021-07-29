use Test2::V0 -no_srand => 1;

eval {
  package Foo;

  use Moo;  ## no critic (Modules::ProhibitConditionalUseStatements)

  with 'AnyEvent::FTP::Role::Event';

  __PACKAGE__->define_events(qw(bar baz other));
};
is $@, '', 'Create class Foo';

my $obj = Foo->new;
isa_ok $obj, 'Foo';

ok $obj->can('on_bar'), "can on_bar";
ok $obj->can('on_baz'), "can on_baz";
ok (!$obj->can('on_bogus'), "can't on_bogus");

my $bar  = 0;
my $baz  = 0;
my $both = 0;

$obj->on_bar(sub { $bar++ });
$obj->on_baz(sub { $baz++ });

$obj->on_bar(sub { $both++ });
$obj->on_baz(sub { $both++ });

ok $obj->can('emit'), 'can emit';

$obj->emit('bar');

is $bar,  1, 'bar  = 1';
is $baz,  0, 'baz  = 0';
is $both, 1, 'both = 1';

$obj->emit('baz');

is $bar,  1, 'bar  = 1';
is $baz,  1, 'baz  = 1';
is $both, 2, 'both = 2';

$obj->emit('bar');

is $bar,  2, 'bar  = 2';
is $baz,  1, 'baz  = 1';
is $both, 3, 'both = 3';

eval { $obj->emit('other') };
is $@, '', 'emitting an event with no listeners';

my $arg1;
my $arg2;
$obj->on_bar(sub {
  ($arg1, $arg2) = @_;
});

$obj->emit('bar', 1, 2);
is $arg1, 1, 'arg1 = 1';
is $arg2, 2, 'arg2 = 2';

$obj->emit('bar', 3, 4);
is $arg1, 3, 'arg1 = 3';
is $arg2, 4, 'arg2 = 4';

done_testing;
