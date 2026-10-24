package App::FileSync::Client;

use strict;
use warnings;

use Digest::SHA ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use Sys::Hostname ();
use Time::HiRes ();

use App::FileSync qw(json_encode validate_relpath set_mtime);
use App::FileSync::Config;
use App::FileSync::Delta;
use App::FileSync::Ignore;
use App::FileSync::Lock;
use App::FileSync::Protocol;
use App::FileSync::Scan;
use App::FileSync::Settings;
use App::FileSync::Snapshot;
use App::FileSync::Transport::Local;
use App::FileSync::Transport::SSH;
use App::FileSync::Trash;
use App::FileSync::Verify;

our $CHUNK = 262_144;
our $MANIFEST_CHUNK = 2_000;

# How many run summaries the local log keeps before trimming the oldest.
our $LOG_LIMIT = 500;

sub new {
    my ($class, %args) = @_;

    die "Client: no config\n" unless $args{config};
    die "Client: no repo name\n" unless defined $args{name} && length $args{name};

    my $opts = $args{opts} || {};

    my $logger = $args{logger} || App::FileSync::Settings::logger(
        verbose => $opts->{verbose},
        quiet   => $opts->{quiet},
    );

    my %self = (
        config => $args{config},
        name   => $args{name},
        opts   => $opts,
        logger => $logger,
    );
    # Read lazily unless the caller (a test, or a command that already loaded
    # them) supplies the process settings.
    $self{settings} = $args{settings} if exists $args{settings};

    return bless \%self, $class;
}

sub sync {
    my ($self) = @_;

    my $name = $self->{name};
    my $repo = $self->{config}{repos}{$name}
        or die "No repo '$name' in " . App::FileSync::Config::client_config_path() . "\n";

    my $result = eval { $self->_run_session($repo) };

    if (my $error = $@) {
        # A run that started and then failed is still something cron attempted,
        # so the audit trail records it before the error escapes.
        my $text = $error;
        $text =~ s/\s+\z//;
        $self->_record_run({ exit => 1, error => $text });
        die $error;
    }

    $self->_record_run($result);

    if ($result->{ok}) {
        $self->{logger}->info('sync finished', {
            repo    => $name,
            (map { $_ => ($result->{summary}{$_} || 0) }
                qw(pulled pushed deleted conflicts skipped bytes_sent bytes_received)),
            exit    => $result->{exit} || 0,
            dry_run => $result->{dry_run} ? 1 : 0,
        });
    }

    return $result;
}

# One attempt: lock, session, cleanup.  Every outcome is a result, so the caller
# can record it; only unexpected failures are raised as exceptions.
sub _run_session {
    my ($self, $repo) = @_;

    my $name = $self->{name};
    my $root = $repo->{root};
    die "Sync root for '$name' is not a directory: " . (defined $root ? $root : '(unset)') . "\n"
        unless defined $root && length $root && -d $root;

    my $marker = File::Spec->catfile($root, '.filesync-root');
    die "Sync root $root has no .filesync-root marker (unmounted drive?); refusing to sync\n"
        unless -e $marker;

    my $lock = App::FileSync::Lock::acquire(path => $self->_lock_path(), nonblock => 1);
    return {
        repo   => $name,
        ok     => 0,
        exit   => 2,
        locked => 1,
        error  => "Another filesync run holds the lock for '$name'",
    } unless $lock;

    my $transport = $self->_transport($repo);
    my $connection = App::FileSync::Protocol->new(
        in  => $transport->reader(),
        out => $transport->writer(),
    );

    my $result;
    my $error;
    eval {
        $result = $self->_session($connection, $repo);
        1;
    } or $error = $@;

    $transport->close();

    if (defined $error && length $error) {
        # A transport that died before the session could start says something
        # useful ("Permission denied (publickey)", a host key mismatch) that the
        # protocol error alone does not.
        if ($error =~ /connection closed by the peer|read error|Cannot write/) {
            my $text = eval { $transport->error_text() };
            if (defined $text && length $text) {
                $error = $text . "\n";
            }
        }

        die $error;
    }

    return $result;
}

sub _session {
    my ($self, $connection, $repo) = @_;

    my $name   = $self->{name};
    my $config = $self->{config};
    my $opts   = $self->{opts};
    my $root   = $repo->{root};

    my $client_id = $config->{client_id};
    die "No client_id in the client configuration\n"
        unless defined $client_id && length $client_id;

    my $role = $repo->{role} || 'client';

    $connection->send({
        cmd              => 'hello',
        proto            => 2,
        client           => $client_id,
        host             => Sys::Hostname::hostname(),
        os               => $^O,
        role             => $role,
        repo             => $repo->{remote_repo} || $name,
        case_insensitive => $self->_case_insensitive($root),
        now              => time,
        dry_run          => $opts->{dry_run} ? 1 : 0,
        force            => $opts->{force} ? 1 : 0,
    });

    my $hello = $connection->recv();
    unless ($hello->{ok}) {
        my $reason = $hello->{error} || 'unknown error';

        # Lock contention is a normal, temporary outcome, not a failure: cron
        # may start a run while the previous one is still finishing.
        if (defined $hello->{code} && $hello->{code} eq 'locked') {
            return {
                repo    => $name,
                ok      => 0,
                exit    => 2,
                locked  => 1,
                error   => $reason,
                summary => { pulled => 0, pushed => 0, deleted => 0, conflicts => 0 },
            };
        }

        die "Server refused the session: $reason\n";
    }

    my $policy = $hello->{policy} || {};

    my @ignore_patterns = @{ $policy->{ignore} || [] };
    # A replica's snapshots live inside its root.  The pattern is reserved, so it
    # applies even to a repo created before snapshots existed, whose stored ignore
    # list does not mention it yet.
    push @ignore_patterns, '.filesync-snapshots'
        unless grep { $_ eq '.filesync-snapshots' } @ignore_patterns;

    my $ignore = App::FileSync::Ignore->new(
        patterns         => \@ignore_patterns,
        case_insensitive => $hello->{case_insensitive} ? 1 : 0,
    );

    App::FileSync::Scan::clean_stale_temps(root => $root);

    my $cache = $self->_load_cache();
    my ($manifest, $stats, $skipped) = App::FileSync::Scan::scan(
        root   => $root,
        ignore => $ignore,
        cache  => $cache->{entries} || {},
    );

    $self->_send_manifest($connection, $manifest);

    $connection->send({ cmd => 'plan' });
    my $plan = $connection->recv();
    unless ($plan->{ok}) {
        my $refusal = $plan->{error} || 'The server refused the plan';
        die "$refusal\n";
    }

    my @actions = @{ $plan->{actions} || [] };
    my @warnings = @{ $plan->{warnings} || [] };

    $self->{logger}->debug('plan received', {
        repo      => $name,
        actions   => scalar @actions,
        deletions => scalar(grep { $_->{a} =~ /\Adelete_/ } @actions),
        conflicts => scalar(grep { $_->{a} eq 'conflict' } @actions),
        dry_run   => $opts->{dry_run} ? 1 : 0,
    });

    if ($opts->{verbose} && !$opts->{dry_run}) {
        for my $action (@actions) {
            my $verb = $action->{a};
            $verb =~ s/_/ /g;
            print '  ', $verb, ' ', $action->{p}, "\n";
        }
    }

    my $summary = {
        pulled       => 0,
        pushed       => 0,
        deleted      => 0,
        conflicts    => 0,
        delta_pulled => 0,
        delta_pushed => 0,
        skipped      => scalar(keys %{$skipped}),
    };

    for my $path (sort keys %{$skipped}) {
        push @warnings, "$path: skipped ($skipped->{$path})";
    }

    if ($opts->{dry_run}) {
        $connection->send({ cmd => 'done' });
        my $end = $connection->recv();
        die 'Server did not accept the end of the session: ' . ($end->{error} || 'unknown') . "\n"
            unless $end->{ok};

        $summary->{pulled}    = scalar grep { $_->{a} eq 'pull' } @actions;
        $summary->{pushed}    = scalar grep { $_->{a} eq 'push' } @actions;
        $summary->{deleted}   = scalar grep { $_->{a} =~ /\Adelete_/ } @actions;
        $summary->{conflicts} = scalar grep { $_->{a} eq 'conflict' } @actions;

        # Nothing but headers and control messages has crossed the connection.
        $summary->{bytes_sent}     = $connection->bytes_sent;
        $summary->{bytes_received} = $connection->bytes_received;

        return {
            repo     => $name,
            ok       => 1,
            exit     => @warnings ? 3 : 0,
            dry_run  => 1,
            actions  => \@actions,
            summary  => $summary,
            warnings => \@warnings,
            stats    => $stats,
        };
    }

    my %after = %{$manifest};

    for my $action (@actions) {
        my $type = $action->{a};
        my $path = $action->{p};

        if ($type eq 'pull') {
            $self->_pull($connection, $action, \%after);
            $summary->{pulled}++;
        } elsif ($type eq 'push') {
            $self->_push($connection, $action);
            $summary->{pushed}++;
        } elsif ($type eq 'delete_remote') {
            $connection->send({ cmd => 'del', p => $path });
            my $reply = $connection->recv();
            die "Cannot delete $path on the server: " . ($reply->{error} || 'unknown error') . "\n"
                unless $reply->{ok};
            delete $after{$path};
            $summary->{deleted}++;
        } elsif ($type eq 'delete_local') {
            $self->_delete_local($path);
            $connection->send({ cmd => 'ack', p => $path, deleted => 1 });
            my $reply = $connection->recv();
            die "Server did not accept the deletion of $path: " . ($reply->{error} || 'unknown error') . "\n"
                unless $reply->{ok};
            delete $after{$path};
            $summary->{deleted}++;
        } elsif ($type eq 'conflict') {
            $self->_resolve_conflict($connection, $action, \%after);
            $summary->{conflicts}++;
        } else {
            die "Unknown action '$type' for $path\n";
        }
    }

    $connection->send({ cmd => 'done' });
    my $end = $connection->recv();
    die 'Server did not accept the end of the session: ' . ($end->{error} || 'unknown') . "\n"
        unless $end->{ok};

    $summary->{delta_pulled}   = $self->{delta_pulled} || 0;
    $summary->{delta_pushed}   = $self->{delta_pushed} || 0;
    $summary->{bytes_sent}     = $connection->bytes_sent;
    $summary->{bytes_received} = $connection->bytes_received;

    $self->_save_cache(\%after, $summary, { %{$policy}, ignore => \@ignore_patterns });

    $self->_prune_local_trash($repo) unless $self->{opts}{no_prune};

    return {
        repo     => $name,
        ok       => 1,
        exit     => @warnings ? 3 : 0,
        summary  => $summary,
        warnings => \@warnings,
        stats    => $stats,
    };
}

sub _send_manifest {
    my ($self, $connection, $manifest) = @_;

    my @entries = map {
        { p => $_, %{ $manifest->{$_} } }
    } sort keys %{$manifest};

    my $parts = @entries ? int((@entries - 1) / $MANIFEST_CHUNK) + 1 : 1;

    for my $part (0 .. $parts - 1) {
        my $from = $part * $MANIFEST_CHUNK;
        my $to   = $from + $MANIFEST_CHUNK - 1;
        $to = $#entries if $to > $#entries;

        my @slice = $from <= $#entries ? @entries[$from .. $to] : ();

        $connection->send({
            cmd     => 'manifest',
            part    => $part,
            of      => $parts,
            entries => \@slice,
        });

        my $reply = $connection->recv();
        die 'Server rejected the manifest: ' . ($reply->{error} || 'unknown error') . "\n"
            unless $reply->{ok};
    }

    return 1;
}

sub _pull {
    my ($self, $connection, $action, $after) = @_;

    my $path = $action->{p};
    my $abs  = $self->_abs($path);

    if (($action->{t} || 'f') eq 'd') {
        make_path($abs) unless -d $abs;
        $connection->send({ cmd => 'ack', p => $path, t => 'd' });
        my $reply = $connection->recv();
        die "Server did not accept directory $path: " . ($reply->{error} || 'unknown error') . "\n"
            unless $reply->{ok};
        $after->{$path} = { t => 'd' };
        return 1;
    }

    my $directory = dirname($abs);
    make_path($directory) unless -d $directory;

    return 1 if $self->_pull_delta($connection, $action, $after, $abs);

    my $temp = File::Spec->catfile(
        $directory, '.filesync-tmp-' . $$ . '-' . int(rand(1_000_000))
    );

    open my $out, '>', $temp or die "Cannot write $temp: $!\n";
    binmode $out;

    my $sha    = Digest::SHA->new(256);
    my $offset = 0;
    my ($size, $mtime, $mode, $hash);

    while (1) {
        $connection->send({ cmd => 'get', p => $path, off => $offset, max => $CHUNK });
        my $header = $connection->recv();
        unless ($header->{ok}) {
            close $out;
            unlink $temp;
            die "Cannot read $path from the server: " . ($header->{error} || 'unknown error') . "\n";
        }

        my $bytes = $connection->read_data($header);
        print {$out} $bytes or do {
            my $error = $!;
            close $out;
            unlink $temp;
            die "Cannot write $temp: $error\n";
        };

        $sha->add($bytes);
        $offset += length $bytes;
        $size  = $header->{s} if defined $header->{s};
        $mtime = $header->{m} if defined $header->{m};
        $mode  = $header->{mode} if defined $header->{mode};
        $hash  = $header->{h} if defined $header->{h};

        last if $header->{eof};
    }

    close $out or do {
        my $error = $!;
        unlink $temp;
        die "Cannot close $temp: $error\n";
    };

    my $got = $sha->hexdigest();
    my $expected = defined $action->{h} ? $action->{h} : $hash;
    if (defined $expected && $got ne $expected) {
        unlink $temp;
        die "Hash mismatch while copying $path: expected $expected, got $got\n";
    }

    chmod($mode & 07777, $temp) if defined $mode && $^O ne 'MSWin32';
    set_mtime($temp, $mtime);

    $self->_clear_target($abs);

    rename($temp, $abs) or do {
        my $error = $!;
        unlink $temp;
        die "Cannot move $temp to $abs: $error\n";
    };

    $connection->send({
        cmd  => 'ack',
        p    => $path,
        h    => $got,
        s    => $offset,
        m    => $mtime,
        mode => $mode,
    });
    my $reply = $connection->recv();
    die "Server did not accept $path: " . ($reply->{error} || 'unknown error') . "\n"
        unless $reply->{ok};

    $after->{$path} = {
        t    => 'f',
        s    => $offset,
        m    => $mtime,
        h    => $got,
        mode => $mode,
    };

    return 1;
}

sub _push {
    my ($self, $connection, $action) = @_;

    my $path = $action->{p};
    my $abs  = $self->_abs($path);

    if (($action->{t} || 'f') eq 'd') {
        $connection->send({ cmd => 'mkdir', p => $path });
        my $reply = $connection->recv();
        die "Cannot create directory $path on the server: " . ($reply->{error} || 'unknown error') . "\n"
            unless $reply->{ok};
        return 1;
    }

    my @stat = Time::HiRes::stat($abs);
    die "Cannot stat $abs: $!\n" unless @stat;

    my $size  = $stat[7];
    my $mtime = $stat[9];
    my $mode  = $stat[2] & 07777;

    if (!$action->{loser_name}
        && $self->_push_delta($connection, $path, $abs, $size, $mtime, $mode, $action->{h})) {
        return 1;
    }

    open my $in, '<', $abs or die "Cannot read $abs: $!\n";
    binmode $in;

    $connection->send({
        cmd           => 'put',
        p             => $path,
        t             => 'f',
        s             => $size,
        m             => $mtime,
        mode          => $mode,
        h             => $action->{h},
        ($action->{loser_name} ? (conflict_name => $action->{loser_name}) : ()),
    });

    # The server acknowledges the header before any chunk is sent; reading it here
    # keeps the lock-step protocol aligned.
    my $accepted = $connection->recv();
    die "Server refused $path: " . ($accepted->{error} || 'unknown error') . "\n"
        unless $accepted->{ok};

    my $sha  = Digest::SHA->new(256);
    my $sent = 0;

    while (1) {
        my $read = read($in, my $buffer, $CHUNK);
        die "Cannot read $abs: $!\n" unless defined $read;
        last if $read == 0;

        $sha->add($buffer);
        $sent += $read;

        $connection->send_data({ cmd => 'chunk', p => $path }, $buffer);

        my $reply = $connection->recv();
        die "Server rejected data for $path: " . ($reply->{error} || 'unknown error') . "\n"
            unless $reply->{ok};
    }

    close $in;

    $connection->send({ cmd => 'chunk_end', p => $path });
    my $reply = $connection->recv();
    die "Cannot store $path on the server: " . ($reply->{error} || 'unknown error') . "\n"
        unless $reply->{ok};

    return 1;
}

# Try to receive only the blocks that differ from the local copy.  Returns 0
# without touching the connection when a whole-file pull is the right answer.
sub _pull_delta {
    my ($self, $connection, $action, $after, $abs) = @_;

    return 0 if $self->{opts}{no_delta};
    return 0 unless -f $abs && !-l $abs;

    my $path = $action->{p};
    my $local_size = -s _;
    return 0 if $local_size < $App::FileSync::Delta::MIN_SIZE;

    my $block = App::FileSync::Delta::block_size($local_size);
    my $signature = App::FileSync::Delta::signature($abs, $block);
    return 0 unless $signature;

    $connection->send_data({
        cmd => 'dsig',
        p   => $path,
        s   => $local_size,
        b   => $block,
        n   => scalar @{ $signature->{blocks} },
        (defined $action->{h} ? (h => $action->{h}) : ()),
    }, App::FileSync::Delta::encode_signature($signature));

    my $reply = $connection->recv();
    die "Server refused the signature for $path: " . ($reply->{error} || 'unknown error') . "\n"
        unless $reply->{ok};
    return 0 unless $reply->{delta};

    my $directory = dirname($abs);
    make_path($directory) unless -d $directory;

    my $temp = File::Spec->catfile(
        $directory, '.filesync-tmp-' . $$ . '-' . int(rand(1_000_000))
    );

    open my $old, '<', $abs or die "Cannot read $abs: $!\n";
    binmode $old;
    open my $out, '>', $temp or die "Cannot write $temp: $!\n";
    binmode $out;

    my $sha = Digest::SHA->new(256);
    my $written = 0;
    my $done = 0;

    while (!$done) {
        $connection->send({ cmd => 'dop', p => $path });
        my $op = $connection->recv();
        unless ($op->{ok}) {
            close $old;
            close $out;
            unlink $temp;
            die "Cannot read $path from the server: " . ($op->{error} || 'unknown error') . "\n";
        }

        if ($op->{done}) {
            $done = 1;
            next;
        }

        my $bytes;
        if (($op->{op} || '') eq 'copy') {
            my ($offset, $length) = ($op->{off}, $op->{len});
            die "Bad copy instruction for $path\n"
                unless defined $offset && $offset =~ /\A\d+\z/
                    && defined $length && $length =~ /\A\d+\z/;
            die "Copy instruction outside $path\n" if $offset + $length > $local_size;

            seek($old, $offset, 0) or die "Cannot seek in $abs: $!\n";
            $bytes = $length
                ? App::FileSync::Delta::read_exact($old, $length, $abs)
                : '';
        } elsif (($op->{op} || '') eq 'lit') {
            $bytes = $connection->read_data($op);
        } else {
            close $old;
            close $out;
            unlink $temp;
            die "Unknown delta instruction for $path\n";
        }

        print {$out} $bytes or do {
            my $error = $!;
            close $old;
            close $out;
            unlink $temp;
            die "Cannot write $temp: $error\n";
        };
        $sha->add($bytes);
        $written += length $bytes;
    }

    close $old;
    close $out or do {
        my $error = $!;
        unlink $temp;
        die "Cannot close $temp: $error\n";
    };

    my $got = $sha->hexdigest();
    my $expected = defined $action->{h} ? $action->{h} : $reply->{h};
    if (defined $expected && $got ne $expected) {
        unlink $temp;
        die "Hash mismatch while copying $path: expected $expected, got $got\n";
    }
    if (defined $reply->{s} && $written != $reply->{s}) {
        unlink $temp;
        die "Size mismatch while copying $path: expected $reply->{s}, got $written\n";
    }

    my $mtime = $reply->{m};
    my $mode  = $reply->{mode};
    chmod($mode & 07777, $temp) if defined $mode && $^O ne 'MSWin32';
    set_mtime($temp, $mtime);

    $self->_clear_target($abs);

    rename($temp, $abs) or do {
        my $error = $!;
        unlink $temp;
        die "Cannot move $temp to $abs: $error\n";
    };

    $connection->send({
        cmd  => 'ack',
        p    => $path,
        h    => $got,
        s    => $written,
        m    => $mtime,
        mode => $mode,
    });
    my $accepted = $connection->recv();
    die "Server did not accept $path: " . ($accepted->{error} || 'unknown error') . "\n"
        unless $accepted->{ok};

    $after->{$path} = {
        t    => 'f',
        s    => $written,
        m    => $mtime,
        h    => $got,
        mode => $mode,
    };
    $self->{delta_pulled} = ($self->{delta_pulled} || 0) + 1;

    return 1;
}

# Ask the server what the master holds and send only the blocks that changed.
# Returns 0 when a whole-file put is cheaper, or when there is nothing to reuse.
sub _push_delta {
    my ($self, $connection, $path, $abs, $size, $mtime, $mode, $hash) = @_;

    return 0 if $self->{opts}{no_delta};
    return 0 unless defined $hash && $size >= $App::FileSync::Delta::MIN_SIZE;

    $connection->send({ cmd => 'sig', p => $path });
    my $reply = $connection->recv();
    die "Server refused the signature for $path: " . ($reply->{error} || 'unknown error') . "\n"
        unless $reply->{ok};
    return 0 unless $reply->{delta};

    my $bytes = $connection->read_data($reply);
    my $blocks = App::FileSync::Delta::decode_signature($bytes, $reply->{n});

    my $spool = File::Temp->new(
        TEMPLATE => '.filesync-tmp-delta-XXXXXXXX',
        DIR      => dirname($abs),
        UNLINK   => 1,
    );
    binmode $spool;

    my $stats = App::FileSync::Delta::diff(
        $abs,
        { size => $reply->{s}, blocklen => $reply->{b}, blocks => $blocks },
        $spool,
    );

    my $estimated = $stats->{literal} + 12 * $stats->{ops} + 64;
    return 0 if $estimated >= $size;

    $connection->send({
        cmd  => 'delta',
        p    => $path,
        s    => $size,
        h    => $hash,
        m    => $mtime,
        mode => $mode,
    });
    my $accepted = $connection->recv();
    die "Server refused the delta for $path: " . ($accepted->{error} || 'unknown error') . "\n"
        unless $accepted->{ok};

    seek($spool, 0, 0) or die "Cannot rewind the delta for $path: $!\n";

    while (my ($type, @rest) = App::FileSync::Delta::read_op($spool)) {
        if ($type eq 'copy') {
            $connection->send({
                cmd => 'dcopy',
                p   => $path,
                off => $rest[0],
                len => $rest[1],
            });
        } else {
            $connection->send_data({ cmd => 'dlit', p => $path }, $rest[0]);
        }

        my $ok = $connection->recv();
        die "Server rejected delta data for $path: " . ($ok->{error} || 'unknown error') . "\n"
            unless $ok->{ok};
    }

    $connection->send({ cmd => 'delta_end', p => $path });
    my $done = $connection->recv();
    die "Cannot store $path on the server: " . ($done->{error} || 'unknown error') . "\n"
        unless $done->{ok};

    $self->{delta_pushed} = ($self->{delta_pushed} || 0) + 1;
    return 1;
}

sub _resolve_conflict {
    my ($self, $connection, $action, $after) = @_;

    my $path = $action->{p};

    if ($action->{winner} eq 'remote') {
        my $abs = $self->_abs($path);
        if ((-e $abs || -l $abs) && defined $action->{loser_name}) {
            my $conflict = $self->_abs($action->{loser_name});
            die "Conflict copy already exists: $conflict\n" if -e $conflict || -l $conflict;
            make_path(dirname($conflict)) unless -d dirname($conflict);
            rename($abs, $conflict)
                or die "Cannot preserve $path as $action->{loser_name}: $!\n";
            $after->{ $action->{loser_name} } = $after->{$path};
            delete $after->{$path};
        }

        $self->_pull($connection, {
            p => $path,
            t => $action->{winner_type} || 'f',
            (defined $action->{h} ? (h => $action->{h}) : ()),
        }, $after);
        return 1;
    }

    $self->_push($connection, {
        p           => $path,
        t           => $action->{winner_type} || 'f',
        h           => $action->{h},
        loser_name  => $action->{loser_name},
    });

    return 1;
}

sub _delete_local {
    my ($self, $path) = @_;

    my $abs = $self->_abs($path);
    return 1 unless -e $abs || -l $abs;

    App::FileSync::Trash::move_to_trash(
        src   => $abs,
        rel   => $path,
        root  => $self->_trash_root(),
        epoch => time,
    );

    return 1;
}

sub _abs {
    my ($self, $path) = @_;

    my ($ok, $reason) = validate_relpath($path);
    die "Unsafe path '$path': $reason\n" unless $ok;

    return File::Spec->catfile($self->{config}{repos}{ $self->{name} }{root},
        split m{/}, $path);
}

sub _clear_target {
    my ($self, $abs) = @_;

    if (-l $abs) {
        unlink $abs or die "Cannot remove symlink $abs: $!\n";
    } elsif (-d $abs) {
        rmdir $abs or die "Cannot replace non-empty directory $abs\n";
    } elsif (-e $abs) {
        unlink $abs or die "Cannot remove $abs: $!\n";
    }

    return 1;
}

sub _transport {
    my ($self, $repo) = @_;

    my $type = $repo->{transport} || ($repo->{server_root} ? 'local' : 'ssh');

    if ($type eq 'local') {
        die "Repo $self->{name} needs a server_root for the local transport\n"
            unless defined $repo->{server_root} && length $repo->{server_root};

        return App::FileSync::Transport::Local->new(
            root       => $repo->{server_root},
            repo       => $repo->{remote_repo} || $self->{name},
            client     => $self->{config}{client_id},
            role       => $repo->{role} || 'client',
            server_bin => $repo->{server_bin},
        );
    }

    if ($type eq 'ssh') {
        die "Repo $self->{name} needs a server (user\@host) for the ssh transport\n"
            unless defined $repo->{server} && length $repo->{server};

        my $ssh = ref($self->{config}{ssh}) eq 'HASH' ? $self->{config}{ssh} : {};

        my $settings = $self->_settings;

        return App::FileSync::Transport::SSH->new(
            server            => $repo->{server},
            repo              => $repo->{remote_repo} || $self->{name},
            client            => $self->{config}{client_id},
            role              => $repo->{role} || 'client',
            port              => $repo->{port},
            identity          => _repo_or_setting($repo->{identity},    $settings->{ssh_identity}),
            known_hosts       => _repo_or_setting($repo->{known_hosts}, $settings->{ssh_known_hosts}),
            host_key_checking => $repo->{host_key_checking},
            server_command    => _repo_or_setting($repo->{server_command},
                                                  $settings->{server_command}),
            command           => $ssh->{command},
            extra_args        => $ssh->{extra_args},
        );
    }

    die "Unknown transport '$type' for repo $self->{name}\n";
}

# Process settings, read once per client.  A bad settings file is reported
# here rather than silently ignored: it decides which key and program a sync uses.
sub _settings {
    my ($self) = @_;

    $self->{settings} = App::FileSync::Settings::load()
        unless exists $self->{settings};

    return $self->{settings} || {};
}

sub _repo_or_setting {
    my ($value, $fallback) = @_;

    return $value if defined $value && length $value;
    return $fallback if defined $fallback && length $fallback;
    return undef;
}

sub _log_path {
    my ($self) = @_;
    return File::Spec->catfile(
        App::FileSync::Config::home_dir(), 'logs', $self->{name} . '.jsonl'
    );
}

# Append one line per attempt, so `filesync log` can audit what cron tried even
# when the run failed or never got the lock.
sub _record_run {
    my ($self, $result) = @_;

    my $path = $self->_log_path();

    my @warnings = map { my $text = $_; $text =~ s/\s+\z//; $text }
        @{ $result->{warnings} || [] };

    my $summary = ref($result->{summary}) eq 'HASH' ? $result->{summary} : {};

    my $entry = {
        ts      => time,
        exit    => defined $result->{exit} ? $result->{exit} + 0 : 0,
        dry_run => $result->{dry_run} ? 1 : 0,
        summary => {
            map { $_ => ($summary->{$_} || 0) }
                qw(pulled pushed deleted conflicts skipped delta_pulled delta_pushed
                   bytes_sent bytes_received)
        },
        warnings => \@warnings,
    };

    $entry->{locked} = 1 if $result->{locked};

    if (defined $result->{error} && length $result->{error}) {
        my $message = $result->{error};
        $message =~ s/\s+\z//;
        $entry->{error} = $message;
    }

    my $ok = eval {
        my $dir = dirname($path);
        make_path($dir) unless -d $dir;

        # A killed run can leave a partial line.  Start on a fresh line, or the
        # new entry would be glued to the fragment and lost as well.
        my $needs_newline = 0;
        if (-s $path) {
            open my $check, '<', $path or die "Cannot read $path: $!\n";
            seek($check, -1, 2);
            my $last = '';
            read($check, $last, 1);
            close $check;
            $needs_newline = $last ne "\n" ? 1 : 0;
        }

        open my $fh, '>>', $path or die "Cannot append to $path: $!\n";
        print {$fh} "\n" if $needs_newline;
        print {$fh} json_encode($entry), "\n"
            or die "Cannot write to $path: $!\n";
        close $fh or die "Cannot close $path: $!\n";

        $self->_trim_log($path);
        1;
    };

    unless ($ok) {
        my $error = $@ || 'unknown error';
        $error =~ s/\s+\z//;
        $self->{logger}->warn("cannot record this run in $path: $error");
    }

    return $ok ? 1 : 0;
}

sub _trim_log {
    my ($self, $path) = @_;

    open my $fh, '<', $path or return 0;
    my @lines = <$fh>;
    close $fh;

    return 0 if @lines <= $LOG_LIMIT;

    my @keep = @lines[ -$LOG_LIMIT .. -1 ];
    App::FileSync::write_atomic($path, join('', @keep));

    return 1;
}

# Recent run attempts, oldest first, at most $opts{limit} of them.  $opts{since}
# and $opts{until} are "YYYY-MM-DD" dates or epochs, $opts{exits} a list of
# exit codes to keep, and $opts{warnings} keeps only runs that recorded one;
# all four filter before the limit is applied.
sub log {
    my ($self, %opts) = @_;

    my $limit = defined $opts{limit} && $opts{limit} > 0 ? $opts{limit} : 20;
    my $since = defined $opts{since} ? App::FileSync::parse_since($opts{since}) : undef;
    my $until = defined $opts{until} ? App::FileSync::parse_until($opts{until}) : undef;
    my $warnings_only = $opts{warnings} ? 1 : 0;
    my $exits = $opts{exits};
    my @exits = ref($exits) eq 'ARRAY' ? map { $_ + 0 } @{$exits}
        : defined $exits ? ($exits + 0) : ();
    my $path  = $self->_log_path();

    my @runs;
    if (-e $path) {
        open my $fh, '<', $path or die "Cannot read $path: $!\n";
        while (my $line = <$fh>) {
            chomp $line;
            next unless length $line;

            # A killed run can leave a torn final line; the rest still counts.
            my $entry = eval { App::FileSync::json_decode($line) };
            next unless ref($entry) eq 'HASH';

            my $ts = $entry->{ts} || 0;

            next if defined $since && $ts < $since;
            next if defined $until && $ts > $until;
            next if @exits && !grep { ($entry->{exit} || 0) == $_ } @exits;
            next if $warnings_only && !_has_warnings($entry);

            push @runs, $entry;
        }
        close $fh;
    }

    @runs = @runs[ -$limit .. -1 ] if @runs > $limit;

    my $result = {
        repo => $self->{name},
        path => $path,
        runs => \@runs,
    };
    $result->{since} = $since if defined $since;
    $result->{until} = $until if defined $until;
    $result->{exits} = \@exits if @exits;
    $result->{warnings} = 1 if $warnings_only;

    return $result;
}

# A run carries warnings when the plan or scanner reported one, or when the
# summary counts a conflict or a skipped path.  Older entries may predate one
# of the fields, so either is enough.
sub _has_warnings {
    my ($entry) = @_;

    return 1 if ref($entry->{warnings}) eq 'ARRAY' && @{ $entry->{warnings} };

    my $summary = $entry->{summary} || {};
    return 1 if ($summary->{conflicts} || 0) > 0;
    return 1 if ($summary->{skipped} || 0) > 0;

    return 0;
}

sub _cache_path {
    my ($self) = @_;
    return File::Spec->catfile(
        App::FileSync::Config::home_dir(), 'cache', $self->{name} . '.json'
    );
}

sub _lock_path {
    my ($self) = @_;
    return File::Spec->catfile(
        App::FileSync::Config::home_dir(), 'locks', $self->{name} . '.lock'
    );
}

sub _trash_root {
    my ($self) = @_;
    return File::Spec->catdir(App::FileSync::Config::home_dir(), 'trash');
}

sub _repo_config {
    my ($self) = @_;

    my $name = $self->{name};
    my $repo = $self->{config}{repos}{$name};
    die "No repo '$name' in " . App::FileSync::Config::client_config_path() . "\n"
        unless $repo;

    return $repo;
}

# Compare the local tree with the cached base: what the last successful sync
# recorded.  Drift means the tree changed without being synced.
sub verify {
    my ($self, %opts) = @_;

    my $repo = $self->_repo_config();
    my $root = $repo->{root};
    die "Sync root for '$self->{name}' is not a directory: "
            . (defined $root ? $root : '(unset)') . "\n"
        unless defined $root && length $root && -d $root;

    die "Sync root $root has no .filesync-root marker (unmounted drive?)\n"
        unless -e File::Spec->catfile($root, '.filesync-root');

    my $cache = $self->_load_cache();
    my @patterns = ref($cache->{ignore}) eq 'ARRAY'
        ? @{ $cache->{ignore} }
        : @App::FileSync::Config::DEFAULT_IGNORE;
    push @patterns, '.filesync-snapshots'
        unless grep { $_ eq '.filesync-snapshots' } @patterns;

    my $ignore = App::FileSync::Ignore->new(patterns => \@patterns);

    my $report = App::FileSync::Verify::verify(
        root    => $root,
        entries => $cache->{entries} || {},
        ignore  => $ignore,
        deep    => $opts{deep},
    );

    $report->{repo} = $self->{name};

    $self->{logger}->info('verify finished', {
        repo     => $self->{name},
        files    => $report->{files},
        modified => scalar @{ $report->{modified} },
        missing  => scalar @{ $report->{missing} },
        extra    => scalar @{ $report->{extra} },
        ok       => $report->{ok} ? 1 : 0,
    });

    return $report;
}

# Put a path back from the local trash.  The newest stored version wins; --list
# shows them all instead.
sub restore {
    my ($self, %opts) = @_;

    my $repo = $self->_repo_config();
    my $path = $opts{path};

    my ($safe, $reason) = validate_relpath($path);
    die "Unsafe path '$path': $reason\n" unless $safe;

    my $trash = $self->_trash_root();
    my @versions = @{ App::FileSync::Trash::versions(root => $trash, rel => $path) };

    if ($opts{list}) {
        return {
            repo     => $self->{name},
            path     => $path,
            versions => [ map { _version_info($_) } @versions ],
        };
    }

    die "No trashed version of '$path' for repo '$self->{name}' in $trash\n"
        unless @versions;

    my $from = $versions[0];
    my $to_root = defined $opts{to} && length $opts{to} ? $opts{to} : $repo->{root};
    make_path($to_root) unless -d $to_root;
    die "Restore target $to_root is not a directory\n" unless -d $to_root;

    my $destination = File::Spec->catfile($to_root, split m{/}, $path);
    die "Refusing to overwrite $destination; move it aside or use --to DIR\n"
        if -e $destination || -l $destination;

    App::FileSync::Trash::restore(src => $from, to => $destination);

    $self->{logger}->info('restored path', {
        repo => $self->{name},
        path => $path,
        from => $from,
        to   => $destination,
    });

    return {
        repo => $self->{name},
        path => $path,
        from => $from,
        to   => $destination,
    };
}

sub _version_info {
    my ($path) = @_;

    my @stat = Time::HiRes::stat($path);

    return {
        path  => $path,
        date  => App::FileSync::Trash::date_of($path),
        size  => @stat ? $stat[7] : undef,
        mtime => @stat ? $stat[9] : undef,
    };
}

# ---------------------------------------------------------------- snapshots

sub snapshot_create {
    my ($self, %opts) = @_;

    my $repo = $self->_repo_config();
    my $name = $self->{name};

    my $role = $repo->{role} || 'client';
    die "Repo '$name' is a client, not a replica; only a replica keeps snapshots\n"
        unless $role eq 'replica';

    my $lock = App::FileSync::Lock::acquire(path => $self->_lock_path(), nonblock => 1);
    return {
        repo  => $name,
        ok    => 0,
        exit  => 2,
        error => "Another filesync run holds the lock for '$name'",
    } unless $lock;

    my $mode = defined $repo->{snapshot_mode} && length $repo->{snapshot_mode}
        ? $repo->{snapshot_mode}
        : App::FileSync::Snapshot::default_mode();

    my $keep = defined $opts{keep} ? $opts{keep} : $repo->{snapshot_keep};
    $keep = 14 unless defined $keep;

    my $created = App::FileSync::Snapshot::create(
        root => $repo->{root},
        mode => $mode,
    );

    my $pruned = undef;
    if ($created->{created} && $keep > 0) {
        $pruned = App::FileSync::Snapshot::prune(root => $repo->{root}, keep => $keep);
    }

    return {
        repo   => $name,
        ok     => 1,
        exit   => 0,
        %{$created},
        keep    => $keep,
        pruned  => $pruned ? $pruned->{removed} : [],
        older   => $pruned ? $pruned->{kept}    : [],
    };
}

sub snapshot_list {
    my ($self) = @_;

    my $repo = $self->_repo_config();
    my $snapshots = App::FileSync::Snapshot::list(root => $repo->{root});

    return {
        repo      => $self->{name},
        snapshots => $snapshots,
    };
}

sub snapshot_restore {
    my ($self, %opts) = @_;

    my $repo = $self->_repo_config();
    my $name = $self->{name};

    my $lock = App::FileSync::Lock::acquire(path => $self->_lock_path(), nonblock => 1);
    return {
        repo  => $name,
        ok    => 0,
        exit  => 2,
        error => "Another filesync run holds the lock for '$name'",
    } unless $lock;

    my $to = defined $opts{to} && length $opts{to} ? $opts{to} : $repo->{root};
    my $paths = defined $opts{path} && length $opts{path} ? [ $opts{path} ] : [];

    my $result = App::FileSync::Snapshot::restore(
        root  => $repo->{root},
        date  => $opts{date},
        paths => $paths,
        to    => $to,
    );

    return {
        repo => $name,
        ok   => 1,
        exit => 0,
        into_root => ($to eq $repo->{root} ? 1 : 0),
        %{$result},
    };
}

sub _load_cache {
    my ($self) = @_;

    my $path = $self->_cache_path();
    return { entries => {} } unless -e $path;

    my $cache = eval { App::FileSync::json_decode(App::FileSync::read_text($path)) };
    return { entries => {} } if $@ || ref($cache) ne 'HASH';

    $cache->{entries} = {} unless ref($cache->{entries}) eq 'HASH';
    return $cache;
}

sub _save_cache {
    my ($self, $entries, $summary, $policy) = @_;
    $policy ||= {};

    App::FileSync::write_atomic($self->_cache_path(), json_encode({
        version  => 1,
        entries  => $entries,
        # Kept so verify can scan with the same exclusions when it runs offline.
        ignore   => $policy->{ignore} || [],
        last_run => {
            ts      => time,
            summary => $summary,
        },
    }) . "\n");

    return 1;
}

sub _prune_local_trash {
    my ($self, $repo) = @_;

    my $days = $repo->{local_trash_days};
    $days = 30 unless defined $days;

    App::FileSync::Trash::prune(
        root  => $self->_trash_root(),
        days  => $days,
        now   => time,
    );

    return 1;
}

sub _case_insensitive {
    my ($self, $root) = @_;

    my $probe   = File::Spec->catfile($root, '.filesync-tmp-caseprobe');
    my $swapped = File::Spec->catfile($root, '.filesync-tmp-CASEPROBE');

    my $handle;
    unless (open($handle, '>', $probe)) {
        return $^O eq 'MSWin32' ? 1 : 0;
    }
    close $handle;

    my $insensitive = (-e $swapped) ? 1 : 0;
    unlink $probe;

    return $insensitive;
}

1;
