#/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Cfn;
use Cfn::Diff;

my $Stack1 = Cfn->new;
$Stack1->addResource(r1 => 'AWS::EC2::Instance', {
    ImageId => 'X',
  }
);

my $Stack1ChangeR1 = Cfn->new;
$Stack1ChangeR1->addResource(r1 => 'AWS::IAM::User', {
  }
);

my $Stack2 = Cfn->new;
$Stack2->addResource(r2 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
  }
);

my $Stack3 = Cfn->new;
$Stack3->addResource(r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
  }
);

my $Stack4 = Cfn->new;
$Stack4->addResource(r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
    KeyName => 'test_key',
  }
);

my $Stack5 = Cfn->new;
$Stack5->addResource(r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
    KeyName => 'test_key',
  }
);

my $Stack6 = Cfn->new;
$Stack6->addResource(r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
    KeyName => { Ref => 'param' },
  }
);

my $Stack7 = Cfn->new;
$Stack7->addResource(DNS => 'AWS::Route53::RecordSet', {
   HostedZoneName => { Ref => 'ZoneName' },
   Name => { 'Fn::Join', [ '.', [ { 'Fn::Join' => [ '-', ['infra', { Ref => 'ID' } ] ] } , { Ref => 'ZoneName' } ] ] },
   Type => 'CNAME',
   TTL => 900,
   ResourceRecords => [
     { 'Fn::GetAtt' => [ 'ELB', 'DNSName' ] },
   ],
  }
);

my $Stack9 = Cfn->new;
$Stack9->addResource(CR => 'AWS::CloudFormation::CustomResource', {
    ServiceToken => 'ST',
    Prop1 => 'X',
  }, {
    Version => "1.0",
  }
);

my $Stack10 = Cfn->new;
$Stack10->addResource(CR => 'Custom::CR', {
    ServiceToken => 'ST',
    "Prop1" => 'Y',
    },{
      "Version" => 1.0
  }
);

{
  my $diff = Cfn::Diff->new(left => $Stack1, right => $Stack1);
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'No changes for same stack');
}

{
  my $diff = Cfn::Diff->new(left => $Stack1, right => $Stack2);
  cmp_ok(scalar(@{ $diff->changes }), '==', 2, '2 changes: 1 res added, 1 deleted');
}

{
  my $diff = Cfn::Diff->new(left => $Stack1, right => $Stack3);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 change: changed ImageId (Stack1 Vs Stack3)');
  isa_ok($diff->changes->[0], 'Cfn::Diff::ResourcePropertyChange','Got a ResourcePropertyChange');
  cmp_ok($diff->changes->[0]->mutability, 'eq', 'Immutable', 'ImageId prop is Immutable');
}

{
  my $diff = Cfn::Diff->new(left => $Stack3, right => $Stack1);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 change: changed ImageId (Stack3 vs Stack1)');
}

{
  my $diff = Cfn::Diff->new(left => $Stack1, right => $Stack4);
  cmp_ok(scalar(@{ $diff->changes }), '==', 2, '2 changes: 2 props changed');
}

{
  my $diff = Cfn::Diff->new(left => $Stack4, right => $Stack5);
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'No changes');
}

{
  my $diff = Cfn::Diff->new(left => $Stack7, right => $Stack7);
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'No changes');
}

{
  my $diff = Cfn::Diff->new(left => $Stack5, right => $Stack6);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 prop changed from Primitive to Ref');
}

{
  my $diff = Cfn::Diff->new(left => $Stack9, right => $Stack9);
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'Custom resources are diffable');
}

{
  my $left = $Stack10;
  $left->cfn_options->custom_resource_rename(1);
  my $right = $Stack9;
  $right->cfn_options->custom_resource_rename(1);

  my $diff = Cfn::Diff->new(left => $left, right => $right);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, 'prop change in a custom resource');
  isa_ok($diff->changes->[0], 'Cfn::Diff::ResourcePropertyChange', 'Got a property change in a custom resource');
}

{
  my $diff = Cfn::Diff->new(left => $Stack10, right => $Stack9);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, 'prop change in a custom resource');
  isa_ok($diff->changes->[0], 'Cfn::Diff::ResourcePropertyChange', 'Got a property change in a custom resource');
}

{
  my $diff = Cfn::Diff->new(left => $Stack1, right => $Stack1ChangeR1);
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, 'Resource type change detected');
  isa_ok($diff->changes->[0], 'Cfn::Diff::IncompatibleChange', 'Got an incompatible change');
}

my $withprops = '{"Resources" : {"IAMUser" : {"Type" : "AWS::IAM::User","Properties" : {}} }}';
my $withoutprops = '{"Resources" : {"IAMUser" : {"Type" : "AWS::IAM::User"} }}';

{
  my $diff = Cfn::Diff->new(
    left => Cfn->from_json($withprops),
    right => Cfn->from_json($withoutprops)
  );
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, 'got one change');
  isa_ok($diff->changes->[0], 'Cfn::Diff::Changes','Got a generic Change object');
  cmp_ok($diff->changes->[0]->path, 'eq', 'Resources.IAMUser', 'path ok');
  cmp_ok($diff->changes->[0]->change, 'eq', 'Properties key deleted', 'correct message');
}

{
  my $diff = Cfn::Diff->new(
    left => Cfn->from_json($withoutprops),
    right => Cfn->from_json($withprops)
  );
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, 'got one change');
  isa_ok($diff->changes->[0], 'Cfn::Diff::Changes','Got a generic Change object');
  cmp_ok($diff->changes->[0]->path, 'eq', 'Resources.IAMUser', 'path ok');
  cmp_ok($diff->changes->[0]->change, 'eq', 'Properties key added', 'correct message');
}

{
  my $diff = Cfn::Diff->new(
    left => Cfn->from_json($withoutprops),
    right => Cfn->from_json($withoutprops)
  );
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'got no changes');
}

done_testing;
