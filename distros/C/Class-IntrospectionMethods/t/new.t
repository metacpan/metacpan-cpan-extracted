#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package X;

use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;

make_methods(
  new => 'new',
  new_with_args => 'new_with_args',
  new_with_init => 'new_with_init', 
  get_set => 'toto'
  );

my $init_called;
my @args_in_init;

sub init {
  my ($self, @args) = @_;
  $init_called++;
  @args_in_init = @args;
}


package main ;

use Test::More tests=> 11;

ok( 1 );

# Regular new
ok( $o = new X );
is( ref $o , 'X' );

# new_with_init
my @args = (1, 2, 3);
ok( $o = X->new_with_init(@args) );
is( ref $o , 'X' );
is(  $#args_in_init , $#args );

for (0..$#args) 
  { 
    is($args_in_init[$_],  $args[$_]);
  };

# new_with_args
ok( $o = X->new_with_args(toto => '3'));
is( $o->toto , '3');

exit 0;

