package MyApp;

use Catalyst qw(
    Static::Simple
);
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.001';

__PACKAGE__->config( foo => 'bar' );
__PACKAGE__->config->{bad} = 'juju';
__PACKAGE__->config(use_request_uri_for_path => 1);

__PACKAGE__->setup();

#warn dump MyApp->config;

Class::C3::initialize();    # fix MRO

#warn dump MyApp->config;

1;
