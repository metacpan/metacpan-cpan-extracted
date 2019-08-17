package MyApp::Config;

use Types::Standard qw( HashRef );

use Curio;
use strictures 2;

add_key 'default';
default_key 'default';

export_function_name 'myapp_config';
always_export;
export_resource;
resource_method_name 'config';

does_caching;

my $default_config = {
    db => {
        writer => {
            dsn => 'dbi:SQLite:dbname=:memory:',
            username => '',
        },
        reader => {
            dsn => 'dbi:SQLite:dbname=:memory:',
            username => '',
        },
    },
};

has config => (
    is      => 'ro',
    isa     => HashRef,
    default => sub{ $default_config },
);

1;
