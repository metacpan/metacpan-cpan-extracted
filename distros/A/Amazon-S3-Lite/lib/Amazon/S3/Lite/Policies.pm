package Amazon::S3::Lite::Policies;
use strict;
use warnings;

use Role::Tiny;

########################################################################
sub restrict_bucket_access_to_ip {
########################################################################
  my ( $self, $bucket, $ip, $action ) = @_;

  die "ERROR: usage: restrict_bucket_to_ip(bucket, ip)\n"
    if !$bucket || !$ip;

  $action //= 's3:*';

  $self->put_bucket_policy(
    $bucket,
    { Version   => '2012-10-17',
      Statement => [
        { Sid       => 'AllowAccessFromSpecificIP',
          Effect    => 'Allow',
          Principal => q{*},
          Action    => $action,
          Resource  => "arn:aws:s3:::$bucket/*",
          Condition => { IpAddress => { 'aws:SourceIp' => $ip } },
        }
      ],
    }
  );

  return;
}

########################################################################
sub restrict_bucket_access_to_vpc {
########################################################################
  my ( $self, $bucket, $vpc_id, $action ) = @_;

  die "ERROR: usage: restrict_bucket_access_to_vpc(bucket, vpc_id)\n"
    if !$bucket || !$vpc_id;

  $action //= 's3:GetObject';  # read-only default â see note

  $self->put_bucket_policy(
    $bucket,
    { Version   => '2012-10-17',
      Statement => [
        { Sid       => 'AllowAccessFromVPC',
          Effect    => 'Allow',
          Principal => q{*},
          Action    => $action,
          Resource  => [ "arn:aws:s3:::$bucket", "arn:aws:s3:::$bucket/*" ],
          Condition => { StringEquals => { 'aws:SourceVpc' => $vpc_id } },
        },
      ],
    }
  );

  return;
}

1;
