#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use CGI::Test;
use CGI::Test::Input::URL;
use Data::Dumper;
use Digest::SHA qw(hmac_sha1_hex);
use File::Basename;

my $secret = 'bar';
my $json = '{"fnord":"gnarz"}';
my $signature = 'sha1='.hmac_sha1_hex($json, $secret);
my $dir = dirname($0);

$ENV{HTTP_X_HUB_SIGNATURE} = $signature;

my $ct = CGI::Test->new(
    -base_url   => "http://webhook.example.org/cgi-bin",
    -cgi_dir    => "$dir/cgi",
    );

my $pr = CGI::Test::Input::URL->new();
$pr->add_field('POSTDATA', $json);

my $page = $ct->POST("http://webhook.example.org/cgi-bin/cgitest.pl", $pr);
like($page->content_type, qr:text/plain\b:, "Content type");
like($page->raw_content, qr/Successfully triggered/, "Successfully triggered");

done_testing;
