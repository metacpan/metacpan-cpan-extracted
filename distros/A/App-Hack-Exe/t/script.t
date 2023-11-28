#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use IPC::Open3 qw/ open3 /;
use Symbol qw/ gensym /;

use FindBin qw//;
my $script = "$FindBin::RealBin/../hack.exe.in";

require App::Hack::Exe;

ok -f $script, 'script exists';

# Test run with no arguments
my ($stdout, $stderr, $ret) = _run_script();
my @args = ('no args');
is($ret, 2,
    "script (@args) should exit 2"
);
like($stderr, qr/^Usage: hack\.exe/,
    qq{script output (@args) should begin with "Usage: hack.exe"}
);
like($stderr, qr/\n$/,
    "script output (@args) should end with a newline"
);
is($stdout, '',
    "script (@args) should not output on stdout"
);

# Test run with too many arguments
@args = ('localhost', 'example.com');
($stdout, $stderr, $ret) = _run_script(@args);
is($ret, 2,
    "script (@args) should exit 2"
);
like($stderr, qr/^Usage: hack\.exe/,
    qq{script output (@args) should begin with "Usage: hack.exe"}
);
like($stderr, qr/\n$/,
    "script output (@args) should end with a newline"
);
is($stdout, '',
    "script (@args) should not output on stdout"
);

# Test simulating one host
@args = ('localhost');
($stdout, $stderr, $ret) = _run_script(@args);
is($ret, 0,
    "script (@args) should exit 0"
);
like($stdout, qr/COMPLETE/,
    "script output (@args) should contain COMPLETE"
);
like($stdout, qr/root\@localhost/,
    "script output (@args) should show a prompt"
);
like($stdout, qr/\n$/,
    "script output (@args) should end with a newline"
);
is($stderr, '',
    "script (@args) should not output on stderr"
);

# Help message tests
@args = ('--help');
($stdout, $stderr, $ret) = _run_script(@args);
is($ret, 0,
    "script (@args) should exit 0"
);
like($stdout, qr/\n$/,
    "script output (@args) should end with a newline"
);
like($stdout, qr/^Usage:/,
    qq{script output (@args) should begin with "Usage:"}
);
is($stderr, '',
    "script (@args) should not output on stderr"
);

# Version message tests
@args = ('--version');
($stdout, $stderr, $ret) = _run_script(@args);
is($ret, 0,
    "script (@args) exits 0"
);
like($stdout, qr/\n$/,
    "script output (@args) should end with a newline"
);
my $cv = quotemeta $App::Hack::Exe::VERSION;
like($stdout, qr/$cv/,
    "script output (@args) should contain module version",
);
is($stderr, '',
    "script (@args) should not output on stderr"
);

sub _run_script {
    my @with_args = @_;
    return _run_capture(
        cmd => [$^X, $script, @with_args],
    );
}

sub _run_capture {
    my (%args) = @_;
    $args{stdin} //= '';
    my @cmd = @{$args{cmd}};
    my $child_out = gensym();
    my $child_err = ($args{combined_io} ? $child_out : gensym());
    my $pid = open3($args{stdin}, $child_out, $child_err, @cmd);
    waitpid $pid, 0;
    my $exitcode = $? >> 8;

    local $/; # slurp!
    return (
        scalar <$child_out>,
        scalar <$child_err>,
        $exitcode,
    );
}
