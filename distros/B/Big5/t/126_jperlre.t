# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

use Big5;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あいう' =~ /(あい{0,1}いう)/) {
    if ("$1" eq "あいう") {
        print "ok - 1 $^X $__FILE__ ('あいう' =~ /あい{0,1}いう/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('あいう' =~ /あい{0,1}いう/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('あいう' =~ /あい{0,1}いう/).\n";
}

__END__
