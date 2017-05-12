# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use INFORMIXV6ALS;
print "1..1\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

open(FILE,'>F機能') || die "Can't open file: F機能\n";
print FILE "1\n";
close(FILE);

# glob
@glob = glob('./*');
if (grep(/F機能/,@glob)) {
    print "ok - 1 glob $^X $__FILE__\n";
}
else {
    print "not ok - 1 glob: ", (map {"($_)"} @glob), ": $! $^X $__FILE__\n";
}

unlink('F機能');

__END__
