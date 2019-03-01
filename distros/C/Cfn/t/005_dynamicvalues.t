#!/usr/bin/env perl

use strict;
use warnings;
use Data::Printer;
use Test::More;
use Cfn;

my $obj = Cfn->new;

$obj->addResource(Instance => 'AWS::EC2::Instance', {
    ImageId => Cfn::DynamicValue->new(Value => sub { return 'DynamicValue' }),
    SecurityGroups => Cfn::DynamicValue->new(Value => sub {
      return [
        'sg-12345',
	Cfn::DynamicValue->new(Value => sub { 'sg-23456' }),
      ],
    }),
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
               Cfn::DynamicValue->new(Value => sub { return 'dynamicvalue in a dynamicvalue' })
            }),
            Cfn::DynamicValue->new(Value => sub { 
               return ('before dynamic', Cfn::DynamicValue->new(Value => sub { return 'dynamicvalue in a list' }), 'after dynamic');
            }),
          ]
        ]
      }
    }
  });

$obj->addResource(ParamGroup => 'AWS::RDS::DBParameterGroup', {
  Description => 'test description',
  Family => 'MySQL5.1',
  Parameters => Cfn::DynamicValue->new(Value => sub {
    return {
      param1 => 'param1value',
      param2 => Cfn::DynamicValue->new(Value => sub { 'param2value' }),
    }
  }),
});

$obj->addResource(Role => 'AWS::IAM::Role', {
    AssumeRolePolicyDocument => Cfn::DynamicValue->new(Value => sub {
      return {
        Version => '2012-10-17',
        Statement => [ {
          Effect => Cfn::DynamicValue->new(Value => sub { 'Allow' }),
          Principal => { Service => [ 'ec2.amazonaws.com' ] },
          Action => [ 'sts:AssumeRole' ],
        } ],
      }
    }),
  });

my $struct = $obj->as_hashref;

my $instance = $struct->{Resources}{Instance}{Properties};

cmp_ok($instance->{ImageId}, 'eq', 'DynamicValue', 'Got a correct DynamicValue');
is_deeply($instance->{SecurityGroups}, [ 'sg-12345', 'sg-23456' ], 'DynamicValue can return an ArrayRef');
cmp_ok($instance->{UserData}{'Fn::Base64'}{'Fn::Join'}[1][0], 'eq', 'line 1', 'userdata dv line 1');
cmp_ok($instance->{UserData}{'Fn::Base64'}{'Fn::Join'}[1][1], 'eq', 'line 2', 'userdata dv line 2');
cmp_ok($instance->{UserData}{'Fn::Base64'}{'Fn::Join'}[1][2], 'eq', 'dynamicvalue in a dynamicvalue', 'a dynamic value returns a dynamic value and gets resolved');
cmp_ok($instance->{UserData}{'Fn::Base64'}{'Fn::Join'}[1][3], 'eq', 'before dynamic', 'multiple dynamic returns');
cmp_ok($instance->{UserData}{'Fn::Base64'}{'Fn::Join'}[1][4], 'eq', 'dynamicvalue in a list', 'multiple dynamic returns');
cmp_ok($instance->{UserData}{'Fn::Base64'}{'Fn::Join'}[1][5], 'eq', 'after dynamic', 'multiple dynamic returns');

my $role = $struct->{Resources}{Role}{Properties};

is_deeply(
  $role->{ AssumeRolePolicyDocument },
  {
    Version => '2012-10-17',
    Statement => [ {
      Effect => 'Allow',
      Principal => { Service => [ 'ec2.amazonaws.com' ] },
      Action => [ 'sts:AssumeRole' ],
    } ],
  }
);

my $param_group = $struct->{Resources}{ParamGroup}{Properties};
is_deeply(
  $param_group->{ Parameters },
  {
    param1 => 'param1value',
    param2 => 'param2value',
  },
  'Cfn::Value can return hashrefs'
);

# -----------------------------------------------
# Test diff with DynamicValues
# -----------------------------------------------
use Cfn::Diff;

my $obj2 = Cfn->new;
$obj2->addResource(IAM => 'AWS::IAM::User', {
    Path => Cfn::DynamicValue->new(Value => sub {
      my $self = shift;
      isa_ok($self, 'Cfn');
      return '/';
    })
  });

{
  my $diff = Cfn::Diff->new(left => $obj, right => $obj2);
  cmp_ok(scalar(@{ $diff->changes }), '==', 4, '4 Changes: delete 3 objects from obj, and add 1 in obj2');
}

my $obj3 = Cfn->new;
$obj3->addResource(IAM => 'AWS::IAM::User', {
    Path => Cfn::DynamicValue->new(Value => sub {
      my $self = shift;
      isa_ok($self, 'Cfn');
      return '/2';
    })
  });

{
  # by default, Cfn::Diff won't try to resolve dynamic values
  my $diff = Cfn::Diff->new(left => $obj2, right => $obj3);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 Change');
  isa_ok($diff->changes->[0]->from, 'Cfn::DynamicValue');
  isa_ok($diff->changes->[0]->to,   'Cfn::DynamicValue');
}

{
  my $diff = Cfn::Diff->new(left => $obj2, right => $obj3, resolve_dynamicvalues => 1);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 Change');
  isa_ok($diff->changes->[0]->from, 'Cfn::String');
  isa_ok($diff->changes->[0]->to,   'Cfn::String');
  cmp_ok($diff->changes->[0]->from->Value, 'eq', '/');
  cmp_ok($diff->changes->[0]->to->Value, 'eq', '/2');
}

{
  my $invocations = 0;
  my $i = \$invocations;

  my $o = Cfn->new;
  $o->addResource(R1 => 'AWS::IAM::User', {
    Path => Cfn::DynamicValue->new(Value => sub {
      $$i = $$i + 1;
    }),
  });
  my $h = $o->as_hashref;
  cmp_ok($h->{ Resources }->{ R1 }->{ Properties }->{ Path }, '==', 1, 'as_hashref only calls dynamicvalues one time');
}

done_testing;
