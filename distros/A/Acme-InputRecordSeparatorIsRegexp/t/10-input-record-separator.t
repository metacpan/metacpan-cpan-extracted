use Test::More;
use Acme::InputRecordSeparatorIsRegexp ':all';
use strict;
use warnings;

# handle the case where the length of a record is much larger
# than the size of the read buffer

my $yy = "";
my $xx = "AAA";
my $ii = 0;
while (length($xx) < 4) {
    for (1..500) {
        $yy .= $ii++ . ":" . $xx++
    }
    if (rand() < 0.333333) {
	$yy .= "\n";
    } elsif (rand() < 0.5) {
	$yy .= "\r";
    } else {
	$yy .= "\r\n";
    }
}
open my $f0, '>:raw', 't/test10.txt';
print $f0 $yy;
close $f0;

my $z = open my $fh, '<:raw:irs(\r\n|\r|\n)', "t/test10.txt";
ok($z && $fh, 'Acme::InputRecordSeparatorIsRegexp::open ok');
ok(tied(*$fh), 'return tied handle');

my $rs = (tied *$fh)->input_record_separator;
ok($rs eq "\r\n|\r|\n" || $rs eq '\r\n|\r|\n',
   'retrieved record separator from method');

$rs = input_record_separator(tied *$fh);
ok($rs eq "\r\n|\r|\n" || $rs eq '\r\n|\r|\n',
   'retrieved record separator from function and tied handle');

$rs = input_record_separator($fh);
ok($rs eq "\r\n|\r|\n" || $rs eq '\r\n|\r|\n',
   'retrieved record separator from function and handle');

$rs = input_record_separator(*$fh);
ok($rs eq "\r\n|\r|\n" || $rs eq '\r\n|\r|\n',
   'retrieved record separator from function and glob');

(tied *$fh)->input_record_separator("1|2|3");
$rs = input_record_separator(tied *$fh);
ok($rs eq '1|2|3', 'set input record separator from method tied handle');
input_record_separator(tied *$fh, "4|5|6");
$rs = input_record_separator(tied *$fh);
ok($rs eq '4|5|6', 'set input record separator from function tied handle');

($fh)->input_record_separator("7|8|9");
$rs = $fh->input_record_separator;
ok($rs eq "7|8|9", "set input record separator from method, handle");
input_record_separator($fh,"0|a|b");
$rs = input_record_separator($fh);
ok($rs eq "0|a|b", "set input record separator from function handle");

input_record_separator(*$fh,"c|d|ef");
$rs = input_record_separator(*$fh);
ok($rs eq "c|d|ef", "set input record separator from function glob");

open my $f1, "<", "t/test10.txt";
$rs = input_record_separator($f1);
ok($rs eq $/, 'get input_record_separator for regular file handle');
$rs = $f1->input_record_separator;
ok($rs eq $/, 'get IO::Handle::input_record_separator for regular file handle');
$rs = input_record_separator(*$f1);
ok($rs eq $/, 'get input_record_separator for regular glob');
ok(!tied *$f1, 'get input_record_separator does not tie handle');

input_record_separator($f1, qr/123|V45|[A-W]X67/);
$rs = input_record_separator($f1);
ok($rs =~ "123\|V45\|\[A-W\]X67",
   'set input_record_separator on regular file handle');
ok(tied *$f1, '... ties the handle');
autochomp($f1,0);
my @x1 = <$f1>;
my @x1A = grep /123$/, @x1;
my @x1B = grep /V45$/, @x1;
my @x1C = grep /X67$/, @x1;
ok(@x1A && @x1B && @x1C, "records have correct line endings");
ok(@x1-@x1A-@x1B-@x1C < 2, "all records have correct line endings")
    or diag 0+@x1,":",0+@x1A,"+",0+@x1B,"+",0+@x1C;
ok(close $f1, 'close handle ok');

open my $f2, "<", "t/test10.txt";
input_record_separator(*$f2, "k|lm|n");
$rs = input_record_separator(*$f2);
ok($rs eq "k|lm|n", 'set input_record_separator on regular glob');
ok(tied *$f2, "... ties the handle");
ok(close $f2, 'close handle ok');

open my $f3, '<', "t/test10.txt";
ok(!tied *$f3, "regular file handle is not tied");
$f3->input_record_separator("op|qr|s");
$rs = input_record_separator($f3);
ok($rs eq "op|qr|s", "IO::Handle::input_record_separator monkey patched");
ok(tied *$f3, 'set input_record_separator ties file handle');
close $f3;

open my $f4, "<:raw", "t/test10.txt";
ok(!tied *$f4, "regular file handle not tied");
$f4->input_record_separator( qr/\r\n|\r|\n/ );
$rs = $f4->input_record_separator;
ok($rs eq "\r\n|\r|\n" || $rs eq '\r\n|\r|\n' ||
   $rs eq '(?^:\r\n|\r|\n)' ||
   $rs eq '(?-xism:\r\n|\r|\n)', "record separator set")
    or diag $rs;

my (@tell, @seek);

push @tell, tell($f4);
my $correct = 0;
my $incorrect = 0;
while (<$f4>) {
    push @seek, $_;
    push @tell, tell($f4);
    if (@seek > 1) {
        if ($seek[-2] =~ /[\r\n]$/) {
            $correct++;
        } else {
            diag $seek[-2], "\n\n", $seek[-1],
                "\n\n", length($seek[-2]),"\t",length($seek[-1]);
            $incorrect++;
        }
    }
}
ok($correct > 0 && $incorrect == 0, 'all line endings correct');

while (@seek) {
    my $i = int(rand(@seek));
    my $t = splice @tell, $i, 1;
    my $s = splice @seek, $i, 1;
    seek($f4, $t, 0);
    my $u = readline($f4);

    is( $u, $s, "seek to $t returns same result");
}
close $f4;

unlink "t/test10.txt";

done_testing();
