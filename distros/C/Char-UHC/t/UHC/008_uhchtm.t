# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..1\n";

# In string, @dog now must be written as \@dog (Perl 5.6.0귏궳)
# 걏빒럻쀱궻뭷궳궼갂@dog궼뜞궼\@dog궴룕궔궶궚귢궽궶귞궶궋걐
if ("됓�@\flower" eq pack('C10',0x89,0xd4,0x81,0x40,0x0C,0x6c,0x6f,0x77,0x65,0x72)) {
    print qq<ok - 1 "HANA yen flower"\n>;
}
else {
    print qq<not ok - 1 "HANA yen flower"\n>;
}

__END__

UHC.pm 궻룉뿚뙅됈궕댥돷궸궶귡궞궴귩딖뫲궢궲궋귡

if ("됓�\@\flower" eq pack('C10',0x89,0xd4,0x81,0x40,0x0C,0x6c,0x6f,0x77,0x65,0x72)) {

Shift-JIS긡긌긚긣귩맫궢궘댌궎
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
