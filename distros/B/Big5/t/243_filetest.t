# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

# ファイルテストが真になる場合は 1 が返るテスト

my $__FILE__ = __FILE__;

use Ebig5;
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

if ((Ebig5::r 'file') == 1) {
    $_ = Ebig5::r 'file';
    print "ok - 1 Ebig5::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::r 'file';
    print "not ok - 1 Ebig5::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::w 'file') == 1) {
    $_ = Ebig5::w 'file';
    print "ok - 2 Ebig5::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::w 'file';
    print "not ok - 2 Ebig5::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::o 'file') == 1) {
    $_ = Ebig5::o 'file';
    print "ok - 3 Ebig5::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::o 'file';
    print "not ok - 3 Ebig5::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::R 'file') == 1) {
    $_ = Ebig5::R 'file';
    print "ok - 4 Ebig5::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::R 'file';
    print "not ok - 4 Ebig5::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::W 'file') == 1) {
    $_ = Ebig5::W 'file';
    print "ok - 5 Ebig5::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::W 'file';
    print "not ok - 5 Ebig5::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::O 'file') == 1) {
    $_ = Ebig5::O 'file';
    print "ok - 6 Ebig5::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::O 'file';
    print "not ok - 6 Ebig5::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::e 'file') == 1) {
    $_ = Ebig5::e 'file';
    print "ok - 7 Ebig5::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::e 'file';
    print "not ok - 7 Ebig5::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::z 'file') == 1) {
    $_ = Ebig5::z 'file';
    print "ok - 8 Ebig5::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::z 'file';
    print "not ok - 8 Ebig5::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5::f 'file') == 1) {
    $_ = Ebig5::f 'file';
    print "ok - 9 Ebig5::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5::f 'file';
    print "not ok - 9 Ebig5::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
