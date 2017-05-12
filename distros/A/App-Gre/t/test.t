use Test::More;
use warnings;

sub runcmd {
    my ($cmd) = @_;
    system "$cmd >../stdout 2>../stderr";
    $EXITCODE = $? >> 8;
    if (open my $fh, "<", "../stdout") {
        $STDOUT = do {local $/; <$fh>};
        close $fh;
    }
    if (open my $fh, "<", "../stderr") {
        $STDERR = do {local $/; <$fh>};
        close $fh;
    }
    if ($ENV{DEBUG}) {
        print "STDOUT: $STDOUT\n";
        print "STDERR: $STDERR\n";
        print "EXITCODE: $EXITCODE\n";
    }
    END {system "rm ../stdout ../stderr"}
}

chdir "t/data";
$ENV{PATH} = "../../bin:$ENV{PATH}";

runcmd("gre apple");
my $e = qr{(?:\e\[.*?[mK])*};
my $test = $STDOUT =~ m{
    ^${e}./fruits.txt${e}\n
    ${e}1${e}:${e}apple${e}\n
    ${e}3${e}:pine${e}apple${e}\n$
}x;
ok $test, "found the apples";

runcmd("gre");
my $out = join "", map "$_\n", sort split /\n/, $STDOUT;
my $exp = <<EOSTR;
./dir1/bar.js
./dir1/foo.html
./dir1/simpsons.txt
./fruits.txt
./pokemon.mon
EOSTR
is $out, $exp, "file listing recursive and textonly";

runcmd("gre -ext=txt -no=simpsons");
$test = $STDOUT eq <<EOSTR;
./fruits.txt
EOSTR
ok $test, "file filtering";

runcmd("gre -html -js");
$out = join "", map "$_\n", sort split /\n/, $STDOUT;
$exp = <<EOSTR;
./dir1/bar.js
./dir1/foo.html
EOSTR
is $out, $exp, "file filtering with combos";

runcmd("gre -X");
$out = join "", map "$_\n", sort split /\n/, $STDOUT;
$exp = <<EOSTR;
./dir1/bar.js
./dir1/foo.html
./dir1/simpsons.txt
./fruits.txt
./fruits.txt.gz
./pokemon.mon
./pokemon.tar.gz
EOSTR
is $out, $exp, "disable builtin filters";

runcmd("gre 'krusty the clown' -i -k");
$test = $STDOUT eq <<EOSTR;
./dir1/simpsons.txt
10:Krusty the Clown
EOSTR
ok $test, "ignore case";

runcmd("gre -help");
$test = $STDOUT =~ /Usage:/;
ok $test, "help";

runcmd("gre -man");
$test = $STDOUT =~ /My own take on grep\/ack/;
ok $test, "man";

runcmd("gre Krusty -A -k");
$test = $STDOUT eq <<EOSTR;
./dir1/simpsons.txt
10:Krusty the Clown
11:The Happy Little Elves
12:Patty Bouvier
EOSTR
ok $test, "after context";

runcmd("gre Krusty -B -k");
$test = $STDOUT eq <<EOSTR;
./dir1/simpsons.txt
8:Grampa Abraham Simpson
9:Itchy & Scratchy
10:Krusty the Clown
EOSTR
ok $test, "before context";

runcmd("gre Krusty -C -k");
$test = $STDOUT eq <<EOSTR;
./dir1/simpsons.txt
8:Grampa Abraham Simpson
9:Itchy & Scratchy
10:Krusty the Clown
11:The Happy Little Elves
12:Patty Bouvier
EOSTR
ok $test, "context";

runcmd("gre -combos");
$test = $STDOUT =~ /^-html\b/m;
ok $test, "combos";

runcmd("gre Krusty -d1");
$test = $STDOUT eq "";
ok $test, "no recursion";

runcmd("gre -f pokemon.mon Krusty");
$test = $STDOUT eq "";
ok $test, "file option";

runcmd("gre -zzz");
$test = $STDOUT eq "" && $STDERR =~ /Invalid argument/;
ok $test, "unknown option";

runcmd("gre -l Krusty");
$test = $STDOUT eq <<EOSTR;
./dir1/simpsons.txt
EOSTR
ok $test, "list matches option";

runcmd("gre -L Krusty");
$out = join "", map "$_\n", sort split /\n/, $STDOUT;
$exp = <<EOSTR;
./dir1/bar.js
./dir1/foo.html
./fruits.txt
./pokemon.mon
EOSTR
ok $test, "list nonmatches option";

runcmd("gre -m 'Char.*?zard' -k");
$test = $STDOUT eq <<EOSTR;
./pokemon.mon
Charmander
Charmeleon
Charizard
EOSTR
ok $test, "multiline";

runcmd("gre zard -o -k");
$test = $STDOUT eq <<EOSTR;
./pokemon.mon
6:zard
EOSTR
ok $test, "only";

runcmd("gre zard -p='**\$&**' -k");
$test = $STDOUT eq <<EOSTR;
./pokemon.mon
6:**zard**
EOSTR
ok $test, "print";

runcmd("gre -passthru zard pokemon.mon");
$test = $STDOUT =~ /Chari${e}zard${e}\nSquirtle\n/m;
ok $test, "passthru";

runcmd("gre apple -t");
$out = join "", map "$_\n", sort split /\n/, $STDOUT;
$exp = <<EOSTR;
./dir1/bar.js
./dir1/foo.html
./dir1/simpsons.txt
./fruits.txt
./pokemon.mon
EOSTR
ok $test, "print files ignore regexp";

runcmd("gre apple fruits.txt -v -k");
$test = $STDOUT eq <<EOSTR;
fruits.txt
2:grape
4:banana
5:pear
6:cherries
7:peach
8:orange
9:grapefruit
10:jackfruit
11:persimmon
EOSTR
ok $test, "invert match";

runcmd("gre apple fruits.txt -y1 -k");
$test = $STDOUT eq <<EOSTR;
fruits.txt
1:apple
3:pineapple
EOSTR
ok $test, "style 1";

runcmd("gre apple fruits.txt -y2 -k");
$test = $STDOUT eq <<EOSTR;
fruits.txt:1:apple
fruits.txt:3:pineapple
EOSTR
ok $test, "style 2";

runcmd("gre apple fruits.txt -y3 -k");
$test = $STDOUT eq <<EOSTR;
apple
pineapple
EOSTR
ok $test, "style 3";

done_testing;

