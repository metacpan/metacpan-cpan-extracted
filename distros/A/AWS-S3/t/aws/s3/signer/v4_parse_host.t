#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use warnings;

use ExtUtils::MakeMaker;
use FindBin '$Bin';
use constant TEST_COUNT => 1169;

use Test::More tests => TEST_COUNT;
use Test::Deep;

use_ok('AWS::S3::Signer::V4');

my $signer = AWS::S3::Signer::V4->new(
    -access_key => 'AKIDEXAMPLE',
    -secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'
);
isa_ok( $signer, 'AWS::S3::Signer::V4' );

# yes there is a bucket name here that matches a region name
# because inevitably someone will have done that
foreach my $bucket ( qw/
    foo
    eu-west-1
    1.ayeayeaye-wat-z
/ ) {

    # aws ec2 describe-regions --all-regions --query 'Regions[*].RegionName' --output text
    foreach my $region ( qw/
        af-south-1
        ap-east-1
        ap-northeast-1 ap-northeast-2 ap-northeast-3
        ap-south-1 ap-south-2
        ap-southeast-1 ap-southeast-2 ap-southeast-3 ap-southeast-4 ap-southeast-5 ap-southeast-7
        ca-central-1
        ca-west-1
        eu-central-1 eu-central-2
        eu-north-1
        eu-south-1
        eu-south-2
        eu-west-1 eu-west-2 eu-west-3
        il-central-1
        me-central-1
        me-south-1
        mx-central-1
        sa-east-1
        us-east-1 us-east-2
        us-west-1 us-west-2
    / ) {

        foreach my $host (

            # https://community.aws/content/2biM1C0TkMkvJ2BLICiff8MKXS9/format-and-parse-amazon-s3-url?lang=en
            [ "$bucket.s3.amazonaws.com"         => [ 's3','us-east-1','legacy with virtual-hosted-style' ] ],
            [ "$bucket.$region.s3.amazonaws.com" => [ 's3',$region    ,'regional virtual-hosted-style'    ] ],
            [ "s3.$region.amazonaws.com"         => [ 's3',$region    ,'regional dot-style'               ] ],
            [ "s3-$region.amazonaws.com"         => [ 's3',$region    ,'regional dash-style'              ] ],
            [ "s3.amazonaws.com"                 => [ 's3','us-east-1','legacy with path-style'           ] ],
            [ "cognito-identity.$region.amazonaws.com" => [ 'cognito-identity',$region,'legacy path-style service' ] ],
        ) {
            cmp_deeply(
                [ $signer->parse_host( $host->[0] ) ],
                $host->[1],
                $host->[0] . ' -> ' . join( ", ",@{ $host->[1] } ),
            );
        }

        foreach my $host (

            # https://community.aws/content/2biM1C0TkMkvJ2BLICiff8MKXS9/format-and-parse-amazon-s3-url?lang=en
            [ "$bucket.s3.amazonaws.com"         => [ 's3',$region    ,'legacy with virtual-hosted-style' ] ],
            [ "$bucket.$region.s3.amazonaws.com" => [ 's3',$region    ,'regional virtual-hosted-style'    ] ],
            [ "s3.$region.amazonaws.com"         => [ 's3',$region    ,'regional dot-style'               ] ],
            [ "s3-$region.amazonaws.com"         => [ 's3',$region    ,'regional dash-style'              ] ],
            [ "s3.amazonaws.com"                 => [ 's3','us-east-1','legacy with path-style'           ] ],
            [ "cognito-identity.$region.amazonaws.com" => [ 'cognito-identity',$region,'legacy path-style service' ] ],
        ) {
            cmp_deeply(
                [ $signer->parse_host( $host->[0],$region ) ],
                $host->[1],
                $host->[0] . ' -> ' . join( ", ",@{ $host->[1] } ) . ' (passed region)',
            );
        }
    }
}

my $paapi_region = AWS::S3::Signer::V4::PAAPI_REGION();

foreach my $host ( sort keys %{ $paapi_region } ) {
    cmp_deeply(
        [ $signer->parse_host( $host ) ],
        [ 'ProductAdvertisingAPI',$paapi_region->{$host},undef ],
        "ProductAdvertisingAPI ($host)",
    );
}
