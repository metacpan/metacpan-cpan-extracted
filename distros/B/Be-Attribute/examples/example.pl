#!/boot/home/config/bin/perl

use Be::Attribute;

$fn = $ARGV[0];
die "gimme filename, bozo" unless ($fn ne undef && -f $fn);
$fnnode = Be::Attribute::GetBNode($fn);
@y = Be::Attribute::ListAttrs($fnnode);
for $i (@y) {
   print "$i: ";
   print Be::Attribute::ReadAttr($fnnode, $i);
   print "\n";
}

