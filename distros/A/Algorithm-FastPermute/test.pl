BEGIN {
    $| = 1;
    print "1..13\n";
}
END {print "not ok 1\n" unless $loaded;}
use Algorithm::FastPermute;
$loaded = 1;
print "ok 1\n";

my @array = (1..9);
my $i = 0;
permute { ++$i } @array;

print ($i == 9*8*7*6*5*4*3*2*1 ? "ok 2\n" : "not ok 2\n");
print ($array[0] == 1 ? "ok 3\n" : "not ok 3\n");

@array = ();
$i = 0;
permute { ++$i } @array;
print ($i == 0 ? "ok 4\n" : "not ok 4\n");

@array = ('A'..'E');
my @foo;
permute { @foo = @array; } @array;

my $ok = ( join("", @foo) eq join("", reverse @array) );
print ($ok ? "ok 5\n" : "not ok 5\n");

tie @array, 'TieTest';
permute { $_ = "@array" } @array;
print (TieTest->c() == 600 ? "ok 6\n" : "not ok 6\t# ".TieTest->c()."\n");

untie @array;
@array = (qw/a r s e/);
$i = 0;
permute {eval {goto foo}; ++$i } @array;
if ($@ =~ /^Can't /) {
    print "ok 7\n";
} else {
    foo: print "not ok 7\t# $@\n";
}

print ($i == 24 ? "ok 8\n" : "not ok 8\n");

eval {
  permute {die} @array;
};
print ($@ =~ /^Died/ ? "ok 9\n" : "not ok 9\n");

eval { permute {return;} @array; };
print ($@ eq "" ? "ok 10\n" : "not ok 10\n");

eval { permute {while (1) {return}} @array; };
print ($@ eq "" ? "ok 11\n" : "not ok 11\n");

eval { permute {@array = ()} @array };
print ($@ =~ /^Modification of a read-only/ ?
	"ok 12\n" :
	"not ok 12\n");

if (!defined &Internals::SvREADONLY) {
    print "ok 13\t#skip No SvREADONLY\n";
}
else {
    my @array = (1..10);
    Internals::SvREADONLY(@array, 1);
    eval { permute {} @array };
    print ($@ =~ /^(Modification of|Can't permute) a read-only/ ?
	"ok 13\n" :
	"not ok 13\t# $@\n");
}

my $c;
package TieTest;
sub TIEARRAY  {bless []}
sub FETCHSIZE {5}
sub FETCH     { ++$c; $_[1]}
sub c         {$c}
