# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

# ファイルテストが真になる場合は 1 が返るテスト

my $__FILE__ = __FILE__;

use Ehp15;
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

if ((Ehp15::r 'file') == 1) {
    $_ = Ehp15::r 'file';
    print "ok - 1 Ehp15::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::r 'file';
    print "not ok - 1 Ehp15::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::w 'file') == 1) {
    $_ = Ehp15::w 'file';
    print "ok - 2 Ehp15::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::w 'file';
    print "not ok - 2 Ehp15::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::o 'file') == 1) {
    $_ = Ehp15::o 'file';
    print "ok - 3 Ehp15::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::o 'file';
    print "not ok - 3 Ehp15::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::R 'file') == 1) {
    $_ = Ehp15::R 'file';
    print "ok - 4 Ehp15::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::R 'file';
    print "not ok - 4 Ehp15::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::W 'file') == 1) {
    $_ = Ehp15::W 'file';
    print "ok - 5 Ehp15::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::W 'file';
    print "not ok - 5 Ehp15::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::O 'file') == 1) {
    $_ = Ehp15::O 'file';
    print "ok - 6 Ehp15::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::O 'file';
    print "not ok - 6 Ehp15::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::e 'file') == 1) {
    $_ = Ehp15::e 'file';
    print "ok - 7 Ehp15::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::e 'file';
    print "not ok - 7 Ehp15::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::z 'file') == 1) {
    $_ = Ehp15::z 'file';
    print "ok - 8 Ehp15::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::z 'file';
    print "not ok - 8 Ehp15::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ehp15::f 'file') == 1) {
    $_ = Ehp15::f 'file';
    print "ok - 9 Ehp15::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ehp15::f 'file';
    print "not ok - 9 Ehp15::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
