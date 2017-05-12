use lib qw(t/lib);
use Test::More tests => 2;
use MyApp;

ok(MyApp->can('Cacheable'));
ok(MyApp->can('cache_adaptive'));
