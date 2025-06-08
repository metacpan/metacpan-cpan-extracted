package DBIx::QuickORM::Connection::RowData;
use strict;
use warnings;

use Carp qw/confess croak carp/;
use List::Util qw/first/;
use Scalar::Util qw/reftype blessed/;

use constant STORED      => 'stored';
use constant PENDING     => 'pending';
use constant DESYNC      => 'desync';
use constant TRANSACTION => 'transaction';
use constant ROW_DATA    => 'row_data';

use Importer Importer => 'import';
our @EXPORT_OK = qw{
    STORED
    PENDING
    DESYNC
    TRANSACTION
    ROW_DATA
};

use DBIx::QuickORM::Util::HashBase qw{
    +connection
    +source
    +stack
    +invalid
};

sub valid      { $_[0]->active(no_fatal => 1) ? 1 : 0 }
sub invalid    { $_[0]->active(no_fatal => 1) ? 0 : ($_[0]->{+INVALID} //= 'Unknown') }

sub invalidate {
    my $self = shift;
    my %params = @_;

    my $reason = $params{reason};
    unless ($reason) {
        my @caller = caller;
        $reason = "unkown at $caller[1] line $caller[2]";
    }

    $self->{+INVALID} = $reason;

    my @old_stack = @{$self->{+STACK}};

    my $active = $self->active(no_fatal => 1) // @old_stack ? $old_stack[-1] : undef;

    my $pending = $active ? $active->{+PENDING} : undef;

    carp "Row invalidated with pending data" if $pending && keys %$pending;

    $self->{+STACK} = [];
}

sub source     { $_[0]->{+SOURCE}->() }
sub connection { $_[0]->{+CONNECTION}->() }

sub stored_data  { $_[0]->active->{+STORED} }
sub pending_data { $_[0]->active->{+PENDING} }
sub desync_data  { $_[0]->active->{+DESYNC} }
sub transaction  { $_[0]->active->{+TRANSACTION} }

sub init {
    my $self = shift;

    my $src = $self->{+SOURCE} or confess "'source' is required";
    my $con = $self->{+CONNECTION}  or confess "'connection' is required";

    my ($src_sub, $src_obj);
    if ((reftype($src) // '') eq 'CODE') {
        $src_sub = $src;
        $src_obj = $src_sub->();
    }
    else {
        $src_obj = $src;
        $src_sub = sub { $src_obj };
    }

    croak "'source' must be either a blessed object that consumes the role 'DBIx::QuickORM::Role::Source', or a coderef that returns such an object"
        unless $src_obj && blessed($src_obj) && $src_obj->DOES('DBIx::QuickORM::Role::Source');

    my ($con_sub, $con_obj);
    if ((reftype($con) // '') eq 'CODE') {
        $con_sub = $con;
        $con_obj = $con_sub->();
    }
    else {
        $con_obj = $con;
        $con_sub = sub { $con_obj };
    }

    croak "'connection' must be either a blessed instance of 'DBIx::QuickORM::Connection', or a coderef that returns such an object"
        unless $con_obj && blessed($con_obj) && $con_obj->isa('DBIx::QuickORM::Connection');

    $self->{+CONNECTION}  = $con_sub;
    $self->{+SOURCE} = $src_sub;
    $self->{+STACK} //= [];
}

sub active {
    my $self = shift;
    my %params = @_;

    my $connection;
    my $stack = $self->{+STACK};
    while (@$stack) {
        my $txn = $stack->[0]->{+TRANSACTION} or last; # No txn, bottom state
        my $res = $txn->result // last; # Undef means still open
        my $done = shift @$stack;

        next unless $res; # Rolled back

        if (@$stack) {
            $self->_merge_state($done);
        }
        else {
            $connection //= $self->connection;
            $done->{+TRANSACTION} = first { !defined($_->result) && $_->id < $txn->id } reverse @{$connection->transactions};
            push @$stack => $done;
        }
    }

    return $stack->[0] if @$stack;

    $self->{+INVALID} //= "Likely inserted during a transaction that was rolled back";

    return if $params{no_fatal};
    confess "This row is invalid (Reason: $self->{+INVALID})";
}

sub change_state {
    my $self = shift;
    my ($state) = @_;

    my $active = $self->active(no_fatal => 1) or return $self->_up_state($state);

    my $row_txn = $self->active->{+TRANSACTION};
    my $state_txn = $state->{+TRANSACTION};

    my $state_res = $state_txn ? $state_txn->result : undef;
    my $row_res   = $row_txn   ? $row_txn->result   : undef;

    croak "Refusing to merge down a rolled-back transaction" if defined($state_res) && !$state_res;

    my $merge = 0;
    $merge ||= !($row_txn || $state_txn);
    $merge ||= $state_txn == $row_txn;

    if ($merge) {
        # If the transactions are the same, or if there are no txns for eather, just merge.
        $self->_merge_state($state);
    }
    else {
        $self->_up_state($state);
    }

    return $self;
}

sub _up_state {
    my $self = shift;
    my ($state) = @_;

    my $stack = $self->{+STACK};
    croak "There is already a base state, and no txn was provided" if @$stack && !$state->{+TRANSACTION};
    unshift @$stack => $state;
    return $self;
}

sub _merge_state {
    my $self = shift;
    my ($merge, $source, $connection) = @_;

    my $into = $self->active;

    if (my $stored = $merge->{+STORED}) {
        if (my $pending = $into->{+PENDING}) {
            for my $field (keys %{$merge->{+STORED}}) {
                $source //= $self->source;
                $connection  //= $self->connection;

                # No change
                next if $self->compare_field($field, $into->{+STORED}, $stored, $source, $connection);

                $into->{+STORED}->{$field} = $stored->{$field};
                $into->{+DESYNC}->{$field} = 1 if $pending->{$field};
            }
            $into->{+PENDING} = $pending if keys %$pending;
        }
        else {
            delete $into->{+DESYNC};
            $into->{+STORED} = $into->{+STORED} ? {%{$into->{+STORED} // {}}, %{$stored}} : $stored;
        }
    }
    elsif (exists $merge->{+STORED}) {
        delete $into->{+STORED};
        delete $into->{+DESYNC};
        delete $merge->{+DESYNC};
    }

    delete $into->{+DESYNC} if exists $merge->{+DESYNC} && !$merge->{+DESYNC};

    my $desync = $merge->{+DESYNC};
    if (my $pending = $merge->{+PENDING}) {
        $into->{+PENDING} = $into->{+PENDING} ? {%{$self->{+PENDING}}, %$pending} : $pending;
        $into->{+DESYNC}  = $into->{+DESYNC}  ? {%{$self->{+DESYNC}},  %$desync}  : $desync if $desync;
    }
    elsif (exists $merge->{+PENDING}) {
        delete $into->{+PENDING};
    }

    delete $into->{+PENDING} if $into->{+PENDING} && !keys %{$into->{+PENDING}};
    delete $into->{+DESYNC} unless $into->{+PENDING};

    return $self;
}

sub compare_field {
    my $self = shift;
    my ($field, $ah, $bh, $source, $connection) = @_;

    $source //= $self->source;
    $connection  //= $self->connection;

    my $affinity = $source->field_affinity($field, $connection->dialect);
    my $type     = $source->field_type($field);

    my $ae = exists $ah->{$field};
    my $be = exists $bh->{$field};
    return 0 if ($ae xor $be);       # One exists, one does not
    return 1 if (!$ae) && (!$be);    # Neither exists

    my $a = $ah->{$field};
    my $b = $bh->{$field};

    my $ad = defined($a);
    my $bd = defined($b);
    return 0 if ($ad xor $bd);       # One is defined, one is not
    return 1 if (!$ad) && (!$bd);    # Neither is defined

    # true if different, false if same
    return !$type->qorm_compare($a, $b) if $type;

    # true if same, false if different
    return DBIx::QuickORM::Affinity::compare_affinity_values($affinity, $a, $b);
}

1;
