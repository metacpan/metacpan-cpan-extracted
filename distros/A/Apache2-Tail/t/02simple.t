#!perl -w
use strict;
use Test::More;

BEGIN {
if (! eval "use Apache::Test qw(:withtestmore); 1;") {
   plan skip_all => "No Apache::Test" ;
}
}

use Apache::TestRequest;

plan tests => 3;

my $content = GET '/tail';

ok $content;
ok $content->code == 200, "Check that the request was OK";
ok $content->content =~ /Apache2::Tail/, "Output smells right";
