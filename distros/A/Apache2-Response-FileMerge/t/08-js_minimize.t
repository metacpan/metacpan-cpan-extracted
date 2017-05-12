
use strict;
use warnings;

my $has_js_min;
BEGIN {
    eval{ require JavaScript::Minifier };
    $has_js_min = ! $@;
};

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, \&need_lwp;
my $r = GET('/minimize/minimize.js');

ok( $r->code() == 200 );

skip ( 
    ! $has_js_min,
    $r->content() =~ /\/\*.*Minify JS:\s*1.*\*\//sg 
);
