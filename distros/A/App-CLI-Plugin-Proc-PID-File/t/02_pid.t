use strict;
use Test::More tests => 2;
use lib qw(t/lib);
use MyApp;
use File::Spec;

our($TEST_PIDFILE, $PID_FILE);

{
    local *ARGV = [qw(write)];
    MyApp->dispatch;
}
ok(!-e $PID_FILE, "pf pidfile non exists test");

open my $fh, "<", $TEST_PIDFILE or die "can not open $TEST_PIDFILE";
chomp(my $pid = do { local $/ = undef; <$fh>});
close $fh;
unlink $TEST_PIDFILE;
ok($pid == $$, "pf same pid test");

