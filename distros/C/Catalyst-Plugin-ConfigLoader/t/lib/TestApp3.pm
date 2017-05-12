package TestApp3;

use strict;
use warnings;

use MRO::Compat;

use Catalyst qw/ConfigLoader/;

our $VERSION = '0.01';

__PACKAGE__->config(
    "Plugin::ConfigLoader" => {
        file => __PACKAGE__->path_to( "config" )
    }
);

__PACKAGE__->setup;

sub finalize_config {
    my $c = shift;
    $c->config( foo => 'bar3' );
    $c->next::method( @_ );
}

1;
