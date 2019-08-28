# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Big5;
print "1..8\n";

my $__FILE__ = __FILE__;

my @m_once = ();

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ m?‚ ‚ ‚ ?) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 1 m?‚ ‚ ‚ ? $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 m?‚ ‚ ‚ ? $^X $__FILE__\n};
}

@m_once = ();
my $re = '';
for (qw(‚ ‚ ‚  ‚¢‚¢‚¢ ‚¤‚¤‚¤)) {
    $re = $_;
    if ($_ =~ m?$re?o) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 2 m?\$re?o $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 m?\$re?o $^X $__FILE__\n};
}

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ m? ‚  ‚  ‚  ?x) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 3 m? ‚  ‚  ‚  ?x $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 m? ‚  ‚  ‚  ?x $^X $__FILE__\n};
}

@m_once = ();
for ("‚ ‚ ‚ \n‚¢‚¢‚¢","‚ ‚ ‚ \n‚¢‚¢‚¢","‚ ‚ ‚ \n‚¢‚¢‚¢") {
    if ($_ =~ m?^‚¢‚¢‚¢?m) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 4 m?^‚¢‚¢‚¢?m $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 m?^‚¢‚¢‚¢?m $^X $__FILE__\n};
}

@m_once = ();
for ("‚ \n‚¢","‚ \n‚¢","‚ \n‚¢") {
    if ($_ =~ m?‚ .‚¢?s) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 5 m?‚ .‚¢?s $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 m?‚ .‚¢?s $^X $__FILE__\n};
}

@m_once = ();
for (qw(AAA AAA AAA)) {
    if ($_ =~ m?aaa?i) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 6 m?aaa?i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 m?aaa?i $^X $__FILE__\n};
}

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ m?‚ ‚ ‚ ?g) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 7 m?‚ ‚ ‚ ?g $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 m?‚ ‚ ‚ ?g $^X $__FILE__\n};
}

@m_once = ();
for (qw(‚ ‚ ‚  ‚ ‚ ‚  ‚ ‚ ‚ )) {
    if ($_ =~ m?‚ ‚ ‚ ?gc) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 8 m?‚ ‚ ‚ ?gc $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 m?‚ ‚ ‚ ?gc $^X $__FILE__\n};
}

__END__

