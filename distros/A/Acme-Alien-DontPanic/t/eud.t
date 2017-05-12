use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => 'test requires blib' unless -d 'blib' }
BEGIN { plan skip_all => 'requires Alien::Base 0.006' unless eval q{ use Alien::Base 0.006 (); 1 } }
use Acme::Alien::DontPanic::Install::Files;

my $config = Acme::Alien::DontPanic::Install::Files->Inline('C');

like $config->{LIBS}, qr{-ldontpanic}, 'libs okay';
like $config->{AUTO_INCLUDE}, qr{libdontpanic\.h}, 'auto include okay';

done_testing;
