# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use GB18030;
print "1..1\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|936/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

open(FILE,'>F婡擻') || die "Can't open file: F婡擻\n";
print FILE "1\n";
close(FILE);

# chown
if (chown(-1,-1,'F婡擻')) {
    print "ok - 1 chown $^X $__FILE__\n";
}
else {
    print "not ok - 1 chown: $! $^X $__FILE__\n";
}

unlink('F婡擻');

__END__
