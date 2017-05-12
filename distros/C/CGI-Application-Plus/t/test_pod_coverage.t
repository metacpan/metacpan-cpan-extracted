#!perl -w
use strict ;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 5;
my $trustme = { trustme => [ qr/^(cgiapp_get_query|cgiapp_init|cgiapp_prerun|dump|dump_html|load_tmpl|setup|teardown|lookup_CODE)$/ ] } ;
pod_coverage_ok( "Apache::Application::Magic", $trustme);
pod_coverage_ok( "Apache::Application::Plus", $trustme);
pod_coverage_ok( "CGI::Application::Magic", $trustme);
pod_coverage_ok( "CGI::Application::Plus", $trustme);
pod_coverage_ok( "CGI::Application::CheckRM", $trustme);

