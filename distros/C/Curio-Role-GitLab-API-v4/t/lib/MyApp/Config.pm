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
    gitlab_api_url => 'https://gitlab.example.com/api/v4',
};

has config => (
    is      => 'ro',
    isa     => HashRef,
    default => sub{ $default_config },
);

1;
