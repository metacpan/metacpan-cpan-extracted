# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..2\n";

my $__FILE__ = __FILE__;

# 峊偊傔側検巜掕巕傪娷傓僷僞乕儞 (椺偊偽 C<.??>傗C<\d*?>) 偼丄
# 嬻暥帤楍偲儅僢僠偡傞偙偲偑偱偒傑偡偑丄C<jsplit()> 偺僷僞乕儞偲偟偰梡偄偨応崌丄
# 慻傒崬傒偺 C<split()> 偐傜梊憐偝傟傞摦嶌偲堎側傞偙偲偑偁傝傑偡丅

if (join('', map {"($_)"} split(/.??/, '傾僀僂')) eq '(傾)(僀)(僂)') {
    print "ok - 1 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/.??/, '傾僀僂')) eq '(傾)(僀)(僂)')\n";
}
else {
    print "not ok - 1 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/.??/, '傾僀僂')) eq '(傾)(僀)(僂)')\n";
}

if (join('', map {"($_)"} split(/\d*?/, '傾僀僂')) eq '(傾)(僀)(僂)') {
    print "ok - 2 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/\\d*?/, '傾僀僂')) eq '(傾)(僀)(僂)')\n";
}
else {
    print "not ok - 2 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/\\d*?/, '傾僀僂')) eq '(傾)(僀)(僂)')\n";
}

__END__

