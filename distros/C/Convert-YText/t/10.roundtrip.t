BEGIN {
   binmode STDOUT, ':utf8';
   binmode STDERR, ':utf8';
}

use Test::More;
use strict;
use warnings;

require 't/corpus.pl';
my @list=corpus();

plan tests => 1+5*(scalar @list);

use_ok 'Convert::YText', qw(encode_ytext decode_ytext);

foreach my $addr (@list){
  is(decode_ytext(encode_ytext($addr)), $addr, "roundtrip: ".$addr);
}

{
  my $enc = Convert::YText->new(SPACE_CHAR=>'',
				SLASH_CHAR=>'');
  foreach my $addr (@list){
    is($enc->decode($enc->encode($addr)), $addr, "roundtrip 2: ".$addr);
  }
}

{
  my $enc = Convert::YText->new(ESCAPE_CHAR=>'@',
				SLASH_CHAR=>'');
  foreach my $addr (@list){
    is($enc->decode($enc->encode($addr)), $addr, "roundtrip 3: ".$addr);
  }
}

{
  my $enc = Convert::YText->new(ESCAPE_CHAR=>'z',
				DIGIT_STRING=>'0123456789!@#$%^&*()'.
				'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqr');

  foreach my $addr (@list){
    is($enc->decode($enc->encode($addr)), $addr, "roundtrip 4: ".$addr);
  }
}

{
  my $enc = Convert::YText->new(
				SPACE_CHAR=>'',
				SLASH_CHAR=>'',
			        DIGIT_STRING=>"ABCDEFGHIJKLMNOPQRSTUVWXYZ" .
                                 "abcdefghijklmnopqrstuvwxyz0123456789-.",
			      ESCAPE_CHAR=>'_',
			      EXTRA_CHARS=>'');

  foreach my $addr (@list){
    is($enc->decode($enc->encode($addr)), $addr, "roundtrip 5: ".$addr);
  }
}
