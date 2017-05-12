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
open my $xx, '>', 't/test09.txt';
print $xx $yy;
close $xx;

my $fh = Acme::InputRecordSeparatorIsRegexp->open( 
    '\r\n|\r|\n', '<', 't/test09.txt',
    { maxrecsize => 100, autochomp => 1 } );
ok($fh, 'Acme::InputRecordSeparatorIsRegexp::open ok');
ok(tied(*$fh), 'return tied handle');

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
