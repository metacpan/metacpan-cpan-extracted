package DBIx::QuickORM::Select::Forked;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak confess/;
use POSIX();
use IO::Select();
use Scope::Guard();

use Cpanel::JSON::XS qw/decode_json/;

use parent 'DBIx::QuickORM::Select';
use DBIx::QuickORM::Util::HashBase qw{
    +ready
    +started
    +ignore_transactions
};

sub ignore_transactions {
    my $self = shift;
    my $val = shift // 1;
    $self->{+IGNORE_TRANSACTIONS} = $val;
    return $self;
}

sub ignoring_transactions { $_[0]->{+IGNORE_TRANSACTIONS} }

sub start {
    my $self = shift;
    my ($post_fork) = @_;

    croak "Forked query already started" if $self->{+STARTED};

    unless ($self->{+IGNORE_TRANSACTIONS}) {
        croak 'Currently inside a transaction, refusing to start a side connection (call $forked->ignore_transactions to override)'
            if $self->{+SOURCE}->connection->in_transaction;
    }

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not open pipe: $!";

    my $pid = fork // die "Failed to fork: $!";

    if ($pid) {
        close($wh);

        my $con = $self->source->connection;

        my $guard;
        unless ($self->{+IGNORE_TRANSACTIONS}) {
            $con->add_side_connection;
            $guard = Scope::Guard->new(sub { $con->pop_side_connection });
        }

        $self->{+STARTED} = {
            pid   => $pid,
            rh    => $rh,
            guard => $guard,
        };

        return $self;
    }

    $post_fork->() if $post_fork;
    $self->run_child($wh);
}

sub run_child {
    my $self = shift;
    my ($wh) = @_;

    $SIG{TERM} = sub { POSIX::_exit(42) };
    $SIG{INT}  = sub { POSIX::_exit(42) };

    my $guard = Scope::Guard->new(sub { POSIX::_exit(1) });
    my $json = Cpanel::JSON::XS->new->ascii(1)->convert_blessed(1)->allow_nonref(1);
    $wh->autoflush(1);

    $self->source->reconnect;

    my $ok = eval {
        my $ret = $self->{+SOURCE}->do_select($self->params, forked => 1, aside => 1);
        my $sth = $ret->{sth};
        my $cols = $ret->{cols};
        my $relmap = $ret->{relmap};

        print $wh $json->encode({cols => $cols}), "\n";
        print $wh $json->encode({relmap => $cols}), "\n";

        while (my $data = $sth->fetchrow_arrayref) {
            print $wh $json->encode({row => $data}), "\n";
        }

        1;
    };
    my ($err) = @_;

    unless ($ok) {
        print STDERR $@;

        eval {
            print $wh $json->encode({error => $err}), "\n";
            1;
        } or print STDERR $@;
    }

    close($wh);

    $guard->dismiss();
    POSIX::_exit(0);
}

sub started { $_[0]->{+STARTED} ? $_[0] : undef }

sub busy {
    my $self = shift;
    return 0 unless $self->started;
    return 1 unless $self->ready;
    return 0;
}

sub ready {
    my $self = shift;
    return $self if defined $self->{+READY};

    my $started = $self->{+STARTED} or croak 'Forked query has not been started (did you forget to call $s->start)?';

    my $s = $started->{ios} //= IO::Select->new($started->{rh});

    my ($timeout) = @_ ? (@_) : (0);

    local $! = 0;
    if ($s->can_read($timeout)) {
        $self->{+READY} = 1;
        return $self;
    }

    die "IO Error: $!" if $!;

    return undef;
}

sub cancel { $_[0]->discard }

sub _rows {
    my $self = shift;
    return $self->{+ROWS} if $self->{+ROWS};

    $self->wait();

    return $self->{+ROWS};
}

sub wait {
    my $self = shift;

    return if exists $self->{+ROWS};

    my $started = $self->{+STARTED} or croak 'Forked query has not been started (did you forget to call $s->start)?';

    unless ($self->{+IGNORE_TRANSACTIONS}) {
        croak 'Source is currently inside a transaction, refusing to taint program state (call $forked->ignore_transactions to override)'
            if $self->{+SOURCE}->connection->in_transaction;
    }

    my $source = $self->source;

    my $rh = $started->{rh};
    my ($cols, $relmap, @rows);
    while (my $line = <$rh>) {
        my $data = decode_json($line);
        next unless defined($data);
        confess $data->{error} if $data->{error};

        if (my $r = $data->{relmap}) { $relmap = $r; next }
        if (my $c = $data->{cols})   { $cols   = $c; next }

        my $row_data = $data->{row} or die "Did not get row data: $line\n";

        my $row = {};
        @{$row}{@$cols} = @$row_data;
        $source->expand_relations($row, $relmap);
        push @rows => $source->_expand_row($row);
    }

    $self->{+ROWS} = \@rows;

    delete $started->{guard};

    my $pid = delete $started->{pid};
    local $? = 0;
    my $check = waitpid($pid, 0);
    my $stat = parse_exit($?);
    croak "Error waiting on pid $pid (got $check)" unless $check == $pid;
    croak "Child exited with status $stat->{err} (sig: $stat->{sig})" if $stat->{all};

    $self->{+READY} = 1;

    return $self;
}

sub parse_exit {
    my ($exit) = @_;
    croak "an exit value is required" unless defined $exit;

    my $sig = $exit & 127;
    my $dmp = $exit & 128;

    return {
        sig => $sig,
        err => ($exit >> 8),
        dmp => $dmp,
        all => $exit,
    };
}


sub count { @{$_[0]->_rows} }

sub discard {
    my $self = shift;

    my $done = 0;
    for my $field (ROWS(), READY()) {
        $done = 1 if delete $self->{$field};
    }

    if (my $started = delete $self->{+STARTED}) {
        if (my $pid = delete $started->{pid}) {
            local $?;
            kill('TERM', $pid);
            waitpid($pid, 0);
        }
    }

    return $self;
}

1;
