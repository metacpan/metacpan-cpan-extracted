# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Sjis;
print "1..8\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..8) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
print FILE "1";
close(FILE);

if (-r 'file') {
    print "ok - 1 -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 -r 'file' $^X $__FILE__\n";
}

if (-e -r 'file') {
    print "ok - 2 -e -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 2 -e -r 'file' $^X $__FILE__\n";
}

if (-s q!file!) {
    print "ok - 3 -s q!file! $^X $__FILE__\n";
}
else {
    print "not ok - 3 -s q!file! $^X $__FILE__\n";
}

if (-s qq!file!) {
    print "ok - 4 -s qq!file! $^X $__FILE__\n";
}
else {
    print "not ok - 4 -s qq!file! $^X $__FILE__\n";
}

if (-r q!file!) {
    print "ok - 5 -r q!file! $^X $__FILE__\n";
}
else {
    print "not ok - 5 -r q!file! $^X $__FILE__\n";
}

if (-r qq!file!) {
    print "ok - 6 -r qq!file! $^X $__FILE__\n";
}
else {
    print "not ok - 6 -r qq!file! $^X $__FILE__\n";
}

if (-e -r q!file!) {
    print "ok - 7 -e -r q!file! $^X $__FILE__\n";
}
else {
    print "not ok - 7 -e -r q!file! $^X $__FILE__\n";
}

if (-e -r qq!file!) {
    print "ok - 8 -e -r qq!file! $^X $__FILE__\n";
}
else {
    print "not ok - 8 -e -r qq!file! $^X $__FILE__\n";
}

unlink('file');

__END__
