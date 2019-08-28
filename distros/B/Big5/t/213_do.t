# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

use Big5;
print "1..2\n";

my $__FILE__ = __FILE__;

if ($^O eq 'MacOS') {
    print "ok - 1 # SKIP $^X $0\n";
    print "ok - 2 # SKIP $^X $0\n";
    exit;
}

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    print "ok - 2 # SKIP $^X $0\n";
    exit;
}

unshift @INC, '.';

open(FILE,'>./file') || die "Can't open file: ./file\n";
print FILE "1\n";
close(FILE);
if (do './file') {
    print "ok - 1 do $^X $__FILE__\n";
}
else {
    print "not ok - 1 do: $! $^X $__FILE__\n";
}
unlink('./file');

open(FILE,'>./F機能') || die "Can't open file: ./F機能\n";
print FILE "1\n";
close(FILE);
if (do './F機能') {
    print "ok - 2 do $^X $__FILE__\n";
}
else {
    print "not ok - 2 do: $! $^X $__FILE__\n";
}
unlink('./F機能');

__END__
