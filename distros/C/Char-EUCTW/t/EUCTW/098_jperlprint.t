# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

my $__FILE__ = __FILE__;

if ($^O eq 'MacOS') {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

open(TMP,'>Kanji_xxx.tmp') || die "Can't open file: Kanji_xxx.tmp\n";
print TMP <<EOL;
あいう    align
abcde お  align
かきくけ  align
こ        align
EOL
close(TMP);

$CAT = 'perl -e "binmode(STDOUT); print STDOUT <>"';
if (`$CAT Kanji_xxx.tmp` eq <<EOL) {
あいう    align
abcde お  align
かきくけ  align
こ        align
EOL
    print "ok - 1 $^X $__FILE__\n";
    unlink "Kanji_xxx.tmp";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

__END__
