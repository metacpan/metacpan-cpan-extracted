#!perl -T

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);

plan tests => 2, have_lwp;

my $response = GET '/jmpl/error.tt';

ok( $response->content =~ /^throw\(/ );
ok( $response->content_type eq 'application/x-javascript' );



