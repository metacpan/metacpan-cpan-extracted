use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use Amazon::S3Curl::PurePerl;
use File::Temp;
use File::Spec;

my $mock_http_date = 'Tue, 01 Oct 2013 19:00:05 +0000';

my $download_file = File::Temp->new;
my $aws_access_key = "foo";
my $aws_secret_key = "bar";

my $filename = "test_download_file";

my $test_bucket = "test_bucket";

my %pp_args = (
    aws_access_key => $aws_access_key,
    aws_secret_key => $aws_secret_key,
    local_file     => "$download_file",
    url            => "/$test_bucket/$filename",
    static_http_date => $mock_http_date,
);

ok my $mock_downloader = Amazon::S3Curl::PurePerl->new(%pp_args),
  "instantiated mock downloader";
ok my $args = $mock_downloader->download_cmd, "->download_cmd args";
ok ( ( grep { /Authorization: AWS foo:xWM52ZBCAFo0MWwhwO94lX7gJxI=/ } @$args ), "found correct signature in args");
