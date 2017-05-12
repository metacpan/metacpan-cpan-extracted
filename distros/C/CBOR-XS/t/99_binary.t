BEGIN { $| = 1; print "1..6144\n"; }

use CBOR::XS;

our $test;
sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, " - $_[1]\n";
}

sub test($) {
   my $js;

   $js = CBOR::XS->new->shrink->encode ([$_[0]]);
   ok ($_[0] eq ((decode_cbor $js)->[0]), 0);
   $js = CBOR::XS->new->encode ([$_[0]]);
   ok ($_[0] eq (CBOR::XS->new->shrink->decode($js))->[0], 1);
}

srand 0; # doesn't help too much, but its at least more deterministic

for (1..768) {
   test join "", map chr ($_ & 255), 0..$_;
   test join "", map chr rand 255, 0..$_;
   test join "", map chr ($_ * 97 & ~0x4000), 0..$_;
   test join "", map chr (rand (2**20) & ~0x800), 0..$_;
}

