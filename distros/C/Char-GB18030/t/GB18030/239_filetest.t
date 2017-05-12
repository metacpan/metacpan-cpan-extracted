# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

# Egb18030::X 偲 -X (Perl偺僼傽僀儖僥僗僩墘嶼巕) 偺寢壥偑堦抳偡傞偙偲偺僥僗僩(懳徾偼僨傿儗僋僩儕)

my $__FILE__ = __FILE__;

use Egb18030;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Egb18030::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Egb18030::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Egb18030::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Egb18030::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Egb18030::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Egb18030::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Egb18030::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Egb18030::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Egb18030::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Egb18030::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Egb18030::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Egb18030::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Egb18030::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Egb18030::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Egb18030::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Egb18030::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Egb18030::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Egb18030::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Egb18030::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Egb18030::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Egb18030::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Egb18030::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Egb18030::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Egb18030::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Egb18030::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Egb18030::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Egb18030::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Egb18030::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Egb18030::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Egb18030::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Egb18030::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Egb18030::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egb18030::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Egb18030::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Egb18030::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Egb18030::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Egb18030::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Egb18030::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Egb18030::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Egb18030::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Egb18030::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Egb18030::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Egb18030::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Egb18030::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Egb18030::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Egb18030::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Egb18030::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Egb18030::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Egb18030::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Egb18030::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Egb18030::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Egb18030::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Egb18030::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Egb18030::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Egb18030::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Egb18030::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Egb18030::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Egb18030::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Egb18030::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Egb18030::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Egb18030::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Egb18030::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egb18030::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Egb18030::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Egb18030::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egb18030::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
