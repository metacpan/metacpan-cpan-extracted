use Test2::V0;
use Test::Alien;
use Alien::Brotli;

alien_ok 'Alien::Brotli';

ok my $exe = Alien::Brotli->exe, 'exe';

run_ok( [ $exe, '--version' ] )
    ->success
    ->out_like(qr/^brotli /);

done_testing;
