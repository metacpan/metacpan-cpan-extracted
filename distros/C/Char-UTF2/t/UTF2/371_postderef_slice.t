# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;

BEGIN {
    print "1..2\n";
    if ($] >= 5.020) {
        require feature;
        feature::->import('postderef');
        require warnings;
        warnings::->unimport('experimental::postderef');
    }
    else{
        for my $tno (1..2) {
            print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
        }
        exit;
    }
}

# same as @$aref[...]
@array = (qw(あか あお き むらさきいろ));
$aref = \@array;
if (join(',',$aref->@[1,3]) eq join(',',@$aref[1,3])) {
    print qq{ok - 1 join(',',\$aref->\@[1,3]) eq join(',',\@\$aref[1,3]) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 join(',',\$aref->\@[1,3]) eq join(',',\@\$aref[1,3]) $^X @{[__FILE__]}\n};
}

# same as @$href{...}
%hash = (red => 1, blue => 2, yellow => 3, violet => 4);
$href = \%hash;
if (join(',',$href->@{qw(red violet)}) eq join(',',@$href{qw(red violet)})) {
    print qq{ok - 2 join(',',\$href->\@{qw(red violet)}) eq join(',',\@\$href{qw(red violet)}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 join(',',\$href->\@{qw(red violet)}) eq join(',',\@\$href{qw(red violet)}) $^X @{[__FILE__]}\n};
}

__END__
