use Test::More;
use Acme::InputRecordSeparatorIsRegexp;
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
open my $xx, '>', 't/test04.txt';
print $xx $yy;
close $xx;

my $fh = Acme::InputRecordSeparatorIsRegexp->open( 
    '\r\n|\r|\n', '<', 't/test04.txt',
    { maxrecsize => 100 } );
ok($fh, 'Acme::InputRecordSeparatorIsRegexp::open ok');
ok(tied(*$fh), 'return tied handle');

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

unlink "t/test04.txt";

done_testing();



