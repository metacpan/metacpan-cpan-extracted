
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use FindBin;

use lib "$FindBin::Bin/lib";
use Apache2::Controller::Test::Funk qw( diag );

plan tests => 5;

ok 1;  # simple load test

my $url = "/simple";

my $data = GET_BODY $url;

ok t_cmp("Top level handler.\n", $data, "basic test: top level handler");

for my $flavor (qw( apple berry peach )) {
    my $url = "/simple/pie/$flavor";
    my $data = GET_BODY $url;
    
    diag("flavor: $flavor, data:\n$data---\n");
    ok t_cmp("Simple as $flavor pie.\n", $data, "basic test: $flavor");
}

