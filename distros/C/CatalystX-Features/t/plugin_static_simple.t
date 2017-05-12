use strict;
use warnings;
use Test::More;
use B::Deparse;

use FindBin;
use lib "$FindBin::Bin/lib/TestAppStatic/lib";

eval { require Catalyst::Plugin::Static::Simple };
plan skip_all => "Catalyst::Plugin::Static::Simple not installed" if $@; 

plan tests => 3;

use_ok 'Catalyst::Test', 'TestApp';

{
    my $resp = request('/static/main.js');
    is($resp->content, "static stuff\n", 'basic static simple');
}

{
    my $resp = request('/static/feature.html');
    is($resp->content, "feature body\n", 'feature static simple');
}

done_testing;

