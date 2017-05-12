use strict;
use warnings;
use Test::More;

package MyAgent;
sub new { bless {}, shift }

package main;
use Amazon::CloudFront::Thin;

subtest 'default user agent' => sub {
    my $cloudfront = Amazon::CloudFront::Thin->new(
        aws_access_key_id     => 123,
        aws_secret_access_key => 321,
        distribution_id       => 1,
    );

    isa_ok $cloudfront->ua, 'LWP::UserAgent';

    ok $cloudfront->ua( MyAgent->new ), 'able to set user agent';

    isa_ok $cloudfront->ua, 'MyAgent';
};

subtest 'overriding user agent in constructor' => sub {
    my $cloudfront = Amazon::CloudFront::Thin->new(
        aws_access_key_id     => 123,
        aws_secret_access_key => 321,
        distribution_id       => 1,
        ua                    => MyAgent->new,
    );

    isa_ok $cloudfront->ua, 'MyAgent';
};

done_testing;
