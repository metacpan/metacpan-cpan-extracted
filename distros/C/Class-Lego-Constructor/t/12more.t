
use Test::More tests => 34;

package Foo;

BEGIN {
  require Class::Lego::Constructor;
  our @ISA = qw( Class::Lego::Constructor );
}

my $counter = 0;

__PACKAGE__->mk_constructor1({
  magical_number => { default => 42 },
  title => { default => '<untitled>' },
  date => { default => sub { scalar localtime } },
  counter => { default => sub { ++$counter } },
});

package main;

ok( defined &Foo::new, '&new was defined' );

{
  my $foo = Foo->new();
  isa_ok( $foo, 'Foo' );

  is( $foo->{magical_number}, 42, 'magical_number gets the default' );
  is( $foo->{title}, '<untitled>', 'title gets the default' );
  ok( $foo->{date}, 'date gets the (computed) default' );
  is( $foo->{counter}, 1, 'counter gets the (computed) default' );
}

{
  my $foo = Foo->new({ magical_number => 13 });
  isa_ok( $foo, 'Foo' );

  is( $foo->{magical_number}, 13, 'magical_number gets the explicit value' );
  is( $foo->{title}, '<untitled>', 'title gets the default' );
  ok( $foo->{date}, 'date gets the (computed) default' );
  is( $foo->{counter}, 2, 'counter gets the (computed) default' );
}

{
  my $foo = Foo->new({ title => 'My Title' });
  isa_ok( $foo, 'Foo' );

  is( $foo->{magical_number}, 42, 'magical_number gets the default' );
  is( $foo->{title}, 'My Title', 'title gets the explicit value' );
  ok( $foo->{date}, 'date gets the (computed) default' );
  is( $foo->{counter}, 3, 'counter gets the (computed) default' );
}

{
  my $foo = Foo->new({ date => 'Today', counter => '?' });
  isa_ok( $foo, 'Foo' );

  is( $foo->{magical_number}, 42, 'magical_number gets the default' );
  is( $foo->{title}, '<untitled>', 'title gets the default' );
  is( $foo->{date}, 'Today', 'date gets the explicit value' );
  is( $foo->{counter}, '?', 'counter gets the explicit value' );
}

{
  my $foo = Foo->new();
  my $bar = Foo->new();

  is( $foo->{counter}, 4, 'counter gets the (computed) default' );
  is( $bar->{counter}, 5, 'counter gets the (computed) default' );
  isnt( $foo->{counter}, $bar->{counter}, 'different objects, different counter value' );
}

package Boo;

BEGIN {
  require Class::Lego::Constructor;
  our @ISA = qw( Class::Lego::Constructor );
}

use Scalar::Defer qw( defer );

__PACKAGE__->mk_constructor1({
  number => { default_value => 0 },
  string => { default_value => 'string' },
  hash => { default_value => { a => 2 } },
  array => { default_value => [1,2] },
  sub => { default_value => sub { $_[0]+1 } },
  deferred => { default_value => defer { 1 } },
});

package main;

use Scalar::Defer 0.13 qw( is_deferred );

ok( defined &Boo::new, '&new was defined' );

{
  my $boo = Boo->new();
  isa_ok( $boo, 'Boo' );

  is( $boo->{number}, 0, "default_value works with numbers" );
  is( $boo->{string}, 'string', "default_value works with strings" );
  is_deeply( $boo->{hash}, { a => 2 }, "default_value works with hash values" );
  is_deeply( $boo->{array}, [1,2], "default_value works with array values" );
  ok( ref $boo->{sub} eq 'CODE', "default_value works with CODE" );
  is( $boo->{sub}->(1), 2, "CODE through default_value works" );
  ok( is_deferred($boo->{deferred}), "default_value works with Scalar::Defer objects" );
  is( $boo->{deferred}, 1, "deferred objects through default_value works" );
}

# TODO test error conditions

