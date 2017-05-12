# -*- cperl-*-
use warnings FATAL => qw(all);

package X;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;

make_methods(
  get_set => [qw/ a b /],
  get_set => 'c' );

sub new { bless {}, shift; }

package main;
use Test::More tests => 6;

my $o = new X;

ok( 1 );
ok( ! defined $o->a );
ok( $o->a(123) );
is( $o->a , 123 );
ok( ! defined $o->a (undef) );
ok( ! defined $o->a );

exit 0;

