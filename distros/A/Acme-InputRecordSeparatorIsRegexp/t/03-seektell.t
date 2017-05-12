use Test::More;
use Acme::InputRecordSeparatorIsRegexp;
use strict;
use warnings;

open my $xx, '>', 't/test03.txt';
my $i = 0;
for ('AAA'..'ZZZ') {
    print $xx $i++,":",$_;
}
close $xx;   # t/test03.txt is about 150K

$! = 0;
my $xh = Acme::InputRecordSeparatorIsRegexp->open( qr/qwer/, '<', 't/bogus-file.qwer' );
ok(!$xh, 'open fail for bogus file');
ok($!, '$! set on bad open');

my $fh = Acme::InputRecordSeparatorIsRegexp->open( 
    qr/1.3|T.4|E....D/s, '<', 't/test03.txt' );
ok($fh, 'Acme::InputRecordSeparatorIsRegexp::open ok');
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

# don't close

while (@seek) {
    my $i = int(rand(@seek));
    my $t = splice @tell, $i, 1;
    my $s = splice @seek, $i, 1;
    seek($fh, $t, 0);
    my $u = readline($fh);

    is( $u, $s, "seek to $t returns same result");
}

unlink "t/test03.txt";

done_testing();



