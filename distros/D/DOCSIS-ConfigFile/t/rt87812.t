use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw( decode_docsis encode_docsis );

my $input = {VendorSpecific => {id => '0x0011ee', options => [0x0a => '0x11']}};
my ($bytes, $output);

{
  $bytes = encode_docsis($input);
  is length $bytes, 48, 'encode_docsis';

  $output = decode_docsis($bytes);
  delete $output->{$_} for qw( CmtsMic CmMic GenericTLV );
  is_deeply $output, $input, 'decode_docsis';
}

done_testing;
