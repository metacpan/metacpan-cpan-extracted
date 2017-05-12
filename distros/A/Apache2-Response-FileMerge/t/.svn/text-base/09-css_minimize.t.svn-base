
use strict;
use warnings;

my $has_css_min;
BEGIN {
    eval{ require CSS::Minifier };
    $has_css_min = ! $@;
};

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, \&need_lwp;
my $r = GET('/minimize/minimize.css');

ok( $r->code() == 200 );

skip ( 
    ! $has_css_min,
    $r->content() =~ /\/\*.*Minify CSS:\s*1.*\*\//sg 
);
