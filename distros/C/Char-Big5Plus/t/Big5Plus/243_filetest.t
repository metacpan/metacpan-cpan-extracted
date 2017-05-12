# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

# ファイルテストが真になる場合は 1 が返るテスト

my $__FILE__ = __FILE__;

use Ebig5plus;
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

if ((Ebig5plus::r 'file') == 1) {
    $_ = Ebig5plus::r 'file';
    print "ok - 1 Ebig5plus::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::r 'file';
    print "not ok - 1 Ebig5plus::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::w 'file') == 1) {
    $_ = Ebig5plus::w 'file';
    print "ok - 2 Ebig5plus::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::w 'file';
    print "not ok - 2 Ebig5plus::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::o 'file') == 1) {
    $_ = Ebig5plus::o 'file';
    print "ok - 3 Ebig5plus::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::o 'file';
    print "not ok - 3 Ebig5plus::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::R 'file') == 1) {
    $_ = Ebig5plus::R 'file';
    print "ok - 4 Ebig5plus::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::R 'file';
    print "not ok - 4 Ebig5plus::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::W 'file') == 1) {
    $_ = Ebig5plus::W 'file';
    print "ok - 5 Ebig5plus::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::W 'file';
    print "not ok - 5 Ebig5plus::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::O 'file') == 1) {
    $_ = Ebig5plus::O 'file';
    print "ok - 6 Ebig5plus::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::O 'file';
    print "not ok - 6 Ebig5plus::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::e 'file') == 1) {
    $_ = Ebig5plus::e 'file';
    print "ok - 7 Ebig5plus::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::e 'file';
    print "not ok - 7 Ebig5plus::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::z 'file') == 1) {
    $_ = Ebig5plus::z 'file';
    print "ok - 8 Ebig5plus::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::z 'file';
    print "not ok - 8 Ebig5plus::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Ebig5plus::f 'file') == 1) {
    $_ = Ebig5plus::f 'file';
    print "ok - 9 Ebig5plus::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Ebig5plus::f 'file';
    print "not ok - 9 Ebig5plus::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
