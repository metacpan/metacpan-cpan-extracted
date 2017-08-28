use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw(decode_docsis encode_docsis);

my $input = {
  eRouter => {
    InitializationMode         => 3,
    InitializationModeOverride => 1,
    ManagementServer           => {
      ACSOverride               => 0,
      ConnectionRequestPassword => "connpass",
      ConnectionRequestUsername => "connuser",
      EnableCWMP                => 1,
      Password                  => "testpass",
      URL                       => "Http://www.acs.de:7547",
      Username                  => "testuser",
    },
  }
};

my $bytes = encode_docsis($input);
is length $bytes, 120, 'encode_docsis';

my $output = decode_docsis($bytes);
delete $output->{$_} for qw( CmtsMic CmMic GenericTLV );
is_deeply $output, $input, 'decode_docsis';

done_testing;
