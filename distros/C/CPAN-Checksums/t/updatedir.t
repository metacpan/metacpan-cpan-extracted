# -*- Mode: cperl; cperl-indent-level: 4 -*-

# Before `make install' is performed this script should be runnable with
# `make test'.

use File::Path qw(mkpath rmtree);
use File::Spec;
use Test::More;
my $HAVE_TIME_HIRES = 0;

sub _f ($) {File::Spec->catfile(split /\//, shift);}
sub _d ($) {File::Spec->catdir(split /\//, shift);}

if (eval { require Time::HiRes; 1; }) {
    $HAVE_TIME_HIRES = 1;
}

use_ok("CPAN::Checksums");
my $ret = CPAN::Checksums::updatedir("t", "..");
ok($ret >= 1, "ret[$ret]");

my $warn;
{
    chmod 0644, _f"t/43";
    local *F;
    open F, ">", _f"t/43" or die;
    print F "4321\n" x 1_000_000;
    close F;
    local $CPAN::Checksums::CAUTION;
    $CPAN::Checksums::CAUTION=1;
    $SIG{__WARN__} = sub { $warn = shift; };
    $ret = CPAN::Checksums::updatedir("t", "..");
    is($ret,2,"changed once");

    like($warn,qr/^differing old\/new/m,"warning emitted");

    my $start = $HAVE_TIME_HIRES ? Time::HiRes::time() : time;
    $ret = CPAN::Checksums::updatedir("t", "..");
    my $tooktime = ($HAVE_TIME_HIRES ? Time::HiRes::time() : time) - $start;
    is($ret,1,"no change tooktime[$tooktime]");

    open F, ">", _f"t/43";
    print F "43\n";
    close F;
    $warn="";
}

$ret = CPAN::Checksums::updatedir("t", "..");
is($ret,2,"changed again");
is($warn,"","no warning");
my @stat = stat _f"t/CHECKSUMS";
sleep 2;
$ret = CPAN::Checksums::updatedir("t", "..");
is($ret,1,"no change");
my @stat2 = stat _f"t/CHECKSUMS";
for my $s (0..7,9..11) { # 8==atime not our business; 12==blocks may magically change
    is($stat[$s],$stat2[$s],"unchanged stat element $s");
}
mkpath _d"t/emptydir";
$ret = CPAN::Checksums::updatedir(_d"t/emptydir", "..");
is($ret,2,"empty dir gives also 2");
ok(-f _f"t/emptydir/CHECKSUMS", "found the checksums file");
{
    rename _d"t/emptydir", _d"t/tdir" or die "Could not rename: $!";
    $ret = CPAN::Checksums::updatedir(_d"t/tdir", "..");
    is($ret,1,"after a rename gives 1");
    open my $fh, ">", _f"t/tdir/1";
    print $fh "1";
    close $fh or die "Could not close: $!";
    open $fh, ">", _f"t/tdir/2";
    print $fh "2\n";
    close $fh or die "Could not close: $!";
    $ret = CPAN::Checksums::updatedir(_d"t/tdir", "..");
    is($ret,2,"tdir with files returns 2");
    my $checksums = do {
        open $fh, "<", _f"t/tdir/CHECKSUMS" or die "Could not open: $!";
        local $/;
        <$fh>
    };
    my $cksum;
    eval $checksums;
    ok exists $cksum->{1}, "checksums file contains file 1";
    is $cksum->{1}{size}, 1, "size of file 1 is 1";
    like $cksum->{1}{cpan_path}, qr"CPAN-Checksums[-\d\.]*/t/tdir",
        "cpan_path is as expected" or diag explain $cksum;
    ok exists $cksum->{2}, "checksums file contains file 2";
    is $cksum->{2}{size}, 2, "size of file 2 is 2";
    unlink, _f"t/tdir/2";
    $ret = CPAN::Checksums::updatedir(_d"t/tdir", "..");
    is($ret,1,"tdir with one deleted file returns 1");
    @stat = stat _f"t/tdir/CHECKSUMS";
    $CPAN::Checksums::MIN_MTIME_CHECKSUMS = $stat[9]+1;
    $ret = CPAN::Checksums::updatedir(_d"t/tdir", "..");
    is($ret,2,"tdir with bumped minimum mtime returns 2");
}
rmtree _d"t/tdir";

done_testing();
