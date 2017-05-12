use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'AWS-CloudFront';
perl_version '5.008001';
license 'perl';
all_from 'lib/AWS/CloudFront.pm';

test_requires 'Test::More'  => '0';

requires      'VSO'                       => '0.022';
requires      'AWS::S3'                   => '0.024';
requires      'Carp'                      => '0';
requires      'HTTP::Date'                => '0';
requires      'MIME::Base64'              => '0';
requires      'URI::Escape'               => '0';
requires      'URI::QueryParam'           => '0';
requires      'URI::Escape'               => '0';
requires      'Digest::HMAC_SHA1'         => '0';
requires      'Data::Validate::Domain'    => '0.10';
requires      'LWP::Protocol::https'      => '6.02';

tests_recursive();
WriteAll();

