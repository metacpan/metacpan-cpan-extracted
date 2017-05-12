# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

# 引数に _ が指定された場合のテスト

my $__FILE__ = __FILE__;

use Ehp15;
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
    if (Ehp15::r(_)) {
        print "ok - 1 Ehp15::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Ehp15::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::r(_)) {
        print "not ok - 1 Ehp15::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Ehp15::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Ehp15::w(_)) {
        print "ok - 2 Ehp15::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Ehp15::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::w(_)) {
        print "not ok - 2 Ehp15::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Ehp15::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Ehp15::x(_)) {
        print "ok - 3 Ehp15::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Ehp15::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::x(_)) {
        print "not ok - 3 Ehp15::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Ehp15::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Ehp15::o(_)) {
        print "ok - 4 Ehp15::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Ehp15::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::o(_)) {
        print "not ok - 4 Ehp15::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Ehp15::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Ehp15::R(_)) {
        print "ok - 5 Ehp15::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Ehp15::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::R(_)) {
        print "not ok - 5 Ehp15::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Ehp15::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Ehp15::W(_)) {
        print "ok - 6 Ehp15::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Ehp15::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::W(_)) {
        print "not ok - 6 Ehp15::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Ehp15::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Ehp15::X(_)) {
        print "ok - 7 Ehp15::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Ehp15::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::X(_)) {
        print "not ok - 7 Ehp15::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Ehp15::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Ehp15::O(_)) {
        print "ok - 8 Ehp15::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Ehp15::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::O(_)) {
        print "not ok - 8 Ehp15::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Ehp15::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Ehp15::e(_)) {
        print "ok - 9 Ehp15::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Ehp15::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::e(_)) {
        print "not ok - 9 Ehp15::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Ehp15::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Ehp15::z(_)) {
        print "ok - 10 Ehp15::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Ehp15::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::z(_)) {
        print "not ok - 10 Ehp15::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Ehp15::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Ehp15::s(_) == $_) {
    print "ok - 11 Ehp15::s _ (@{[Ehp15::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ehp15::s _ (@{[Ehp15::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Ehp15::f(_)) {
        print "ok - 12 Ehp15::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Ehp15::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::f(_)) {
        print "not ok - 12 Ehp15::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Ehp15::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Ehp15::d(_)) {
        print "ok - 13 Ehp15::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Ehp15::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::d(_)) {
        print "not ok - 13 Ehp15::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Ehp15::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Ehp15::p(_)) {
        print "ok - 14 Ehp15::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Ehp15::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::p(_)) {
        print "not ok - 14 Ehp15::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Ehp15::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Ehp15::S(_)) {
        print "ok - 15 Ehp15::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Ehp15::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::S(_)) {
        print "not ok - 15 Ehp15::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Ehp15::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Ehp15::b(_)) {
        print "ok - 16 Ehp15::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Ehp15::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::b(_)) {
        print "not ok - 16 Ehp15::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Ehp15::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Ehp15::c(_)) {
        print "ok - 17 Ehp15::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Ehp15::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::c(_)) {
        print "not ok - 17 Ehp15::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Ehp15::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Ehp15::u(_)) {
        print "ok - 18 Ehp15::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Ehp15::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::u(_)) {
        print "not ok - 18 Ehp15::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Ehp15::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Ehp15::g(_)) {
        print "ok - 19 Ehp15::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Ehp15::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::g(_)) {
        print "not ok - 19 Ehp15::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Ehp15::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Ehp15::k(_)) {
        print "ok - 20 Ehp15::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Ehp15::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Ehp15::k(_)) {
        print "not ok - 20 Ehp15::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Ehp15::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Ehp15::M(_) == $_) {
    print "ok - 21 Ehp15::M _ (@{[Ehp15::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ehp15::M _ (@{[Ehp15::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Ehp15::A(_) == $_) {
    print "ok - 22 Ehp15::A _ (@{[Ehp15::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ehp15::A _ (@{[Ehp15::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Ehp15::C(_) == $_) {
    print "ok - 23 Ehp15::C _ (@{[Ehp15::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ehp15::C _ (@{[Ehp15::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
