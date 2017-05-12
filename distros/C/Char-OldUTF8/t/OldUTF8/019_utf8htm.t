# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..1\n";

$_ = '';

# Search pattern not terminated
# 「サーチパターンが終了しない」
eval { /表/ };
if ($@) {
    print "not ok - 1 eval { /HYO/ }\n";
}
else {
    print "ok - 1 eval { /HYO/ }\n";
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
