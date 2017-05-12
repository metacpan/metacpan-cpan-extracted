# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;

BEGIN {
    print "1..4\n";
    if ($] >= 5.020) {
        require feature;
        feature::->import('postderef');
        require warnings;
        warnings::->unimport('experimental::postderef');
    }
    else{
        for my $tno (1..4) {
            print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
        }
        exit;
    }
}

$FILE = 'a scalar value';
@FILE = (qw(5 20 0));
%FILE = (qw(あか 1 あお 2 き 3 むらさきいろ 4));
open(FILE,$0);
sub FILE { 'はんなり' }
format FILE =
.
$gref = *FILE;

# same as *{$gref}{SCALAR}
if (${$gref->*{SCALAR}} eq ${*{$gref}{SCALAR}}) {
    print qq{ok - 1 \${\$gref->*{SCALAR}} eq \${*{\$gref}{SCALAR}} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 \${\$gref->*{SCALAR}} eq \${*{\$gref}{SCALAR}} $^X @{[__FILE__]}\n};
}

# same as *{$gref}{ARRAY}
if (join('.',@{$gref->*{ARRAY}}) eq join('.',@{*{$gref}{ARRAY}})) {
    print qq{ok - 2 join('.',\@{\$gref->*{ARRAY}}) eq join('.',\@{*{\$gref}{ARRAY}}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 join('.',\@{\$gref->*{ARRAY}}) eq join('.',\@{*{\$gref}{ARRAY}}) $^X @{[__FILE__]}\n};
}

# same as *{$gref}{HASH}
if (join(',',%{$gref->*{HASH}}) eq join(',',%{*{$gref}{HASH}})) {
    print qq{ok - 3 join(',',%{\$gref->*{HASH}}) eq join(',',%{*{\$gref}{HASH}}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 join(',',%{\$gref->*{HASH}}) eq join(',',%{*{\$gref}{HASH}}) $^X @{[__FILE__]}\n};
}

# same as *{$gref}{CODE}
if (&{$gref->*{CODE}} eq &{*{$gref}{CODE}}) {
    print qq{ok - 4 &{\$gref->*{CODE}} eq &{*{\$gref}{CODE}} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 &{\$gref->*{CODE}} eq &{*{\$gref}{CODE}} $^X @{[__FILE__]}\n};
}

__END__
