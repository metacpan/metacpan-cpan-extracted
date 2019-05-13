package MyApp::Service::SingleCache;

use MyApp::FakeCHI;

use Curio;
use strictures 2;

does_caching;

has chi => (
    is => 'lazy',
);

sub _build_chi {
    return MyApp::FakeCHI->new();
}

1;
