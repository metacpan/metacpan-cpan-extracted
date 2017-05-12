# encoding: Latin5
# This file is encoded in Latin-5.
die "This file is not encoded in Latin-5.\n" if q{‚ } ne "\x82\xa0";

use Latin5;
print "1..1\n";

my $__FILE__ = __FILE__;

open(TMP,'>Kanji_xxx.tmp') || die "Can't open file: Kanji_xxx.tmp\n";
print TMP <<EOL;
‚ ‚¢‚¤    align
abcde ‚¨  align
‚©‚«‚­‚¯  align
‚±        align
EOL
close(TMP);

$CAT = 'perl -e "print <>"';
if (`$CAT Kanji_xxx.tmp` eq <<EOL) {
‚ ‚¢‚¤    align
abcde ‚¨  align
‚©‚«‚­‚¯  align
‚±        align
EOL
    print "ok - 1 $^X $__FILE__\n";
    unlink "Kanji_xxx.tmp";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

__END__
