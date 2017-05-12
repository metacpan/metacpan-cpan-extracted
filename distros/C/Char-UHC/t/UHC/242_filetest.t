# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

# 덙릶궸 _ 궕럚믦궠귢궫뤾뜃궻긡긚긣

my $__FILE__ = __FILE__;

use Euhc;
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
    if (Euhc::r(_)) {
        print "ok - 1 Euhc::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Euhc::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::r(_)) {
        print "not ok - 1 Euhc::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Euhc::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Euhc::w(_)) {
        print "ok - 2 Euhc::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Euhc::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::w(_)) {
        print "not ok - 2 Euhc::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Euhc::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Euhc::x(_)) {
        print "ok - 3 Euhc::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Euhc::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::x(_)) {
        print "not ok - 3 Euhc::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Euhc::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Euhc::o(_)) {
        print "ok - 4 Euhc::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Euhc::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::o(_)) {
        print "not ok - 4 Euhc::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Euhc::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Euhc::R(_)) {
        print "ok - 5 Euhc::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Euhc::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::R(_)) {
        print "not ok - 5 Euhc::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Euhc::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Euhc::W(_)) {
        print "ok - 6 Euhc::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Euhc::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::W(_)) {
        print "not ok - 6 Euhc::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Euhc::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Euhc::X(_)) {
        print "ok - 7 Euhc::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Euhc::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::X(_)) {
        print "not ok - 7 Euhc::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Euhc::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Euhc::O(_)) {
        print "ok - 8 Euhc::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Euhc::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::O(_)) {
        print "not ok - 8 Euhc::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Euhc::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Euhc::e(_)) {
        print "ok - 9 Euhc::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Euhc::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::e(_)) {
        print "not ok - 9 Euhc::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Euhc::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Euhc::z(_)) {
        print "ok - 10 Euhc::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Euhc::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::z(_)) {
        print "not ok - 10 Euhc::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Euhc::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Euhc::s(_) == $_) {
    print "ok - 11 Euhc::s _ (@{[Euhc::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Euhc::s _ (@{[Euhc::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Euhc::f(_)) {
        print "ok - 12 Euhc::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Euhc::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::f(_)) {
        print "not ok - 12 Euhc::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Euhc::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Euhc::d(_)) {
        print "ok - 13 Euhc::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Euhc::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::d(_)) {
        print "not ok - 13 Euhc::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Euhc::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Euhc::p(_)) {
        print "ok - 14 Euhc::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Euhc::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::p(_)) {
        print "not ok - 14 Euhc::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Euhc::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Euhc::S(_)) {
        print "ok - 15 Euhc::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Euhc::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::S(_)) {
        print "not ok - 15 Euhc::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Euhc::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Euhc::b(_)) {
        print "ok - 16 Euhc::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Euhc::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::b(_)) {
        print "not ok - 16 Euhc::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Euhc::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Euhc::c(_)) {
        print "ok - 17 Euhc::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Euhc::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::c(_)) {
        print "not ok - 17 Euhc::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Euhc::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Euhc::u(_)) {
        print "ok - 18 Euhc::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Euhc::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::u(_)) {
        print "not ok - 18 Euhc::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Euhc::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Euhc::g(_)) {
        print "ok - 19 Euhc::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Euhc::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::g(_)) {
        print "not ok - 19 Euhc::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Euhc::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Euhc::k(_)) {
        print "ok - 20 Euhc::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Euhc::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Euhc::k(_)) {
        print "not ok - 20 Euhc::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Euhc::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Euhc::M(_) == $_) {
    print "ok - 21 Euhc::M _ (@{[Euhc::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Euhc::M _ (@{[Euhc::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Euhc::A(_) == $_) {
    print "ok - 22 Euhc::A _ (@{[Euhc::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Euhc::A _ (@{[Euhc::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Euhc::C(_) == $_) {
    print "ok - 23 Euhc::C _ (@{[Euhc::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Euhc::C _ (@{[Euhc::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
