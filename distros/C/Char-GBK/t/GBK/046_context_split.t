# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..3\n";

my $__FILE__ = __FILE__;

$text = '俬俷丏俽倄俽丗俀俀俆俆俆俉丗俋俆亅侾侽亅侽俁丗亅倎亅倱倛丗倧倫倲倝倧値倎倢';

local $^W = 0;

# 7.7 split墘嶼巕(儕僗僩僐儞僥僉僗僩)
@_ = split(/丗/, $text);
if (join('', map {"($_)"} @_) eq "(俬俷丏俽倄俽)(俀俀俆俆俆俉)(俋俆亅侾侽亅侽俁)(亅倎亅倱倛)(倧倫倲倝倧値倎倢)") {
    print qq{ok - 1 \@_ = split(/丗/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(/丗/, \$text); $^X $__FILE__\n};
}

# 7.7 split墘嶼巕(僗僇儔僐儞僥僉僗僩)
my $a = split(/丗/, $text);
if (join('', map {"($_)"} @_) eq "(俬俷丏俽倄俽)(俀俀俆俆俆俉)(俋俆亅侾侽亅侽俁)(亅倎亅倱倛)(倧倫倲倝倧値倎倢)") {
    print qq{ok - 2 \$a = split(/丗/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$a = split(/丗/, \$text); $^X $__FILE__\n};
}

# 7.7 split墘嶼巕(void僐儞僥僉僗僩)
split(/丗/, $text);
if (join('', map {"($_)"} @_) eq "(俬俷丏俽倄俽)(俀俀俆俆俆俉)(俋俆亅侾侽亅侽俁)(亅倎亅倱倛)(倧倫倲倝倧値倎倢)") {
    print qq{ok - 3 (void) split(/丗/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 (void) split(/丗/, \$text); $^X $__FILE__\n};
}

__END__
