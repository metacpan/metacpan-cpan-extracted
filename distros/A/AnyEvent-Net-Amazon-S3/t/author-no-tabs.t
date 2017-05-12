
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/s3cl_ae',
    'lib/AnyEvent/Net/Amazon/S3.pm',
    'lib/AnyEvent/Net/Amazon/S3/Bucket.pm',
    'lib/AnyEvent/Net/Amazon/S3/Client.pm',
    'lib/AnyEvent/Net/Amazon/S3/Client/Bucket.pm',
    'lib/AnyEvent/Net/Amazon/S3/Client/Object.pm',
    'lib/AnyEvent/Net/Amazon/S3/HTTPRequest.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/AbortMultipartUpload.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/CompleteMultipartUpload.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/CreateBucket.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/DeleteBucket.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/DeleteMultiObject.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/DeleteMultipleObjects.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/DeleteObject.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/GetBucketAccessControl.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/GetBucketLocationConstraint.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/GetObject.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/GetObjectAccessControl.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/InitiateMultipartUpload.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/ListAllMyBuckets.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/ListBucket.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/ListParts.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/PutObject.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/PutPart.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/SetBucketAccessControl.pm',
    'lib/AnyEvent/Net/Amazon/S3/Request/SetObjectAccessControl.pm',
    'lib/Module/AnyEvent/Helper/PPI/Transform/Net/Amazon/S3.pm',
    'lib/Module/AnyEvent/Helper/PPI/Transform/Net/Amazon/S3/Client/Bucket.pm',
    'lib/Module/AnyEvent/Helper/PPI/Transform/Net/Amazon/S3/Client/Object.pm',
    't/00-compile.t',
    't/00use.t',
    't/01api.t',
    't/02client.t',
    't/03token.t'
);

notabs_ok($_) foreach @files;
done_testing;
