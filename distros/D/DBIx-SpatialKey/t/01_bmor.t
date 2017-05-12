BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use DBIx::SpatialKey;
$loaded = 1;
print "ok 1\n";

$key = new DBIx::SpatialKey 'binary_morton', 10, 20, 40, 80, 160, 1e6;
print "ok 2\n";

sub key {
   my $n = shift;
   my $a = shift;
   my $b = unpack "H*", $key->index(@_);
   if ($a eq $b) {
      print "ok $n\n";
   } else {
      print "not ok $n # $a != $b\n";
   }
}

key(3, "00000000000000", 0, 0, 0, 0,  0,  0);
key(4, "fc1fc100809000",10,20,40,80,160,1e6);
key(5, "120096b7407d00", 4, 3, 1,79, 60,500);
key(6, "00050c34600000", 0, 4, 5,29, 10,  0);

for $a (1,4,8) {
   for $b (4,10,15) {
      for $c (0,39) {
         for $d (30,70) {
            for $e (158,159) {
               for $f (1e1, 1e2, 1e3, 1e4, 1e5) {
                  $k = $key->index($a,$b,$c,$d,$e,$f);
                  ($A,$B,$C,$D,$E,$F) = $key->unpack($k);
                  $same += "$a $b $c $d $e $f" eq "$A $B $C $D $E $F";
               }
            }
         }
      }
   }
}

print $same==360 ? "" : "not ", "ok 7 # $same fine compares\n";


