package App::FileSync::Transport::Local;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec;
use IPC::Open3 ();

# Runs filesync-server as a child process and speaks the wire protocol over its pipes.
# Used by the test suite, and for a server directory that is local to the client.
sub new {
    my ($class, %args) = @_;

    my $root   = $args{root}   or die "Local transport: no server root\n";
    my $repo   = $args{repo}   or die "Local transport: no repo\n";
    my $client = $args{client} or die "Local transport: no client id\n";
    my $role   = $args{role} || 'client';

    my $binary = $args{server_bin} || _default_server_bin();

    my @command = (
        $^X, $binary,
        '--root', $root,
        '--repo', $repo,
        '--client', $client,
        '--role', $role,
    );

    # stderr must NOT share the stdout pipe: that sends the child's diagnostics
    # into the protocol stream and corrupts it the first time the server warns
    # about anything.  "&>STDERR" dups the parent's stderr; passing a filehandle
    # here does not redirect the child at all - it leaves the child writing into
    # an unread pipe, so the first log line kills it with SIGPIPE.
    my ($writer, $reader);
    my $pid = IPC::Open3::open3($writer, $reader, '>&STDERR', @command);

    return bless {
        pid    => $pid,
        writer => $writer,
        reader => $reader,
    }, $class;
}

sub reader { $_[0]{reader} }
sub writer { $_[0]{writer} }

sub close {
    my ($self) = @_;

    return 1 if $self->{closed};
    $self->{closed} = 1;

    close $self->{writer} if $self->{writer};
    close $self->{reader} if $self->{reader};

    waitpid($self->{pid}, 0) if $self->{pid};

    return 1;
}

sub _default_server_bin {
    return $ENV{FILESYNC_SERVER_BIN}
        if defined $ENV{FILESYNC_SERVER_BIN} && length $ENV{FILESYNC_SERVER_BIN};

    # Works from lib/ in a checkout and from blib/lib/ under "make test": walk up
    # until a bin/filesync-server is found, then fall back to PATH (installed).
    my $directory = dirname(__FILE__);
    for (1 .. 6) {
        my $candidate = File::Spec->catfile($directory, 'bin', 'filesync-server');
        return $candidate if -f $candidate;
        $directory = dirname($directory);
    }

    return 'filesync-server';
}

1;
