# $Id: 01-dh.t 1860 2005-06-11 06:15:44Z btrott $

use strict;

use Test::More;
use Crypt::DH;

my $has_pari;
BEGIN {
    $has_pari = eval { require Math::Pari; 1 };
}
Test::More->import( tests => 18 + ($has_pari ? 3 : 0));

my @pgs = (
           {
               p => "0xdcf93a0b883972ec0e19989ac5a2ce310e1d37717e8d9571bb7623731866e61ef75a2e27898b057f9891c2e27a639c3f29b60814581cd3b2ca3986d2683705577d45c2e7e52dc81c7a171876e5cea74b1448bfdfaf18828efd2519f14e45e3826634af1949e5b535cc829a483b8a76223e5d490a257f05bdff16f2fb22f5615b",
               g => "2",
           },
           {
               p => "0xdcf93a0b883972ec0e19989ac5a2ce310e1d37717e8d9571bb7623731866e61ef75a2e27898b057f9891c2e27a639c3f29b60814581cd3b2ca3986d2683705577d45c2e7e52dc81c7a171876e5cea74b1448bfdfaf18828efd2519f14e45e3826634af1949e5b535cc829a483b8a76223e5d490a257f05bdff16f2fb230138c3",
               g => "2",
           },
           {
              p => "0xdcf93a0b883972ec0e19989ac5a2ce310e1d37717e8d9571bb7623731866e61ef75a2e27898b057f9891c2e27a639c3f29b60814581cd3b2ca3986d2683705577d45c2e7e52dc81c7a171876e5cea74b1448bfdfaf18828efd2519f14e45e3826634af1949e5b535cc829a483b8a76223e5d490a257f05bdff16f2fb22f2d1b7",
               g => "5",
           },
           {
               p => "0xce96240b0b5684d9e281fda07d5b6c316e14c7ae83913f86d13cad2546f93b533d15629d4b3e2c76753c5abcc29a8fb610ca1c3eb1014b0fd8209c330fff6eb8a562474b7d387e3f8074fa29d0b58bad5e6967a0ad667c41d41e1241669431f865c57e9eeb00e69beb1d18c3b940810324b394fab8f75b27a9b4e7972f07b4916a6a3d50f0445024697155382bf1ad14f90f8bab7e9d3ccbae6cd84e488a98770a8c64943582c6d2bb529511945aba146115273eb6bd718b62febfcd503fb56e8d4262e17dc5ce1a9b1d3e8ffa5ce0b825498bc6254da9cc69ddf7ad9ba582ab8f812c4de3228c88c5640baef5f62b7c039588d6cd7f694f039507aa3aaf4fb368a3712230ffc05b66a14c7003e2ad6a938d544b8b9908c4536f945ac4bdb1ca623f2826a25ca16b39730c9fe940a8642eb35088ed341be768c10b152c8a65d32e4dbe68764e6b2abde6824088b6be258d7e3aea155cb919e1c500cdcee435515cf09575f75551c16fba0f3aede0aaba544e89a58e4c34e255eaafd8f65340daa55e3ed8ab903fe188416340ace15d36f9cede379cc3586e6d320f72aa310a1b0a781d06b7418a50525105fa749306ac59a788d6866b7ddd0f4c059ba6cee43fad5ad2a362b9de1c57324ade8b5b46c6b1ddabd82f0670f7a4da869f204efb27ea7e049bc7d6cfd2071682c894161922a99108eb3bb8922113ba9924018e41b7",
               g => "5",
           }
           );

my $num = '10000000000000000001';
my @try = ($num, Math::BigInt->new($num));
push @try, Math::Pari->new($num) if $has_pari;
for my $try (@try) {
    my $type = 'any2bigint(' . (ref($try) || 'scalar') . ')';
    my $val = Crypt::DH::_any2bigint($try);
    ok($val, $type . ' returns a defined value');
    is(ref($val), 'Math::BigInt', $type  . ' returns a Math::BigInt');
    is($val->bstr, $num, $type . ' returns the correct value');
}

for my $pg (@pgs) {
    my $dh1 = Crypt::DH->new(g => $pg->{g}, p => $pg->{p});
    my $dh2 = Crypt::DH->new(g => $pg->{g}, p => $pg->{p});
    $dh1->generate_keys;
    $dh2->generate_keys;

    is($dh1->g->bstr, $pg->{g}, 'Key generation did not modify g');
    is($dh1->p->as_hex, $pg->{p}, 'Key generation did not modify p');

    my $pub1    = $dh1->pub_key;
    my $pub2    = $dh2->pub_key;

    my $ss1 = $dh1->compute_key($pub2);
    my $ss2 = $dh2->compute_key($pub1);

    is($ss1, $ss2, 'Shared secrets match');
}
