package MyRDBO;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.01';

__PACKAGE__->config(
    name   => 'MyRDBO',
    'Catalyst::Plugin::Static::Simple::ByClass' => {
        mime_types   => { null => 'text/html' },
        include_path => [
            __PACKAGE__->path_to('root'),
            __PACKAGE__->path_to('../../lib/CatalystX/CRUD/YUI/TT'),
        ],
    }
);

__PACKAGE__->setup;

#Data::Dump::dump( __PACKAGE__->config );

# **MUST** call this after setup()
Class::C3::initialize();

1;
