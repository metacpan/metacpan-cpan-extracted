use strict;
use Test::More;
use File::Temp qw(tempdir);

eval "use Capture::Tiny";
Test::More->builder->BAIL_OUT("test requires Capture::Tiny") if $@;

eval "use IPC::Shareable";
Test::More->builder->BAIL_OUT("test requires IPC::Shareable") if $@;

# global variables across processes
my ($stdout, $stderr);
tie $stdout, 'IPC::Shareable', 'stdout', { create => 'true' } or die "tie failed\n";;
tie $stderr, 'IPC::Shareable', 'stderr', { create => 'true' } or die "tie failed\n";;

# emulate calling ppp on command line
sub ppp(@) {
    $stdout = undef;
    $stderr = undef;

    my $pid = fork();
    if ($pid == 0) {
        local @ARGV = @_;
        my ($stdout, $stderr);
        tie $stdout, 'IPC::Shareable', 'stdout';
        tie $stderr, 'IPC::Shareable', 'stderr';
        ($stdout, $stderr) = Capture::Tiny::capture(sub { do 'bin/ppp'; });
        exit;
    }
    waitpid($pid, 0);
}

# explicitly state dirs via command line
my $tmp = tempdir;

ppp "--img", "$tmp/images", "--log", "$tmp/logfiles", "t/files/hello.md";

is $stdout, "Hello, World!\n", "passed Markdown";
ok -d "$tmp/images", "created image directory";
ok -d "$tmp/logfiles", "created logfile directory";


done_testing;
