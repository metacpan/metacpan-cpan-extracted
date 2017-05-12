# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

print "1..4\n";

my $__FILE__ = __FILE__;

if ($] < 5.014) {
    for my $tno (1..4) {
        print "ok - $tno # SKIP $^X $__FILE__\n";
    }
    exit;
}

if (open(TEST,">@{[__FILE__]}.t")) {
    print TEST <DATA>;
    close(TEST);
    system(qq{$^X @{[__FILE__]}.t});
    unlink("@{[__FILE__]}.t");
    unlink("@{[__FILE__]}.t.e");
}

__END__
# encoding: Sjis
use Sjis;

my $__FILE__ = __FILE__;

my $name = 'fred';
Sjis::substr($name, 4) = 'dy';
if ($name eq 'freddy') {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

my $null = Sjis::substr $name, 6, 2;
if ($null eq "") {
    print "ok - 2 $^X $__FILE__\n";
}
else {
    print "not ok - 2 $^X $__FILE__\n";
}

my $oops = Sjis::substr $name, 7;
if (not defined $oops) {
    print "ok - 3 $^X $__FILE__\n";
}
else {
    print "not ok - 3 $^X $__FILE__\n";
}

eval {
    Sjis::substr($name, 7) = 'gap';
};
if ($@) {
    print "ok - 4 $^X $__FILE__\n";
}
else {
    print "not ok - 4 $^X $__FILE__\n";
}

__END__
http://perldoc.perl.org/functions/substr.html

1.    my $name = 'fred';
2.    substr($name, 4) = 'dy';         # $name is now 'freddy'
3.    my $null = substr $name, 6, 2;   # returns "" (no warning)
4.    my $oops = substr $name, 7;      # returns undef, with warning
5.    substr($name, 7) = 'gap';        # raises an exception
