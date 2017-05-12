use lib 't/lib';
use strict;
use Test::More;
use Apache::test qw(skip_test have_httpd test);
BEGIN {
  skip_test unless have_httpd;
  plan tests => 3;
}
use Apache::JemplateFilter;


my $response = Apache::test->fetch('/docs/tmpl/test.tt');

is( $response->content_type, 'application/x-javascript' );
ok( $response->content =~ /\QJemplate.templateMap['test.tt']\E/ );
ok( $response->content =~ /\Qstash.get('value')\E/ );

