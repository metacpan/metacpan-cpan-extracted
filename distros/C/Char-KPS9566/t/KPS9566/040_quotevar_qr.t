# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use KPS9566;
print "1..5\n";

my $__FILE__ = __FILE__;

$a = "ソ";
if ($a =~ qr/^\Q$a\E$/) {
    print qq#ok - 1 \$a =~ qr/^\\Q\$a\\E\$/ $^X $__FILE__\n#;
}
else {
    print qq#not ok - 1 \$a =~ qr/^\\Q\$a\\E\$/ $^X $__FILE__\n#;
}

$a[0] = "ソ";
if ($a[0] =~ qr/^\Q$a[0]\E$/) {
    print qq#ok - 2 \$a[0] =~ qr/^\\Q\$a[0]\\E\$/ $^X $__FILE__\n#;
}
else {
    print qq#not ok - 2 \$a[0] =~ qr/^\\Q\$a[0]\\E\$/ $^X $__FILE__\n#;
}

$b = 1;
$a[1] = '';
if ($a[$b] =~ qr/^\Q$a[$b]\E$/) {
    print qq#ok - 3 \$a[\$b] =~ qr/^\\Q\$a[\$b]\\E\$/ $^X $__FILE__\n#;
}
else {
    print qq#not ok - 3 \$a[\$b] =~ qr/^\\Q\$a[\$b]\\E\$/ $^X $__FILE__\n#;
}

$a{"ソ"} = "表";
if ($a{'ソ'} =~ qr/^\Q$a{'ソ'}\E$/) {
    print qq#ok - 4 \$a{'ソ'} =~ qr/^\\Q\$a{'ソ'}\\E\$/ $^X $__FILE__\n#;
}
else {
    print qq#not ok - 4 \$a{'ソ'} =~ qr/^\\Q\$a{'ソ'}\\E\$/ $^X $__FILE__\n#;
}

$b = "ソ";
if ($a{$b} =~ qr/^\Q$a{$b}\E$/) {
    print qq#ok - 5 \$a{\$b} =~ qr/^\\Q\$a{\$b}\\E\$/ $^X $__FILE__\n#;
}
else {
    print qq#not ok - 5 \$a{\$b} =~ qr/^\\Q\$a{\$b}\\E\$/ $^X $__FILE__\n#;
}

__END__
