use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 3;

{
    use Dancer;

    # settings must be loaded before we load the plugin
    setting(plugins => {
        SiteMap => {
            html_route => '',
        },
    });

    eval 'use Dancer::Plugin::SiteMap';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';
}

use Dancer::Test;

route_doesnt_exist [ GET => '/sitemap'     ], 'removing /sitemap';
route_exists       [ GET => '/sitemap.xml' ], 'keeping /sitemap.xml';

