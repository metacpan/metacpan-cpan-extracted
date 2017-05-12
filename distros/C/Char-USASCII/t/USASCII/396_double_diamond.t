# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{‚ } ne "\x82\xa0";

use USASCII;

print "1..1\n";
if ($] < 5.022) {
    for my $tno (1..1) {
        print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
    }
    exit;
}

eval q{ undef @ARGV; close STDIN; <<>> };
if (not $@) {
    print qq{ok - 1 <<>> $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 <<>> $^X @{[__FILE__]}\n};
}

__END__
