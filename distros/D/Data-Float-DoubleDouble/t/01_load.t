use strict;
use warnings;

print "1..3\n";

eval {require Data::Float::DoubleDouble;};

if($@) {
  warn "\$\@: $@";
  print "not ok 1\n";
}
else {print "ok 1\n"}

if($Data::Float::DoubleDouble::VERSION eq '1.09') {
  print "ok 2\n";
}
else {
  warn "version: $Data::Float::DoubleDouble::VERSION\n";
  print "not ok 2\n";
}

my $end = Data::Float::DoubleDouble::_endianness();

if(defined($end)) {
  warn "\nEndianness: $end\n";
  print "ok 3\n";
}
else {
  print "not ok 3\n";
}
