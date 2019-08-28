# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{‚ } ne "\x82\xa0";

use Big5HKSCS;
print "1..3\n";

my $__FILE__ = __FILE__;

$text = '‚h‚nD‚r‚x‚rF‚Q‚Q‚T‚T‚T‚WF‚X‚T|‚P‚O|‚O‚RF|‚|‚“‚ˆF‚‚‚”‚‰‚‚‚‚Œ';

local $^W = 0;

# 7.7 split‰‰Zq(ƒŠƒXƒgƒRƒ“ƒeƒLƒXƒg)
@_ = split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(‚h‚nD‚r‚x‚r)(‚Q‚Q‚T‚T‚T‚W)(‚X‚T|‚P‚O|‚O‚R)(|‚|‚“‚ˆ)(‚‚‚”‚‰‚‚‚‚Œ)") {
    print qq{ok - 1 \@_ = split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(/F/, \$text); $^X $__FILE__\n};
}

# 7.7 split‰‰Zq(ƒXƒJƒ‰ƒRƒ“ƒeƒLƒXƒg)
my $a = split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(‚h‚nD‚r‚x‚r)(‚Q‚Q‚T‚T‚T‚W)(‚X‚T|‚P‚O|‚O‚R)(|‚|‚“‚ˆ)(‚‚‚”‚‰‚‚‚‚Œ)") {
    print qq{ok - 2 \$a = split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$a = split(/F/, \$text); $^X $__FILE__\n};
}

# 7.7 split‰‰Zq(voidƒRƒ“ƒeƒLƒXƒg)
split(/F/, $text);
if (join('', map {"($_)"} @_) eq "(‚h‚nD‚r‚x‚r)(‚Q‚Q‚T‚T‚T‚W)(‚X‚T|‚P‚O|‚O‚R)(|‚|‚“‚ˆ)(‚‚‚”‚‰‚‚‚‚Œ)") {
    print qq{ok - 3 (void) split(/F/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 (void) split(/F/, \$text); $^X $__FILE__\n};
}

__END__
