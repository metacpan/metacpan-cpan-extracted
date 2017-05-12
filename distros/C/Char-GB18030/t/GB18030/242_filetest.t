# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

# 堷悢偵 _ 偑巜掕偝傟偨応崌偺僥僗僩

my $__FILE__ = __FILE__;

use Egb18030;
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
    if (Egb18030::r(_)) {
        print "ok - 1 Egb18030::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Egb18030::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::r(_)) {
        print "not ok - 1 Egb18030::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Egb18030::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Egb18030::w(_)) {
        print "ok - 2 Egb18030::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Egb18030::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::w(_)) {
        print "not ok - 2 Egb18030::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Egb18030::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Egb18030::x(_)) {
        print "ok - 3 Egb18030::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Egb18030::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::x(_)) {
        print "not ok - 3 Egb18030::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Egb18030::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Egb18030::o(_)) {
        print "ok - 4 Egb18030::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Egb18030::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::o(_)) {
        print "not ok - 4 Egb18030::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Egb18030::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Egb18030::R(_)) {
        print "ok - 5 Egb18030::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Egb18030::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::R(_)) {
        print "not ok - 5 Egb18030::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Egb18030::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Egb18030::W(_)) {
        print "ok - 6 Egb18030::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Egb18030::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::W(_)) {
        print "not ok - 6 Egb18030::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Egb18030::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Egb18030::X(_)) {
        print "ok - 7 Egb18030::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Egb18030::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::X(_)) {
        print "not ok - 7 Egb18030::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Egb18030::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Egb18030::O(_)) {
        print "ok - 8 Egb18030::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Egb18030::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::O(_)) {
        print "not ok - 8 Egb18030::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Egb18030::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Egb18030::e(_)) {
        print "ok - 9 Egb18030::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Egb18030::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::e(_)) {
        print "not ok - 9 Egb18030::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Egb18030::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Egb18030::z(_)) {
        print "ok - 10 Egb18030::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Egb18030::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::z(_)) {
        print "not ok - 10 Egb18030::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Egb18030::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Egb18030::s(_) == $_) {
    print "ok - 11 Egb18030::s _ (@{[Egb18030::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egb18030::s _ (@{[Egb18030::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Egb18030::f(_)) {
        print "ok - 12 Egb18030::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Egb18030::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::f(_)) {
        print "not ok - 12 Egb18030::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Egb18030::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Egb18030::d(_)) {
        print "ok - 13 Egb18030::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Egb18030::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::d(_)) {
        print "not ok - 13 Egb18030::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Egb18030::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Egb18030::p(_)) {
        print "ok - 14 Egb18030::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Egb18030::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::p(_)) {
        print "not ok - 14 Egb18030::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Egb18030::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Egb18030::S(_)) {
        print "ok - 15 Egb18030::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Egb18030::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::S(_)) {
        print "not ok - 15 Egb18030::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Egb18030::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Egb18030::b(_)) {
        print "ok - 16 Egb18030::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Egb18030::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::b(_)) {
        print "not ok - 16 Egb18030::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Egb18030::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Egb18030::c(_)) {
        print "ok - 17 Egb18030::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Egb18030::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::c(_)) {
        print "not ok - 17 Egb18030::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Egb18030::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Egb18030::u(_)) {
        print "ok - 18 Egb18030::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Egb18030::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::u(_)) {
        print "not ok - 18 Egb18030::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Egb18030::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Egb18030::g(_)) {
        print "ok - 19 Egb18030::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Egb18030::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::g(_)) {
        print "not ok - 19 Egb18030::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Egb18030::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Egb18030::k(_)) {
        print "ok - 20 Egb18030::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Egb18030::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Egb18030::k(_)) {
        print "not ok - 20 Egb18030::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Egb18030::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Egb18030::M(_) == $_) {
    print "ok - 21 Egb18030::M _ (@{[Egb18030::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egb18030::M _ (@{[Egb18030::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Egb18030::A(_) == $_) {
    print "ok - 22 Egb18030::A _ (@{[Egb18030::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egb18030::A _ (@{[Egb18030::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Egb18030::C(_) == $_) {
    print "ok - 23 Egb18030::C _ (@{[Egb18030::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Egb18030::C _ (@{[Egb18030::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
