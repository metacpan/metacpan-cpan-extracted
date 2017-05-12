# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCTW;
print "1..8\n";

my $__FILE__ = __FILE__;

my @m_once = ();

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ ?あああ?) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 1 ?あああ? $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 ?あああ? $^X $__FILE__\n};
}

@m_once = ();
my $re = '';
for (qw(あああ いいい ううう)) {
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
for (qw(あああ あああ あああ)) {
    if ($_ =~ ? あ あ あ ?x) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 3 ? あ あ あ ?x $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 ? あ あ あ ?x $^X $__FILE__\n};
}

@m_once = ();
for ("あああ\nいいい","あああ\nいいい","あああ\nいいい") {
    if ($_ =~ ?^いいい?m) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 4 ?^いいい?m $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 ?^いいい?m $^X $__FILE__\n};
}

@m_once = ();
for ("あ\nい","あ\nい","あ\nい") {
    if ($_ =~ ?あ.い?s) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 5 ?あ.い?s $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 ?あ.い?s $^X $__FILE__\n};
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
for (qw(あああ あああ あああ)) {
    if ($_ =~ ?あああ?g) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 7 ?あああ?g $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 ?あああ?g $^X $__FILE__\n};
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ ?あああ?gc) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 8 ?あああ?gc $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 ?あああ?gc $^X $__FILE__\n};
}

__END__

