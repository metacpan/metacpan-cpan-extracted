#/usr/bin/env perl

use Test::More;

use Cfn;
use Cfn::Diff;

package Test401::Stack1 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource r1 => 'AWS::EC2::Instance', {
    ImageId => 'X',
  }
}

package Test401::Stack2 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource r2 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
  }
}

package Test401::Stack3 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
  }
}

package Test401::Stack4 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
    KeyName => 'test_key',
  }
}

package Test401::Stack5 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
    KeyName => 'test_key',
  }
}

package Test401::Stack6 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource r1 => 'AWS::EC2::Instance', {
    ImageId => 'Y',
    KeyName => Ref('param'),
  }
}

package Test401::Stack7 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource DNS => 'AWS::Route53::RecordSet', {
   HostedZoneName => Ref('ZoneName'),
   Name => { 'Fn::Join', [ '.', [ { 'Fn::Join' => [ '-', ['infra', Ref('ID') ] ] } , Ref('ZoneName') ] ] },
   Type => 'CNAME',
   TTL => 900,
   ResourceRecords => [
     GetAtt('ELB', 'DNSName')
   ],
  };
}

package Test401::Stack8Params {
  use CCfnX::CommonArgs;
  use Moose;
  extends 'CCfnX::CommonArgs';
  has dns_type => (is => 'ro', isa => 'Str', default => 'CNAME');
}

package Test401::Stack8 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';
  
  has params => (is => 'ro', default => sub { Test401::Stack8Params->new(account => 'X', name => 'N', region => 'X') });

  resource DNS => 'AWS::Route53::RecordSet', {
   HostedZoneName => Ref('ZoneName'),
   Name => Fn::Join('.', Fn::Join('-', 'infra', Ref('ID')), Ref('ZoneName')),
   Type => Parameter('dns_type'),
   TTL => 900,
   ResourceRecords => [
     GetAtt('ELB', 'DNSName')
   ],
  };
}

package Test401::Stack9 {
  use CCfn;
  use CCfnX::Shortcuts;
  use Moose;
  extends 'CCfn';

  use CCfnX::CommonArgs;
  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(account => 'X', name => 'N', region => 'X') });

  resource CR => 'AWS::CloudFormation::CustomResource', {
    Prop1 => 'X',
  }, {
    Version => "1.0",
  };
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack1->new, right => Test401::Stack2->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 2, '2 changes: 1 res added, 1 deleted');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack1->new, right => Test401::Stack3->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 change: changed ImageId (Stack1 Vs Stack3)');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack3->new, right => Test401::Stack1->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 change: changed ImageId (Stack3 vs Stack1)');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack1->new, right => Test401::Stack4->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 2, '2 changes: 2 props changed');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack4->new, right => Test401::Stack5->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'No changes');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack7->new, right => Test401::Stack7->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'No changes');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack5->new, right => Test401::Stack6->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 prop changed from Primitive to Ref');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack7->new, right => Test401::Stack8->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 props changed from hardcoded value to DynamicValue');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack8->new, right => Test401::Stack7->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 1, '1 props changed from DynamicValue to hardcoded value');
}

{
  my $diff = Cfn::Diff->new(left => Test401::Stack9->new, right => Test401::Stack9->new);
  $diff->diff;
  cmp_ok(scalar(@{ $diff->changes }), '==', 0, 'Custom resources are diffable');
}



done_testing;
