BEGIN { $| = 1; print "1..4\n"; }

use Convert::Scalar ':refcnt';

no bytes;

my $x = 5;

print refcnt($x) == 1 ? "" : "not ", "ok 1\n";
print refcnt($x,2) == 1 ? "" : "not ", "ok 2\n";
refcnt_inc_rv \$x;
print refcnt_rv(\$x,2) == 4 ? "" : "not ", "ok 3\n";
refcnt_inc $x;
refcnt_inc_rv \$x;
refcnt_dec $x;
print refcnt($x) == 2 ? "" : "not ", "ok 4\n";
refcnt_dec $x;
