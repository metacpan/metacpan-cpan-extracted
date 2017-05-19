#!/usr/bin/env perl

use Test::More;
use Data::Printer;

package TestClass {
  use Moose;
  extends 'CCfn';
  use CCfnX::CommonArgs;
  use CCfnX::Shortcuts;
  use CCfnX::InstanceArgs;

  has params => (is => 'ro', isa => 'CCfnX::CommonArgs', default => sub { CCfnX::InstanceArgs->new(
    instance_type => 'x1.xlarge',
    region => 'eu-west-1',
    account => 'devel-capside',
    name => 'NAME'
  ); } );

  output 'output1', Ref('XXX');
  output 'output2', GetAtt('XXX', 'InstanceID');
  output 'keyed/output', Ref('XXX');
}

my $obj = TestClass->new;
my $struct = $obj->as_hashref;

#p $struct;

is_deeply($struct->{Outputs}->{output1}->{Value},
          { Ref => 'XXX' },
          'Got the correct structure for the output');

is_deeply($struct->{Outputs}->{output2}->{Value},
          { 'Fn::GetAtt' => [ 'XXX', 'InstanceID' ] },
          'Got the correct structure for the output');

# The / (slash) from keyed/output is missiing because CCfn supports slashed names
is_deeply($struct->{Outputs}->{keyedoutput}->{Value},
          { Ref => 'XXX' },
          'Got the correct structure for the output');



done_testing;
