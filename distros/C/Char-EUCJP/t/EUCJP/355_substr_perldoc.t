# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

print "1..2\n";

my $__FILE__ = __FILE__;

if ($] < 5.016) {
    for my $tno (1..2) {
        print "ok - $tno # SKIP $^X $__FILE__\n";
    }
    exit;
}

if (open(TEST,">@{[__FILE__]}.t")) {
    open(SELF,__FILE__);
    @_ = <SELF>;
    close(SELF);
    print TEST @_[0..2];
    print TEST <DATA>;
    close(TEST);
    system(qq{$^X @{[__FILE__]}.t});
    unlink("@{[__FILE__]}.t");
    unlink("@{[__FILE__]}.t.e");
}

__END__

use EUCJP;

my $__FILE__ = __FILE__;

my $x = '1234';
for (substr($x,-3,2)) {
    $_ = 'a';
    if ($x eq '1a4') {
        print "ok - 1 $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__\n";
    }

    $x = 'abcdefg';
    if ($_ eq 'f') {
        print "ok - 2 $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 $^X $__FILE__\n";
    }
}

__END__
http://perldoc.perl.org/functions/substr.html

1.    $x = '1234';
2.    for (substr($x, -3, 2)) {
3.        $_ = 'a';   print $x,"\n";    # prints 1a4, as above
4.        $x = 'abcdefg';
5.        print $_,"\n";                # prints f
6.    }
