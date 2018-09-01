use Test::More;
use Acme::InputRecordSeparatorIsRegexp 'open','autochomp';
use strict;
use warnings;

# handle the case where the length of a record is much larger
# than the size of the read buffer

my $yy = "";
for (1..20) {
    $yy .= "x" x 9999;
    if (rand() < 0.333333) {
	$yy .= "\n";
    } elsif (rand() < 0.5) {
	$yy .= "\r";
    } else {
	$yy .= "\r\n";
    }
}
open my $xx, '>:raw', 't/test09.txt';
print $xx $yy;
close $xx;

my $z = open my $fh, '<:raw:irs(\r\n|\r|\n)', "t/test09.txt";
ok($z && $fh, 'Acme::InputRecordSeparatorIsRegexp::open ok');
ok(tied(*$fh), 'return tied handle');

ok(!(tied *$fh)->autochomp(), 'autochomp is off');
ok(!autochomp(tied *$fh), 'autochomp get function');
ok(!autochomp($fh), 'autochomp get function');

(tied *$fh)->autochomp(1);
ok((tied *$fh)->autochomp(), 'autochomp is on');

autochomp(tied *$fh, 0);
ok(!autochomp(tied $fh), 'autochomp set function');
autochomp($fh, 1);
ok(autochomp(tied *$fh), 'autochomp set function');
ok(autochomp($fh), 'autochomp set function');
ok(autochomp(*$fh), 'autochomp set function');

open my $f1, "<", "t/test09.txt";
my $line = <$f1>;
ok($line =~ m<$/$>, 'line from regular fh contains line ending');
ok(!tied *$f1, "f1 is regular filehandle");
my $z1 = autochomp($f1);
ok(defined($z1) && $z1==0, 'can call autochomp on regular filehandle');
ok(!tied *$f1, "f1 is still regular fh after get autochomp");
$line = <$f1>;
ok($line =~ m<$/$>, 'line from regular fh still contains line ending');
my $z2 = autochomp($f1,1);
ok(defined($z2) && $z2==0, 'autochomp called on regular filehandle');
ok(tied *$f1, "set autochomp on regular fh ties it to this package");
$line = <$f1>;
ok($line !~ m<$/$>, 'line from autochomped fh does not contain line ending');






my (@tell, @seek);

push @tell, tell($fh);
while (<$fh>) {
    push @seek, $_;
    push @tell, tell($fh);
    if (@seek > 1) {
	ok( $seek[-2] !~ /[\r\n]$/, 'line ending was chomped' )
	    or diag $seek[-2], "\n\n", $seek[-1],
	    "\n\n", length($seek[-2]),"\t",length($seek[-1]);
	ok( length($seek[-2]) == 9999, 'autochomped line length' );

	my $x = $seek[-2];
	my $u = tied(*$fh)->chomp($x);
	ok($u==0, 'chomp return value for already chomped');
	ok($x eq $seek[-2], 'already chomped line not changed');
    }
}

# don't close

while (@seek) {
    my $i = int(rand(@seek));
    my $t = splice @tell, $i, 1;
    my $s = splice @seek, $i, 1;
    seek($fh, $t, 0);
    my $u = readline($fh);

    is( $u, $s, "seek to $t returns same result");
}

unlink "t/test09.txt";

done_testing();
