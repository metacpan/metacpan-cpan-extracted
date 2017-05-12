# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Big5Plus;
print "1..2\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    print "ok - 2 # SKIP $^X $0\n";
    exit;
}

if (defined($ENV{'PERL5SHELL'}) and ($ENV{'PERL5SHELL'} =~ /Win95Cmd\.exe/xmsi)) {
    print "ok - 1 # SKIP $^X $0\n";
    print "ok - 2 # SKIP $^X $0\n";
    exit;
}

mkdir('directory',0777);
if (rmdir('directory')) {
    print "ok - 1 rmdir $^X $__FILE__\n";
    system("mkdir directory");
}
else {
    print "not ok - 1 rmdir: $! $^X $__FILE__\n";
}
rmdir('directory');

mkdir('D機能',0777);
if (rmdir('D機能')) {
    print "ok - 2 rmdir $^X $__FILE__\n";
    system("mkdir D機能");
}
else {
    print "not ok - 2 rmdir: $! $^X $__FILE__\n";
}
rmdir('D機能');

__END__
