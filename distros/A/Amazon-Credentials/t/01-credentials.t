use strict;
use warnings;

use Test::More tests => 6;

use File::Temp qw/:mktemp/;
use File::Path;
use Data::Dumper;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $home = mkdtemp("amz-credentials-XXXXX");

my $credentials_file = eval {
  mkdir "$home/.aws";
  
  open (my $fh, ">$home/.aws/credentials") or BAIL_OUT("could not create temporary credentials file");
  print $fh <<eot;
[default]
region = us-west-1

[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

[bar]
aws_access_key_id=bar-aws-access-key-id
aws_secret_access_key=bar-aws-secret-access-key
region = us-east-1

eot
  close $fh;
  "$home/.aws/credentials";
};

$ENV{HOME} = "$home";
$ENV{AWS_PROFILE} = undef;

my $creds = new Amazon::Credentials({ order => [qw/file/]});
ok(ref($creds), 'find credentials');
is($creds->get_aws_access_key_id, 'foo-aws-access-key-id', 'default profile');
is($creds->get_region, 'us-west-1', 'default region');

print "wtf\n";

$creds = new Amazon::Credentials({ profile => 'bar', order => [qw/file/], region => 'foo'});

is($creds->{aws_access_key_id}, 'bar-aws-access-key-id', 'retrieve profile');
is($creds->get_region, 'us-east-1', 'region');

END {
  eval {
    rmtree($home)
      if $home;
  };
}
