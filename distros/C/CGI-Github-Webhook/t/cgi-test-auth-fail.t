#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use CGI::Test;
use CGI::Test::Input::URL;
use Data::Dumper;
use File::Basename;

my $dir = dirname($0);

my $ct = CGI::Test->new(
    -base_url   => "http://webhook.example.org/cgi-bin",
    -cgi_dir    => "$dir/cgi",
    );

my $pr = CGI::Test::Input::URL->new();

my $page = $ct->GET("http://webhook.example.org/cgi-bin/cgitest.pl", $pr);
like($page->content_type, qr:text/plain\b:, "Content type");
like($page->raw_content, qr/Authentication failed/,
     "Simple request without payload doesn't succeed.");

done_testing;
