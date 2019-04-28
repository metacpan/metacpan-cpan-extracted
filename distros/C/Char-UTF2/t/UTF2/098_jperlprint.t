# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
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
