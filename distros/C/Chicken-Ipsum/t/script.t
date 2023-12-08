#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use IPC::Open3 qw/ open3 /;
use Symbol qw/ gensym /;

use FindBin qw//;
my $script = "$FindBin::RealBin/../chicken-ipsum.in";

require Chicken::Ipsum;

ok -f $script, 'script exists';

# Test run with no arguments
my ($stdout, $stderr, $ret) = run_script();
is $ret, 0, 'script exits 0';
like $stdout, qr/^[A-Z]/, 'beginning of script output is a capitalized word';
like $stdout, qr/[!.?]/, 'script output contains a sentence-ending mark';
like $stdout, qr/\n$/, 'script output ends with a newline';
is $stderr, '', 'script does not output on stderr';

# Test getting only one paragraph
($stdout, $stderr, $ret) = run_script('1');
is $ret, 0, 'script (1) exits 0';
like $stdout, qr/^[A-Z]/, 'beginning of script output (1) is a capitalized word';
like $stdout, qr/[!.?]/, 'script output (1) contains a sentence-ending mark';
like $stdout, qr/\n$/, 'script output (1) ends with a newline';
unlike $stdout, qr/\n\n/, 'script output (1) does not contain more than one paragraph';
is $stderr, '', 'script (1) does not output on stderr';

# Test getting only one paragraph
($stdout, $stderr, $ret) = run_script('4');
is $ret, 0, 'script (4) exits 0';
like $stdout, qr/^[A-Z]/, 'beginning of script output (4) is a capitalized word';
like $stdout, qr/[!.?]/, 'script output (4) contains a sentence-ending mark';
like $stdout, qr/\n$/, 'script output (4) ends with a newline';
like $stdout, qr/\n\n/, 'script output (4) contains more than one paragraph';
is $stderr, '', 'script (4) does not output on stderr';

# Help message tests
($stdout, $stderr, $ret) = run_script('--help');
is $ret, 0, 'script (--help) exits 0';
like $stdout, qr/\n$/, 'script output (--help) ends with a newline';
like $stdout, qr/^Usage:/, 'script output (--help) begins with "Usage:"';
is $stderr, '', 'script (--help) does not output on stderr';

# Version message tests
($stdout, $stderr, $ret) = run_script('--version');
is $ret, 0, 'script (--version) exits 0';
like $stdout, qr/\n$/, 'script output (--version) ends with a newline';
my $cv = quotemeta $Chicken::Ipsum::VERSION;
like $stdout, qr/$cv/, 'script output (--version) contains module version';
is $stderr, '', 'script (--version) does not output on stderr';

sub run_script {
    my @args = @_;
    return run_capture(
        cmd => [$^X, $script, @args],
    );
}

sub run_capture {
    my (%args) = @_;
    $args{stdin} //= '';
    my @cmd = @{$args{cmd}};
    my $child_out = gensym();
    my $child_err = ($args{combined_io} ? $child_out : gensym());
    my $pid = open3 $args{stdin}, $child_out, $child_err, @cmd;
    waitpid $pid, 0;
    my $exitcode = $? >> 8;

    local $/; # slurp!
    return (
        scalar <$child_out>,
        scalar <$child_err>,
        $exitcode,
    );
}
