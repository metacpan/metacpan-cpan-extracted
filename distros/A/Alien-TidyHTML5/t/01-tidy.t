use Test2::V0;
use Test::Alien;
use Alien::TidyHTML5;

alien_ok 'Alien::TidyHTML5';

ok my $exe = Alien::TidyHTML5->exe, 'exe';

run_ok( [ $exe, '-version' ] )
    ->success
    ->out_like(qr/^HTML Tidy /);

done_testing;
