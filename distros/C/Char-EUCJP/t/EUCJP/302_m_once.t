# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
print "1..8\n";

my $__FILE__ = __FILE__;

my @m_once = ();

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ m?あああ?) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 1 m?あああ? $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 m?あああ? $^X $__FILE__\n};
}

@m_once = ();
my $re = '';
for (qw(あああ いいい ううう)) {
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
for (qw(あああ あああ あああ)) {
    if ($_ =~ m? あ あ あ ?x) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 3 m? あ あ あ ?x $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 m? あ あ あ ?x $^X $__FILE__\n};
}

@m_once = ();
for ("あああ\nいいい","あああ\nいいい","あああ\nいいい") {
    if ($_ =~ m?^いいい?m) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 4 m?^いいい?m $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 m?^いいい?m $^X $__FILE__\n};
}

@m_once = ();
for ("あ\nい","あ\nい","あ\nい") {
    if ($_ =~ m?あ.い?s) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 5 m?あ.い?s $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 m?あ.い?s $^X $__FILE__\n};
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
for (qw(あああ あああ あああ)) {
    if ($_ =~ m?あああ?g) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 7 m?あああ?g $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 m?あああ?g $^X $__FILE__\n};
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ m?あああ?gc) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 8 m?あああ?gc $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 m?あああ?gc $^X $__FILE__\n};
}

__END__

