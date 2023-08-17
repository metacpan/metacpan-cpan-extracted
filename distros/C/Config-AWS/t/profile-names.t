#!/usr/bin/env perl

use Test2::V0;
use Config::AWS;

my $profiles = <<'PROFILES';
[profile with:colon]
source = https://github.com/aws/aws-sdk-java-v2/issues/1847
[profile with%percent]
source = https://github.com/aws/aws-toolkit-jetbrains/pull/1418
[profile with_underscore]
source = https://github.com/aws/aws-toolkit-jetbrains/pull/1418
[profile 1234/Foo-Bar/foo@bar.com]
source = https://github.com/aws/aws-sdk-java-v2/issues/389#issuecomment-421193804
PROFILES

is [ Config::AWS::list_profiles(\$profiles) ], [qw(
    with:colon
    with%percent
    with_underscore
    1234/Foo-Bar/foo@bar.com
)], 'List profiles';

is Config::AWS::read_all(\$profiles), hash {
    field 'with:colon'               => E;
    field 'with%percent'             => E;
    field 'with_underscore'          => E;
    field '1234/Foo-Bar/foo@bar.com' => E;
    end;
}, 'Read profiles';

done_testing;
