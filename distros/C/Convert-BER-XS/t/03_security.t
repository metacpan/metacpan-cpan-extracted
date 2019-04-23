BEGIN { $| = 1; print "1..807\n"; }

use common::sense;
use Convert::BER::XS ':all';

our $test;
sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, " # $_[1]\n";
}

my $uvsize = length pack "J", 0;

for (1..4) {
   for my $bit (0 .. 199) {
      # I wrote this at 4 in the morning. I am sure there must be a more
      # elegant way than this shit.
      my $c = "1" . join "", map int 2 * rand, 1 .. $bit;
      $c = "0$c" while (length $c) % 7;
      $c = "1" . join "1", unpack "(a7)*", $c;
      substr $c, -8, 1, "0";
      $c = "\x06" . chr ((length $c) / 8) . pack "B*", $c;

      my $ok = eval { ber_decode $c } || $@ !~ "overflow";

      ok ($ok ^ ($bit >= $uvsize * 8), unpack "H*", $c);

      #   my $asn = "\x02" . (chr 1 + @c) . pack "B*", join "1"
   }
}

ok ( eval { ber_decode pack "CCa*a*", 2, $uvsize    , "\x00\x80", "\x00" x ($uvsize - 2) });
ok ( eval { ber_decode pack "CCa*a*", 2, $uvsize + 1, "\x00\x80", "\x00" x ($uvsize - 1) });
ok ( eval { ber_decode pack "CCa*a*", 2, $uvsize    , "\x01\x00", "\x00" x ($uvsize - 2) });
ok (!eval { ber_decode pack "CCa*a*", 2, $uvsize + 1, "\x01\x00", "\x00" x ($uvsize - 1) });
ok ( eval { ber_decode pack "CCa*a*", 2, $uvsize    , "\x80\x00", "\x00" x ($uvsize - 2) });
ok (!eval { ber_decode pack "CCa*a*", 2, $uvsize + 1, "\x80\x00", "\x00" x ($uvsize - 1) });

# would be nice, if, but not yet
# 2.25.24197857203266734864793317670504947440
ok (!eval { ber_decode pack"H*","061369A4B4AB9E93ABE6FBE0929A95CF89D5F3BD70" });
