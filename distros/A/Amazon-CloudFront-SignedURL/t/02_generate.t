use strict;
use warnings;
use Amazon::CloudFront::SignedURL;
use File::Basename qw(dirname);
use File::Spec;
use Test::Exception;
use Test::More;
use t::Util;

my $private_key = slurp( File::Spec->catfile( dirname(__FILE__), 'test.pem' ) );
my $signed_url = Amazon::CloudFront::SignedURL->new(
    private_key_string => $private_key,
    key_pair_id        => 'FLSIGIOFD4CF6IDLG2DD',
);

subtest 'invalid arguments' => sub {
    throws_ok {
        $signed_url->generate();
    }
    qr/Missing parameter: 'resource'/;

    throws_ok {
        $signed_url->generate( resource => 'test' );
    }
    qr/Missing parameter: 'expires' \(or 'policy'\)/;

    throws_ok {
        $signed_url->generate(
            resource => 'test',
            expires  => 1422494408,
            policy   => '{"Statement":[{"Resource":"test","Condition":{"DateLessThan":{"AWS:EpochTime":1422494408}}}]}',
        );
    }
    qr/Exclusive parameters passed together: 'expires' v\.s\. 'policy'/;
};

subtest 'invalid private key' => sub {
    throws_ok {
        my $signed_url = Amazon::CloudFront::SignedURL->new(
            private_key_string => 'invalid key',
            key_pair_id        => 'FLSIGIOFD4CF6IDLG2DD',
        );
        $signed_url->generate(
            resource => 'test',
            expires  => 1422494408,
        );
    }
    qr/Private Key Error: Maybe your key is invalid/;
};

subtest 'use canned policy' => sub {
    my $url = $signed_url->generate(
        resource => 'test',
        expires  => 1422494408,
    );
    is $url,
        'test?Expires=1422494408&Signature=oEBQc6j6e3CZ~P83QAux3Fftj89RQwq3ww3zFa09lVcfkmTObM-uqGhojC-lCWo8L-kiZLl4csM5aPvnOUj8wNzNa7eOMQajEFkGxp8od3Cl8BT-tjBKd5nl-M8Kvk-yOgdZQAcTK85llluvvZGQRAn-nwe0-a1kDNj~fS8-N3yMSI5FvOlgsm3C4-H0K6KimgsRJrygmIxUG6V6ogIkap74I7vdSt7R0NXQQUg7M6GF6eHcqYu3POTSU3XYLsVgP8wVJYlP6-JhopxdD0S-GAva21P0M8aX4yN0IWTCaNdZY6dk17rdiVjPVTdTp2HskS95lNQsCvS8tcjqyaOSVw__&Key-Pair-Id=FLSIGIOFD4CF6IDLG2DD';
};

subtest 'use custom policy' => sub {
    my $url = $signed_url->generate(
        resource => 'test',
        policy =>
            '{"Statement":[{"Resource":"test","Condition":{"DateLessThan":{"AWS:EpochTime":1422494408},"IpAddress":{"AWS:SourceIp":"192.0.2.1"}}}]}',
    );
    is $url,
        'test?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoidGVzdCIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTQyMjQ5NDQwOH0sIklwQWRkcmVzcyI6eyJBV1M6U291cmNlSXAiOiIxOTIuMC4yLjEifX19XX0_&Signature=kJyVkf5xCpCWNYoyiP~LqU~VzdsbqxUkVbaULMynF7opnHODAkgEIDvQ48epslcXdYifc79tsoTUpK60nUJ8IqRt~6jKjBhMQzYy2wFYprqYzivDvYwne1CCrA6IKLCJF7KZhpmuHMIRa963bpQzXjLCmaHEjh0b9biLZGVCo~nCRrC8ItV-rFhV1gVdWNnpgDpMYU4euzYE6YxzN51LGGcrMXEgxm~CEbPwyYhqrx6xWrCp~1H7CMPC54BgxnW33902uCDN9riB-521fHSnqTHKn1XmJ5Hp01PkS6X16sKnQGVFkgxfAd4oClBRVNCMqZ~LG-YKBntLnDJfFRgQvQ__&Key-Pair-Id=FLSIGIOFD4CF6IDLG2DD';
};

done_testing;

