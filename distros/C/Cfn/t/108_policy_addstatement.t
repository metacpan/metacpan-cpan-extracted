#!/usr/bin/env perl

use Test::More;
use Cfn;

my $o = Cfn->new;
$o->addResource(Policy => 'AWS::IAM::Policy', {
    PolicyName => 'AbilityToGetMetadata',
    Users => [ { Ref => 'CfnUser' } ],
    PolicyDocument => {
      Statement => [ {
        Effect   => "Allow",
        Action   => "cloudformation:DescribeStackResource",
        Resource => "*"
      }, ]
    },
  });
$o->Resource('Policy')->addStatement({
      Effect => 'Allow',
      Action => 's3:*',
      Resource => '*'
    });

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

