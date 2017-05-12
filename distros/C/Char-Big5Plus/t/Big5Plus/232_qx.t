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

my @qx = ();

mkdir('directory',0777);
system('echo 1 >directory\\qx.txt');
if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    @qx = split /\n/, `dir /b directory`;
}
else{
    @qx = split /\n/, `dir /b directory 2>NUL`;
}
if (@qx) {
    print "ok - 1 qx $^X $__FILE__\n";
}
else {
    print "not ok - 1 qx: $! $^X $__FILE__\n";
}
system('del directory\\qx.txt');
rmdir('directory');

mkdir('D機能',0777);
system('echo 1 >D機能\\qx.txt');
if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    @qx = split /\n/, `dir /b D機能`;
}
else{
    @qx = split /\n/, `dir /b D機能 2>NUL`;
}
if (@qx) {
    print "ok - 2 qx $^X $__FILE__\n";
}
else {
    print "not ok - 2 qx: $! $^X $__FILE__\n";
}
system('del D機能\\qx.txt');
rmdir('D機能');

__END__
