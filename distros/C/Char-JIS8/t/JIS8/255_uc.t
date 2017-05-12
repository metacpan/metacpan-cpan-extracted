# encoding: JIS8
# This file is encoded in JIS8.
die "This file is not encoded in JIS8.\n" if q{‚ } ne "\x82\xa0";

use strict;
use JIS8;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

printf("1..%d\n", scalar(keys %uc));

my $tno = 1;
for my $char (sort keys %uc){
    if (uc($char) eq $uc{$char}) {
        printf(qq{ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    else {
        printf(qq{not ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    $tno++;
}

__END__
