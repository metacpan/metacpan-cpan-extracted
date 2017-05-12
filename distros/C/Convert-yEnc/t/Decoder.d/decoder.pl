use strict;
use Convert::yEnc::Decoder;

my $dir     = shift;
my $decoder = new Convert::yEnc::Decoder $dir;
   $decoder->decode;
