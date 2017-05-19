#!/usr/bin/env perl

use Test::More;

package PolicyTest {
  use Moose;
  extends 'CCfn';
  use CCfnX::Shortcuts;
  use CCfnX::CommonArgs;

  has params => (is => 'ro', isa => 'CCfnX::CommonArgs', default => sub {
    CCfnX::CommonArgs->new(
      region => 'fake',
      account => 'devel-capside',
      name   => 'PolicyTest',
    );
  });

  resource Policy => 'AWS::IAM::Policy', {
    PolicyName => 'AbilityToGetMetadata',
    Users => [ Ref('CfnUser') ],
    PolicyDocument => {
      Statement => [ {
        Effect   => "Allow",
        Action   => "cloudformation:DescribeStackResource",
        Resource => "*"
      }, ]
    },
  };

  after build => sub {
    my $self = shift;
    $self->Resource('Policy')->addStatement({
      Effect => 'Allow',
      Action => 's3:*',
      Resource => '*'
    });
  } 
}

my $o = PolicyTest->new;

my $hash = $o->as_hashref;

is_deeply($hash->{Resources}->{Policy}->{Properties}->{PolicyDocument}->{Statement},
          [
            {
              Effect   => "Allow",
              Action   => "cloudformation:DescribeStackResource",
              Resource => "*"
            },
            {
              Effect => 'Allow',
              Action => 's3:*',
              Resource => '*'
            }
          ],
          'The statement was correctly added to the policy'
);

done_testing;

