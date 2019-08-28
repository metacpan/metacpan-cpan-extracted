# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Big5;
print "1..2\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|950/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    print "ok - 2 # SKIP $^X $0\n";
    exit;
}

mkdir('directory',0777);
mkdir('D機能',0777);
open(FILE,'>D機能/file1.txt') || die "Can't open file: D機能/file1.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/file2.txt') || die "Can't open file: D機能/file2.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/file3.txt') || die "Can't open file: D機能/file3.txt\n";
print FILE "1\n";
close(FILE);

# glob (1/2)
my @glob = glob('./*');
if (grep(/D機能/,@glob)) {
    print "ok - 1 glob (1/2) $^X $__FILE__\n";
}
else {
    print "not ok - 1 glob: ", (map {"($_)"} @glob), ": $! $^X $__FILE__\n";
}

# glob (2/2)
@glob = glob('./D機能/*');
if (@glob) {
    print "ok - 2 glob (2/2) $^X $__FILE__\n";
}
else {
    print "not ok - 2 glob: ", (map {"($_)"} @glob), ": $! $^X $__FILE__\n";
}

unlink('D機能/file1.txt');
unlink('D機能/file2.txt');
unlink('D機能/file3.txt');
rmdir('directory');
rmdir('D機能');

__END__
