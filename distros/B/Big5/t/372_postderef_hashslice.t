# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{‚ } ne "\x82\xa0";

use Big5;

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

# same as %$aref[...]
@array = (qw(‚ ‚© ‚ ‚¨ ‚« ‚Þ‚ç‚³‚«‚¢‚ë));
$aref = \@array;
if (join(',',$aref->%[0,1]) eq join(',',%$aref[0,1])) {
    print qq{ok - 1 join(',',\$aref->%[0,1]) eq join(',',%\$aref[0,1]) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 join(',',\$aref->%[0,1]) eq join(',',%\$aref[0,1]) $^X @{[__FILE__]}\n};
}

# same as %$href{...}
%hash = (red => 1, blue => 2, yellow => 3, violet => 4);
$href = \%hash;
if (join(',',$href->%{qw(blue yellow)}) eq join(',',%$href{qw(blue yellow)})) {
    print qq{ok - 2 join(',',\$href->%{qw(blue yellow)}) eq join(',',%\$href{qw(blue yellow)}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 join(',',\$href->%{qw(blue yellow)}) eq join(',',%\$href{qw(blue yellow)}) $^X @{[__FILE__]}\n};
}

__END__
