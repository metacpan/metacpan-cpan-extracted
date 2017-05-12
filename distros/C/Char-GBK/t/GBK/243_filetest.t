# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

# 僼傽僀儖僥僗僩偑恀偵側傞応崌偼 1 偑曉傞僥僗僩

my $__FILE__ = __FILE__;

use Egbk;
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

if ((Egbk::r 'file') == 1) {
    $_ = Egbk::r 'file';
    print "ok - 1 Egbk::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::r 'file';
    print "not ok - 1 Egbk::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::w 'file') == 1) {
    $_ = Egbk::w 'file';
    print "ok - 2 Egbk::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::w 'file';
    print "not ok - 2 Egbk::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::o 'file') == 1) {
    $_ = Egbk::o 'file';
    print "ok - 3 Egbk::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::o 'file';
    print "not ok - 3 Egbk::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::R 'file') == 1) {
    $_ = Egbk::R 'file';
    print "ok - 4 Egbk::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::R 'file';
    print "not ok - 4 Egbk::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::W 'file') == 1) {
    $_ = Egbk::W 'file';
    print "ok - 5 Egbk::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::W 'file';
    print "not ok - 5 Egbk::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::O 'file') == 1) {
    $_ = Egbk::O 'file';
    print "ok - 6 Egbk::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::O 'file';
    print "not ok - 6 Egbk::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::e 'file') == 1) {
    $_ = Egbk::e 'file';
    print "ok - 7 Egbk::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::e 'file';
    print "not ok - 7 Egbk::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::z 'file') == 1) {
    $_ = Egbk::z 'file';
    print "ok - 8 Egbk::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::z 'file';
    print "not ok - 8 Egbk::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Egbk::f 'file') == 1) {
    $_ = Egbk::f 'file';
    print "ok - 9 Egbk::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Egbk::f 'file';
    print "not ok - 9 Egbk::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
