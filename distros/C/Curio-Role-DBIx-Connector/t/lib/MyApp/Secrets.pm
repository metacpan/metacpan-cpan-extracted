package MyApp::Secrets;

use Types::Standard qw( HashRef );

use Curio;
use strictures 2;

export_function_name 'myapp_secret';
always_export;
resource_method_name 'secrets';
does_caching;

sub myapp_secret {
    my $key = pop;
    return __PACKAGE__->factory->fetch_resource( @_ )->{ $key };
}

my $default_secrets = {
    baz => 54,
    qux => 'yellow',
};

has secrets => (
    is      => 'ro',
    isa     => HashRef,
    default => sub{ $default_secrets },
);

1;
