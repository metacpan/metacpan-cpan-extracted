# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

use Big5;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あxyzう' =~ /(あ.*う)/) {
    if ("$1" eq "あxyzう") {
        print "ok - 1 $^X $__FILE__ ('あxyzう' =~ /あ.*う/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('あxyzう' =~ /あ.*う/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('あxyzう' =~ /あ.*う/).\n";
}

__END__
