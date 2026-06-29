package DBIx::QuickORM::Connection::RowData;
use strict;
use warnings;

our $VERSION = '0.000025';

use Carp qw/confess croak carp/;
use Scalar::Util qw/reftype blessed/;

use DBIx::QuickORM::Affinity();

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

use Object::HashBase qw{
    +connection
    +source
    +stack
    +invalid
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Connection::RowData - Per-row state tracked across a
transaction stack.

=head1 DESCRIPTION

Holds the mutable state behind a single row for one connection: the stored
(as-fetched) data, pending (unsaved) changes, and a desync map flagging
fields whose stored value changed underneath a pending edit. The state is
kept as a stack of frames keyed by transaction, so that committing or rolling
back a transaction merges or discards the right frame.

The frame stack always mirrors the connection's transaction nesting: when a
state frame is pushed for a transaction, carrier frames are inserted for any
open transactions between the current frame's transaction and the new one,
each starting as a copy of the data beneath it. When a transaction commits,
its frame merges into the frame immediately below it (and no further), so
data committed inside a savepoint is still discarded if an enclosing
transaction later rolls back.

A row becomes invalid when the transaction it was created in rolls back, or
when explicitly invalidated; an invalid row has an empty stack and a reason.

The state-frame keys (C<STORED>, C<PENDING>, C<DESYNC>, C<TRANSACTION>,
C<ROW_DATA>) are available as exported constants.

=head1 SYNOPSIS

    my $data = DBIx::QuickORM::Connection::RowData->new(
        source     => $source,
        connection => $connection,
    );

    my $stored  = $data->stored_data;
    my $pending = $data->pending_data;

=head1 ATTRIBUTES

=over 4

=item connection

The owning L<DBIx::QuickORM::Connection>, stored internally as a coderef and
returned resolved by the C<connection> method.

=item source

The row's source object (consumes C<DBIx::QuickORM::Role::Source>), stored
internally as a coderef and returned resolved by the C<source> method.

=item stack

Arrayref of state frames, newest first. Empty when the row is invalid.

=item invalid

The reason string when the row has been invalidated.

=back

=head1 EXPORTS

Nothing is exported by default. The following state-frame key constants may
be imported by name:

=over 4

=item STORED

=item PENDING

=item DESYNC

=item TRANSACTION

=item ROW_DATA

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = $data->valid

True when the row has a live active state.

=item $reason = $data->invalid

False when the row is valid, otherwise the invalidation reason string.

=cut

sub valid      { $_[0]->active(no_fatal => 1) ? 1 : 0 }
sub invalid    { $_[0]->active(no_fatal => 1) ? 0 : ($_[0]->{+INVALID} //= 'Unknown') }

=pod

=item $data->invalidate(reason => $why)

Marks the row invalid with the given reason (defaulting to the call site),
clears the state stack, and warns if pending data was discarded.

=cut

sub invalidate {
    my $self = shift;
    my %params = @_;

    my $reason = $params{reason};
    unless ($reason) {
        my @caller = caller;
        $reason = "unknown at $caller[1] line $caller[2]";
    }

    $self->{+INVALID} = $reason;

    my @old_stack = @{$self->{+STACK}};

    my $active = $self->active(no_fatal => 1) // (@old_stack ? $old_stack[0] : undef);

    my $pending = $active ? $active->{+PENDING} : undef;

    carp "Row invalidated with pending data" if $pending && keys %$pending;

    $self->{+STACK} = [];
}

=pod

=item $source = $data->source

The resolved source object.

=item $connection = $data->connection

The resolved connection object.

=item $href = $data->stored_data

=item $href = $data->pending_data

=item $href = $data->desync_data

=item $txn = $data->transaction

The respective fields of the active state frame.

=back

=cut

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

    # Rebuild any provided stack through _up_state so carrier frames are
    # inserted for open transactions; the stack must mirror txn nesting.
    my $stack = $self->{+STACK} // [];
    $self->{+STACK} = [];
    $self->_up_state($_) for reverse @$stack;
}

=pod

=over 4

=item $frame = $data->active

=item $frame = $data->active(no_fatal => 1)

Returns the active (top) state frame, first resolving the stack: a frame
whose transaction rolled back is discarded, a frame whose transaction
committed is merged into the frame immediately below it. Confesses when the
row is invalid unless C<no_fatal> is set, in which case it returns nothing.

=cut

sub active {
    my $self = shift;
    my %params = @_;

    my $stack = $self->{+STACK};
    while (@$stack) {
        my $frame = $stack->[0];
        my $txn = $frame->{+TRANSACTION} or last;    # No txn, base state

        # A dataless frame on top means every frame that held this row's data
        # was discarded with a rolled-back transaction; it cannot represent
        # the row, discard it too.
        unless (exists($frame->{+STORED}) || exists($frame->{+PENDING})) {
            shift @$stack;
            next;
        }

        my $res = $txn->result // last;    # Undef means still open
        my $done = shift @$stack;

        next unless $res;    # Rolled back, discard the frame

        if (@$stack) {
            # Committed: fold into the immediate next frame only. If that
            # frame's transaction later rolls back, the merged data is
            # discarded along with it.
            $self->_merge_state($done, $stack->[0]);
        }
        else {
            # Frame fill guarantees no open outer transaction exists when the
            # stack empties under a committed frame, so it becomes the base.
            delete $done->{+TRANSACTION};
            push @$stack => $done;
        }
    }

    return $stack->[0] if @$stack;

    $self->{+INVALID} //= "Likely inserted during a transaction that was rolled back";

    return if $params{no_fatal};
    confess "This row is invalid (Reason: $self->{+INVALID})";
}

=pod

=item $data->change_state($state)

Applies a new state frame: merges it into the active frame when they share a
transaction (or neither has one), otherwise pushes it as a new frame. Croaks
when asked to merge down a rolled-back transaction.

=back

=cut

sub change_state {
    my $self = shift;
    my ($state) = @_;

    my $active = $self->active(no_fatal => 1) or return $self->_up_state($state);

    my $row_txn   = $active->{+TRANSACTION};
    my $state_txn = $state->{+TRANSACTION};

    my $state_res = $state_txn ? $state_txn->result : undef;

    croak "Refusing to merge down a rolled-back transaction" if defined($state_res) && !$state_res;

    my $merge = 0;
    $merge ||= !($row_txn || $state_txn);
    $merge ||= $state_txn && $row_txn && $state_txn == $row_txn;

    if ($merge) {
        # If the transactions are the same, or if there are no txns for either, just merge.
        $self->_merge_state($state, $active);
    }
    else {
        $self->_up_state($state);
    }

    return $self;
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $bool = $data->compare_field($field, \%a, \%b)

Returns true when the named field compares equal between two field hashes,
using the field's type comparator when one exists and otherwise comparing by
affinity. Treats existence and definedness mismatches as unequal.

=back

=cut

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

    # true if same, false if different
    return $type->qorm_compare($a, $b) if $type;

    # true if same, false if different
    return DBIx::QuickORM::Affinity::compare_affinity_values($affinity, $a, $b);
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $data->_up_state($state)

Pushes a new state frame onto the stack. When the state carries a
transaction, carrier frames are first inserted for any open transactions
between the current top frame and the new one, and the new frame starts as a
copy of the data beneath it with the state merged in. Croaks when there is
already a base state and the new frame carries no transaction.

=cut

sub _up_state {
    my $self = shift;
    my ($state) = @_;

    my $stack = $self->{+STACK};
    croak "There is already a base state, and no txn was provided" if @$stack && !$state->{+TRANSACTION};

    my $txn = $state->{+TRANSACTION};

    unless ($txn) {
        unshift @$stack => $state;
        return $self;
    }

    $self->_fill_frames($txn);

    my $frame = $self->_carry_frame($txn);
    unshift @$stack => $frame;
    $self->_merge_state($state, $frame);

    # Explicit "clear" markers (a data key present but false) must survive on
    # the frame so they still clear the layer below when this frame merges
    # down on commit.
    for my $key (STORED, PENDING, DESYNC) {
        $frame->{$key} = undef if exists $state->{$key} && !$state->{$key} && !exists $frame->{$key};
    }

    return $self;
}

=pod

=item $data->_fill_frames($txn)

Insert carrier frames for every open transaction between the current top
frame's transaction and C<$txn>, so the stack mirrors the connection's
transaction nesting.

=cut

sub _fill_frames {
    my $self = shift;
    my ($txn) = @_;

    my $stack = $self->{+STACK};
    my $below_txn = @$stack ? $stack->[0]->{+TRANSACTION} : undef;
    my $below_id  = $below_txn ? $below_txn->id : undef;

    for my $open (@{$self->connection->transactions}) {
        next unless $open && !defined($open->result);
        next if defined($below_id) && $open->id <= $below_id;
        last if $open->id >= $txn->id;
        unshift @$stack => $self->_carry_frame($open);
    }

    return $self;
}

=pod

=item $frame = $data->_carry_frame($txn)

Build a new frame owned by C<$txn> carrying a shallow copy of the data in
the current top frame (if any).

=cut

sub _carry_frame {
    my $self = shift;
    my ($txn) = @_;

    my $frame = {TRANSACTION() => $txn};

    my $below = $self->{+STACK}->[0] or return $frame;

    for my $key (STORED, PENDING, DESYNC) {
        next unless exists $below->{$key};
        my $val = $below->{$key};
        $frame->{$key} = ref($val) eq 'HASH' ? {%$val} : $val;
    }

    return $frame;
}

=pod

=item $data->_merge_state($merge, $into)

Merges the C<$merge> state frame into the C<$into> frame, reconciling
stored, pending, and desync fields.

=back

=cut

sub _merge_state {
    my $self = shift;
    my ($merge, $into) = @_;

    die "No merge target frame provided" unless $into;

    my ($source, $connection);

    if (my $stored = $merge->{+STORED}) {
        if (my $pending = $into->{+PENDING}) {
            for my $field (keys %$stored) {
                $source     //= $self->source;
                $connection //= $self->connection;

                # No change
                next if $self->compare_field($field, $into->{+STORED}, $stored, $source, $connection);

                $into->{+STORED}->{$field} = $stored->{$field};
                $into->{+DESYNC}->{$field} = 1 if exists $pending->{$field};
            }
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
        $into->{+PENDING} = $into->{+PENDING} ? {%{$into->{+PENDING}}, %$pending} : $pending;
        $into->{+DESYNC}  = $into->{+DESYNC}  ? {%{$into->{+DESYNC}},  %$desync}  : $desync if $desync;
    }
    elsif (exists $merge->{+PENDING}) {
        delete $into->{+PENDING};
    }

    delete $into->{+PENDING} if $into->{+PENDING} && !keys %{$into->{+PENDING}};
    delete $into->{+DESYNC} unless $into->{+PENDING};

    return $self;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
