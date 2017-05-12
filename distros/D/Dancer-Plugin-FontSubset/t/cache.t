package MyTest;

use strict;
use warnings;

use Test::More;

use Dancer ':tests';
use Dancer::Test;

BEGIN {
    config->{plugins}{FontSubset} = {
        fonts_dir => 't/fonts',
        use_cache => 1,
    };
    config->{plugins}{'Cache::CHI'} = {
        driver => 'Memory',
        global => 1,
    };
    set show_warnings => 1;
    set logger => 'console';
}

BEGIN {
    eval "use Dancer::Plugin::Cache::CHI; 1" or plan skip_all => 'Dancer::Plugin::Cache::CHI required';
}

use Dancer::Plugin::FontSubset;
use Dancer::Plugin::Cache::CHI;

plan tests => 3;

is cache->get( 'font-Bocklin.ttf-fo' ) => undef;

response_status_is '/font/Bocklin.ttf?t=fo', 200
    or diag dancer_response( 'GET', '/font/Bocklin.ttf?t=fo' )->content;

is cache->get( 'font-Bocklin.ttf-fo' ) => undef;

