# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..2\n";

my $__FILE__ = __FILE__;

my $input = '  My name is Yamada Taro';

my $space = ' ';
my $a = join '_', split $space, $input;
if ($a eq 'My_name_is_Yamada_Taro') {
    print qq{ok - 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__\n};
}

my $b = join '_', split ' ', $input;
if ($b eq 'My_name_is_Yamada_Taro') {
    print qq{ok - 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__\n};
}

__END__
http://d.hatena.ne.jp/syohex/20130613/1371103504

曄峏揰

split偺戞堦堷悢偵嬻敀堦偮偺暥帤楍儕僥儔儖傪梌偊偨偲偒偲

嬻敀堦偮偑戙擖偝傟偨曄悢傪巜掕偟偨偲偒偺嫇摦偑崱傑偱堘偭偰

偄偨偺偑摨偠偵側偭偨傛偆偱偡丅

Perl 5.16.3偱偺寢壥
  a = __My_name_is_Yamada_Taro
  b = My_name_is_Yamada_Taro

Perl 5.18.0偱偺寢壥
  a = My_name_is_Yamada_Taro
  b = My_name_is_Yamada_Taro

傓偟傠 5.18.0傛傝慜偼偦傫側嫇摦偩偭偨偺偐偲偄偆姶偠偱偡偑丄

堦墳抦偭偰偍偄偨曽偑椙偝偦偆偱偡丅
