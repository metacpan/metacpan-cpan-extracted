#!/usr/bin/env perl
use Test::More;
use strict;
use warnings;
no strict 'refs';

use lib '../lib', '../../lib';

our ($module, $modulekey);
BEGIN {
    our $module    = 'Crypt::MagicSignatures::Envelope';
    our $modulekey = 'Crypt::MagicSignatures::Key';
    use_ok($module);
    use_ok($modulekey, qw/b64url_encode b64url_decode/);
};


###############
# From MiniMe #

ok(my $me = Crypt::MagicSignatures::Envelope->new(<<'ME'), 'Envelope Construction');
<?xml version="1.0" encoding="UTF-8"?>
<me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
  <me:data type="application/atom+xml">PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPGVudHJ5IHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDA1L0F0b20iIHhtbG5zOmFjdGl2aXR5PSJodHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zcGVjLzEuMC8iPgogIDxpZD5taW1pbWU6MTI4MDg0MzI4MzwvaWQ-CiAgPHRpdGxlPlVzZXIgQyBpcyBub3cgZm9sbG93aW5nIHVzZXItYkBsb2NhbGhvc3Q8L3RpdGxlPgogIDxjb250ZW50IHR5cGU9Imh0bWwiPiZsdDthIGhyZWY9J2h0dHA6Ly9sb2NhbGhvc3QvaW5kZXgucGhwP2NvbnRyb2xsZXI9cHJvZmlsZSZhbXA7dXNlcm5hbWU9dXNlci1jJyZndDtVc2VyIEMgaXMgbm93IGZvbGxvd2luZyB1c2VyLWJAbG9jYWxob3N0PC9jb250ZW50PgogIDxhdXRob3I-CiAgICA8dXJpPmFjY3Q6dXNlci1jQGxvY2FsaG9zdDwvdXJpPgogICAgPG5hbWU-VXNlciBDPC9uYW1lPgogIDwvYXV0aG9yPgogIDxhY3Rpdml0eTphY3Rvcj4KICAgIDxhY3Rpdml0eTpvYmplY3QtdHlwZT5odHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zY2hlbWEvMS4wL3BlcnNvbjwvYWN0aXZpdHk6b2JqZWN0LXR5cGU-CiAgICA8aWQ-aHR0cDovL2xvY2FsaG9zdC9pbmRleC5waHA_Y29udHJvbGxlcj1wcm9maWxlJmFtcDt1c2VybmFtZT11c2VyLWM8L2lkPgogICAgPHRpdGxlPlVzZXIgQzwvdGl0bGU-CiAgICA8bGluayByZWw9ImFsdGVybmF0ZSIgdHlwZT0idGV4dC9odG1sIiBocmVmPSJodHRwOi8vbG9jYWxob3N0L2luZGV4LnBocD9jb250cm9sbGVyPXByb2ZpbGUmYW1wO3VzZXJuYW1lPXVzZXItYyIvPgogIDwvYWN0aXZpdHk6YWN0b3I-CiAgPGFjdGl2aXR5OnZlcmI-aHR0cDovL2FjdGl2aXR5c3RyZWEubXMvc2NoZW1hLzEuMC9mb2xsb3c8L2FjdGl2aXR5OnZlcmI-CjwvZW50cnk-Cg==</me:data>
  <me:encoding>base64url</me:encoding>
  <me:alg>RSA-SHA256</me:alg>
  <me:sig>SoYN1toewy1f1KBf7Nm2W7EgbsP2OGa42MxZas5ATX3BwQE1l4U5olG7Yr80efbqp82_cHIcNe2kTZ7Nnfx_KtuS28dvglewjHYmqnQhDr9lW6-NlThC1E7K4Cbln6MZetMXUa3IcxRPJTdEsBojNsBE7H8afpDpEd2Dyjbbar0=</me:sig>
</me:env>
ME

ok(my $mkey = Crypt::MagicSignatures::Key->new(<<'MKEY'), 'Key Construction');
RSA.gGvGh83fHtavoKyqcld5oZUW0LNIwdr-zXfEXjfLY2FwuQzC-5gHNU59l-1NNKWTlEREti6I6Wn7b18NOnZNXzpjqE9yzUZoK4JB4je4WnaWdvDTapmrVQO1qaVD4zm589TQ93Q_hUnApziTtJ_0wd7IUSnDk4lmAyF7k64w52U=.AQAB
MKEY

is($mkey->n, '901802916520320011720317078670415225517146602419978904921636'.
     '16893857535911640609231722704424603629170739381483892089308314930471'.
     '57394240853707016325998769445310476998293633578143715575116828431331'.
     '30082270384369594692607406177489773182356761873783067882005539460004'.
     '64903234307347745477560531254436274621179749', 'MiniMe Modulus');

is($mkey->_emLen, 128, 'MiniMe k');

is($mkey->e, 65537, 'MiniMe e');

is($me->signature->{value}, 'SoYN1toewy1f1KBf7Nm2W7EgbsP2OGa42MxZas5ATX3Bw'.
     'QE1l4U5olG7Yr80efbqp82_cHIcNe2kTZ7Nnfx_KtuS28dvglewjHYmqnQhDr9lW6-Nl'.
     'ThC1E7K4Cbln6MZetMXUa3IcxRPJTdEsBojNsBE7H8afpDpEd2Dyjbbar0=',
     'MiniMe Signature');

is(b64url_encode($me->data), 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRG'.
     'LTgiPz4KPGVudHJ5IHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDA1L0F0b20iIHht'.
     'bG5zOmFjdGl2aXR5PSJodHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zcGVjLzEuMC8iPgog'.
     'IDxpZD5taW1pbWU6MTI4MDg0MzI4MzwvaWQ-CiAgPHRpdGxlPlVzZXIgQyBpcyBub3cg'.
     'Zm9sbG93aW5nIHVzZXItYkBsb2NhbGhvc3Q8L3RpdGxlPgogIDxjb250ZW50IHR5cGU9'.
     'Imh0bWwiPiZsdDthIGhyZWY9J2h0dHA6Ly9sb2NhbGhvc3QvaW5kZXgucGhwP2NvbnRy'.
     'b2xsZXI9cHJvZmlsZSZhbXA7dXNlcm5hbWU9dXNlci1jJyZndDtVc2VyIEMgaXMgbm93'.
     'IGZvbGxvd2luZyB1c2VyLWJAbG9jYWxob3N0PC9jb250ZW50PgogIDxhdXRob3I-CiAg'.
     'ICA8dXJpPmFjY3Q6dXNlci1jQGxvY2FsaG9zdDwvdXJpPgogICAgPG5hbWU-VXNlciBD'.
     'PC9uYW1lPgogIDwvYXV0aG9yPgogIDxhY3Rpdml0eTphY3Rvcj4KICAgIDxhY3Rpdml0'.
     'eTpvYmplY3QtdHlwZT5odHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zY2hlbWEvMS4wL3Bl'.
     'cnNvbjwvYWN0aXZpdHk6b2JqZWN0LXR5cGU-CiAgICA8aWQ-aHR0cDovL2xvY2FsaG9z'.
     'dC9pbmRleC5waHA_Y29udHJvbGxlcj1wcm9maWxlJmFtcDt1c2VybmFtZT11c2VyLWM8'.
     'L2lkPgogICAgPHRpdGxlPlVzZXIgQzwvdGl0bGU-CiAgICA8bGluayByZWw9ImFsdGVy'.
     'bmF0ZSIgdHlwZT0idGV4dC9odG1sIiBocmVmPSJodHRwOi8vbG9jYWxob3N0L2luZGV4'.
     'LnBocD9jb250cm9sbGVyPXByb2ZpbGUmYW1wO3VzZXJuYW1lPXVzZXItYyIvPgogIDwv'.
     'YWN0aXZpdHk6YWN0b3I-CiAgPGFjdGl2aXR5OnZlcmI-aHR0cDovL2FjdGl2aXR5c3Ry'.
     'ZWEubXMvc2NoZW1hLzEuMC9mb2xsb3c8L2FjdGl2aXR5OnZlcmI-CjwvZW50cnk-Cg==',
     'MiniMe data');

my $sig = $me->signature->{value};

my $signum = b64url_decode( $sig );


is(length($signum), 128, 'MiniMe signature length');
is($mkey->_emLen, length($signum), 'MiniMe k and signature length');

my $os2ip = *{"${modulekey}::_os2ip"}->($signum);

is($os2ip, '52332285781146674675512007035461285225137515191979069694136542'.
     '97654501416666643197762493477515926726134351096274407328478740409297'.
     '69199351329961332454210694523149606342173691483983460223710961189914'.
     '19593140674421980076259854159133067734583887117373056019018120313509'.
     '984905617350967619672735853279306258803389', 'MiniMe os2ip(s)');

my $rsavp1 = *{"${modulekey}::_rsavp1"}->($mkey, $os2ip);

is($rsavp1, '5486124068793688683255936251187209270074392635932332070112001988456197381759672947165175699536362793613284725337872111744958183862744647903224103718245670299614498700710006264535421091908069935709303403272242499531581061652193644482294243304285839259709257766405022153630057173895876978029013572575452041', 'MiniMe rsavp1');

# MiniMe does not use the base signature! This seems to be wrong!
ok($mkey->verify(b64url_encode($me->data), $sig), 'MiniMe Verification');
ok(!$me->verify($mkey), 'MiniMe Envelope Verification fail');
ok($me->verify([$mkey, -data]), 'MiniMe Envelope Verification');
ok($me->verify([$mkey, -compatible]), 'MiniMe Envelope Verification');

ok($mkey = Crypt::MagicSignatures::Key->new(<<'MKEY'), 'Key Construction');
RSA.hkwS0EK5Mg1dpwA4shK5FNtHmo9F7sIP6gKJ5fyFWNotObbbckq4dk4dhldMKF42b2FPsci109MF7NsdNYQ0kXd3jNs9VLCHUujxiafVjhw06hFNWBmvptZud7KouRHz4Eq2sB-hM75MEn3IJElOquYzzUHi7Q2AMalJvIkG26c=.AQAB.JrT8YywoBoYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9NzuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxxz6Nqxx352oPh4vycnXOk=
MKEY

ok($me = Crypt::MagicSignatures::Envelope->new(<<'ME'), 'Envelope Construction');
<?xml version="1.0" encoding="UTF-8"?>
<me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
  <me:data type="application/atom+xml">PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPGVudHJ5IHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDA1L0F0b20iIHhtbG5zOmFjdGl2aXR5PSJodHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zcGVjLzEuMC8iPgogIDxpZD5taW1pbWU6MTIzNDU2ODk8L2lkPgogIDx0aXRsZT5UdW9tYXMgaXMgbm93IGZvbGxvd2luZyBQYW1lbGEgQW5kZXJzb248L3RpdGxlPgogIDxjb250ZW50IHR5cGU9InRleHQvaHRtbCI-VHVvbWFzIGlzIG5vdyBmb2xsb3dpbmcgUGFtZWxhIEFuZGVyc29uPC9jb250ZW50PgogIDx1cGRhdGVkPjIwMTAtMDctMjZUMDY6NDI6NTUrMDI6MDA8L3VwZGF0ZWQ-CiAgPGF1dGhvcj4KICAgIDx1cmk-aHR0cDovL2xvYnN0ZXJtb25zdGVyLm9yZy90dW9tYXM8L3VyaT4KICAgIDxuYW1lPlR1b21hcyBLb3NraTwvbmFtZT4KICA8L2F1dGhvcj4KICA8YWN0aXZpdHk6YWN0b3I-CiAgICA8YWN0aXZpdHk6b2JqZWN0LXR5cGU-aHR0cDovL2FjdGl2aXR5c3RyZWEubXMvc2NoZW1hLzEuMC9wZXJzb248L2FjdGl2aXR5Om9iamVjdC10eXBlPgogICAgPGlkPnR1b21hc0Bsb2JzdGVybW9uc3Rlci5vcmc8L2lkPgogICAgPHRpdGxlPlR1b21hcyBLb3NraTwvdGl0bGU-CiAgICA8bGluayByZWY9ImFsdGVybmF0ZSIgdHlwZT0idGV4dC9odG1sIiBocmVmPSJodHRwOi8vaWRlbnRpLmNhL3Rrb3NraSIvPgogIDwvYWN0aXZpdHk6YWN0b3I-CiAgPGFjdGl2aXR5OnZlcmI-aHR0cDovL2FjdGl2aXR5c3RyZWEubXMvc2NoZW1hLzEuMC9mb2xsb3c8L2FjdGl2aXR5OnZlcmI-CjwvZW50cnk-Cg==</me:data>
  <me:encoding>base64url</me:encoding>
  <me:alg>RSA-SHA256</me:alg>
  <me:sig>aMMmGLJd81bgBdU26WjVCT1zIH17ND0dlfArs1Kii_fVYFyz6IEyQzM3GddvzAfJ51vo-uN_RY9TEHtoHp12N9Abg9AbCcrPcBGvcP7VBhFWw857v_sYlbD6nek9cX9JKBu-C_Xf20QGuE5dPFL0S4kZsuemeQ8p6cJAj_RbumM=</me:sig>
</me:env>
ME

# MiniMe does not use the base signature! This seems to be wrong!
ok($mkey->verify(b64url_encode($me->data), $me->signature->{value}), 'MiniMe Verification 2');

ok(!$me->verify($mkey), 'MiniMe Verification fail');
ok($me->verify([$mkey, -data]), 'MiniMe Verification');
ok($me->verify([$mkey, -compatible]), 'MiniMe Verification');

is ($mkey->sign(b64url_encode($me->data)), $me->signature->{value}, 'MiniMe Signature Identity');

ok($me = Crypt::MagicSignatures::Envelope->new(<<'ME2'), 'Envelope creation');
<?xml version="1.0" encoding="UTF-8"?>
<me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
  <me:data type="application/atom+xml">PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPGVudHJ5IHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDA1L0F0b20iIHhtbG5zOmFjdGl2aXR5PSJodHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zcGVjLzEuMC8iPgogIDxpZD5taW1pbWU6MTI4MTA5NDk3OTwvaWQ-CiAgPHRpdGxlPkB0a29za2ksIEFyZSB5b3UgZ2V0dGluZyB0aGlzIHNhbG1vbiBuaWNlbHk_PC90aXRsZT4KICA8Y29udGVudCB0eXBlPSJodG1sIj5AdGtvc2tpLCBBcmUgeW91IGdldHRpbmcgdGhpcyBzYWxtb24gbmljZWx5PzwvY29udGVudD4KICA8YXV0aG9yPgogICAgPHVyaT5hY2N0Omtvc2tpQGxvYnN0ZXJtb25zdGVyLm9yZzwvdXJpPgogICAgPG5hbWU-VHVvbWFzIEtvc2tpPC9uYW1lPgogIDwvYXV0aG9yPgogIDxhY3Rpdml0eTphY3Rvcj4KICAgIDxhY3Rpdml0eTpvYmplY3QtdHlwZT5odHRwOi8vYWN0aXZpdHlzdHJlYS5tcy9zY2hlbWEvMS4wL3BlcnNvbjwvYWN0aXZpdHk6b2JqZWN0LXR5cGU-CiAgICA8aWQ-aHR0cDovL3d3dy5sb2JzdGVybW9uc3Rlci5vcmcvcHJvZmlsZS9rb3NraTwvaWQ-CiAgICA8dGl0bGU-VHVvbWFzIEtvc2tpPC90aXRsZT4KICAgIDxsaW5rIHJlbD0iYWx0ZXJuYXRlIiB0eXBlPSJ0ZXh0L2h0bWwiIGhyZWY9Imh0dHA6Ly93d3cubG9ic3Rlcm1vbnN0ZXIub3JnL3Byb2ZpbGUva29za2kiLz4KICAgIDxsaW5rIHJlbD0iYXZhdGFyIiB0eXBlPSJpbWFnZS9wbmciIGhyZWY9Imh0dHA6Ly93d3cuZ3JhdmF0YXIuY29tL2F2YXRhci9hMGM2ZTYzYjliOGI4ZDRmNmZhYTNjOWVhNjJmNDNiZi5wbmciLz4KICA8L2FjdGl2aXR5OmFjdG9yPgo8L2VudHJ5Pgo=</me:data>
  <me:encoding>base64url</me:encoding>
  <me:alg>RSA-SHA256</me:alg>
  <me:sig>VXBI5WYkJmj82AmdXOsfi3fjn3J7kYJsWsFUGbnGaqntUkA_Sza67eBJDUsoSjhd4Knb-FUb8hTJVzadqaCq_Bj4n0DouoRZ6bW9T1gGS2-Qgpwm_ZVb9xFZogGkHKF6-15_Lb7ntuQcee5tnHwxzMGty51uuai6qiZZ_u51wrk=</me:sig>
</me:env>
ME2

ok($mkey = Crypt::MagicSignatures::Key->new(<<'MKEY2'), 'MagicKey Creation');
RSA.quCNBj3KbWmJG1huVxTvHWjCenThHYSb49y7HLPz_fVUfTUYMVfz7Qt8IkTXKj9TartEhNG2FzTIZzu4mkSzkKDZ9NflWs2VIJCWZoF-xJY4FAGKvja-Tuxn-K2trjKa6bypIEfM4qYWVHr_Sxfx3r4fioAe2z90p3AKF6aWm10=.AQAB
MKEY2

# From MiniMe-file
ok($mkey->verify(b64url_encode($me->data), $me->signature->{value}), 'Identica Verification');

ok(!$me->verify($mkey), 'MiniMe Verification fail');
ok($me->verify([$mkey, -data]), 'MiniMe Verification');
ok($me->verify([$mkey, -compatible]), 'MiniMe Verification');


done_testing;

__END__
