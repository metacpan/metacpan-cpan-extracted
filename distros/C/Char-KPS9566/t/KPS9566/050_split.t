# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use KPS9566;
print "1..15\n";

my $__FILE__ = __FILE__;

$text = '‚h‚nD‚r‚x‚rF‚Q‚Q‚T‚T‚T‚WF‚X‚T|‚P‚O|‚O‚RF|‚|‚“‚ˆF‚‚‚”‚‰‚‚‚‚Œ';

# 7.7 split‰‰Zq(ƒŠƒXƒgƒRƒ“ƒeƒLƒXƒg)
@_ = split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(‚h‚nD‚r‚x‚r)(‚Q‚Q‚T‚T‚T‚W)(‚X‚T|‚P‚O|‚O‚R)(|‚|‚“‚ˆ)(‚‚‚”‚‰‚‚‚‚Œ)") {
    print qq{ok - 1 \@_ = split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(/F/, \$text); $^X $__FILE__\n};
}

# “Áê‚Èƒ}ƒbƒ`”í‰‰Zq // ‚ğg‚Á‚½ê‡
@_ = split(//, "‚“‚ˆ‚‚’‚”@‚”‚…‚“‚”");
if (join('', map {"($_)"} @_) eq "(‚“)(‚ˆ)(‚)(‚’)(‚”)(@)(‚”)(‚…)(‚“)(‚”)") {
    print qq{ok - 2 \@_ = split(//, "‚“‚ˆ‚‚’‚”@‚”‚…‚“‚”") $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \@_ = split(//, "‚“‚ˆ‚‚’‚”@‚”‚…‚“‚”") $^X $__FILE__\n};
}

# “Áê‚Èƒ}ƒbƒ`”í‰‰Zq " "(ƒXƒy[ƒX1ŒÂ•ª‚Ì’Êí‚Ì•¶š—ñ)‚ğg‚Á‚½ê‡
@_ = split(" ", "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ");
if (join('', map {"($_)"} @_) eq "(‚)(‚“‚ˆ‚‚’‚”)(‚”‚…‚“‚”)") {
    print qq{ok - 3 \@_ = split(" ", "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ") $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \@_ = split(" ", "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ") $^X $__FILE__\n};
}

# æ“ª‚Ì‹ó”’‚ğc‚µ‚½‚¢ê‡
@_ = split(m/\s+/, "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ");
if (join('', map {"($_)"} @_) eq "()(‚)(‚“‚ˆ‚‚’‚”)(‚”‚…‚“‚”)") {
    print qq{ok - 4 \@_ = split(m/\\s+/, "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ") $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \@_ = split(m/\\s+/, "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ") $^X $__FILE__\n};
}

# ––”ö‚Ì‹ó”’‚ğc‚µ‚½‚¢ê‡
@_ = split(" ", "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ", -1);
if (join('', map {"($_)"} @_) eq "(‚)(‚“‚ˆ‚‚’‚”)(‚”‚…‚“‚”)()") {
    print qq{ok - 5 \@_ = split(" ", "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ", -1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 \@_ = split(" ", "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ", -1) $^X $__FILE__\n};
}

# ƒ}ƒbƒ`”í‰‰Zq‚ªw’è‚³‚ê‚Ä‚¢‚È‚¢ê‡
$_ = "   ‚ ‚“‚ˆ‚‚’‚”   ‚”‚…‚“‚”   ";
@_ = split;
if (join('', map {"($_)"} @_) eq "(‚)(‚“‚ˆ‚‚’‚”)(‚”‚…‚“‚”)") {
    print qq{ok - 6 \@_ = split $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 \@_ = split $^X $__FILE__\n};
}

# 7.7.1.2 ƒ^[ƒQƒbƒg•¶š—ñ‚ªw’è‚³‚ê‚Ä‚¢‚È‚¢ê‡
$_ = $text;
@_ = split(/F/);
if (join('', map {"($_)"} @_) eq "(‚h‚nD‚r‚x‚r)(‚Q‚Q‚T‚T‚T‚W)(‚X‚T|‚P‚O|‚O‚R)(|‚|‚“‚ˆ)(‚‚‚”‚‰‚‚‚‚Œ)") {
    print qq{ok - 7 \@_ = split(/F/) $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 \@_ = split(/F/) $^X $__FILE__\n};
}

# 7.7.1.3 ŒÂ”ãŒÀ”í‰‰Zq‚ÌŠî–{
@_ = split(/F/, $text, 3);
if (join('', map {"($_)"} @_) eq "(‚h‚nD‚r‚x‚r)(‚Q‚Q‚T‚T‚T‚W)(‚X‚T|‚P‚O|‚O‚RF|‚|‚“‚ˆF‚‚‚”‚‰‚‚‚‚Œ)") {
    print qq{ok - 8 \@_ = split(/F/, \$text, 3) $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 \@_ = split(/F/, \$text, 3) $^X $__FILE__\n};
}

# 7.7.2 ‹ó—v‘f
@_ = split(m/F/, "‚P‚QF‚R‚SFF‚V‚W");
if (join('', map {"($_)"} @_) eq "(‚P‚Q)(‚R‚S)()(‚V‚W)") {
    print qq{ok - 9 \@_ = split(m/F/, "‚P‚QF‚R‚SFF‚V‚W") $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 \@_ = split(m/F/, "‚P‚QF‚R‚SFF‚V‚W") $^X $__FILE__\n};
}

# 7.7.2.1 ––”ö‚Ì‹ó—v‘f
@_ = split(m/F/, "‚P‚QF‚R‚SFF‚V‚WFFF");
if (join('', map {"($_)"} @_) eq "(‚P‚Q)(‚R‚S)()(‚V‚W)") {
    print qq{ok - 10 \@_ = split(m/F/, "‚P‚QF‚R‚SFF‚V‚WFFF") $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 \@_ = split(m/F/, "‚P‚QF‚R‚SFF‚V‚WFFF") $^X $__FILE__\n};
}

# 7.7.2.3 •¶š—ñ‚Ì—¼’[‚Å‚Ì“Áê‚Èƒ}ƒbƒ`
@_ = split(m/F/, "F‚P‚QF‚R‚SFF‚V‚W");
if (join('', map {"($_)"} @_) eq "()(‚P‚Q)(‚R‚S)()(‚V‚W)") {
    print qq{ok - 11 \@_ = split(m/F/, "F‚P‚QF‚R‚SFF‚V‚W") $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 \@_ = split(m/F/, "F‚P‚QF‚R‚SFF‚V‚W") $^X $__FILE__\n};
}

# u^v‚Æ‚¢‚¤³‹K•\Œ»‚ğg‚Á‚½ê‡
$_ = "‚`‚`‚`\n‚a‚a‚a\n‚b‚b‚b";
@_ = split(m/^/, $_);
if (join('', map {"($_)"} @_) eq "(‚`‚`‚`\n)(‚a‚a‚a\n)(‚b‚b‚b)") {
    print qq{ok - 12 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}
@_ = split(m/^/m, $_);
if (join('', map {"($_)"} @_) eq "(‚`‚`‚`\n)(‚a‚a‚a\n)(‚b‚b‚b)") {
    print qq{ok - 13 \@_ = split(m/^/m, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 \@_ = split(m/^/m, \$\_) $^X $__FILE__\n};
}

# 7.7.4 ƒLƒƒƒvƒ`ƒƒ•t‚«Š‡ŒÊ‚ğŠÜ‚Ş split ‚Ìƒ}ƒbƒ`”í‰‰Zq
@_ = split(/(<[^>]*>)/, "@‚‚‚„@<‚a>‚–‚…‚’‚™@<‚e‚n‚m‚s@‚ƒ‚‚Œ‚‚’‚’‚…‚„>‚–‚…‚’‚™</‚e‚n‚m‚s>@‚‚•‚ƒ‚ˆ</B>@‚…‚†‚†‚‚’‚”");
if (join('', map {"($_)"} @_) eq "(@‚‚‚„@)(<‚a>)(‚–‚…‚’‚™@)(<‚e‚n‚m‚s@‚ƒ‚‚Œ‚‚’‚’‚…‚„>)(‚–‚…‚’‚™)(</‚e‚n‚m‚s>)(@‚‚•‚ƒ‚ˆ)(</B>)(@‚…‚†‚†‚‚’‚”)") {
    print qq{ok - 14 \@_ = split(/(<[^>]*>)/, "@‚‚‚„@<‚a>‚–‚…‚’‚™@<‚e‚n‚m‚s@‚ƒ‚‚Œ‚‚’‚’‚…‚„>‚–‚…‚’‚™</‚e‚n‚m‚s>@‚‚•‚ƒ‚ˆ</B>@‚…‚†‚†‚‚’‚”") $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 \@_ = split(/(<[^>]*>)/, "@‚‚‚„@<‚a>‚–‚…‚’‚™@<‚e‚n‚m‚s@‚ƒ‚‚Œ‚‚’‚’‚…‚„>‚–‚…‚’‚™</‚e‚n‚m‚s>@‚‚•‚ƒ‚ˆ</B>@‚…‚†‚†‚‚’‚”") $^X $__FILE__\n};
}

# 7.7.3.1 split ‚É‚Í•›ì—p‚ª‚È‚¢‚±‚Æ‚ÌŠm”F
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
$a =~ m/ABC(DEF)G(HI)/;
if (($1 eq "DEF") and ($2 eq "HI")) {
    $b = "123,45,6,78,,90";
    @_ = split(/,/,$b);
    if (($1 eq "DEF") and ($2 eq "HI")) {
        print qq{ok - 15 split ‚É•›ì—p‚ª‚È‚¢‚±‚Æ‚ÌŠm”F ($1)($2) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 split ‚É•›ì—p‚ª‚È‚¢‚±‚Æ‚ÌŠm”F ($1)($2) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 split ‚É•›ì—p‚ª‚È‚¢‚±‚Æ‚ÌŠm”F ($1)($2) $^X $__FILE__\n};
}

__END__
