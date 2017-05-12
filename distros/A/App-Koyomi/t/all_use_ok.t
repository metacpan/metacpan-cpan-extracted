use strict;
use warnings;
use Test::More;
use File::Find;
use FindBin;

my $BASE_DIR = "$FindBin::Bin/../lib";

diag "Check use_ok for all modules under $BASE_DIR";
find(\&test_use_ok, $BASE_DIR);

done_testing;

sub test_use_ok {
    my $found = $_;
    return unless (-f $found);
    return unless ($found =~ m/.*\.pm$/);

    my $path = $File::Find::name;
    $path =~ s|$BASE_DIR/||;
    my $module = $path;
    $module =~ s|.pm$||;
    $module =~ s|/|::|g;

    use_ok($module);
}

