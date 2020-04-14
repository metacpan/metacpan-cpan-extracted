# -*- mode: perl; -*-

use Test2::V0;
use Test::Alien;
use Alien::MUSCLE;

alien_ok 'Alien::MUSCLE';

run_ok(['muscle', '-version'])
  ->exit_is(0);

ok( my $version = Alien::MUSCLE->version );
ok( my $bin_dir = Alien::MUSCLE->bin_dir );
ok( Alien::MUSCLE->muscle_binary, 'returns' );
like( Alien::MUSCLE->muscle_binary, qr{^\Q$bin_dir\E\/muscle}, 'correct' );

like( Alien::MUSCLE->muscle_dist_type, qr/^(source|binary)$/, 'type set');

done_testing;
