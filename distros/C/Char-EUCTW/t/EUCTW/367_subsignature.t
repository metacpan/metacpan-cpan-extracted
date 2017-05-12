# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
BEGIN {
    print "1..9\n";
    if ($] >= 5.020) {
        require feature;
        feature::->import('signatures');
        require warnings;
        warnings::->unimport('experimental::signatures');
    }
    else {
        for my $tno (1 .. 9) {
            print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
        }
        exit;
    }
}

sub f001 ($a="ソ") { $a }
if (f001() eq "ソ") {
    print qq{ok - 1 sub f001 (\$a="ソ") $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 sub f001 (\$a="ソ") $^X @{[__FILE__]}\n};
}

sub f002 ($a=qq{ソ}) { $a }
if (f002() eq 'ソ') {
    print qq{ok - 2 sub f002 (\$a=qq{ソ}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 sub f002 (\$a=qq{ソ}) $^X @{[__FILE__]}\n};
}

sub f003 ($a=<<END) { $a }
ソ
END
if (f003() eq "ソ\n") {
    print qq{ok - 3 sub f003 (\$a=<<END) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 sub f003 (\$a=<<END) $^X @{[__FILE__]}\n};
}

sub f004 ($a=<<"END") { $a }
ソ
END
if (f004() eq "ソ\n") {
    print qq{ok - 4 sub f004 (\$a=<<"END") $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 sub f004 (\$a=<<"END") $^X @{[__FILE__]}\n};
}

sub f005 ($a='ソ') { $a }
if (f005() eq 'ソ') {
    print qq{ok - 5 sub f005 (\$a='ソ') $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 sub f005 (\$a='ソ') $^X @{[__FILE__]}\n};
}

sub f006 ($a=q{ソ}) { $a }
if (f006() eq 'ソ') {
    print qq{ok - 6 sub f006 (\$a=q{ソ}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 sub f006 (\$a=q{ソ}) $^X @{[__FILE__]}\n};
}

sub f007 ($a=<<'END') { $a }
ソ
END
if (f007() eq "ソ\n") {
    print qq{ok - 7 sub f007 (\$a=<<'END') $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 sub f007 (\$a=<<'END') $^X @{[__FILE__]}\n};
}

sub f008 ($a=qr{ソ}) { $a }
if ('ソ' =~ f008()) {
    print qq{ok - 8 sub f008 (\$a=qr{ソ}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 sub f008 (\$a=qr{ソ}) $^X @{[__FILE__]}\n};
}

sub f009 ($a=qr'ソ') { $a }
if ('ソ' =~ f009()) {
    print qq{ok - 9 sub f009 (\$a=qr'ソ') $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 sub f009 (\$a=qr'ソ') $^X @{[__FILE__]}\n};
}

__END__
