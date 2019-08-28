# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{あ} ne "\x82\xa0";

use Big5;
print "1..10\n";

my $__FILE__ = __FILE__;

$a = "ソ";
if ("$a" eq $a) {
    print qq/ok - 1 "\$a" eq \$a $^X $__FILE__\n/;
}
else {
    print qq/not ok - 1 "\$a" eq \$a $^X $__FILE__\n/;
}

$a[0] = "ソ";
if ("$a[0]" eq $a[0]) {
    print qq/ok - 2 "\$a[0]" eq \$a[0] $^X $__FILE__\n/;
}
else {
    print qq/not ok - 2 "\$a[0]" eq \$a[0] $^X $__FILE__\n/;
}

$b = 1;
$a[1] = '';
if ("$a[$b]" eq $a[$b]) {
    print qq/ok - 3 "\$a[\$b]" eq \$a[\$b] $^X $__FILE__\n/;
}
else {
    print qq/not ok - 3 "\$a[\$b]" eq \$a[\$b] $^X $__FILE__\n/;
}

$a{"ソ"} = "表";
if ("$a{'ソ'}" eq $a{'ソ'}) {
    print qq/ok - 4 "\$a{'ソ'}" eq \$a{'ソ'} $^X $__FILE__\n/;
}
else {
    print qq/not ok - 4 "\$a{'ソ'}" eq \$a{'ソ'} $^X $__FILE__\n/;
}

$b = "ソ";
if ("$a{$b}" eq $a{$b}) {
    print qq/ok - 5 "\$a{\$b}" eq \$a{\$b} $^X $__FILE__\n/;
}
else {
    print qq/not ok - 5 "\$a{\$b}" eq \$a{\$b} $^X $__FILE__\n/;
}

#---

$a = "ソ";
if (qq{$a} eq $a) {
    print qq/ok - 6 qq{\$a} eq \$a $^X $__FILE__\n/;
}
else {
    print qq/not ok - 6 "\$a" eq \$a $^X $__FILE__\n/;
}

$a[0] = "ソ";
if (qq{$a[0]} eq $a[0]) {
    print qq/ok - 7 qq{\$a[0]} eq \$a[0] $^X $__FILE__\n/;
}
else {
    print qq/not ok - 7 "\$a[0]" eq \$a[0] $^X $__FILE__\n/;
}

$b = 1;
if (qq{$a[$b]} eq $a[$b]) {
    print qq/ok - 8 qq{\$a[\$b]} eq \$a[\$b] $^X $__FILE__\n/;
}
else {
    print qq/not ok - 8 "\$a[\$b]" eq \$a[\$b] $^X $__FILE__\n/;
}

$a{"ソ"} = "表";
if (qq{$a{'ソ'}} eq $a{'ソ'}) {
    print qq/ok - 9 qq{\$a{'ソ'}} eq \$a{'ソ'} $^X $__FILE__\n/;
}
else {
    print qq/not ok - 9 "\$a{'ソ'}" eq \$a{'ソ'} $^X $__FILE__\n/;
}

$b = "ソ";
if (qq{$a{$b}} eq $a{$b}) {
    print qq/ok - 10 qq{\$a{\$b}} eq \$a{\$b} $^X $__FILE__\n/;
}
else {
    print qq/not ok - 10 "\$a{\$b}" eq \$a{\$b} $^X $__FILE__\n/;
}

__END__
