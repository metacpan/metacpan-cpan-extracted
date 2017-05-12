
use Test::More tests => 24;

package Foo;

BEGIN {
  require Class::Lego::Constructor;
  our @ISA = qw( Class::Lego::Constructor );
}

my $counter = 0;

__PACKAGE__->mk_constructor0({
  magical_number => 42,
  title => '<untitled>',
  date => sub { scalar localtime },
  counter => sub { ++$counter },
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
