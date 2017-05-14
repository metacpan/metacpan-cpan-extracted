#!/usr/bin/perl

use Test;
BEGIN { plan tests => 28 }

package X;

use Class::MakeMethods::Template::Hash ( 
  'new --with_values' => 'new',
  'scalar' => 'a',
  'scalar --protected' => 'b',
  'scalar --private' => 'c',
  'scalar --private --protected --public' => 'd',
  'scalar --protected e --public --private' => 'f',
  'scalar --get_private_set' => 'g',
);

sub x_incr_b {
  my $self = shift; $self->b( $self->b + 1 )
}

sub x_incr_c {
  my $self = shift; $self->c( $self->c + 1 )
}

sub x_incr_e {
  my $self = shift; $self->c( $self->c + 1 )
}

sub x_incr_g {
  my $self = shift; $self->g( $self->g + 1 )
}

package Y;
@ISA = 'X';

sub y_incr_b {
  my $self = shift; $self->b( $self->b + 1 )
}

sub y_incr_c {
  my $self = shift; $self->c( $self->c + 1 )
}

sub y_incr_e {
  my $self = shift; $self->e( $self->e + 1 )
}

sub y_incr_g {
  my $self = shift; $self->g( $self->g + 1 )
}

package main;

ok( 1 ); #1

my $o = X->new( a=>1 , b=>2, c=>3, d=>4, e=>5, g=>21 );
my $o2 = Y->new( a=>1 , b=>2, c=>3, d=>4, e=>5, g=>21 );

# public
ok( $o->a(1) ); #2

# public / subclass
ok( $o2->a(1) ); #3


# protected
ok( ! eval { $o->b(1); 1 } ); #4
ok( $o->x_incr_b() ); #5

# protected / subclass
ok( ! eval { $o2->b(1); 1 } ); #6
ok( $o2->x_incr_b() ); #7
ok( $o2->y_incr_b() ); #8


# private
ok( ! eval { $o->c(1); 1 } ); #9
ok( $o->x_incr_c() ); #10

# private / subclass
ok( ! eval { $o2->c(1); 1 } ); #11
ok( $o2->x_incr_c() ); #12
ok( ! eval { $o2->y_incr_c(); 1 } ); #13


# public
ok( $o2->d() ); #14


# protected
ok( ! eval { $o->e(1); 1 } ); #15
ok( $o->x_incr_e() ); #16

# protected / subclass
ok( ! eval { $o2->e(1); 1 } ); #17
ok( $o2->x_incr_e() ); #18
ok( $o2->y_incr_e() ); #19

# private
ok( ! eval { $o->f(1); 1 } ); #20

# private / subclass
ok( ! eval { $o2->f(1); 1 } ); #21


# private_set
ok( $o->g() ); #22
ok( ! eval { $o->g(1); 1 } ); #23
ok( $o->x_incr_g() ); #24

# private_set / subclass
ok( $o2->g() ); #25
ok( ! eval { $o2->g(1); 1 } ); #26
ok( $o2->x_incr_g() ); #27
ok( ! eval { $o2->y_incr_g(1); 1 } ); #28

