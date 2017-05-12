# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

# ファイルテストが真になる場合は 1 が返るテスト

my $__FILE__ = __FILE__;

use Einformixv6als;
print "1..9\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..9) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if ((Einformixv6als::r 'file') == 1) {
    $_ = Einformixv6als::r 'file';
    print "ok - 1 Einformixv6als::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::r 'file';
    print "not ok - 1 Einformixv6als::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::w 'file') == 1) {
    $_ = Einformixv6als::w 'file';
    print "ok - 2 Einformixv6als::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::w 'file';
    print "not ok - 2 Einformixv6als::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::o 'file') == 1) {
    $_ = Einformixv6als::o 'file';
    print "ok - 3 Einformixv6als::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::o 'file';
    print "not ok - 3 Einformixv6als::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::R 'file') == 1) {
    $_ = Einformixv6als::R 'file';
    print "ok - 4 Einformixv6als::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::R 'file';
    print "not ok - 4 Einformixv6als::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::W 'file') == 1) {
    $_ = Einformixv6als::W 'file';
    print "ok - 5 Einformixv6als::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::W 'file';
    print "not ok - 5 Einformixv6als::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::O 'file') == 1) {
    $_ = Einformixv6als::O 'file';
    print "ok - 6 Einformixv6als::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::O 'file';
    print "not ok - 6 Einformixv6als::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::e 'file') == 1) {
    $_ = Einformixv6als::e 'file';
    print "ok - 7 Einformixv6als::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::e 'file';
    print "not ok - 7 Einformixv6als::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::z 'file') == 1) {
    $_ = Einformixv6als::z 'file';
    print "ok - 8 Einformixv6als::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::z 'file';
    print "not ok - 8 Einformixv6als::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Einformixv6als::f 'file') == 1) {
    $_ = Einformixv6als::f 'file';
    print "ok - 9 Einformixv6als::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Einformixv6als::f 'file';
    print "not ok - 9 Einformixv6als::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
