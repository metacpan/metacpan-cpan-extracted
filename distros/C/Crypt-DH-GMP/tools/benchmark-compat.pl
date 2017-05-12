use strict;
use Math::BigInt::GMP;
use Crypt::DH;
use Crypt::DH::GMP;
use Benchmark qw(cmpthese);

# This package is NOT exactly the same as Crypt::DH::GMP::Compat, but it
# mimics what that module does.

package Crypt::DH::GMP::Mocked;
use strict;
use base qw(Crypt::DH::GMP);

sub generate_keys { shift->SUPER::generate_keys(@_) }
sub compute_key { shift->SUPER::compute_key(@_) }

package main;

my %args = (
     p => "0xce96240b0b5684d9e281fda07d5b6c316e14c7ae83913f86d13cad2546f93b533d15629d4b3e2c76753c5abcc29a8fb610ca1c3eb1014b0fd8209c330fff6eb8a562474b7d387e3f8074fa29d0b58bad5e6967a0ad667c41d41e1241669431f865c57e9eeb00e69beb1d18c3b940810324b394fab8f75b27a9b4e7972f07b4916a6a3d50f0445024697155382bf1ad14f90f8bab7e9d3ccbae6cd84e488a98770a8c64943582c6d2bb529511945aba146115273eb6bd718b62febfcd503fb56e8d4262e17dc5ce1a9b1d3e8ffa5ce0b825498bc6254da9cc69ddf7ad9ba582ab8f812c4de3228c88c5640baef5f62b7c039588d6cd7f694f039507aa3aaf4fb368a3712230ffc05b66a14c7003e2ad6a938d544b8b9908c4536f945ac4bdb1ca623f2826a25ca16b39730c9fe940a8642eb35088ed341be768c10b152c8a65d32e4dbe68764e6b2abde6824088b6be258d7e3aea155cb919e1c500cdcee435515cf09575f75551c16fba0f3aede0aaba544e89a58e4c34e255eaafd8f65340daa55e3ed8ab903fe188416340ace15d36f9cede379cc3586e6d320f72aa310a1b0a781d06b7418a50525105fa749306ac59a788d6866b7ddd0f4c059ba6cee43fad5ad2a362b9de1c57324ade8b5b46c6b1ddabd82f0670f7a4da869f204efb27ea7e049bc7d6cfd2071682c894161922a99108eb3bb8922113ba9924018e41b7",
     g => "5",
);
my $tmp_dh = Crypt::DH::GMP::Mocked->new(%args);
my $pub_key = $tmp_dh->pub_key;

cmpthese(1000, {
    pp => sub {
        my $dh = Crypt::DH->new(%args);
        $dh->generate_keys();
        $dh->compute_key($pub_key);
    },
    gmp => sub {
        my $dh = Crypt::DH::GMP::Mocked->new(%args);
        $dh->generate_keys();
        $dh->compute_key($pub_key);
    },
});
