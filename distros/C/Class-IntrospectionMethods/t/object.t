#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package Y;
use ExtUtils::testlib;
our $nb = 0;

sub new { my $type = shift ; bless {  foo => 'foo', bar => 'bar', @_ }, $type; }
sub foo { shift->{'foo'}; }
sub bar {
  my ($self, $new) = @_;
  defined $new and $self->{'bar'} = $new;
  $self->{'bar'};
}

sub cim_init
  {
    my $self = shift;
    $nb++ ;
  }

package X;
use ExtUtils::testlib;

use Class::IntrospectionMethods  qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
   object  => [
	       'Y' => 'a',
	       'Y' => [ qw / b c d / ],
	       'Y' => [
		       {
			slot => 'e',
		       },
		       {
			slot => 'f',
		       }
		      ],
	      ],
   '-parent' ,
   object => [ 'Y' => [qw/g h j/ ]],
   object => [ 'Y' => { slot => ['y','z'], constructor_args => [foo => 'clobbered' ]}] 
  );

sub new { bless {}, shift; } ;


package main ;
use ExtUtils::testlib;

use Test::More tests => 19 ;


ok( 1 );

my $o = new X;
#$::CMM_PARENT_TRACE = 1;

# this kind of code is used within Class::IntrospectionMethods, so
# we'd better test it here in case older perl have some problem with
# it.
ok(defined *Y::,"test if class is defined");

ok( not $o->defined_a ) ;

is( ref $o->a , 'Y' );
is( ref $o->b , 'Y' );

ok( $o->defined_a ) ;


my $y = new Y;
ok( $o->c($y) );
is( $o->c , $y );
is( ref $o->c , 'Y' );

is( ref $o->e , 'Y' );

is($o->g->CMM_PARENT , $o) ;
is($o->h->CMM_PARENT , $o) ;

my $other = new X ;
is($other->g->CMM_PARENT , $other) ;
is($o->g->CMM_PARENT , $o) ;

# test constructor args
is( $o->z->foo , 'clobbered' );
is( $o->y->foo , 'clobbered' );

# test slot name
is($other->g->{CMM_SLOT_NAME} , 'g') ;
is($other->h->{CMM_SLOT_NAME} , 'h') ;

#print $Y::nb,"\n";
is($Y::nb , 10 ) ;



exit 0;

