BEGIN { $ENV{DOCSIS_CAN_TRANSLATE_OID} = 0; }
use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw(encode_docsis decode_docsis);

my $bytes = encode_docsis({MtaConfigDelimiter => 1}, {mta_algorithm => ''});

is_deeply(decode_docsis($bytes), {MtaConfigDelimiter => [1, 255]}, 'mta_algorithm',);

$bytes = encode_docsis({MtaConfigDelimiter => 255}, {mta_algorithm => 'md5'});

is_deeply(
  decode_docsis($bytes),
  {
    MtaConfigDelimiter => [1, 255],
    SnmpMibObject      =>
      {oid => '1.3.6.1.4.1.4491.2.2.1.1.2.7.0', STRING => 'w%d8%b8y%b3%1b%cf%0a%ac"%14%e1%99-1%d5'}
  },
  'md5',
);

$bytes = encode_docsis({MtaConfigDelimiter => 255}, {mta_algorithm => 'sha1'});

is_deeply(
  decode_docsis($bytes),
  {
    MtaConfigDelimiter => [1, 255],
    SnmpMibObject      => {
      oid    => '1.3.6.1.4.1.4491.2.2.1.1.2.7.0',
      STRING => 'T%df~f%89X%ee%83U%08%e4%f4%975%10[%e9%ae%25b'
    }
  },
  'sha1',
);

done_testing;
