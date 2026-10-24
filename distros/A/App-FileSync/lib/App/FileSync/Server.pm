package App::FileSync::Server;

use strict;
use warnings;

use Digest::SHA ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use Time::HiRes ();

use App::FileSync qw(json_encode validate_relpath validate_client_id validate_repo_name);
use App::FileSync::Delta;
use App::FileSync::Merge;
use App::FileSync::Protocol;
use App::FileSync::Settings;
use App::FileSync::Store;

our $CHUNK = 262_144;
our $PROTO = 2;

sub new {
    my ($class, %args) = @_;

    for my $required (qw(root repo client role)) {
        die "Server: no $required given\n"
            unless defined $args{$required} && length $args{$required};
    }

    die "Server: bad role '$args{role}'\n"
        unless $args{role} eq 'client' || $args{role} eq 'replica';

    for my $pair ([repo => 'repo name'], [client => 'client id']) {
        my ($field, $what) = @{$pair};
        my ($ok, $reason) = $field eq 'repo'
            ? validate_repo_name($args{$field})
            : validate_client_id($args{$field});
        die "Server: bad $what: $reason\n" unless $ok;
    }

    my $self = bless {
        root   => $args{root},
        repo   => $args{repo},
        client => $args{client},
        role   => $args{role},
        conn   => $args{connection},
        dry_run => 0,
        force   => 0,
        finished => 0,
        uploads  => {},
        client_manifest => {},
        plan    => {},
        index   => {},
        base    => {},
        base_after => {},
        applied => {},
        counts  => { pulled => 0, pushed => 0, deleted => 0, conflicts => 0 },
        logger  => $args{logger} || App::FileSync::Settings::logger(),
    }, $class;

    die "Server: no connection\n" unless $self->{conn};

    return $self;
}

sub run {
    my ($self) = @_;

    my $connection = $self->{conn};

    my $ok = eval {
        my $hello = $connection->recv();
        $self->_validate_hello($hello);

        $self->{store} = App::FileSync::Store->new(
            root => $self->{root},
            repo => $self->{repo},
        );

        $self->_check_client_allowed();

        $self->{lock} = $self->{store}->acquire_lock();
        unless ($self->{lock}) {
            $self->{refusal} = 'locked';
            die "Another sync session holds the lock for repo '$self->{repo}'\n";
        }

        $self->{index} = $self->{store}->load_index();
        $self->{base}  = $self->{store}->load_base($self->{client});

        $self->{store}->clean_stale_temps();
        $self->{store}->prune_trash() unless $self->{dry_run};

        $self->{logger}->info('session opened', {
            repo   => $self->{repo},
            client => $self->{client},
            role   => $self->{role},
        });

        my $policy = $self->{store}->config();
        $connection->send({
            ok     => 1,
            proto  => $PROTO,
            server => { os => $^O },
            repo   => { name => $self->{repo} },
            policy => {
                ignore              => $policy->{ignore},
                trash_days          => $policy->{trash_days},
                max_deletes         => $policy->{max_deletes},
                max_delete_percent  => $policy->{max_delete_percent},
            },
        });

        $self->_loop();
        1;
    };

    unless ($ok) {
        my $error = $@ || 'unknown server error';
        chomp $error;

        $self->{logger}->error($error);
        $self->_journal_failed_session($error);

        my %reply = (ok => 0, error => $error, fatal => 1);
        $reply{code} = $self->{refusal} if $self->{refusal};
        eval { $connection->send(\%reply) };
        return 0;
    }

    return 1;
}

# A run that never reached _finish() is an attempt the admin should see, with
# the same exit codes the client records: 2 for a lock refusal, 1 otherwise.
# Nothing is journalled when there is no repo store yet (a bad hello, say), and
# a journal write that fails must not mask the original error.
sub _journal_failed_session {
    my ($self, $error) = @_;

    return 0 if $self->{finished} || $self->{session_journalled} || $self->{dry_run};

    my $store = $self->{store} or return 0;

    my $locked = ($self->{refusal} || '') eq 'locked' ? 1 : 0;
    my %event = (
        client => $self->{client},
        action => 'session',
        result => 'error',
        exit   => $locked ? 2 : 1,
        error  => $error,
    );
    $event{locked} = 1 if $locked;

    my $ok = eval { $store->journal(\%event); 1 };
    $self->{logger}->warn('cannot journal the failed session', { error => $@ })
        unless $ok;

    return $ok ? 1 : 0;
}

sub _validate_hello {
    my ($self, $hello) = @_;

    die "Unsupported protocol version\n"
        unless defined $hello->{proto} && $hello->{proto} == $PROTO;

    for my $field (qw(client repo role)) {
        my $expected = $self->{$field};
        my $given = defined $hello->{$field} ? $hello->{$field} : '';
        die "Session is pinned to $field '$expected' but the client asked for '$given'\n"
            unless $given eq $expected;
    }

    $self->{dry_run} = $hello->{dry_run} ? 1 : 0;
    $self->{force}   = $hello->{force} ? 1 : 0;
    $self->{case_insensitive} = $hello->{case_insensitive} ? 1 : 0;

    return 1;
}

sub _check_client_allowed {
    my ($self) = @_;

    my $clients = $self->{store}->config()->{clients} || {};
    return 1 unless keys %{$clients};

    my $entry = $clients->{ $self->{client} };
    die "Client '$self->{client}' is not allowed on repo '$self->{repo}'\n"
        unless $entry;

    my $role = ref($entry) eq 'HASH' ? ($entry->{role} || 'client') : 'client';
    die "Client '$self->{client}' is registered as '$role', not '$self->{role}'\n"
        unless $role eq $self->{role};

    return 1;
}

sub _loop {
    my ($self) = @_;

    my $connection = $self->{conn};

    while (!$self->{finished}) {
        my $message = $connection->recv();
        my $command = defined $message->{cmd} ? $message->{cmd} : '';

        if ($command eq 'manifest') {
            $self->_manifest($message);
        } elsif ($command eq 'plan') {
            $self->_plan($message);
        } elsif ($command eq 'get') {
            $self->_get($message);
        } elsif ($command eq 'put') {
            $self->_put($message);
        } elsif ($command eq 'chunk') {
            $self->_chunk($message);
        } elsif ($command eq 'chunk_end') {
            $self->_chunk_end($message);
        } elsif ($command eq 'sig') {
            $self->_signature($message);
        } elsif ($command eq 'delta') {
            $self->_delta_start($message);
        } elsif ($command eq 'dcopy') {
            $self->_delta_copy($message);
        } elsif ($command eq 'dlit') {
            $self->_delta_literal($message);
        } elsif ($command eq 'delta_end') {
            $self->_delta_end($message);
        } elsif ($command eq 'dsig') {
            $self->_pull_signature($message);
        } elsif ($command eq 'dop') {
            $self->_pull_op($message);
        } elsif ($command eq 'mkdir') {
            $self->_mkdir($message);
        } elsif ($command eq 'del') {
            $self->_delete($message);
        } elsif ($command eq 'ack') {
            $self->_ack($message);
        } elsif ($command eq 'done') {
            $self->_finish();
        } else {
            die "Unknown command '$command'\n";
        }
    }

    return 1;
}

sub _manifest {
    my ($self, $message) = @_;

    my $entries = $message->{entries};
    die "Manifest is not a list\n" unless ref($entries) eq 'ARRAY';

    for my $entry (@{$entries}) {
        die "Manifest entry is not an object\n" unless ref($entry) eq 'HASH';

        my $path = delete $entry->{p};
        my ($safe, $reason) = validate_relpath($path);
        die "Manifest path rejected: $reason\n" unless $safe;

        my $type = defined $entry->{t} ? $entry->{t} : 'f';
        die "Bad type for $path\n" unless $type eq 'f' || $type eq 'd';

        if ($type eq 'd') {
            $self->{client_manifest}{$path} = { t => 'd' };
            next;
        }

        die "Bad hash for $path\n"
            unless defined $entry->{h} && $entry->{h} =~ /\A[0-9a-f]{64}\z/;
        die "Bad size for $path\n"
            unless defined $entry->{s} && $entry->{s} =~ /\A\d+\z/;

        $entry->{m} = 0 unless defined $entry->{m};
        $entry->{mode} = oct(644) unless defined $entry->{mode};

        $self->{client_manifest}{$path} = {
            t    => 'f',
            s    => $entry->{s} + 0,
            m    => $entry->{m} + 0,
            h    => $entry->{h},
            mode => $entry->{mode} + 0,
        };
    }

    $self->{conn}->send({ ok => 1 });
    return 1;
}

sub _plan {
    my ($self) = @_;

    my $store = $self->{store};

    my ($master, $stats, $skipped) = $store->walk_master($self->{index});
    $self->{index} = $master;

    my $config = $store->config();
    my $plan = App::FileSync::Merge::plan(
        base      => $self->{base},
        client    => $self->{client_manifest},
        master    => $master,
        client_id => $self->{client},
        role      => $self->{role},
        now       => time,
    );

    my $refusal = App::FileSync::Merge::check_delete_limit(
        deletions          => $plan->{deletions},
        base_size          => scalar(keys %{ $self->{base} }),
        max_deletes        => $config->{max_deletes},
        max_delete_percent => $config->{max_delete_percent},
        force              => $self->{force},
    );

    if (defined $refusal) {
        die "$refusal\n";
    }

    # Two conflicts resolved in the same second would otherwise pick the same
    # conflict-copy name; make each one unique against the master and the plan.
    my %used_names;
    for my $action (@{ $plan->{actions} }) {
        next unless $action->{a} eq 'conflict' && defined $action->{loser_name};

        my $candidate = $action->{loser_name};
        my $suffix = 1;
        while ($used_names{$candidate} || exists $self->{index}{$candidate}) {
            $suffix++;
            $candidate = _name_with_suffix($action->{loser_name}, $suffix);
        }
        $used_names{$candidate} = 1;
        $action->{loser_name} = $candidate;
    }

    $self->{plan} = { map { $_->{p} => $_ } @{ $plan->{actions} } };
    $self->{base_after} = { %{ $self->{client_manifest} } };

    $self->{logger}->debug('plan', {
        repo      => $self->{repo},
        client    => $self->{client},
        actions   => scalar @{ $plan->{actions} },
        deletions => $plan->{deletions},
        conflicts => $plan->{conflicts},
        dry_run   => $self->{dry_run} ? 1 : 0,
    });

    $self->{store}->journal({
        client  => $self->{client},
        action  => 'plan',
        dry_run => $self->{dry_run} ? 1 : 0,
        actions => scalar @{ $plan->{actions} },
        deletions => $plan->{deletions},
        conflicts => $plan->{conflicts},
    }) unless $self->{dry_run};

    $self->{conn}->send({
        ok       => 1,
        actions  => $plan->{actions},
        warnings => $plan->{warnings},
    });

    return 1;
}

sub _planned {
    my ($self, $path) = @_;
    return $self->{plan}{$path};
}

sub _get {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Read of unplanned path '$path'\n";

    die "Read of '$path' is not in the plan\n"
        unless $action->{a} eq 'pull'
            || ($action->{a} eq 'conflict' && $action->{winner} eq 'remote');

    my $abs = $self->{store}->abs_path($path);
    my @stat = Time::HiRes::stat($abs);
    die "Cannot stat $abs: $!\n" unless @stat;
    die "Cannot send a directory for '$path'\n" unless -f _;

    my $size = $stat[7];
    my $offset = defined $message->{off} ? $message->{off} + 0 : 0;
    my $max = defined $message->{max} ? $message->{max} + 0 : $CHUNK;

    die "Invalid offset for '$path'\n" if $offset < 0 || $offset > $size;

    my $length = $size - $offset;
    $length = $max if $length > $max;
    $length = 0 if $length < 0;

    my $bytes = '';
    if ($length > 0) {
        open my $fh, '<', $abs or die "Cannot read $abs: $!\n";
        binmode $fh;
        seek($fh, $offset, 0) or die "Cannot seek in $abs: $!\n";

        while (length($bytes) < $length) {
            my $read = read($fh, my $part, $length - length($bytes));
            die "Cannot read $abs: $!\n" unless defined $read;
            last if $read == 0;
            $bytes .= $part;
        }
        close $fh;
    }

    $self->{conn}->send_data({
        ok   => 1,
        eof  => ($offset + length($bytes) >= $size) ? 1 : 0,
        s    => $size,
        m    => $stat[9],
        mode => $stat[2] & 07777,
    }, $bytes);

    return 1;
}

sub _put {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Write of unplanned path '$path'\n";

    my $is_conflict = $action->{a} eq 'conflict';
    die "Write of '$path' is not in the plan\n"
        unless $action->{a} eq 'push'
            || ($is_conflict && $action->{winner} eq 'client');

    die "Already receiving '$path'\n" if $self->{uploads}{$path};

    $self->{store}->ensure_parent($path);

    if ($is_conflict && defined $message->{conflict_name}) {
        $self->_preserve_loser($path, $message->{conflict_name}, {
            sha256 => $message->{h},
            mtime  => $message->{m},
        });
    }

    my $temp = $self->{store}->temp_path($path);
    open my $fh, '>', $temp or die "Cannot write $temp: $!\n";
    binmode $fh;

    $self->{uploads}{$path} = {
        fh    => $fh,
        temp  => $temp,
        sha   => Digest::SHA->new(256),
        got   => 0,
        size  => defined $message->{s} ? $message->{s} + 0 : undef,
        hash  => $message->{h},
        mtime => $message->{m},
        mode  => $message->{mode},
    };

    $self->{conn}->send({ ok => 1, off => 0 });
    return 1;
}

sub _chunk {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $upload = $self->{uploads}{$path}
        or die "Data for '$path' without a put\n";

    my $length = $message->{len};
    die "Bad chunk length\n"
        unless defined $length && $length =~ /\A\d+\z/ && $length <= 8 * 1024 * 1024;

    my $bytes = $length ? $self->{conn}->read_data($message) : '';
    die "Chunk for '$path' is too large\n" if length($bytes) > 8 * 1024 * 1024;

    print { $upload->{fh} } $bytes or do {
        my $error = $!;
        close $upload->{fh};
        unlink $upload->{temp};
        delete $self->{uploads}{$path};
        die "Cannot write $upload->{temp}: $error\n";
    };

    $upload->{sha}->add($bytes);
    $upload->{got} += length($bytes);

    $self->{conn}->send({ ok => 1, off => $upload->{got} });
    return 1;
}

sub _chunk_end {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $upload = delete $self->{uploads}{$path}
        or die "End of data for '$path' without a put\n";

    $self->_commit_upload($path, $upload);
    $self->{conn}->send({ ok => 1 });
    return 1;
}

# Close, verify and install an upload, whether it arrived whole or as a delta.
sub _commit_upload {
    my ($self, $path, $upload, %extra) = @_;

    close $upload->{fh} or do {
        my $error = $!;
        unlink $upload->{temp};
        die "Cannot close $upload->{temp}: $error\n";
    };
    close $upload->{old_fh} if $upload->{old_fh};

    my $hash = $upload->{sha}->hexdigest();

    if (defined $upload->{hash} && $hash ne $upload->{hash}) {
        unlink $upload->{temp};
        die "Hash mismatch for '$path': expected $upload->{hash}, got $hash\n";
    }

    if (defined $upload->{size} && $upload->{got} != $upload->{size}) {
        unlink $upload->{temp};
        die "Size mismatch for '$path': expected $upload->{size}, got $upload->{got}\n";
    }

    $self->{store}->commit_temp($path, $upload->{temp}, $upload->{mtime}, $upload->{mode});

    my $entry = {
        t    => 'f',
        s    => $upload->{got},
        m    => defined $upload->{mtime} ? $upload->{mtime} : time,
        h    => $hash,
        mode => defined $upload->{mode} ? $upload->{mode} : oct(644),
    };

    $self->{index}{$path}      = $entry;
    $self->{base_after}{$path} = { %{$entry} };

    $self->{store}->journal({
        client => $self->{client},
        action => 'push',
        path   => $path,
        size   => $upload->{got},
        sha256 => $hash,
        result => 'ok',
        %extra,
    });

    $self->{applied}{$path} = 1;
    return $entry;
}

# The client holds the new content and asks for a description of the master's
# current version, so it can send only the blocks that differ.
sub _signature {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Signature request for unplanned path '$path'\n";

    die "Signature request for '$path' is not in the plan\n"
        unless $action->{a} eq 'push';

    my $abs = $self->{store}->abs_path($path);
    my $signature;
    if (-f $abs && (-s _) >= $App::FileSync::Delta::MIN_SIZE) {
        $signature = App::FileSync::Delta::signature($abs);
    }

    unless ($signature) {
        $self->{conn}->send({ ok => 1, delta => 0 });
        return 1;
    }

    $self->{conn}->send_data({
        ok    => 1,
        delta => 1,
        s     => $signature->{size},
        b     => $signature->{blocklen},
        n     => scalar @{ $signature->{blocks} },
    }, App::FileSync::Delta::encode_signature($signature));

    return 1;
}

sub _delta_start {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Delta write of unplanned path '$path'\n";

    die "Delta write of '$path' is not in the plan\n"
        unless $action->{a} eq 'push';
    die "Already receiving '$path'\n" if $self->{uploads}{$path};

    my $hash = $message->{h};
    die "Bad hash for '$path'\n"
        unless defined $hash && $hash =~ /\A[0-9a-f]{64}\z/;
    my $size = $message->{s};
    die "Bad size for '$path'\n"
        unless defined $size && $size =~ /\A\d+\z/;

    $self->{store}->ensure_parent($path);

    my $temp = $self->{store}->temp_path($path);
    open my $fh, '>', $temp or die "Cannot write $temp: $!\n";
    binmode $fh;

    my $old = $self->{store}->abs_path($path);
    my $old_fh;
    if (-f $old) {
        open $old_fh, '<', $old or die "Cannot read $old: $!\n";
        binmode $old_fh;
    } else {
        $old = undef;
    }

    $self->{uploads}{$path} = {
        fh     => $fh,
        temp   => $temp,
        sha    => Digest::SHA->new(256),
        got    => 0,
        size   => $size + 0,
        hash   => $hash,
        mtime  => $message->{m},
        mode   => $message->{mode},
        delta  => 1,
        old    => $old,
        old_fh => $old_fh,
    };

    $self->{conn}->send({ ok => 1 });
    return 1;
}

sub _delta_copy {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $upload = $self->{uploads}{$path}
        or die "Delta data for '$path' without a delta\n";
    die "Copy for '$path' outside a delta\n" unless $upload->{delta};

    my ($offset, $length) = ($message->{off}, $message->{len});
    die "Bad delta copy for '$path'\n"
        unless defined $offset && $offset =~ /\A\d+\z/
            && defined $length && $length =~ /\A\d+\z/ && $length > 0;

    my $old_fh = $upload->{old_fh}
        or die "No master content to copy for '$path'\n";
    my $old_size = -s $upload->{old};
    die "Delta copy outside '$path'\n"
        if $offset + $length > $old_size;

    seek($old_fh, $offset, 0) or die "Cannot seek in $upload->{old}: $!\n";
    my $bytes = App::FileSync::Delta::read_exact($old_fh, $length, $upload->{old});

    $self->_write_delta($path, $upload, $bytes);
    $self->{conn}->send({ ok => 1, off => $upload->{got} });
    return 1;
}

sub _delta_literal {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $upload = $self->{uploads}{$path}
        or die "Delta data for '$path' without a delta\n";
    die "Literal for '$path' outside a delta\n" unless $upload->{delta};

    my $bytes = $self->{conn}->read_data($message);
    $self->_write_delta($path, $upload, $bytes);
    $self->{conn}->send({ ok => 1, off => $upload->{got} });
    return 1;
}

sub _write_delta {
    my ($self, $path, $upload, $bytes) = @_;

    my $length = length $bytes;
    die "Delta for '$path' is larger than announced\n"
        if $upload->{got} + $length > $upload->{size};

    print { $upload->{fh} } $bytes or do {
        my $error = $!;
        close $upload->{fh};
        unlink $upload->{temp};
        delete $self->{uploads}{$path};
        die "Cannot write $upload->{temp}: $error\n";
    };

    $upload->{sha}->add($bytes);
    $upload->{got} += $length;
    return 1;
}

sub _delta_end {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $upload = delete $self->{uploads}{$path}
        or die "End of delta for '$path' without a delta\n";
    die "End of delta for '$path' outside a delta\n" unless $upload->{delta};

    $self->_commit_upload($path, $upload, delta => 1);
    $self->{conn}->send({ ok => 1, delta => 1 });
    return 1;
}

# The client describes its old version; the server spools a delta from the
# master's current version and serves it one block at a time.
sub _pull_signature {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Signature upload for unplanned path '$path'\n";
    die "Signature upload for '$path' is not in the plan\n"
        unless $action->{a} eq 'pull';

    my $count = $message->{n};
    my $block = $message->{b};
    die "Bad signature for '$path'\n"
        unless defined $count && $count =~ /\A\d+\z/
            && $count <= 16_384
            && defined $block && $block =~ /\A\d+\z/
            && $block >= 1024 && $block <= 1024 * 1024;

    my $bytes  = $self->{conn}->read_data($message);
    my $blocks = App::FileSync::Delta::decode_signature($bytes, $count);

    my $abs = $self->{store}->abs_path($path);
    my @stat = Time::HiRes::stat($abs);
    die "Cannot stat $abs: $!\n" unless @stat;

    if (!-f _ || $stat[7] < $App::FileSync::Delta::MIN_SIZE) {
        $self->{conn}->send({ ok => 1, delta => 0 });
        return 1;
    }

    my $spool = File::Temp->new(UNLINK => 1);
    binmode $spool;
    my $stats = App::FileSync::Delta::diff(
        $abs,
        { blocklen => $block + 0, blocks => $blocks },
        $spool,
    );
    $spool->flush();

    # Only the literal bytes and record headers go on the wire; compression can
    # shrink them further, so this is a conservative estimate.
    my $estimated = $stats->{literal} + 12 * $stats->{ops} + 64;
    if ($estimated >= $stat[7]) {
        $self->{conn}->send({ ok => 1, delta => 0 });
        return 1;
    }

    seek($spool, 0, 0) or die "Cannot rewind the delta for '$path': $!\n";
    $self->{pull_deltas}{$path} = {
        spool => $spool,
        size  => $stat[7],
        m     => $stat[9],
        mode  => $stat[2] & 07777,
    };

    $self->{conn}->send({
        ok    => 1,
        delta => 1,
        s     => $stat[7],
        m     => $stat[9],
        mode  => $stat[2] & 07777,
        b     => $block + 0,
    });

    return 1;
}

sub _pull_op {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $state = $self->{pull_deltas}{$path}
        or die "Delta read for '$path' without a signature\n";

    my ($type, @rest) = App::FileSync::Delta::read_op($state->{spool});
    unless ($type) {
        delete $self->{pull_deltas}{$path};
        $self->{conn}->send({ ok => 1, done => 1 });
        return 1;
    }

    if ($type eq 'copy') {
        $self->{conn}->send({
            ok  => 1,
            op  => 'copy',
            off => $rest[0],
            len => $rest[1],
        });
        return 1;
    }

    $self->{conn}->send_data({ ok => 1, op => 'lit' }, $rest[0]);
    return 1;
}

sub _mkdir {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Directory creation for unplanned path '$path'\n";

    die "Directory creation for '$path' is not in the plan\n"
        unless $action->{a} eq 'push'
            || ($action->{a} eq 'conflict' && $action->{winner} eq 'client');

    my $abs = $self->{store}->abs_path($path);
    make_path($abs) unless -d $abs;

    $self->{index}{$path}      = { t => 'd' };
    $self->{base_after}{$path} = { t => 'd' };

    $self->{store}->journal({
        client => $self->{client},
        action => 'mkdir',
        path   => $path,
        result => 'ok',
    });

    $self->{applied}{$path} = 1;
    $self->{conn}->send({ ok => 1 });
    return 1;
}

sub _delete {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path)
        or die "Deletion of unplanned path '$path'\n";

    die "Deletion of '$path' is not in the plan\n"
        unless $action->{a} eq 'delete_remote';

    my $trashed = $self->{store}->move_to_trash($path, time);

    $self->{applied}{$path} = 1;
    delete $self->{index}{$path};
    delete $self->{base_after}{$path};

    $self->{store}->journal({
        client => $self->{client},
        action => 'delete',
        path   => $path,
        trash  => $trashed,
        result => 'ok',
    });

    $self->{conn}->send({ ok => 1, trash => $trashed });
    return 1;
}

sub _ack {
    my ($self, $message) = @_;

    my $path = $message->{p};
    my $action = $self->_planned($path) or die "Ack for unplanned path '$path'\n";

    if ($message->{deleted}) {
        delete $self->{base_after}{$path};
    } elsif (($message->{t} || '') eq 'd') {
        $self->{base_after}{$path} = { t => 'd' };
    } else {
        die "Bad ack hash for '$path'\n"
            unless defined $message->{h} && $message->{h} =~ /\A[0-9a-f]{64}\z/;

        $self->{base_after}{$path} = {
            t    => 'f',
            s    => defined $message->{s} ? $message->{s} + 0 : 0,
            m    => defined $message->{m} ? $message->{m} + 0 : 0,
            h    => $message->{h},
            mode => defined $message->{mode} ? $message->{mode} + 0 : oct(644),
        };
    }

    if (($action->{a} || '') eq 'conflict' && ($action->{winner} || '') eq 'remote') {
        my $loser  = $self->{client_manifest}{$path} || {};
        my $winner = $self->{index}{$path} || {};

        $self->{store}->journal({
            client        => $self->{client},
            action        => 'conflict',
            path          => $path,
            winner        => 'remote',
            loser_name    => $action->{loser_name},
            winner_sha256 => $winner->{h},
            winner_mtime  => $winner->{m},
            loser_sha256  => $loser->{h},
            loser_mtime   => $loser->{m},
            result        => 'ok',
        });
    }

    $self->{applied}{$path} = 1;
    delete $self->{pull_deltas}{$path};
    $self->{conn}->send({ ok => 1 });
    return 1;
}

# Move the master's losing version aside before the client's version is written.
sub _preserve_loser {
    my ($self, $path, $conflict_rel, $winner) = @_;
    $winner ||= {};

    my ($safe, $reason) = validate_relpath($conflict_rel);
    die "Unsafe conflict name: $reason\n" unless $safe;
    die "Conflict name is the same as the path\n" if $conflict_rel eq $path;

    my $abs = $self->{store}->abs_path($path);
    return 1 unless -e $abs || -l $abs;

    my $destination = $self->{store}->abs_path($conflict_rel);
    die "Conflict copy already exists: $conflict_rel\n"
        if -e $destination || -l $destination;

    make_path(dirname($destination)) unless -d dirname($destination);

    rename($abs, $destination)
        or die "Cannot preserve $path as $conflict_rel: $!\n";

    my $old = $self->{index}{$path};
    delete $self->{index}{$path};
    $self->{index}{$conflict_rel} = $old if $old;

    $self->{store}->journal({
        client => $self->{client},
        action => 'conflict_copy',
        path   => $conflict_rel,
        from   => $path,
        sha256 => $old ? $old->{h} : undef,
        result => 'ok',
    });

    $self->{store}->journal({
        client        => $self->{client},
        action        => 'conflict',
        path          => $path,
        winner        => 'client',
        loser_name    => $conflict_rel,
        winner_sha256 => $winner->{sha256},
        winner_mtime  => $winner->{mtime},
        loser_sha256  => $old ? $old->{h} : undef,
        loser_mtime   => $old ? $old->{m} : undef,
        result        => 'ok',
    });

    return 1;
}

# The pinned arguments in authorized_keys are the authority for a session.
# sshd passes the command the client asked for in SSH_ORIGINAL_COMMAND, so check
# that it agrees with the pinned repo, client, role and protocol and asks for
# nothing else: in particular it may not choose its own --root.
sub validate_forced_command {
    my ($original, $pinned) = @_;

    return (1, undef) unless defined $original;
    $original =~ s/\A\s+//;
    $original =~ s/\s+\z//;
    return (1, undef) unless length $original;

    my @tokens = split /\s+/, $original;

    if (@tokens && $tokens[0] !~ /\A--/) {
        my $program = shift @tokens;
        return (0, "unexpected program '$program' in the remote command")
            unless $program =~ m{(?:\A|/)filesync-server\z};
    }

    my %allowed = (
        repo   => 'repo',
        client => 'client',
        role   => 'role',
        proto  => 'proto',
    );

    while (@tokens) {
        my $token = shift @tokens;
        return (0, "unexpected argument '$token' in the remote command")
            unless $token =~ /\A--([a-z][a-z-]*)(?:=(.*))?\z/s;

        my ($flag, $value) = ($1, $2);
        unless (defined $value) {
            return (0, "the remote command gives --$flag without a value")
                unless @tokens;
            $value = shift @tokens;
        }

        my $field = $allowed{$flag};
        return (0, "the remote command may not set --$flag") unless $field;

        if ($field eq 'proto') {
            return (0, "the remote command asks for protocol '$value'")
                unless $value eq $PROTO;
            next;
        }

        my $expected = $pinned->{$field};
        return (0, "the remote command asks for $field '$value' but this key is pinned to "
                . "'$expected'")
            unless defined $expected && $value eq $expected;
    }

    return (1, undef);
}

sub _finish {
    my ($self) = @_;

    my $store = $self->{store};

    unless ($self->{dry_run}) {
        my @unfinished = grep { !$self->{applied}{ $_->{p} } } values %{ $self->{plan} };
        die 'Session ended before all actions completed: '
            . join(', ', map { $_->{p} } @unfinished) . "\n"
            if @unfinished;
    }

    unless ($self->{dry_run}) {
        $store->save_index($self->{index});
        $store->save_base($self->{client}, $self->{base_after});
    }

    my $summary = {
        pulled    => scalar(grep { $_->{a} eq 'pull' } values %{ $self->{plan} }),
        pushed    => scalar(grep { $_->{a} eq 'push' } values %{ $self->{plan} }),
        deleted   => scalar(grep { $_->{a} =~ /\Adelete_/ } values %{ $self->{plan} }),
        conflicts => scalar(grep { $_->{a} eq 'conflict' } values %{ $self->{plan} }),
    };

    $self->{logger}->info('session finished', {
        repo => $self->{repo},
        client => $self->{client},
        %{$summary},
        dry_run => $self->{dry_run} ? 1 : 0,
    });

    $self->{store}->journal({
        client  => $self->{client},
        action  => 'session',
        result  => 'ok',
        # The client exits 3 when it had to keep conflict copies; record that
        # here too, so --exit means the same thing on both sides.
        exit    => $summary->{conflicts} ? 3 : 0,
        dry_run => $self->{dry_run} ? 1 : 0,
        %{$summary},
    }) unless $self->{dry_run};
    $self->{session_journalled} = 1;

    $self->{conn}->send({ ok => 1, summary => $summary });
    $self->{finished} = 1;

    return 1;
}

sub _name_with_suffix {
    my ($name, $suffix) = @_;

    my ($dir, $base) = ('', $name);
    if ($name =~ m{\A(.*)/([^/]+)\z}) {
        ($dir, $base) = ($1, $2);
    }

    my ($stem, $ext) = ($base, '');
    if ($base =~ /\A(.+)(\.[^.]+)\z/) {
        ($stem, $ext) = ($1, $2);
    }

    my $new = "$stem-$suffix$ext";
    return length($dir) ? "$dir/$new" : $new;
}

1;
