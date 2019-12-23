#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Path::Tiny qw(path);
use lib path( $FindBin::Bin, 'lib' )->stringify;

use Test2::V0;

use HTTP::Tiny ();

use AWS::Lambda::Quick::Processor ();
use TestHelper::CreateTestFiles qw(populated_tempdir);

ok( 1, 'processor compiled' );

if ( $ENV{DO_AWS_TESTS} ) {
    my $tempdir      = populated_tempdir();
    my $zip_filename = path( $tempdir, 'handler.zip' );

    # upload;

    my $url = AWS::Lambda::Quick::Processor->new(
        src_filename => path( $tempdir, 'src', 'handler.pl' ),
        name         => 'aws-uploader-quick-test-suite-function',
        extra_files  => ['lib'],
    )->process;

    ## try to use

    my $response = HTTP::Tiny->new->get( $url . '?who=Everyone' );
    is( $response->{content}, 'Hello, Everyone', 'api works' );
}

done_testing;
