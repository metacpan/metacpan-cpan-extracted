use Test2::V0 -no_srand => 1;
use Acme::Alien::DontPanic::Install::Files;

my $config = Acme::Alien::DontPanic::Install::Files->Inline('C');

like $config->{LIBS}, qr{-ldontpanic}, 'libs okay';
like $config->{AUTO_INCLUDE}, qr{libdontpanic\.h}, 'auto include okay';

done_testing;
