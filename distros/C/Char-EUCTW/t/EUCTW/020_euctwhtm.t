# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

$_ = '';

# Substitution replacement not terminated
# 「置換操作の置換文字列が終了しない」
my $eval = eval { s/表/裏/; };
if ($@) {
    print "not ok - 1 eval { s/HYO/URA/; }\n";
}
else {
    print "ok - 1 eval { s/HYO/URA/; }\n";
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
