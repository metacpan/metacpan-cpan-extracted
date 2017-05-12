use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw( decode_docsis encode_docsis );

my $input = {
  'eRouter' => {
    'ManagementServer' => {
      'EnableCWMP' => 1,
      'URL' => 'http://tr069.example.com/',
      'Username' => 'goodUser',
      'Password' => 'passwordsAreGood',
      'ConnectionRequestUsername' => 'remoteUser',
      'ConnectionRequestPassword' => 'securePasswordsAreBetter',
      'ACSOverride' => 1,
    }
  }
};

my ($bytes, $output);

{
  $bytes = encode_docsis($input);
  is length $bytes, 144, 'encode_docsis';

  $output = decode_docsis($bytes);
  delete $output->{$_} for qw( CmtsMic CmMic GenericTLV );
  is_deeply $output, $input, 'decode_docsis';  
}

done_testing;
