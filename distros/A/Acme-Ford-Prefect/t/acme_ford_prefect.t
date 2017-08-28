use Test2::V0;
use Acme::Ford::Prefect;

is( Acme::Ford::Prefect::answer(), 42, 'Ford Prefect knows the answer' );

subtest 'share install' => sub {
  skip_all 'test requires share install' if Acme::Alien::DontPanic->install_type eq 'system';
  ok( exists( $Acme::Alien::DontPanic::AlienLoaded{-ldontpanic} ), 'AlienLoaded hash populated' );
  ok( -e $Acme::Alien::DontPanic::AlienLoaded{-ldontpanic}, 'AlienLoaded hash points to existant file' );
};

done_testing;
