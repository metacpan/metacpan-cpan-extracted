# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use strict;
use OldUTF8;
print "1..256\n";

my $__FILE__ = __FILE__;

my $tno = 1;
for my $hexchr (0x00 .. 0xFF) {
    my $char = pack('C',$hexchr);
    if($char =~ /\C/){
        printf qq{ok - $tno "\\x%02X" =~ /\\C/ $^X $__FILE__\n}, $hexchr;
    }
    else{
        printf qq{not ok - $tno "\\x%02X" =~ /\\C/ $^X $__FILE__\n}, $hexchr;
    }
    $tno++;
}

__END__
