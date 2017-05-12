package MyDBIC;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.01';

use MyDBIC::Schema;    # must load in order to call init_connect_info

__PACKAGE__->config(
    name   => 'MyDBIC',
    static => {
        mime_types   => { null => 'text/html' },
        include_path => [
            __PACKAGE__->path_to('root'),
            __PACKAGE__->path_to('../../lib/CatalystX/CRUD/YUI/TT'),
        ],
    },
    'Model::DB' => {
        schema_class => 'MyDBIC::Schema',
        connect_info => [ MyDBIC::Schema->init_connect_info ],
    },
);

# Start the application
__PACKAGE__->setup;

# **MUST** call this after setup()
Class::C3::initialize();

1;
