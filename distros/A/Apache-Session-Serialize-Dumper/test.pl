# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::Session::Serialize::Dumper;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $session = { data => { array => [1,2,3], scalar=>5, hash=>{id1=>1,id2=>2} } };

eval {
  Apache::Session::Serialize::Dumper::serialize($session);
  print "ok 2\n";
};
print ("not ok 2: $@\n") if $@;

eval {
  Apache::Session::Serialize::Dumper::unserialize($session);
  print "ok 3\n";
};
print "not ok 2: $@\n" if $@;

my $d = $session->{data};
if ( ref($d) eq 'HASH'
	  && ref($d->{array}) eq 'ARRAY'
	  && !ref($d->{scalar})
	  && ref($d->{hash}) eq 'HASH') {
  print "ok 4\n";
} else {
  print "not ok 4: level 1 structure\n";
}

$d = $session->{data}->{array};
if ( $d->[0]==1 && $d->[1]==2 && $d->[2]==3 ) {
  print "ok 5\n";
} else {
  print "not ok 5: array values\n";
}

if ( $session->{data}->{scalar}!=5 ) {
  print "not ok 6: scalar\n";
} else {
  print "ok 6\n";
}

$d = $session->{data}->{hash};
if ( $d->{id1}==1 && $d->{id2}==2) {
  print "ok 7\n";
} else {
  print "not ok 7: hash values\n";
}
