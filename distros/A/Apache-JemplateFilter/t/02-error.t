use lib 't/lib';
use strict;
use Test::More;
use Apache::test qw(skip_test have_httpd test);
BEGIN {
  skip_test unless have_httpd;
  plan tests => 2;
}
use Apache::JemplateFilter;

my $response = Apache::test->fetch('/docs/tmpl/error.tt');

is( $response->content_type, 'application/x-javascript' );
ok( $response->content =~ /^throw\(/ );
