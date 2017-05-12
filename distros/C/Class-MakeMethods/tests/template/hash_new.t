#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 19 }

use Class::MakeMethods::Template::Hash (
  new => 'new',
  'new --with_init' => 'new_with_init',
  'new --instance_with_methods' => 'new_hash_init'
);

my $init_called;
my @args_in_init;
my $foo_called;
my $bar_called;

sub init {
  my ($self, @args) = @_;
  $init_called++;
  @args_in_init = @args;
}

sub foo {
  my ($self, $new) = @_;
  defined $new and $self->{'foo'} = $new;
  $foo_called = 1;
  $self->{'foo'};
}

sub bar {
  my ($self, $new) = @_;
  defined $new and $self->{'bar'} = $new;
  $bar_called = 1;
  $self->{'bar'};
}


ok( 1 ); #1

# Regular new
ok( $o = new X ); #2
ok( ref $o eq 'X' ); #3

# new_with_init
my @args = (1, 2, 3);
ok( $o = X->new_with_init(@args) ); #4
ok( ref $o eq 'X' ); #5
ok(  $#args_in_init == $#args ); #6
ok do {
  my $v = 1;
  for (0..$#args) { $args_in_init[$_] == $args[$_] or $v = 0; }
   $v;
};

# new_hash_init
ok( $o = X->new_hash_init( 'foo' => 123, 'bar' => 456 ) ); #7
ok( ref $o eq 'X' ); #8
ok( $foo_called ); #9
ok( $bar_called ); #10
ok( $o->foo == 123 ); #11
ok( $o->bar == 456 ); #12

# new_hash_init (taking hashref)
ok( $o = X->new_hash_init({ 'foo' => 123, 'bar' => 456 }) ); #13
ok( ref $o eq 'X' ); #14
ok( $foo_called ); #15
ok( $bar_called ); #16
ok( $o->foo == 123 ); #17
ok( $o->bar == 456 ); #18

exit 0;

