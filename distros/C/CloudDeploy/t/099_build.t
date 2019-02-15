#!/usr/bin/env perl

use Test::More;

use CCfn;
package TestClass {
  use Moose;
  extends 'CCfn';
  use CCfnX::InstanceArgs;
  use CCfnX::Shortcuts;
  has params => (is => 'ro', isa => 'CCfnX::InstanceArgs', default => sub { CCfnX::InstanceArgs->new(
    instance_type => 'x1.xlarge',
    region => 'eu-west-1',
    account => 'devel-capside',
    name => 'NAME'
  ); } );

  resource Instance => 'AWS::EC2::Instance', {
    ImageId => 'ami-XXXXXX', 
    InstanceType => 't1.micro',
    SecurityGroups => [ 'sg-XXXXX' ],
  };

  output 'instanceid' => Ref('Instance');

  before build => sub {
    my $self = shift;
    $self->addResourceMetadata('Instance', MyMetadata => 'MyValue');
  };
}

my $obj = TestClass->new;
ok($obj->Resource('Instance'), 'Instance object is defined just after create');
ok($obj->Output('instanceid'), 'Output is defined just after create');
my $struct = $obj->as_hashref;

is_deeply($struct->{Resources}{Instance}{Metadata}, { MyMetadata => 'MyValue' }, 'Got the correct metadata');

done_testing;
