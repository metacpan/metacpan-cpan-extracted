package TestApp;

use strict;
use base qw/Catalyst/;
use Data::Dumper;

our $VERSION = '0.01';

TestApp->config(
    name => 'TestApp',
    cache => {
        storage => "$FindBin::Bin/cache.dat",
    },
);

# Fail gracefully if we don't have FastMmap
my @plugins = ();
eval {
    require Catalyst::Plugin::Cache::FastMmap;
};
unless ($@) {
    push @plugins, qw/UploadProgress Cache::FastMmap/;
}
Catalyst->import( @plugins );
__PACKAGE__->setup;

1;
