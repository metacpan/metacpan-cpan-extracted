use File::Compare;

my $result;
my $rundir = "script\\";

print "1..2\n";

#print "running unifdef+ -D FOO -D D1=1 -D D2=2 -DX=x -U BAR -U U1 -D E= -I t\\test1.c -O t\\test1.c.out\n";
$result = system ("perl", $rundir."unifdef+.pl", "-D","FOO","-D","D1=1","-D","-D2=2","-DX=x", "-U", "BAR", "-UU1", "-DE=", "-I","t\\test1.c","-O","t\\test1.c.out");
#die if $result != 1;
die "not ok 1\nError: test output for C file differs from expected output!\n" if compare("t\\test1.c.out","t\\test1.c.expectedout") != 0;
print "ok 1\n";

#print "running unifdef+ -D FOO -D D1=1 -D D2=2 -DX=x -U BAR -U U1 -D E= -I t\\test2.mak -O t\\test2.mak.out\n";
$result = system ("perl", $rundir."unifdef+.pl", "-D","FOO","-D","D1=1","-D","-D2=2","-DX=x", "-U", "BAR", "-UU1", "-DE=", "-I","t\\test2.mak","-O","t\\test2.mak.out");
#die if $result != 1;
die "not ok 2\nError: test output for makefile differs from expected output!" if compare("t\\test2.mak.out","t\\test2.maK.expectedout") != 0;
print "ok 2\n";

# TBD: add test for Kconfig
# TBD: add test for return values

print "\n\nTEST PASSED\n\n";

0;