package App::FileSync::Transport::SSH;

use strict;
use warnings;

use File::Temp ();
use IPC::Open3 ();

use App::FileSync qw(validate_client_id validate_repo_name);

our $PROTO = 2;

# Runs filesync-server on the server host over one ssh connection and speaks the
# wire protocol on its pipes.  The ssh argument list is built here and never
# passed through a shell, so a repo or client id cannot become a command.
sub new {
    my ($class, %args) = @_;

    my $server = $args{server};
    die "SSH transport: no server given\n" unless defined $server && length $server;
    die "SSH transport: bad server '$server'\n" unless valid_server($server);

    my $repo = $args{repo};
    die "SSH transport: no repo given\n" unless defined $repo && length $repo;
    my ($repo_ok, $repo_reason) = validate_repo_name($repo);
    die "SSH transport: bad repo name: $repo_reason\n" unless $repo_ok;

    my $client = $args{client};
    die "SSH transport: no client id given\n" unless defined $client && length $client;
    my ($client_ok, $client_reason) = validate_client_id($client);
    die "SSH transport: bad client id: $client_reason\n" unless $client_ok;

    my $role = $args{role} || 'client';
    die "SSH transport: bad role '$role'\n"
        unless $role eq 'client' || $role eq 'replica';

    my $program = defined $args{server_command} && length $args{server_command}
        ? $args{server_command}
        : 'filesync-server';
    die "SSH transport: bad server command '$program'\n" unless valid_program($program);

    my $checking = defined $args{host_key_checking} && length $args{host_key_checking}
        ? $args{host_key_checking}
        : 'yes';
    die "SSH transport: bad host_key_checking '$checking'\n"
        unless $checking eq 'yes' || $checking eq 'accept-new';

    my @command = (defined $args{command} && length $args{command} ? $args{command} : 'ssh');

    push @command, '-T';
    push @command, '-o', 'BatchMode=yes';
    push @command, '-o', 'ServerAliveInterval=30';
    push @command, '-o', 'ConnectTimeout=10';
    push @command, '-o', "StrictHostKeyChecking=$checking";

    if (defined $args{known_hosts} && length $args{known_hosts}) {
        die "SSH transport: bad known_hosts path\n"
            if $args{known_hosts} =~ /[\0\n]/;
        push @command, '-o', 'UserKnownHostsFile=' . $args{known_hosts};
    }

    if (defined $args{identity} && length $args{identity}) {
        die "SSH transport: bad identity path\n" if $args{identity} =~ /[\0\n]/;
        push @command, '-i', $args{identity};
    }

    if (defined $args{port} && length $args{port}) {
        die "SSH transport: bad port '$args{port}'\n"
            unless $args{port} =~ /\A\d{1,5}\z/ && $args{port} > 0 && $args{port} < 65_536;
        push @command, '-p', $args{port};
    }

    for my $extra (@{ $args{extra_args} || [] }) {
        die "SSH transport: bad extra argument\n"
            if !defined($extra) || ref($extra) || $extra =~ /[\0\n]/;
        push @command, $extra;
    }

    push @command, $server;

    # The remote shell splits this back into arguments; every value below is
    # restricted to characters that are inert in a POSIX shell.
    push @command, $program,
        '--repo',   $repo,
        '--client', $client,
        '--role',   $role,
        '--proto',  $PROTO;

    # CreateProcess cannot start a batch file on its own, so a configured
    # .cmd/.bat wrapper is launched by the command interpreter explicitly.
    if ($^O eq 'MSWin32' && $command[0] =~ /\.(?:cmd|bat)\z/i) {
        my $comspec = defined $ENV{COMSPEC} && length $ENV{COMSPEC}
            ? $ENV{COMSPEC}
            : 'cmd.exe';
        unshift @command, $comspec, '/d', '/c';
    }

    my $errors = File::Temp->new(UNLINK => 1);
    my $err_path = $errors->filename;

    # stderr is a file, not the protocol pipe: ssh and the remote shell both
    # write warnings there, and they must never be mistaken for a frame.
    open my $err_fh, '>', $err_path
        or die "SSH transport: cannot write $err_path: $!\n";

    # IPC::Open3 rather than a hand-rolled fork/exec.  On Windows fork() is a
    # pseudo-process, and perlfork warns that handles created by pipe() are not
    # always duplicated into it, which leaves a full-duplex session waiting on
    # a pipe end that never closes.  Open3 spawns natively there.
    my ($writer, $reader);
    my $pid = IPC::Open3::open3(
        $writer, $reader, '>&' . fileno($err_fh), @command,
    );
    close $err_fh;

    return bless {
        pid        => $pid,
        writer     => $writer,
        reader     => $reader,
        errors     => $errors,
        error_path => $err_path,
        command    => \@command,
        status     => undef,
        stderr     => '',
    }, $class;
}

sub reader { $_[0]{reader} }
sub writer { $_[0]{writer} }

# The argv that was run, minus the local ssh path; used by --verbose and tests.
sub command {
    my ($self) = @_;
    return [ @{ $self->{command} } ];
}

sub close {
    my ($self) = @_;

    return 1 if $self->{closed};
    $self->{closed} = 1;

    CORE::close($self->{writer}) if $self->{writer};
    CORE::close($self->{reader}) if $self->{reader};

    if ($self->{pid}) {
        waitpid($self->{pid}, 0);
        my $status = $?;
        $self->{status} = $status >> 8;
        $self->{signal} = $status & 127;
        $self->{pid} = 0;
    }

    $self->{stderr} = _slurp($self->{error_path});

    return ($self->{status} || 0) == 0 ? 1 : 0;
}

sub exit_status { $_[0]{status} }

# What ssh or the remote shell said, for when the protocol itself failed.
sub error_text {
    my ($self) = @_;

    my $text = $self->{stderr};
    $text = _slurp($self->{error_path}) unless defined $text && length $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    $text =~ s/\n+/\n/g;

    return $text;
}

sub _slurp {
    my ($path) = @_;

    return '' unless defined $path && -e $path;
    open my $fh, '<', $path or return '';
    local $/;
    my $text = <$fh>;
    CORE::close($fh);

    return defined $text ? $text : '';
}

# user@host, host, or a bracketed IPv6 literal.  Anything that could be read as
# an ssh option (a leading '-') or that could split into another word is refused.
sub valid_server {
    my ($value) = @_;

    return 0 unless defined $value && length $value;
    return 0 if $value =~ /[\s\0\n]/;

    return $value =~ /\A(?:[A-Za-z0-9._-]+@)?
        (?:[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?|\[[0-9A-Fa-f:]+\])\z/x ? 1 : 0;
}

sub valid_program {
    my ($value) = @_;

    return 0 unless defined $value && length $value;
    return 0 if $value =~ /[\s\0\n'";&|<>]/;
    return 0 if index($value, '`') >= 0;
    return 0 if index($value, '$') >= 0;
    return 0 if index($value, '\\') >= 0;

    return $value =~ m{\A[A-Za-z0-9._/-]+\z} ? 1 : 0;
}

1;
