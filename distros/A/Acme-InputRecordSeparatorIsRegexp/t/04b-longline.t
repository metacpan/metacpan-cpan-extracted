use Test::More;
use Acme::InputRecordSeparatorIsRegexp 'binmode';
use strict;
use warnings;

# handle the case where the length of a record is much larger
# than the size of the read buffer

if ($] < 5.010000) {
    diag "readline on this package is sloooow for Perl $]. ",
        "Skipping this set of tests which is a near duplicate of ",
        "another set of tests.";
    ok(1, "# skip $0 tests on Perl $]");
    done_testing();
    exit;
}

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
open my $xx, '>:raw', 't/test04b.txt';
print $xx $yy;
close $xx;

my $z = open(my $fh, '<:raw', "t/test04b.txt");
ok(!tied(*$fh), 'builtin open does not tie filehandle');
ok($z, 'builtin open ok');
$z = binmode $fh, ':irs(\r\n|\r|\n)';
ok($z, 'package binmode ok');
ok(tied(*$fh), 'handle is tied after binmode');
(tied *$fh)->{maxrecsize} = 100;

my (@tell, @seek);

push @tell, tell($fh);
while (<$fh>) {
    push @seek, $_;
    push @tell, tell($fh);
    if (@seek > 1) {
	ok( $seek[-2] =~ /[\r\n]$/, 'correct line ending' )
	    or diag $seek[-2], "\n\n", $seek[-1],
	    "\n\n", length($seek[-2]),"\t",length($seek[-1]);
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

unlink "t/test04b.txt";

done_testing();



