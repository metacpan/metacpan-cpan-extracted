# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

# 引数に _ が指定された場合のテスト

my $__FILE__ = __FILE__;

use Esjis;
print "1..23\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..23) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if (-r ('file')) {
    if (Esjis::r(_)) {
        print "ok - 1 Esjis::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Esjis::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::r(_)) {
        print "not ok - 1 Esjis::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Esjis::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Esjis::w(_)) {
        print "ok - 2 Esjis::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Esjis::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::w(_)) {
        print "not ok - 2 Esjis::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Esjis::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Esjis::x(_)) {
        print "ok - 3 Esjis::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Esjis::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::x(_)) {
        print "not ok - 3 Esjis::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Esjis::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Esjis::o(_)) {
        print "ok - 4 Esjis::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Esjis::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::o(_)) {
        print "not ok - 4 Esjis::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Esjis::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Esjis::R(_)) {
        print "ok - 5 Esjis::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Esjis::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::R(_)) {
        print "not ok - 5 Esjis::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Esjis::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Esjis::W(_)) {
        print "ok - 6 Esjis::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Esjis::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::W(_)) {
        print "not ok - 6 Esjis::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Esjis::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Esjis::X(_)) {
        print "ok - 7 Esjis::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Esjis::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::X(_)) {
        print "not ok - 7 Esjis::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Esjis::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Esjis::O(_)) {
        print "ok - 8 Esjis::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Esjis::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::O(_)) {
        print "not ok - 8 Esjis::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Esjis::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Esjis::e(_)) {
        print "ok - 9 Esjis::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Esjis::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::e(_)) {
        print "not ok - 9 Esjis::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Esjis::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Esjis::z(_)) {
        print "ok - 10 Esjis::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Esjis::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::z(_)) {
        print "not ok - 10 Esjis::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Esjis::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Esjis::s(_) == $_) {
    print "ok - 11 Esjis::s _ (@{[Esjis::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Esjis::s _ (@{[Esjis::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Esjis::f(_)) {
        print "ok - 12 Esjis::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Esjis::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::f(_)) {
        print "not ok - 12 Esjis::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Esjis::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Esjis::d(_)) {
        print "ok - 13 Esjis::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Esjis::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::d(_)) {
        print "not ok - 13 Esjis::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Esjis::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Esjis::p(_)) {
        print "ok - 14 Esjis::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Esjis::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::p(_)) {
        print "not ok - 14 Esjis::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Esjis::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Esjis::S(_)) {
        print "ok - 15 Esjis::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Esjis::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::S(_)) {
        print "not ok - 15 Esjis::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Esjis::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Esjis::b(_)) {
        print "ok - 16 Esjis::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Esjis::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::b(_)) {
        print "not ok - 16 Esjis::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Esjis::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Esjis::c(_)) {
        print "ok - 17 Esjis::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Esjis::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::c(_)) {
        print "not ok - 17 Esjis::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Esjis::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Esjis::u(_)) {
        print "ok - 18 Esjis::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Esjis::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::u(_)) {
        print "not ok - 18 Esjis::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Esjis::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Esjis::g(_)) {
        print "ok - 19 Esjis::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Esjis::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::g(_)) {
        print "not ok - 19 Esjis::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Esjis::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Esjis::k(_)) {
        print "ok - 20 Esjis::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Esjis::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Esjis::k(_)) {
        print "not ok - 20 Esjis::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Esjis::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Esjis::M(_) == $_) {
    print "ok - 21 Esjis::M _ (@{[Esjis::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Esjis::M _ (@{[Esjis::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Esjis::A(_) == $_) {
    print "ok - 22 Esjis::A _ (@{[Esjis::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Esjis::A _ (@{[Esjis::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Esjis::C(_) == $_) {
    print "ok - 23 Esjis::C _ (@{[Esjis::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Esjis::C _ (@{[Esjis::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
