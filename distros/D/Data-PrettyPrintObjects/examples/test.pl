#!/usr/bin/perl

use Data::PrettyPrintObjects;

$obj = new PPOtest01;
print PPO($obj);

package PPOtest01;

sub new {
   my $self = { 'a01' => 'foo',
                'b01' => 'bar' };
   bless $self;
   return $self;
}

sub members {
   my($self) = @_;

   return sort keys %$self;
}

