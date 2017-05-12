# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use GB18030;
print "1..2\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    print "ok - 2 # SKIP $^X $0\n";
    exit;
}

mkdir('directory',0777);
if (rename('directory','directory2')) {
    print "ok - 1 rename $^X $__FILE__\n";
    rename('directory2','directory');
}
else {
    print "not ok - 1 rename: $! $^X $__FILE__\n";
}
rmdir('directory');

mkdir('D婡擻',0777);
rmdir('D2婡擻');
if (rename('D婡擻','D2婡擻')) {
    print "ok - 2 rename $^X $__FILE__\n";
    rename('D2婡擻','D婡擻');
}
else {
    print "not ok - 2 rename: $! $^X $__FILE__\n";
}
rmdir('D婡擻');

__END__
