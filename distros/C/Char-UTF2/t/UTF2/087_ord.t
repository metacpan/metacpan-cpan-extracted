# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..2\n";

my $__FILE__ = __FILE__;

if (UTF2::ord('あ') == 0xE38182) {
    print qq{ok - 1 UTF2::ord('あ') == 0xE38182 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 UTF2::ord('あ') == 0xE38182 $^X $__FILE__\n};
}

$_ = 'い';
if (UTF2::ord == 0xE38184) {
    print qq{ok - 2 \$_ = 'い'; UTF2::ord() == 0xE38184 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = 'い'; UTF2::ord() == 0xE38184 $^X $__FILE__\n};
}

__END__
