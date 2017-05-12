use strict;
use warnings;
use lib 't/lib';
use TestClass;

my $schema = TestClass->schema({ populate => 1 });
isa_ok($schema, 'Test::Schema', 'correct schema class');

JoeFoo : {
  my $joe = $schema->resultset('Foo')->search_rs({
    first_name => 'Joe',
  }, { rows => '1' })->single;
  isa_ok($joe, 'Test::Schema::Result::Foo');

  ok($joe->can('has_bars'), "Joe has 'has_bars' predicate");
  ok($joe->has_bars, "Joe has bars");

  my $joe_bar = $joe->bars->first;
  isa_ok($joe_bar, 'Test::Schema::Result::Bar');
  ok($joe_bar->can('has_foo'), "Joe's Bar has 'has_foo' predicate");
  ok($joe_bar->has_foo, "Joe's Bar has foo");

  ok($joe->can('got_a_buzz'), "Joe has 'got_a_buzz' predicate");
  ok($joe->got_a_buzz, "Joe has a buzz");
  my $joe_buzz = $joe->buzz;
  isa_ok($joe_buzz, 'Test::Schema::Result::Buzz');

  ok(!$joe->can('has_foo_baz'), "Joe has not 'has_foo_baz' predicate");
  ok(!$joe->can('has_bazes'), "Joe has not 'has_bazes' predicate");
};

JohnFoo: {
  my $john = $schema->resultset('Foo')->search_rs({
    first_name => 'John',
  }, { rows => '1' })->single;
  isa_ok($john, 'Test::Schema::Result::Foo');

  ok($john->can('got_a_buzz'), "John has 'got_a_buzz' predicate");
  ok(!$john->got_a_buzz, "John has not a buzz");

  ok(!$john->can('has_foo_baz'), "John has not 'has_foo_baz' predicate");
  ok(!$john->can('has_bazes'), "John has not 'has_bazes' predicate");
};

done_testing();
