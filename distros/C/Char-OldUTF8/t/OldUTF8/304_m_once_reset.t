# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use strict;
use OldUTF8;
print "1..8\n";

my $__FILE__ = __FILE__;

# Test::Harness::runtests() and reset() make "Error: Runtime exception".
#
# t/304_m_once_reset........Error: Runtime exception
# Error: Runtime exception
# Can't spawn "cmd.exe": No such file or directory at Foo.pm line NNN.
# Callback called exit at t/304_m_once_reset.t line NNN.
# BEGIN failed--compilation aborted at t/304_m_once_reset.t line NNN.
# dubious
#         Test returned status 2 (wstat 512, 0x200)
# DIED. FAILED tests 1-8
#         Failed 8/8 tests, 0.00% okay

if ($] =~ /^5\.005/) {
    for my $tno (1 .. 8) {
        print qq{ok - $tno # SKIP $^X/$] $^O $__FILE__\n};
    }
    exit;
}

my @m_once = ();

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ m?あああ?) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 1 m?あああ?; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 m?あああ?; reset $^X $__FILE__\n};
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
    reset;
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 2 m?\$re?o; reset $^X $__FILE__\n};
}
else {
    if (($^O eq 'MSWin32') and ($] eq '5.006001')) {
        print qq{ok - 2 # SKIP m?\$re?o; reset $^X/$] $^O $__FILE__\n};
    }
    else {
        print qq{not ok - 2 m?\$re?o; reset $^X $__FILE__\n};
    }
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ m? あ あ あ ?x) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 3 m? あ あ あ ?x; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 m? あ あ あ ?x; reset $^X $__FILE__\n};
}

@m_once = ();
for ("あああ\nいいい","あああ\nいいい","あああ\nいいい") {
    if ($_ =~ m?^いいい?m) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 4 m?^いいい?m; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 m?^いいい?m; reset $^X $__FILE__\n};
}

@m_once = ();
for ("あ\nい","あ\nい","あ\nい") {
    if ($_ =~ m?あ.い?s) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 5 m?あ.い?s; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 m?あ.い?s; reset $^X $__FILE__\n};
}

@m_once = ();
for (qw(AAA AAA AAA)) {
    if ($_ =~ m?aaa?i) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 6 m?aaa?i; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 m?aaa?i; reset $^X $__FILE__\n};
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ m?あああ?g) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 7 m?あああ?g; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 m?あああ?g; reset $^X $__FILE__\n};
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ m?あああ?gc) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 8 m?あああ?gc; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 m?あああ?gc; reset $^X $__FILE__\n};
}

__END__

