#!perl -T

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);

plan tests => 3, have_lwp;

my $response = GET '/jmpl/test.tt';

ok( $response->content =~ /\QJemplate.templateMap['test.tt']\E/ );
ok( $response->content =~ /\Qstash.get('value')\E/ );
ok( $response->content_type eq 'application/x-javascript' );



