use strict;
use warnings;
use Test::More;
plan tests => 1;
use Devel::Hide qw[ Digest::HMAC ];
use Amazon::S3Curl::PurePerl;
use Data::Dumper;
ok $INC{'Amazon/S3Curl/PurePerl/Digest/HMAC.pm'}, "found Amazon::S3Curl::PurePerl::Digest::HMAC in %INC";
