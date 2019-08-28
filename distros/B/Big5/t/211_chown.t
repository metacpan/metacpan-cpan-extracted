# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Big5;
print "1..1\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|950/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

open(FILE,'>F機能') || die "Can't open file: F機能\n";
print FILE "1\n";
close(FILE);

# chown
if (chown(-1,-1,'F機能')) {
    print "ok - 1 chown $^X $__FILE__\n";
}
else {
    print "not ok - 1 chown: $! $^X $__FILE__\n";
}

unlink('F機能');

__END__
