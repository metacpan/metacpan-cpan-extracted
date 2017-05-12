# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

# 긲�@귽깑긡긚긣궕�^궸궶귡뤾뜃궼 1 궕뺅귡긡긚긣

my $__FILE__ = __FILE__;

use Euhc;
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

if ((Euhc::r 'file') == 1) {
    $_ = Euhc::r 'file';
    print "ok - 1 Euhc::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::r 'file';
    print "not ok - 1 Euhc::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::w 'file') == 1) {
    $_ = Euhc::w 'file';
    print "ok - 2 Euhc::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::w 'file';
    print "not ok - 2 Euhc::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::o 'file') == 1) {
    $_ = Euhc::o 'file';
    print "ok - 3 Euhc::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::o 'file';
    print "not ok - 3 Euhc::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::R 'file') == 1) {
    $_ = Euhc::R 'file';
    print "ok - 4 Euhc::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::R 'file';
    print "not ok - 4 Euhc::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::W 'file') == 1) {
    $_ = Euhc::W 'file';
    print "ok - 5 Euhc::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::W 'file';
    print "not ok - 5 Euhc::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::O 'file') == 1) {
    $_ = Euhc::O 'file';
    print "ok - 6 Euhc::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::O 'file';
    print "not ok - 6 Euhc::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::e 'file') == 1) {
    $_ = Euhc::e 'file';
    print "ok - 7 Euhc::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::e 'file';
    print "not ok - 7 Euhc::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::z 'file') == 1) {
    $_ = Euhc::z 'file';
    print "ok - 8 Euhc::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::z 'file';
    print "not ok - 8 Euhc::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Euhc::f 'file') == 1) {
    $_ = Euhc::f 'file';
    print "ok - 9 Euhc::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Euhc::f 'file';
    print "not ok - 9 Euhc::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
