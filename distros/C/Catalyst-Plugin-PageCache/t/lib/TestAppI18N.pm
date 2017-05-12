package TestAppI18N;

use strict;
use Catalyst;
use File::Path qw(make_path remove_tree);

our $VERSION = '0.01';

my $cache_root = 't/var';
remove_tree($cache_root);
make_path($cache_root);

TestAppI18N->config(
    name => 'TestApp-I18N',
    counter => 0,
    'Plugin::Cache' => {
        backend => { 
            class => 'Cache::FileCache',
            cache_root => $cache_root,
        },
    },
    'Plugin::PageCache' => {
        disable_index => 0,
    },  
);

TestAppI18N->setup( qw/Cache I18N PageCache/ );

1;
