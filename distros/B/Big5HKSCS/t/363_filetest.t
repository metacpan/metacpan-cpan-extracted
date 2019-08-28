# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{�栂 ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Big5HKSCS;
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
my %hash = ();
$hash{1} = 1;

if (exists $hash{-r 'file'}) {
    print "ok - 1 \$hash{-r 'file'} $^X $__FILE__\n";
}
else {
    print "not ok - 1 \$hash{-r 'file'} $^X $__FILE__\n";
}

if (exists $hash{-e -r 'file'}) {
    print "ok - 2 \$hash{-e -r 'file'} $^X $__FILE__\n";
}
else {
    print "not ok - 2 \$hash{-e -r 'file'} $^X $__FILE__\n";
}

if (exists $hash{-s q!file!}) {
    print "ok - 3 \$hash{-s q!file!} $^X $__FILE__\n";
}
else {
    print "not ok - 3 \$hash{-s q!file!} $^X $__FILE__\n";
}

if (exists $hash{-s qq!file!}) {
    print "ok - 4 \$hash{-s qq!file!} $^X $__FILE__\n";
}
else {
    print "not ok - 4 \$hash{-s qq!file!} $^X $__FILE__\n";
}

if (exists $hash{-r q!file!}) {
    print "ok - 5 \$hash{-r q!file!} $^X $__FILE__\n";
}
else {
    print "not ok - 5 \$hash{-r q!file!} $^X $__FILE__\n";
}

if (exists $hash{-r qq!file!}) {
    print "ok - 6 \$hash{-r qq!file!} $^X $__FILE__\n";
}
else {
    print "not ok - 6 \$hash{-r qq!file!} $^X $__FILE__\n";
}

if (exists $hash{-e -r q!file!}) {
    print "ok - 7 \$hash{-e -r q!file!} $^X $__FILE__\n";
}
else {
    print "not ok - 7 \$hash{-e -r q!file!} $^X $__FILE__\n";
}

if (exists $hash{-e -r qq!file!}) {
    print "ok - 8 \$hash{-e -r qq!file!} $^X $__FILE__\n";
}
else {
    print "not ok - 8 \$hash{-e -r qq!file!} $^X $__FILE__\n";
}

unlink('file');

__END__
