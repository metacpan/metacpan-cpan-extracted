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


open my $xx, '>', 't/test03b.txt';
my $i = 0;
for ('AAA'..'ZZZ') {
    print $xx $i++,":",$_;
}
close $xx;   # t/test03b.txt is about 150K

$! = 0;
my $z;

$z = open my $fh, '<', "t/test03b.txt";
ok($z, 'builtin open ok');
ok(!tied(*$fh), 'file handle is not tied yet');
$z = binmode $fh, ":irs(1.3|T.4|E....D)";
ok($z, 'Acme::IRSasRegeexp binmode ok');
ok(tied(*$fh), 'handle is tied after binmode');

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

# don't close

while (@seek) {
    my $i = int(rand(@seek));
    my $t = splice @tell, $i, 1;
    my $s = splice @seek, $i, 1;
    seek($fh, $t, 0);
    my $u = readline($fh);

    is( $u, $s, "seek to $t returns same result");
}

unlink "t/test03b.txt";

done_testing();



