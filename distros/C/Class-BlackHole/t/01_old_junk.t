
# Time-stamp: "2004-12-29 18:53:40 AST"


BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::BlackHole;
$loaded = 1;
print "ok 1\n";


sub Test123::foo { return 456 }
@Test123::ISA = ('Class::BlackHole');

print( (Test123->foo == 456) ? "ok 2\n" : "fail 2!\n");
print( defined(Test123->fneh) ? "fail 3!\n" : "ok 3\n");

