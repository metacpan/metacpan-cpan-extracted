package MyApp::Service::SingleCache;

use MyApp::FakeCHI;

use Curio;
use strictures 2;

add_key 'default';
default_key 'default';

does_caching;

has chi => (
    is => 'lazy',
);

sub _build_chi {
    return MyApp::FakeCHI->new();
}

1;
