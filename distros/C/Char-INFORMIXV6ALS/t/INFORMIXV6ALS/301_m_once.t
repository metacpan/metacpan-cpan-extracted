# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{‚ } ne "\x82\xa0";

use strict;
use INFORMIXV6ALS;
print "1..8\n";

my $__FILE__ = __FILE__;

my @m_once = ();

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ ?‚ ‚ ‚ ?) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 1 ?‚ ‚ ‚ ? $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 ?‚ ‚ ‚ ? $^X $__FILE__\n};
}

@m_once = ();
my $re = '';
for (qw(‚ ‚ ‚  ‚¢‚¢‚¢ ‚¤‚¤‚¤)) {
    $re = $_;
    if ($_ =~ ?$re?o) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 2 ?\$re?o $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 ?\$re?o $^X $__FILE__\n};
}

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ ? ‚  ‚  ‚  ?x) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 3 ? ‚  ‚  ‚  ?x $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 ? ‚  ‚  ‚  ?x $^X $__FILE__\n};
}

@m_once = ();
for ("‚ ‚ ‚ \n‚¢‚¢‚¢","‚ ‚ ‚ \n‚¢‚¢‚¢","‚ ‚ ‚ \n‚¢‚¢‚¢") {
    if ($_ =~ ?^‚¢‚¢‚¢?m) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 4 ?^‚¢‚¢‚¢?m $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 ?^‚¢‚¢‚¢?m $^X $__FILE__\n};
}

@m_once = ();
for ("‚ \n‚¢","‚ \n‚¢","‚ \n‚¢") {
    if ($_ =~ ?‚ .‚¢?s) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 5 ?‚ .‚¢?s $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 ?‚ .‚¢?s $^X $__FILE__\n};
}

@m_once = ();
for (qw(AAA AAA AAA)) {
    if ($_ =~ ?aaa?i) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 6 ?aaa?i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 ?aaa?i $^X $__FILE__\n};
}

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ ?‚ ‚ ‚ ?g) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 7 ?‚ ‚ ‚ ?g $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 ?‚ ‚ ‚ ?g $^X $__FILE__\n};
}

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ ?‚ ‚ ‚ ?gc) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 8 ?‚ ‚ ‚ ?gc $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 ?‚ ‚ ‚ ?gc $^X $__FILE__\n};
}

__END__

