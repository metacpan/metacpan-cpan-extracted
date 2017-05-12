package TestApp;
use strict;
use warnings;

use Catalyst::Runtime '5.80';

use Catalyst qw/ConfigLoader::Etc/;

__PACKAGE__->config(
    'Plugin::ConfigLoader::Etc' => {
        files => [
            "$FindBin::Bin/etc/conf/test1.yml",
        ]
    }
);

__PACKAGE__->setup;

