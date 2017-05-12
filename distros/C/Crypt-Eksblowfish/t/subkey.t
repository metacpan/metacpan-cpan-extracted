use warnings;
use strict;

use Test::More tests => 42 + 6*10;

BEGIN { use_ok "Crypt::Eksblowfish::Subkeyed"; }

is(Crypt::Eksblowfish::Subkeyed->blocksize, 8);

my $init = Crypt::Eksblowfish::Subkeyed->new_initial;
ok $init;
is ref($init), "Crypt::Eksblowfish::Subkeyed";
is $init->blocksize, 8;

my $pa = $init->p_array;
is ref($pa), "ARRAY";
is scalar(@$pa), 18;
is $pa->[0], 0x243f6a88;
is $pa->[17], 0x8979fb1b;

my $sb = $init->s_boxes;
is ref($sb), "ARRAY";
is scalar(@$sb), 4;
for(my $i = 4; $i--; ) {
	is ref($sb->[$i]), "ARRAY";
	is scalar(@{$sb->[$i]}), 256;
}
is $sb->[0]->[0], 0xd1310ba6;
is $sb->[3]->[255], 0x3ac372e6;

ok !$init->is_weak;

eval { Crypt::Eksblowfish::Subkeyed->new_from_subkeys(3, $sb); };
isnt $@, "";
eval { Crypt::Eksblowfish::Subkeyed->new_from_subkeys([], $sb); };
isnt $@, "";
eval { Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa, []); };
isnt $@, "";
eval {
	Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa, [@{$sb}[0..2],3]);
};
isnt $@, "";
eval {
	Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa, [@{$sb}[0..2],[]]);
};
isnt $@, "";

my $cinit = Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa, $sb);
ok $cinit;
is ref($cinit), "Crypt::Eksblowfish::Subkeyed";
is $cinit->blocksize, 8;
is_deeply $cinit->p_array, $pa;
is_deeply $cinit->s_boxes, $sb;
ok !$cinit->is_weak;

$pa = [ reverse(@$pa) ];
$sb = [ map { [ reverse(@$_) ] } @$sb ];
my $tcipher = Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa, $sb);
ok $tcipher;
is ref($tcipher), "Crypt::Eksblowfish::Subkeyed";
is $tcipher->blocksize, 8;
is_deeply $tcipher->p_array, $pa;
is_deeply $tcipher->s_boxes, $sb;
ok !$tcipher->is_weak;

ok !Crypt::Eksblowfish::Subkeyed->new_from_subkeys([ @{$pa}[0..5,9,7..17] ],
	$sb)->is_weak;
ok !Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa,
	[ @{$sb}[0,0,0,0] ])->is_weak;
ok !!Crypt::Eksblowfish::Subkeyed->new_from_subkeys($pa,
	[ $sb->[0], [ @{$sb->[1]}[0..5,9,7..255] ], @{$sb}[1,2] ])->is_weak;

while(<DATA>) {
	my($pt, $ict, $tct) = map { pack("H*", $_) } split;
	is $init->encrypt($pt), $ict;
	is $init->decrypt($ict), $pt;
	is $cinit->encrypt($pt), $ict;
	is $cinit->decrypt($ict), $pt;
	is $tcipher->encrypt($pt), $tct;
	is $tcipher->decrypt($tct), $pt;
}

1;

__DATA__
c2e05cec152b7f84 e7ae62039464d1a3 95360a60c9d8ae55
8f2a4b8beb786d34 b268b3c6cd763b9b 1cbfcb33912e6aad
08953ae2bc9b6fac 85f97065bb2cfb95 fde450df89601c8f
e146d6f4593bb6d4 4bb9b1a1cd6d3519 08ee35abde632849
ea95a8d87f8b3707 b81b2bc161d4858f eed42049b4473cd3
754f65df7612b623 be6858951aaa5b8e 667e2ef6e618fa09
189b7138fbe47050 599861bf55e807d7 e5245a3ad5f1927e
c4d8aa6c8f89d566 eaedc699152cb8bd ce615d5dde70b9db
17360076b8aa87d8 fcc844ffa2cb9a39 cac0835a83c7dcc6
837397193cd28b9f f6ac385258e1d151 e08588070546c327
