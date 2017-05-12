# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..2\n";

my $__FILE__ = __FILE__;

if (OldUTF8::ord('あ') == 0xE38182) {
    print qq{ok - 1 OldUTF8::ord('あ') == 0xE38182 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 OldUTF8::ord('あ') == 0xE38182 $^X $__FILE__\n};
}

$_ = 'い';
if (OldUTF8::ord == 0xE38184) {
    print qq{ok - 2 \$_ = 'い'; OldUTF8::ord == 0xE38184 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = 'い'; OldUTF8::ord == 0xE38184 $^X $__FILE__\n};
}

__END__
