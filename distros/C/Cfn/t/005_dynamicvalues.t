#!/usr/bin/env perl

use Data::Printer;
use Test::More;
use Cfn;

my $obj = Cfn->new;

$obj->addResource(Instance => 'AWS::EC2::Instance', {
    ImageId => Cfn::DynamicValue->new(Value => sub { return 'DynamicValue' }),
    SecurityGroups => [ 'sg-XXXXX' ],
    AvailabilityZone => Cfn::DynamicValue->new(Value => sub {
      # Sick hack to import isa_ok into TestClasses namespace
      use Test::More;
      isa_ok($_[0], 'Cfn', 'A DynamicValue recieves as first parameter a reference to the infrastructure');
      return 'eu-west-2'
    }),
    UserData => {
      'Fn::Base64' => {
        'Fn::Join' => [
          '', [
            Cfn::DynamicValue->new(Value => sub { return 'line 1' }),
            Cfn::DynamicValue->new(Value => sub { return 'line 2' }),
            Cfn::DynamicValue->new(Value => sub { 
               Cfn::DynamicValue->new(Value => sub { return 'dv in a dv' })
            }),
            Cfn::DynamicValue->new(Value => sub { 
               return ('before dynamic', Cfn::DynamicValue->new(Value => sub { return 'in middle' }), 'after dynamic');
            }),
          ]
        ]
      }
    }
  });

my $struct = $obj->as_hashref;

cmp_ok($struct->{Resources}{Instance}{Properties}{ImageId}, 'eq', 'DynamicValue', 'Got a correct DynamicValue');
cmp_ok($struct->{Resources}{Instance}{Properties}{UserData}{'Fn::Base64'}{'Fn::Join'}[1][0], 'eq', 'line 1', 'userdata dv line 1');
cmp_ok($struct->{Resources}{Instance}{Properties}{UserData}{'Fn::Base64'}{'Fn::Join'}[1][1], 'eq', 'line 2', 'userdata dv line 2');
cmp_ok($struct->{Resources}{Instance}{Properties}{UserData}{'Fn::Base64'}{'Fn::Join'}[1][2], 'eq', 'dv in a dv', 'a dynamic value returns a dynamic value and gets resolved');
cmp_ok($struct->{Resources}{Instance}{Properties}{UserData}{'Fn::Base64'}{'Fn::Join'}[1][3], 'eq', 'before dynamic', 'multiple dynamic returns');
cmp_ok($struct->{Resources}{Instance}{Properties}{UserData}{'Fn::Base64'}{'Fn::Join'}[1][4], 'eq', 'in middle', 'multiple dynamic returns');
cmp_ok($struct->{Resources}{Instance}{Properties}{UserData}{'Fn::Base64'}{'Fn::Join'}[1][5], 'eq', 'after dynamic', 'multiple dynamic returns');

done_testing;
