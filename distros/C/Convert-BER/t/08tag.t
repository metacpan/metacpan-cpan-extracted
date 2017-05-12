#!/usr/local/bin/perl

use Convert::BER qw(/BER/ ber_tag);

print "1..22\n";

my $i = 1;

sub test ($$) {
  unless ($_[0] == $_[1]) {
    printf "# expecting 0x%x, got 0x%x\nnot ",@_;
  }
  print "ok ",$i++,"\n";
}

test 0x00, ber_tag(0,0);
test 0x81, ber_tag(BER_CONTEXT,1);
test 0x42, ber_tag(BER_APPLICATION,2);
test 0x03, ber_tag(BER_UNIVERSAL,3);
test 0xC4, ber_tag(BER_PRIVATE,4);
test 0x05, ber_tag(BER_PRIMITIVE,5);
test 0x26, ber_tag(BER_CONSTRUCTOR,6);

test 0x261f, ber_tag(0,38);
test 0x279f, ber_tag(BER_CONTEXT,39);
test 0x285f, ber_tag(BER_APPLICATION,40);
test 0x291f, ber_tag(BER_UNIVERSAL,41);
test 0x2adf, ber_tag(BER_PRIVATE,42);
test 0x2b1f, ber_tag(BER_PRIMITIVE,43);
test 0x2c3f, ber_tag(BER_CONSTRUCTOR,44);

test 0x38821f, ber_tag(0,0x138);
test 0x39829f, ber_tag(BER_CONTEXT,0x139);
test 0x40825f, ber_tag(BER_APPLICATION,0x140);
test 0x41821f, ber_tag(BER_UNIVERSAL,0x141);
test 0x4282df, ber_tag(BER_PRIVATE,0x142);
test 0x43821f, ber_tag(BER_PRIMITIVE,0x143);
test 0x44823f, ber_tag(BER_CONSTRUCTOR,0x144);


test 0xa1, ber_tag(BER_CONTEXT | BER_CONSTRUCTOR,1);
