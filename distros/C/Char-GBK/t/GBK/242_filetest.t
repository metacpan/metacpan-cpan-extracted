# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

# 堷悢偵 _ 偑巜掕偝傟偨応崌偺僥僗僩

my $__FILE__ = __FILE__;

use Egbk;
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
    if (Egbk::r(_)) {
        print "ok - 1 Egbk::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Egbk::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::r(_)) {
        print "not ok - 1 Egbk::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Egbk::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Egbk::w(_)) {
        print "ok - 2 Egbk::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Egbk::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::w(_)) {
        print "not ok - 2 Egbk::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Egbk::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Egbk::x(_)) {
        print "ok - 3 Egbk::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Egbk::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::x(_)) {
        print "not ok - 3 Egbk::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Egbk::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Egbk::o(_)) {
        print "ok - 4 Egbk::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Egbk::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::o(_)) {
        print "not ok - 4 Egbk::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Egbk::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Egbk::R(_)) {
        print "ok - 5 Egbk::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Egbk::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::R(_)) {
        print "not ok - 5 Egbk::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Egbk::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Egbk::W(_)) {
        print "ok - 6 Egbk::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Egbk::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::W(_)) {
        print "not ok - 6 Egbk::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Egbk::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Egbk::X(_)) {
        print "ok - 7 Egbk::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Egbk::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::X(_)) {
        print "not ok - 7 Egbk::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Egbk::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Egbk::O(_)) {
        print "ok - 8 Egbk::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Egbk::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::O(_)) {
        print "not ok - 8 Egbk::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Egbk::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Egbk::e(_)) {
        print "ok - 9 Egbk::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Egbk::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::e(_)) {
        print "not ok - 9 Egbk::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Egbk::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Egbk::z(_)) {
        print "ok - 10 Egbk::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Egbk::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::z(_)) {
        print "not ok - 10 Egbk::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Egbk::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Egbk::s(_) == $_) {
    print "ok - 11 Egbk::s _ (@{[Egbk::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egbk::s _ (@{[Egbk::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Egbk::f(_)) {
        print "ok - 12 Egbk::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Egbk::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::f(_)) {
        print "not ok - 12 Egbk::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Egbk::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Egbk::d(_)) {
        print "ok - 13 Egbk::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Egbk::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::d(_)) {
        print "not ok - 13 Egbk::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Egbk::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Egbk::p(_)) {
        print "ok - 14 Egbk::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Egbk::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::p(_)) {
        print "not ok - 14 Egbk::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Egbk::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Egbk::S(_)) {
        print "ok - 15 Egbk::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Egbk::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::S(_)) {
        print "not ok - 15 Egbk::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Egbk::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Egbk::b(_)) {
        print "ok - 16 Egbk::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Egbk::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::b(_)) {
        print "not ok - 16 Egbk::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Egbk::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Egbk::c(_)) {
        print "ok - 17 Egbk::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Egbk::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::c(_)) {
        print "not ok - 17 Egbk::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Egbk::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Egbk::u(_)) {
        print "ok - 18 Egbk::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Egbk::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::u(_)) {
        print "not ok - 18 Egbk::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Egbk::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Egbk::g(_)) {
        print "ok - 19 Egbk::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Egbk::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::g(_)) {
        print "not ok - 19 Egbk::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Egbk::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Egbk::k(_)) {
        print "ok - 20 Egbk::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Egbk::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Egbk::k(_)) {
        print "not ok - 20 Egbk::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Egbk::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Egbk::M(_) == $_) {
    print "ok - 21 Egbk::M _ (@{[Egbk::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egbk::M _ (@{[Egbk::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Egbk::A(_) == $_) {
    print "ok - 22 Egbk::A _ (@{[Egbk::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egbk::A _ (@{[Egbk::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Egbk::C(_) == $_) {
    print "ok - 23 Egbk::C _ (@{[Egbk::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Egbk::C _ (@{[Egbk::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
