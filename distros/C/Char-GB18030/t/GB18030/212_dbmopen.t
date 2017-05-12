# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use GB18030;
print "1..1\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932|936/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

# dbmopen
my %DBM;
eval {
    if (dbmopen(%DBM,'F婡擻',0777)) {
        print "ok - 1 dbmopen $^X $__FILE__\n";
        dbmclose(%DBM);
    }
    else {
        print "not ok - 1 dbmopen: $! $^X $__FILE__\n";
    }
};
if ($@) {
    print "ok - 1 # PASS dbmopen $^X $__FILE__\n";
}

if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    system('del F*.* >NUL');
}
else {
    system('del F*.* >NUL 2>NUL');
}
unlink('F婡擻');

__END__
