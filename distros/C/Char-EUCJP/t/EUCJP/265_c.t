# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
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
