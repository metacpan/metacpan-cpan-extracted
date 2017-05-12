use Test::More;
use Acme::InputRecordSeparatorIsRegexp;
use strict;
use warnings;

# read and write access to same file

my $fh = Symbol::gensym;
tie *$fh, 'Acme::InputRecordSeparatorIsRegexp', '\r\n|[\r\n]';
ok(tied(*$fh), 'tie ok');

my $z = open $fh, '+>', 't/test05.txt';
ok($z, 'open +> ok') or diag $!;

# binmode on this filehandle will make these tests work on MSWin32
$z = binmode $fh;
ok($z, 'binmode ok');


for (1..4) {
    $z = print $fh "x" x 99, "\r";
    ok($z, "print x $_ ok");
    print $fh "y" x 99, "\n";
    ok($z, "print y $_ ok");
    print $fh "z" x 98, "\r\n";
    ok($z, "print z $_ ok");
}
ok(tell($fh) == 4 * 300, "tell correct after print statements");
$z = seek $fh, 100, 0;
ok($z, 'seek said it was successful');
ok(tell($fh) == 100, 'tell/seek consistent');
my $c = getc($fh);
ok($c eq 'y', 'found "y" as expected at 100 position');
ok(tell($fh) == 101, "tell=101 after read 1 char");
my $x = <$fh>;
ok(defined($x), "readline ok");
ok(length($x) == 99, "read line has correct length");
ok($x =~ /y\n$/, "read line has expected line ending");
ok(tell($fh) == 200, 'got tell after readline');

my $newmsg = "A new message at pos 200\n";
$z = print $fh $newmsg;
ok($z, 'print ok');
$x = <$fh>;
ok(defined($x), 'readline after print ok');
ok(length($x) == 100 - length($newmsg), 'expected line length')
    or diag length($x)," ",$x;
ok($x =~ /z\r\n/, 'expected line ending');

$z = seek($fh,0,0);
ok($z, 'seek 0,0 ok');
ok(tell($fh) == 0, 'seek 0 0 worked');
$x = <$fh>;
ok($x =~ /xxxx\r$/, 'read line correctly');
ok(tell($fh) == 100, 'tell correct after 1 readline');
$x = <$fh>;
ok($x =~ /yyyyy\n$/, 'read line 2');
ok(tell($fh) == 200, 'tell after 2 readline');
$x = <$fh>;
ok($x eq $newmsg, 'read line 3: new message');
ok(tell($fh) == 200 + length($newmsg), 'tell after 3 newline');
$x = <$fh>;
ok($x =~ /zzz\r\n$/, 'readline 4');
ok(tell($fh) == 300, 'tell after 4 readline');
ok(close $fh, 'close ok');
ok(unlink "t/test05.txt", 'remove test file');

done_testing();



