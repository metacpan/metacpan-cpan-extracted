# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..1\n";

# 긄깋�[궸궼궶귞궶궋궚궵빒럻돸궚궥귡걁괫걂
if (lc('귺귽긂긄긆') eq '귺귽긂긄긆') {
    print "ok - 1 lc('귺귽긂긄긆') eq '귺귽긂긄긆'\n";
}
else {
    print "not ok - 1 lc('귺귽긂긄긆') eq '귺귽긂긄긆'\n";
}

__END__

UHC.pm 궻룉뿚뙅됈궕댥돷궸궶귡궞궴귩딖뫲궢궲궋귡

if (Euhc::lc('귺귽긂긄긆') eq '귺귽긂긄긆') {

Shift-JIS긡긌긚긣귩맫궢궘댌궎
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
