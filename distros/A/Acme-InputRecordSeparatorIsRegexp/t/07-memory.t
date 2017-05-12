use Test::More;
use Acme::InputRecordSeparatorIsRegexp;
use strict;
use warnings;

my $yy = "";
my $i = 0;
for ('AAA'..'ZZZ') {
    $yy .= sprintf "%d:%s", $i++, $_;
}

my $fh = Acme::InputRecordSeparatorIsRegexp->open( 
    '1.3|T.4|E....D', '<', \$yy);
ok($fh, 'Acme::InputRecordSeparatorIsRegexp::open ok to memory handle');
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



