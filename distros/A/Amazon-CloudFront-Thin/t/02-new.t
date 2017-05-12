use strict;
use warnings;
use Test::More tests => 2;

use Amazon::CloudFront::Thin;

subtest 'object instantiation (hash)' => sub {
    plan tests => 6;
    my $cloudfront;

    eval { $cloudfront = Amazon::CloudFront::Thin->new };
    like $@, qr/missing on call to new/
        => 'exception raised on new() without args';

    eval {
        $cloudfront = Amazon::CloudFront::Thin->new(
            aws_access_key_id => 1
        )
    };
    like $@, qr/missing on call to new/
        => 'exception raised on new() with just key_id';

    eval {
        $cloudfront = Amazon::CloudFront::Thin->new(
            aws_secret_access_key => 1
        )
    };
    like $@, qr/missing on call to new/
        => 'exception raised on new() with just secret key';

    eval {
        $cloudfront = Amazon::CloudFront::Thin->new(
            aws_access_key_id     => 1,
            aws_secret_access_key => 1,
        )
    };
    like $@, qr/missing on call to new/
        => 'providing required keys creates object';

    ok $cloudfront = Amazon::CloudFront::Thin->new(
        aws_access_key_id     => 1,
        aws_secret_access_key => 1,
        distribution_id       => 1,
    ), 'providing required keys creates object';


    isa_ok $cloudfront, 'Amazon::CloudFront::Thin';
};

subtest 'object instantiation (hashref)' => sub {
    plan tests => 6;
    my $cloudfront;

    eval { $cloudfront = Amazon::CloudFront::Thin->new({}) };
    like $@, qr/missing on call to new/
        => 'exception raised on new() without args';

    eval {
        $cloudfront = Amazon::CloudFront::Thin->new({
            aws_access_key_id => 1
        })
    };
    like $@, qr/missing on call to new/
        => 'exception raised on new() with just key_id';

    eval {
        $cloudfront = Amazon::CloudFront::Thin->new({
            aws_secret_access_key => 1
        })
    };
    like $@, qr/missing on call to new/
        => 'exception raised on new() with just secret key';

    eval {
        $cloudfront = Amazon::CloudFront::Thin->new({
            aws_access_key_id     => 1,
            aws_secret_access_key => 1,
        })
    };
    like $@, qr/missing on call to new/
        => 'providing required keys creates object';


    ok $cloudfront = Amazon::CloudFront::Thin->new({
        aws_access_key_id     => 1,
        aws_secret_access_key => 1,
        distribution_id       => 1,
    }), 'providing required keys creates object';

    isa_ok $cloudfront, 'Amazon::CloudFront::Thin';
};
