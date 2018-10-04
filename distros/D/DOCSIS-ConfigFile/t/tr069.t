use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw(decode_docsis encode_docsis);

my $input = {
  eRouter => {
    ManagementServer => {
      ACSOverride               => 1,
      ConnectionRequestPassword => 'securePasswordsAreBetter',
      ConnectionRequestUsername => 'remoteUser',
      EnableCWMP                => 1,
      Password                  => 'passwordsAreGood',
      URL                       => 'http://tr069.example.com/',
      Username                  => 'goodUser',
    }
  }
};

my $bytes = encode_docsis $input;
is length $bytes, 144, 'encode_docsis';

my $output = decode_docsis($bytes);
delete $output->{$_} for qw(CmtsMic CmMic GenericTLV);
is_deeply $output, $input, 'decode_docsis';

done_testing;
