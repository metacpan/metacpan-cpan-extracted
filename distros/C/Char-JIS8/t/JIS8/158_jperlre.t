# encoding: JIS8
# This file is encoded in JIS8.
die "This file is not encoded in JIS8.\n" if q{あ} ne "\x82\xa0";

use JIS8;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あ]う' =~ /(あ[^]い]う)/) {
    print "not ok - 1 $^X $__FILE__ not ('あ]う' =~ /あ[^]い]う/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('あ]う' =~ /あ[^]い]う/).\n";
}

__END__
