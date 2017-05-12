use strict;
use warnings;

use Cwd;
use File::Temp qw(tempdir);
use Test::More;
use CPAN::Inject;

plan skip_all => "CPAN::Inject->from_cpan_config() failed: $@." unless eval "CPAN::Inject->from_cpan_config(); 1;";

$| = 1;

use_ok('App::NoPAN');

my $tempdir = tempdir(CLEANUP => 1);

# test build
unless (my $pid = fork) {
    die "fork failed:$!"
        unless defined $pid;
    # child process
    open my $fh, '>', "$tempdir/build.log"
        or die "failed to open temporary file:$tempdir/build.log:$!";
    open STDOUT, '>&', $fh
        or die "failed to redirect STDOUT:$!";
    open STDERR, '>&', $fh,
        or die "failed to redirect STDERR:$!";
    close $fh;
    close STDIN;
    exec(
        $^X,
        qw(blib/script/nopan --no-install),
        "file://@{[getcwd]}/t.assets/perl/",
    );
    die "could not exec nopan:$!";
}
while (wait == -1) {}
my $exit_status = $?;

open my $fh, '<', "$tempdir/build.log"
    or die "failed to open $tempdir/build.log:$!";
print STDERR "******** $_"
    for ("log of test build:\n", <$fh>);
close $fh;
is $exit_status, 0, "build and test";

done_testing;

