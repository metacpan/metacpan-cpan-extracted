package MyApp::Config;

use Types::Standard qw( HashRef );

use Curio;
use strictures 2;

export_function_name 'myapp_config';
always_export;
export_resource;
resource_method_name 'config';
does_caching;

my $default_config = {
    foo => 3,
    bar => 'green',
};

has config => (
    is      => 'ro',
    isa     => HashRef,
    default => sub{ $default_config },
);

1;
