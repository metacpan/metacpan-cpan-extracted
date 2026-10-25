use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Brotli;

alien_diag 'Alien::Brotli', { 'properties' => ['exe'] };
alien_ok 'Alien::Brotli';

ok my $exe = Alien::Brotli->exe, 'exe';

run_ok( [ $exe, '--version' ] )
    ->success
    ->out_like(qr/^brotli /);

done_testing;
