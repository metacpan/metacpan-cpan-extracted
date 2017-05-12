use Test::More tests => 4;

use_ok(Crypt::VERPString);

my $cv = Crypt::VERPString->new(key => 'HLAUGAHLGALG');
ok($cv, 'Constructor');

my $foo = 'HURF DUH HLGUAGHLAG';

my $str = $cv->encrypt(31337, $foo);
#print "# $str\n";
ok($str eq '00007a69-N962EWXKWA5QJ7TTODMG09YCJFEHXO1G5TM1N5G', 'Encryption');

my $cipher = '00003039-HVPJX6COBRQ21RF6YVCOPC8Q4ND1SHQ5H1J8B98';

my $plain = $cv->decrypt($cipher);
is($plain, $foo, 'Decryption');
