use warnings;
use strict;
use DOCSIS::ConfigFile 'encode_docsis';
use Test::More;

my ($bytes, $input, $output);

$input  = {CpeMacAddress => 'aabbccddeeff'};
$bytes  = encode_docsis($input);
$output = decode_docsis($bytes);
is_deeply $input, $output, 'CpeMacAddress';

$input
  = {MfgCVCData =>
    '0x3082038130820269a003020102021025e506f4870a8a20792a2450f4a3c5a6300d06092a864886f70d0101050500306f310b3009060355040613024245311f301d060355040a131674436f6d4c616273202d266696361746530820122300d06092a864886f70d01010105000382010f003082010a0282010100c'
  };
$bytes  = encode_docsis($input);
$output = decode_docsis($bytes);
is_deeply $input, $output, 'MfgCVCData';

$input  = {SwUpgradeFilename => 'bootfile.bin'};
$bytes  = encode_docsis($input);
$output = decode_docsis($bytes);
is_deeply $input, $output, 'SwUpgradeFilename';

$input  = {SwUpgradeServer => '1.2.3.4'};
$bytes  = encode_docsis($input);
$output = decode_docsis($bytes);
is_deeply $input, $output, 'SwUpgradeServer';

done_testing;

sub decode_docsis {
  my $output = DOCSIS::ConfigFile::decode_docsis($_[0]);
  delete $output->{$_} for qw(CmtsMic CmMic GenericTLV);
  $output;
}
