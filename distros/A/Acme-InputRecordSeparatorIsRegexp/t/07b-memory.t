use Test::More;
use Acme::InputRecordSeparatorIsRegexp 'binmode';
use strict;
use warnings;

if ($] < 5.010000) {
    diag "readline on this package is sloooow for Perl $]. ",
        "Skipping this set of tests which is a near duplicate of ",
        "another set of tests.";
    ok(1, "# skip $0 tests on Perl $]");
    done_testing();
    exit;
}

my $yy = "";
my $i = 0;
for ('AAA'..'ZZZ') {
    $yy .= sprintf "%d:%s", $i++, $_;
}

my $z = open(my $fh, "<", \$yy);
ok($z && $fh, 'builtin open ok to memory handle');
ok(!tied($fh), 'builtin open does not tie filehandle');
$z = binmode $fh, ':irs(1.3|T.4|E....D)';
ok($z, 'package binmode ok');
ok(tied(*$fh), 'return tied handle');

my (@tell, @seek);

push @tell, tell($fh);
while (<$fh>) {
    push @seek, $_;
    push @tell, tell($fh);
    if (@seek > 1) {
	ok( $seek[-2] =~ /1.3$/ || $seek[-2] =~ /T.4$/ || 
	    $seek[-2] =~ /E....D$/, 'correct line ending' )
	    or diag $seek[-2], "\n\n", $seek[-1],
	    "\n\n", length($seek[-2]),"\t",length($seek[-1]);
    }
}

while (@seek) {
    my $i = int(rand(@seek));
    my $t = splice @tell, $i, 1;
    my $s = splice @seek, $i, 1;
    seek($fh, $t, 0);
    my $u = readline($fh);

    is( $u, $s, "seek to $t returns same result");
}

done_testing();
