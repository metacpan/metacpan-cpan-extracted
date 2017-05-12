package TestApp2;

use strict;
use warnings;

use MRO::Compat;

use Catalyst qw/ConfigLoader/;

__PACKAGE__->config( "Plugin::ConfigLoader",
                     {
                         file => __PACKAGE__->path_to( "customconfig.pl" )
                     }
                 );

our $VERSION = '0.01';

__PACKAGE__->setup;

sub finalize_config {
    my $c = shift;
    $c->config( foo => 'bar2' );
    $c->next::method( @_ );
}

1;
