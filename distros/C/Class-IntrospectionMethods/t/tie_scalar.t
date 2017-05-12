#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package Y;

use Carp;
use strict;

require Tie::Scalar ;

sub TIESCALAR 
  {
    my $type = shift;
    my %args = @_ ;
    my $self={} ;
    if (defined $args{enum})
      {
        # store all enum values in a hash. This way, checking
        # whether a value is present in the enum set is easier
        map {$self->{enum}{$_} =  1;} @{$args{enum}} ;
      }
    else
      {
        croak ref($self)," error: no enum values defined when calling init";
      }

    $self->{default} = $args{default};
    $self->{name} = $args{name};
    bless $self,$type;
  }

sub STORE
  {
    my ($self,$value) = @_ ;
    croak "cannot set ",ref($self)," item to $value. Expected ",
      join(' ',keys %{$self->{enum}}) 
        unless defined $self->{enum}{$value} ;
    # we may want to check other rules here ... TBD
    $self->{value} = $value ;
    return $value;
  }


sub FETCH
  {
    my $self = shift ;
    return defined $self->{value} ? $self->{value} : $self->{default}  ;
  }

sub get_name
  {
    my $self = shift ;
    return $self->{CMM_SLOT_NAME} ;
  }

package NewStdScalar;
our @ISA = qw(Tie::StdScalar);

package X ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
  tie_scalar => 
  [
   a => ['Y',  
         enum =>    [qw/A B C/], 
         default => 'B' ],
   'normal' => 'NewStdScalar',
  ],
  -parent ,
  tie_scalar => [
                 [qw/n1 n2 n3/] => ['Y',  
                                  enum =>    [qw/A B C/], 
                                  default => 'B' ],
                ],
  new => 'new'
  );

package main;
use ExtUtils::testlib;

use Test::More tests => 13;

#use Data::Dumper;
my $o = new X;

ok( 1 );
is($o->a , 'B') ;
is($o->a('A') , 'A') ;
is($o->a , 'A') ;

is($o->n1 , 'B') ;
is($o->n2 , 'B') ;

my $obj = $o->tied_n1;
#print Dumper $obj ;

is($obj->get_name , 'n1') ;
is($o->tied_n2->CMM_PARENT , $o) ;

# get a tied scalar that was not used before
ok($o->tied_n3) ;

# test that we can assign an undef value
ok($o->normal('coucou')) ;
is($o->normal() , 'coucou') ;
ok(not defined $o->normal(undef)) ;
ok(not defined $o->normal) ;


exit 0;

