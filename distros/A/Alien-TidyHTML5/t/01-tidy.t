use Test2::V0;
use Test::Alien;
use Alien::TidyHTML5;

alien_ok 'Alien::TidyHTML5';
run_ok( [qw/ tidy -version /] )
    ->success
    ->out_like(qr/^HTML Tidy /);

done_testing;
