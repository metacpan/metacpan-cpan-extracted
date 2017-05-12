use strict;
use warnings;
use Amazon::CloudFront::SignedURL;
use File::Basename qw(dirname);
use File::Spec;
use Test::Exception;
use Test::More;
use t::Util;

my $private_key = slurp( File::Spec->catfile( dirname(__FILE__), 'test.pem' ) );

subtest 'invalid arguments' => sub {
    throws_ok {
        Amazon::CloudFront::SignedURL->new();
    }
    qr/Attribute \(private_key_string\) is required/;

    throws_ok {
        Amazon::CloudFront::SignedURL->new( private_key_string => $private_key, );
    }
    qr/Attribute \(key_pair_id\) is required/;
};

subtest 'new' => sub {
    my $signed_url = Amazon::CloudFront::SignedURL->new(
        private_key_string => $private_key,
        key_pair_id        => 'FLSIGIOFD4CF6IDLG2DD',
    );
    isa_ok $signed_url, 'Amazon::CloudFront::SignedURL';
};

done_testing;

