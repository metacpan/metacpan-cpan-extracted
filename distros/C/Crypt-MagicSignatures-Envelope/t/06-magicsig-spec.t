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


#############################
# From MagicSignatures Spec #

ok(my $mkey = Crypt::MagicSignatures::Key->new(<<'MESPECKEY'), 'Key Construction');
RSA.mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKUEK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww.AQAB
MESPECKEY

ok(my $mkey2 = Crypt::MagicSignatures::Key->new(<<'MESPECKEY2'), 'Key Construction');
RSA.wvwmdK0eeUPe2hURBTstndvmUUPb4UZTd6wvwmddSrrC89yN8k6FilGwvwmddSKE5z_jvKUEKj9f4Pj-5CmHww.AQAB
MESPECKEY2

ok(my $me = Crypt::MagicSignatures::Envelope->new(<<'MESPEC'), 'Envelope construction');
<?xml version='1.0' encoding='UTF-8'?>
<me:env xmlns:me='http://salmon-protocol.org/ns/magic-env'>
  <me:data type='application/atom+xml'>
    PD94bWwgdmVyc2lvbj0nMS4wJyBlbmNvZGluZz0nVVRGLTgnPz4KPGVudHJ5IHhtbG5zPS
    dodHRwOi8vd3d3LnczLm9yZy8yMDA1L0F0b20nPgogIDxpZD50YWc6ZXhhbXBsZS5jb20s
    MjAwOTpjbXQtMC40NDc3NTcxODwvaWQ-ICAKICA8YXV0aG9yPjxuYW1lPnRlc3RAZXhhbX
    BsZS5jb208L25hbWU-PHVyaT5hY2N0OmpwYW56ZXJAZ29vZ2xlLmNvbTwvdXJpPjwvYXV0a
    G9yPgogIDx0aHI6aW4tcmVwbHktdG8geG1sbnM6dGhyPSdodHRwOi8vcHVybC5vcmcvc3l
    uZGljYXRpb24vdGhyZWFkLzEuMCcKICAgICAgcmVmPSd0YWc6YmxvZ2dlci5jb20sMTk5O
    TpibG9nLTg5MzU5MTM3NDMxMzMxMjczNy5wb3N0LTM4NjE2NjMyNTg1Mzg4NTc5NTQnPnR
    hZzpibG9nZ2VyLmNvbSwxOTk5OmJsb2ctODkzNTkxMzc0MzEzMzEyNzM3LnBvc3QtMzg2M
    TY2MzI1ODUzODg1Nzk1NAogIDwvdGhyOmluLXJlcGx5LXRvPgogIDxjb250ZW50PlNhbG1
    vbiBzd2ltIHVwc3RyZWFtITwvY29udGVudD4KICA8dGl0bGU-U2FsbW9uIHN3aW0gdXBzdH
    JlYW0hPC90aXRsZT4KICA8dXBkYXRlZD4yMDA5LTEyLTE4VDIwOjA0OjAzWjwvdXBkYXRl
    ZD4KPC9lbnRyeT4KICAgIA
  </me:data>
  <me:encoding>base64url</me:encoding>
  <me:alg>RSA-SHA256</me:alg>
  <me:sig key_id="4k8ikoyC2Xh+8BiIeQ+ob7Hcd2J7/Vj3uM61dy9iRMI=">
    EvGSD2vi8qYcveHnb-rrlok07qnCXjn8YSeCDDXlbhILSabgvNsPpbe76up8w63i2f
    WHvLKJzeGLKfyHg8ZomQ
  </me:sig>
</me:env>
MESPEC

is($mkey->size, 512, 'Key size');
is($mkey2->size, 512, 'Key size');

#warn $me->sig_base;

SKIP: {
  skip 'Specification example does not work yet', 5;
  ok($me->verify( $mkey ), 'MagicSignatures Spec Verification fail');
  ok($me->verify([$mkey, -compatible]), 'MagicSignatures Spec Verification');
  ok(!$me->verify( $mkey2 ), 'MagicSignatures Spec Verification fail');
  ok(!$me->verify([$mkey2, -compatible]), 'MagicSignatures Spec Verification');

  ok($mkey->verify(b64url_encode($me->data), $me->signature->{value}), 'MagicSignatures Spec Verification');
};

done_testing;
exit;




__END__
