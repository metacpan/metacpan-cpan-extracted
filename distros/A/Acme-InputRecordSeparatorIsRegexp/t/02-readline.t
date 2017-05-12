use Test::More;
use Acme::InputRecordSeparatorIsRegexp;
use strict;
use warnings;

my $i = 0;
my $yy = "";
for ('AAA'..'ZZZ') {
    $yy .= $i++ . ":" . $_;
}
open my $xx, '>', 't/test02.txt';
print $xx $yy;
close $xx;   # t/test02.txt is about 150K

my $pkg = 'Acme::IRSRegexp';

my $fh;
my $zz = "";
my $t = tie *{$fh = Symbol::gensym}, $pkg, '123|V45|[A-W]X67';
ok($t, 'tied filehandle -- works with alias Acme::IRSRegexp');
my $z = open $fh, '<', 't/test02.txt';
ok($z, 'open ok');
ok($t->{handle} && $t->{handle} ne *$fh, 'handle internals set after open');
ok(fileno($fh), '$fh has fileno');
my %le;
my $last;
while (<$fh>) {
    $zz .= $_;
    if ($last) {
	ok($last =~ /123$/ || $last =~ /V45$/ || $last =~ /X67$/,
	   'correct line ending')
	or diag length($last), $last;
    }
    $le{ substr($_, -3) }++;
    $last = $_;
}
ok($yy eq $zz, 'output equals expected input');
my $x = <$fh>;
ok(!defined($x), 'no read on exhausted filehandle');
$z = close $fh;
ok($z, 'CLOSE ok');
$x = <$fh>;
ok(!defined($x), 'no read on closed filehandle');
ok($le{'123'}, 'some lines end in 123');
ok($le{'V45'}, 'some lines end in V45');
ok($le{'X67'}, 'some lines end in X67');
ok($le{'V45'} > $le{'X67'}, 'V45 line endings are more common');

unlink 't/test02.txt';
done_testing();
