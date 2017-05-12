# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あA]い' =~ /あ[^]]い/) {
    print "not ok - 1 $^X $__FILE__ ('あA]い' =~ /あ[^]]い/)\n";
}
else {
    print "ok - 1 $^X $__FILE__ ('あA]い' =~ /あ[^]]い/)\n";
}

__END__
