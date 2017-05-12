use strict;
use warnings FATAL => 'all';

use Apache::Test qw(plan ok have_lwp have_module);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

# test CleanLevel

my $module = "cgi";
plan tests => 4, [$module];
my $response;

$response = GET "/$module/content-type.pl?ct=text/html";
ok ($response->code == 200
 && $response->content_type =~ m|text/html|
 && $response->content =~ m|^\s*<b>ok</b>\s*$|);

$response = GET "/$module/content-type.pl?ct=text/plain";
ok ($response->code == 200
 && $response->content_type =~ m|text/plain|
 && $response->content =~ m|^\s*<b>ok</b>\s*$|);

$response = GET "/$module/all.pl";
ok ($response->code == 200
 && $response->content_type =~ m|text/plain|);

$response = GET "/$module/env.pl?env=QUERY_STRING";
ok ($response->code == 200
 && $response->content_type =~ m|text/plain|
 && t_cmp($response->content, "env=QUERY_STRING", "Checking QUERY_STRING"));
