use strict;
use warnings;
use 5.008_001;

use Test::More 0.98;
use File::Find;
use FindBin;

my $LIB_DIR    = "$FindBin::Bin/../lib";
my $SCRIPT_DIR = "$FindBin::Bin/../script";

find(\&test_use_ok,  $LIB_DIR);
find(\&test_scripts, $SCRIPT_DIR);

done_testing;

sub test_use_ok {
    my $found = $_;
    return unless (-f $found);
    return unless ($found =~ m/.*\.pm$/);

    my $path = $File::Find::name;
    $path =~ s|$LIB_DIR/||;
    my $module = $path;
    $module =~ s|.pm$||;
    $module =~ s|/|::|g;

    use_ok($module);
}

sub test_scripts {
    my $found = $_;
    return unless (-f $found && $found =~ m/^[^\.]/);
    require_ok($found);
    unless ($^O =~ m/^MSWin32$/) {
        ok -x $found, "$found is executable";
    }
}
