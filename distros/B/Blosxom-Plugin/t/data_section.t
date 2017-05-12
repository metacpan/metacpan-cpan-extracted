use strict;
use warnings;
use parent 'Blosxom::Plugin';
use Test::More tests => 3;

{
    package blosxom;
    our %template;
}

sub component_base_class { 'Blosxom::Plugin' }

my $plugin = __PACKAGE__;

$plugin->load_components( 'DataSection' );

is $plugin->get_data_section( 'my_plugin.html' ), "hello, world\n";

$plugin->merge_data_section_into( \%blosxom::template );

is_deeply \%blosxom::template, {
    html => {
        my_plugin => "hello, world\n",
    },
};

ok !$plugin->has_method( 'init' );

__DATA__
@@ my_plugin.html
hello, world
