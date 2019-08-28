# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{あ} ne "\x82\xa0";

# 引数に _ が指定された場合のテスト

my $__FILE__ = __FILE__;

use Ebig5hkscs;
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
    if (Ebig5hkscs::r(_)) {
        print "ok - 1 Ebig5hkscs::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Ebig5hkscs::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::r(_)) {
        print "not ok - 1 Ebig5hkscs::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Ebig5hkscs::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Ebig5hkscs::w(_)) {
        print "ok - 2 Ebig5hkscs::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Ebig5hkscs::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::w(_)) {
        print "not ok - 2 Ebig5hkscs::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Ebig5hkscs::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Ebig5hkscs::x(_)) {
        print "ok - 3 Ebig5hkscs::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Ebig5hkscs::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::x(_)) {
        print "not ok - 3 Ebig5hkscs::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Ebig5hkscs::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Ebig5hkscs::o(_)) {
        print "ok - 4 Ebig5hkscs::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Ebig5hkscs::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::o(_)) {
        print "not ok - 4 Ebig5hkscs::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Ebig5hkscs::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Ebig5hkscs::R(_)) {
        print "ok - 5 Ebig5hkscs::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Ebig5hkscs::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::R(_)) {
        print "not ok - 5 Ebig5hkscs::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Ebig5hkscs::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Ebig5hkscs::W(_)) {
        print "ok - 6 Ebig5hkscs::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Ebig5hkscs::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::W(_)) {
        print "not ok - 6 Ebig5hkscs::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Ebig5hkscs::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Ebig5hkscs::X(_)) {
        print "ok - 7 Ebig5hkscs::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Ebig5hkscs::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::X(_)) {
        print "not ok - 7 Ebig5hkscs::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Ebig5hkscs::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Ebig5hkscs::O(_)) {
        print "ok - 8 Ebig5hkscs::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Ebig5hkscs::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::O(_)) {
        print "not ok - 8 Ebig5hkscs::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Ebig5hkscs::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Ebig5hkscs::e(_)) {
        print "ok - 9 Ebig5hkscs::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Ebig5hkscs::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::e(_)) {
        print "not ok - 9 Ebig5hkscs::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Ebig5hkscs::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Ebig5hkscs::z(_)) {
        print "ok - 10 Ebig5hkscs::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Ebig5hkscs::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::z(_)) {
        print "not ok - 10 Ebig5hkscs::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Ebig5hkscs::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Ebig5hkscs::s(_) == $_) {
    print "ok - 11 Ebig5hkscs::s _ (@{[Ebig5hkscs::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ebig5hkscs::s _ (@{[Ebig5hkscs::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Ebig5hkscs::f(_)) {
        print "ok - 12 Ebig5hkscs::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Ebig5hkscs::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::f(_)) {
        print "not ok - 12 Ebig5hkscs::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Ebig5hkscs::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Ebig5hkscs::d(_)) {
        print "ok - 13 Ebig5hkscs::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Ebig5hkscs::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::d(_)) {
        print "not ok - 13 Ebig5hkscs::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Ebig5hkscs::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Ebig5hkscs::p(_)) {
        print "ok - 14 Ebig5hkscs::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Ebig5hkscs::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::p(_)) {
        print "not ok - 14 Ebig5hkscs::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Ebig5hkscs::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Ebig5hkscs::S(_)) {
        print "ok - 15 Ebig5hkscs::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Ebig5hkscs::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::S(_)) {
        print "not ok - 15 Ebig5hkscs::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Ebig5hkscs::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Ebig5hkscs::b(_)) {
        print "ok - 16 Ebig5hkscs::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Ebig5hkscs::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::b(_)) {
        print "not ok - 16 Ebig5hkscs::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Ebig5hkscs::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Ebig5hkscs::c(_)) {
        print "ok - 17 Ebig5hkscs::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Ebig5hkscs::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::c(_)) {
        print "not ok - 17 Ebig5hkscs::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Ebig5hkscs::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Ebig5hkscs::u(_)) {
        print "ok - 18 Ebig5hkscs::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Ebig5hkscs::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::u(_)) {
        print "not ok - 18 Ebig5hkscs::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Ebig5hkscs::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Ebig5hkscs::g(_)) {
        print "ok - 19 Ebig5hkscs::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Ebig5hkscs::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::g(_)) {
        print "not ok - 19 Ebig5hkscs::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Ebig5hkscs::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Ebig5hkscs::k(_)) {
        print "ok - 20 Ebig5hkscs::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Ebig5hkscs::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Ebig5hkscs::k(_)) {
        print "not ok - 20 Ebig5hkscs::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Ebig5hkscs::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Ebig5hkscs::M(_) == $_) {
    print "ok - 21 Ebig5hkscs::M _ (@{[Ebig5hkscs::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ebig5hkscs::M _ (@{[Ebig5hkscs::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Ebig5hkscs::A(_) == $_) {
    print "ok - 22 Ebig5hkscs::A _ (@{[Ebig5hkscs::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ebig5hkscs::A _ (@{[Ebig5hkscs::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Ebig5hkscs::C(_) == $_) {
    print "ok - 23 Ebig5hkscs::C _ (@{[Ebig5hkscs::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ebig5hkscs::C _ (@{[Ebig5hkscs::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
