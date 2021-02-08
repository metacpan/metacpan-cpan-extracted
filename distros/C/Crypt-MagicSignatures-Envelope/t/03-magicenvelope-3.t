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

my $test_msg = 'Not really Atom'; # Tm90IHJlYWxseSBBdG9t
my $test_data_type = 'application/atom+xml';

my $mkey_string =  '
  RSA.
  mVgY8RN6URBTstndvmUUPb4UZTdwvw
  mddSKE5z_jvKUEK6yk1u3rrC9yN8k6
  FilGj9K0eeUPe2hf4Pj-5CmHww==.
  AQAB.
  Lgy_yL3hsLBngkFdDw1Jy9TmSRMiH6
  yihYetQ8jy-jZXdsZXd8V5ub3kuBHH
  k4M39i3TduIkcrjcsiWQb77D8Q==';

my $me = Crypt::MagicSignatures::Envelope->new(
  data => 'Some arbitrary string.',
  data_type => 'text/plain'
);

is($me->signature_base,
   'U29tZSBhcmJpdHJhcnkgc3RyaW5nLg.'.
   'dGV4dC9wbGFpbg==.'.
   'YmFzZTY0dXJs.'.
   'UlNBLVNIQTI1Ng==', 'Base String');

ok(!$me->signed, 'Envelope not signed');
ok(!$me->signature, 'Envelope has no signature');

$me->sign($mkey_string);
ok($me->signature, 'Envelope has signatures');

ok($me->signed, 'Envelope signed');

my $mkey = Crypt::MagicSignatures::Key->new(<<'MKEY');
  RSA.
  mVgY8RN6URBTstndvmUUPb4UZTdwvw
  mddSKE5z_jvKUEK6yk1u3rrC9yN8k6
  FilGj9K0eeUPe2hf4Pj-5CmHww==.
  AQAB
MKEY

ok($me->verify($mkey), 'MagicEnvelope Verification');

my $xml = $me->to_xml;
$xml =~ s/\s//gm;

is ($xml, '<?xmlversion="1.0"encoding="U'.
      'TF-8"standalone="yes"?><me:envxml'.
      'ns:me="http://salmon-protocol.org'.
      '/ns/magic-env"><me:datatype="text'.
      '/plain">U29tZSBhcmJpdHJhcnkgc3Rya'.
      'W5nLg</me:data><me:encoding>base6'.
      '4url</me:encoding><me:alg>RSA-SHA'.
      '256</me:alg><me:sig>UFF5N0tlVEJWU'.
      'mY3dWZQUlhUeFZsaExSU0dkLUZ4cS14Vm'.
      '9TbUJBYU1tNVVOUDJmNnZUa0dDYklfTUh'.
      'yNm0xRUJfdllNYmxrbUtCMm40R09YVFdQ'.
      'M3c9PQ==</me:sig></me:env>',
  'XML Generation');

ok(my $compact = $me->to_compact, 'Compact serialization');

is ($me->to_compact,
  '.UFF5N0tlVEJWUmY3dWZQUlhUeFZsaExSU0dk'.
  'LUZ4cS14Vm9TbUJBYU1tNVVOUDJmNnZUa0dDY'.
  'klfTUhyNm0xRUJfdllNYmxrbUtCMm40R09YVF'.
  'dQM3c9PQ==.U29tZSBhcmJpdHJhcnkgc3RyaW'.
  '5nLg.dGV4dC9wbGFpbg==.YmFzZTY0dXJs.Ul'.
  'NBLVNIQTI1Ng==',
  'Compact serialization');

done_testing
__END__
