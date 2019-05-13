package MyApp::Service::MultiCache;

use MyApp::FakeCHI;

use Curio;
use strictures 2;

does_caching;

add_key 'test_one';
add_key 'test_two';
add_key 'test_keyed';
add_key 'test_default';

default_key 'test_default';

has chi => (
    is => 'lazy',
);

sub _build_chi {
    return MyApp::FakeCHI->new();
}

1;
