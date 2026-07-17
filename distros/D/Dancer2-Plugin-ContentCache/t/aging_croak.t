use Test2::V1 -ipP;
use FindBin;
use lib "$FindBin::Bin/lib";

eval { require TestAppBadSchema; };
my $err = $@;

ok( $err, 'app with cache_aging on but no created_dt/expiry_dt columns dies at startup' );
like(
    $err,
    qr/cache_aging is enabled/,
    'the error explains that cache_aging is the problem'
);

done_testing;
