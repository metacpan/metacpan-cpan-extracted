use Test2::V0;
use Test::Alien;
use Alien::TidyHTML5;

alien_ok 'Alien::TidyHTML5';

ok my $exe_file = Alien::TidyHTML5->exe_file, 'exe_file';

run_ok( [ $exe_file, '-version' ] )
    ->success
    ->out_like(qr/^HTML Tidy /);

done_testing;
