#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package X;

use Test::More tests => 15;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
   list => [ qw / a b / ],
   list => 'c'
  );

sub new { bless {}, shift; }
my $o = new X;

ok( 1, "start" );
ok( ! scalar @{$o->a} );
ok( $o->a(123, 456) );
ok( $o->unshift_a('baz') );
is( $o->pop_a , 456 );
is( $o->shift_a , 'baz' );

#7--8
my @a = (123, 'foo', [ qw / a b c / ], 'bar') ;
ok( $o->b_push(@a));
is_deeply([$o->b], \@a,"check push");

my @r = splice @a,1,2,'baz' ;

is_deeply([$o->splice_b(1, 2, 'baz')], \@r, "splice") ;
is_deeply([$o->b], \@a,"check after splice");

ok( ! scalar @{$o->clear_b} );
ok( ! scalar @{$o->b} );

$o->b_unshift (qw/ a b c /);

is_deeply([$o->b_index (2, 1, 1, 2)],
	  [qw/c b b c/]);

$o->b_set ( 1 => 'd' );

is_deeply([$o->b], [qw/a d c/]) ;

eval {
  $o->b_set ( 0 => 'e', 1 );
};
# 20
ok( $@ ,"check wrong arguments");
exit 0;

