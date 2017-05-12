# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use INFORMIXV6ALS;
print "1..1\n";

my $chcp = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    $chcp = `chcp`;
}
if ($chcp !~ /932/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

# dbmopen
my %DBM;
eval {
    if (dbmopen(%DBM,'F機能',0777)) {
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
unlink('F機能');

__END__
