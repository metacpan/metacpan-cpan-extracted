package MyApp;
use Catalyst::Runtime 5.70;
use Catalyst;
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.04';

__PACKAGE__->config( foo => 'bar' );
__PACKAGE__->config->{bad} = 'juju';
__PACKAGE__->config(use_request_uri_for_path => 1);

__PACKAGE__->setup();

#warn dump MyApp->config;

Class::C3::initialize();    # for REST

#warn dump MyApp->config;

1;
