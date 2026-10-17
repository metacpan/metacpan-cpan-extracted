package TestUtil;

use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use IPC::Open3;
use JSON::MaybeXS;
use Time::HiRes qw(sleep);

our @EXPORT_OK = qw(ROOT free_port wait_port start_bg stop_bg run_cli
                    write_config mock_stdio_cmd);

use constant ROOT => abs_path(File::Spec->catdir(dirname(abs_path(__FILE__)), '..', '..'));

sub mock_stdio_cmd { return [ $^X, ROOT . '/t/lib/mock_stdio.pl' ] }

sub free_port {
    my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "free_port: $!";
    my $p = $s->sockport;
    close $s;
    return $p;
}

sub wait_port {
    my ($port) = @_;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 1);
        if ($s) { close $s; return 1 }
        sleep 0.1;
    }
    return 0;
}

# Starts a background process; returns its pid.
sub start_bg {
    my (%a) = @_;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        open STDOUT, '>', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;
        $ENV{$_} = $a{env}{$_} for keys %{ $a{env} || {} };
        exec @{ $a{cmd} } or exit 127;
    }
    return $pid;
}

sub stop_bg {
    my ($pid) = @_;
    return unless $pid;
    kill 'TERM', $pid;
    waitpid($pid, 0);
}

# Writes a config file with the given mcpServers map; returns its path.
sub write_config {
    my ($servers, %extra) = @_;
    my $dir  = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'config.json');
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} JSON::MaybeXS->new(utf8 => 1)->encode({ mcpServers => $servers, %extra });
    close $fh;
    return $path;
}

# Runs script/mcpcli; returns ($stdout, $stderr, $exit_code).
sub run_cli {
    my (%a) = @_;
    my @args = @{ $a{args} };
    my $dir  = tempdir(CLEANUP => 1);
    my $errf = File::Spec->catfile($dir, 'stderr');
    open my $errfh, '>', $errf or die $!;

    local %ENV = (%ENV, %{ $a{env} || {} });
    my $pid = open3(my $in, my $out, '>&' . fileno($errfh),
                    $^X, '-I' . ROOT . '/lib', ROOT . '/script/mcpcli', @args);
    close $errfh;

    local $SIG{ALRM} = sub { kill 'KILL', $pid; die "run_cli timed out\n" };
    alarm 60;
    { local $SIG{PIPE} = 'IGNORE'; print {$in} $a{stdin} if defined $a{stdin}; close $in; }
    my $stdout = do { local $/; <$out> };
    waitpid($pid, 0);
    alarm 0;

    open my $ef, '<', $errf or die $!;
    my $stderr = do { local $/; <$ef> };
    return ($stdout // '', $stderr // '', $? >> 8);
}

1;
