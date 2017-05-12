# encoding: TIS620
# This file is encoded in TIS-620.
die "This file is not encoded in TIS-620.\n" if q{ } ne "\x82\xa0";

use TIS620;

BEGIN {
    if ($] >= 5.022) {
        eval q{
            require experimental;
            experimental->import(qw(bitwise));
        };
    }
}

print "1..7\n";
if ($] < 5.022) {
    for my $tno (1..7) {
        print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
    }
    exit;
}

$_ = eval q{ ~. '105' };
if (not $@) {
    print qq{ok - 1 ~. '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 ~. '105' $^X @{[__FILE__]}\n};
}

$_ = eval q{ '150' |. '105' };
if (not $@) {
    print qq{ok - 2 '150' |. '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 '150' |. '105' $^X @{[__FILE__]}\n};
}

$_ = eval q{ '150' &. '105' };
if (not $@) {
    print qq{ok - 3 '150' &. '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 '150' &. '105' $^X @{[__FILE__]}\n};
}

$_ = eval q{ '150' ^. '105' };
if (not $@) {
    print qq{ok - 4 '150' ^. '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 '150' ^. '105' $^X @{[__FILE__]}\n};
}

$_ = '150';
eval q{ $_ &.= '105' };
if (not $@) {
    print qq{ok - 5 \$_ &.= '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 \$_ &.= '105' $^X @{[__FILE__]}\n};
}

$_ = '150';
eval q{ $_ |.= '105' };
if (not $@) {
    print qq{ok - 6 \$_ |.= '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 \$_ |.= '105' $^X @{[__FILE__]}\n};
}

$_ = '150';
eval q{ $_ ^.= '105' };
if (not $@) {
    print qq{ok - 7 \$_ ^.= '105' $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 \$_ ^.= '105' $^X @{[__FILE__]}\n};
}

__END__
