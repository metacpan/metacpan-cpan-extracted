use Test::More tests => 20;

use strict;
use warnings;

BEGIN { use_ok('Crypt::Keyczar::Util') };

ok(Crypt::Keyczar::Util::encode('1') eq 'MQ');
ok(Crypt::Keyczar::Util::encode('12') eq 'MTI');
ok(Crypt::Keyczar::Util::encode('123') eq 'MTIz');
ok(Crypt::Keyczar::Util::encode('1234') eq 'MTIzNA');
ok(Crypt::Keyczar::Util::encode('12345') eq 'MTIzNDU');
ok(Crypt::Keyczar::Util::encode('123456') eq 'MTIzNDU2');
ok(Crypt::Keyczar::Util::encode('1234567') eq 'MTIzNDU2Nw');
ok(Crypt::Keyczar::Util::encode('12345678') eq 'MTIzNDU2Nzg');

ok(Crypt::Keyczar::Util::decode('MQ') eq '1');
ok(Crypt::Keyczar::Util::decode('MTI') eq '12');
ok(Crypt::Keyczar::Util::decode('MTIz') eq '123');
ok(Crypt::Keyczar::Util::decode('MTIzNA') eq '1234');
ok(Crypt::Keyczar::Util::decode('MTIzNDU') eq '12345');
ok(Crypt::Keyczar::Util::decode('MTIzNDU2') eq '123456');
ok(Crypt::Keyczar::Util::decode('MTIzNDU2Nw') eq '1234567');
ok(Crypt::Keyczar::Util::decode('MTIzNDU2Nzg') eq '12345678');

my $d1 = Crypt::Keyczar::Util::random(8);
my $d2 = Crypt::Keyczar::Util::random(8);
ok(length $d1 == 8);
ok(length $d2 == 8);
ok($d1 ne $d2);
