package DBIx::QuickORM::Connection::Transaction;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak confess/;
use Scalar::Util qw/weaken/;

use Object::HashBase qw{
    <id
    +connection
    +savepoint

    +on_success
    +on_fail
    +on_completion

    verbose

    <result
    <errors
    <trace

    exception
    +aborted

    <in_destroy
    +finalize

    no_last
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Connection::Transaction - One transaction or savepoint on a
DBIx::QuickORM connection.

=head1 DESCRIPTION

Represents a single transaction (or savepoint) and the callbacks queued
against it. C<commit> and C<rollback> record the outcome and break out of the
enclosing C<QORM_TRANSACTION> loop; C<terminate> records the final result and
fires the queued success / fail / completion callbacks. An optional finalize
callback runs when the transaction completes or, as a safety net, when the
object is destroyed while still pending.

=head1 SYNOPSIS

    QORM_TRANSACTION: {
        my $txn = DBIx::QuickORM::Connection::Transaction->new(id => $id);
        $txn->add_success_callback(sub { ... });
        ...
        $txn->commit;
    }

=head1 ATTRIBUTES

=over 4

=item id

The transaction identifier (required).

=item savepoint

The savepoint name when this transaction is implemented as a savepoint, undef
for a top-level transaction. Use C<is_savepoint> for a boolean check.

=item on_success

=item on_fail

=item on_completion

Callback queues (arrayrefs, or a single coderef normalized to one) fired by
C<terminate>. Success or fail callbacks run depending on the outcome,
followed by completion callbacks in both cases.

=item verbose

When true, C<commit> / C<rollback> warn a trace line. A string longer than
one character is used as the transaction name in that warning.

=item result

Undef while open; 1 on success, 0 on failure once terminated.

=item errors

The error(s) captured on failure.

=item trace

Arrayref describing where the transaction was started, used in C<throw>.

=item exception

The exception that forced the transaction to roll back, if any. Set when the
transaction's body threw (or the transaction fell out of scope); undef for a
normal commit or an explicit C<rollback>.

=item in_destroy

True while finalize runs from C<DESTROY>.

=item finalize

The finalize callback, if set.

=item no_last

When true, C<commit> / C<rollback> skip the C<last QORM_TRANSACTION> jump.

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = $txn->is_savepoint

True when this is a savepoint.

=cut

sub is_savepoint { $_[0]->{+SAVEPOINT} ? 1 : 0 }

=pod

=item $txn->init

Object construction hook invoked by L<Object::HashBase>. Validates the id and
normalizes the callback queues. Not called directly.

=cut

sub init {
    my $self = shift;

    croak "A transaction ID is required" unless $self->{+ID};

    # Hold the connection weakly. The connection holds its transactions weakly in
    # turn, so this back-reference does not create a strong cycle; weakening it
    # keeps a transaction from pinning its connection alive and from dragging the
    # whole connection into a dump or deep comparison of the txn.
    weaken($self->{+CONNECTION}) if $self->{+CONNECTION};

    $self->{+RESULT} = undef;

    $self->{+ON_SUCCESS}    = [$self->{+ON_SUCCESS}]    if 'CODE' eq ref($self->{+ON_SUCCESS});
    $self->{+ON_FAIL}       = [$self->{+ON_FAIL}]       if 'CODE' eq ref($self->{+ON_FAIL});
    $self->{+ON_COMPLETION} = [$self->{+ON_COMPLETION}] if 'CODE' eq ref($self->{+ON_COMPLETION});
}

=pod

=item $bool = $txn->complete

True once a result has been recorded.

=cut

sub complete { defined $_[0]->{+RESULT} }

=pod

=item $str = $txn->state

Returns C<active> while the transaction is open, then C<committed> or
C<rolled_back> once it finishes. Derived from C<result>.

=item $bool = $txn->committed

True if the transaction committed, false if it rolled back, undef while still
open. Derived from C<result>.

=item $bool = $txn->rolled_back

The inverse of C<committed>: true if it rolled back, false if it committed,
undef while still open.

=item $bool = $txn->aborted

True if an explicit C<rollback> was requested on this transaction.

=cut

sub committed {
    my $r = $_[0]->{+RESULT};
    return undef unless defined $r;
    return $r ? 1 : 0;
}

sub rolled_back {
    my $r = $_[0]->{+RESULT};
    return undef unless defined $r;
    return $r ? 0 : 1;
}

# True if an explicit rollback was requested (drives the commit/rollback
# decision in Connection::txn before the result is recorded).
sub aborted { $_[0]->{+ABORTED} ? 1 : 0 }

sub _assert_innermost {
    my $self = shift;
    my ($op) = @_;

    # last QORM_TRANSACTION unwinds to the innermost dynamically-enclosing
    # transaction callback, which is not necessarily this transaction's. When a
    # nested (callback-managed) transaction is open, committing or rolling back
    # an outer transaction object would resolve the wrong (inner) one, so refuse.
    #
    # The connection is held weakly (the connection already holds its
    # transactions weakly, so this just avoids following the back-ref in a dump
    # or deep comparison). By the time commit()/rollback() reach this point we
    # are running inside the transaction's own action, so the connection is
    # alive and it always has a current transaction (at least this one) --
    # neither being missing is a normal case, so croak rather than skip the
    # check silently.
    my $con = $self->{+CONNECTION}
        or croak "Cannot $op a transaction whose connection is gone";
    my $current = $con->current_txn
        or croak "Cannot $op: the connection reports no current transaction";
    return if $current == $self;

    croak "Cannot $op an outer transaction from within a nested transaction; resolve the innermost transaction first";
}

sub state {
    my $self = shift;
    my $r = $self->{+RESULT};
    return 'active' unless defined $r;
    return $r ? 'committed' : 'rolled_back';
}

=pod

=item $txn->rollback

=item $txn->rollback($why)

=item $txn->abort

=item $txn->abort($why)

Records the rollback (optionally with a reason), runs finalize when set, and
breaks out of the enclosing C<QORM_TRANSACTION> loop unless C<no_last> is set.
C<abort> is an alias for C<rollback>.

=cut

{
    no warnings 'once';
    *abort = \&rollback;
}
sub rollback {
    my $self = shift;
    my ($why) = @_;

    croak "Transaction is already complete" if $self->complete;

    if ($self->{+VERBOSE} || !$why) {
        my @caller = caller;
        my $trace = "$caller[1] line $caller[2]";

        if (my $verbose = $self->{+VERBOSE}) {
            my $name = length($verbose) > 1 ? $verbose : $self->{+ID};
            warn "Transaction '$name' rolled back in $trace" . ($why ? " ($why)" : ".") . "\n";
        }

        if ($why) {
            $why .= " in $trace" unless $why =~ m/\n$/;
        }
        else {
            $why = $trace;
        }
    }

    $self->{+ABORTED} = 1;

    $self->finalize(1, $why) if $self->{+FINALIZE};

    return if $self->{+NO_LAST};

    $self->_assert_innermost('roll back');

    no warnings 'exiting';
    last QORM_TRANSACTION;
}

=pod

=item $txn->commit

=item $txn->commit($why)

Records the commit (optionally with a reason), runs finalize when set, and
breaks out of the enclosing C<QORM_TRANSACTION> loop unless C<no_last> is set.

=cut

sub commit {
    my $self = shift;
    my ($why) = @_;

    croak "Transaction is already complete" if $self->complete;

    # rollback() sets ABORTED before running finalize; if that finalize was
    # refused by a guard (e.g. an in-flight async query) the transaction stays
    # recoverable but aborted. A later commit would silently issue a ROLLBACK
    # while returning normally, so the caller believes the data committed.
    croak "Cannot commit a transaction that has already been rolled back"
        if $self->{+ABORTED};

    if ($self->{+VERBOSE} || !$why) {
        my @caller = caller;
        my $trace = "$caller[1] line $caller[2]";

        if (my $verbose = $self->{+VERBOSE}) {
            my $name = length($verbose) > 1 ? $verbose : $self->{+ID};
            warn "Transaction '$name' committed in $trace" . ($why ? " ($why)" : ".") . "\n";
        }

        if ($why) {
            $why .= " in $trace" unless $why =~ m/\n$/;
        }
        else {
            $why = $trace;
        }
    }

    $self->finalize(1) if $self->{+FINALIZE};

    return if $self->{+NO_LAST};

    $self->_assert_innermost('commit');

    no warnings 'exiting';
    last QORM_TRANSACTION;
}

=pod

=item ($ok, $errors) = $txn->terminate($res, $err)

Records the final result, clears the callback queues, then runs the
success-or-fail callbacks followed by the completion callbacks. Returns a
list: a boolean for whether all callbacks succeeded, and an arrayref of any
callback errors (undef when none). The savepoint name is retained so
post-completion callbacks can still see C<is_savepoint>.

=cut

sub terminate {
    my $self = shift;
    my ($res, $err) = @_;

    $self->{+RESULT} = $res ? 1 : 0;
    $self->{+ERRORS} = $res ? undef : $err;

    my $todo = $res ? $self->{+ON_SUCCESS} : $self->{+ON_FAIL};
    $todo = [@{$todo // []}, @{$self->{+ON_COMPLETION} // []}];

    delete $self->{+ON_SUCCESS};
    delete $self->{+ON_FAIL};
    delete $self->{+ON_COMPLETION};

    return (1, undef) unless $todo && @$todo;

    my ($out, $out_err) = (1, undef);
    for my $cb (@$todo) {
        local $@;
        eval { $cb->($self); 1 } and next;
        push @{$out_err //= []} => $@;
        $out = 0;
    }

    return ($out, $out_err);
}

=pod

=item $txn->add_success_callback($cb)

=item $txn->add_fail_callback($cb)

=item $txn->add_completion_callback($cb)

Queue a callback to run from C<terminate> on success, on failure, or in both
cases respectively.

=cut

sub add_success_callback {
    my $self = shift;
    my ($cb) = @_;
    push @{$self->{+ON_SUCCESS} //= []} => $cb;
}

sub add_fail_callback {
    my $self = shift;
    my ($cb) = @_;
    push @{$self->{+ON_FAIL} //= []} => $cb;
}

sub add_completion_callback {
    my $self = shift;
    my ($cb) = @_;
    push @{$self->{+ON_COMPLETION} //= []} => $cb;
}

=pod

=item $txn->throw($err)

Confesses with C<$err> annotated by where the transaction was started, noting
when the throw happens during C<DESTROY>.

=cut

sub throw {
    my $self = shift;
    my ($err) = @_;

    my $trace = $self->{+TRACE} // [qw/unknown unknown unknown/];
    $err = "Transaction error in transaction started in $trace->[1] line $trace->[2]: $err";
    $err = "[In DESTROY] $err" if $self->{+IN_DESTROY};

    confess $err;
}

=pod

=item $txn->set_finalize($cb)

Sets the finalize callback.

=cut

sub set_finalize {
    my $self = shift;
    my ($cb) = @_;

    $self->{+FINALIZE} = $cb;
}

=pod

=item $ok = $txn->finalize($ok, $err)

Runs the finalize callback, passing it the transaction, C<$ok>, and C<$err>;
returns C<$ok>. The callback is cleared only after it returns successfully, so
a refused finalization (for example a commit attempted while an async query is
active) can be retried later. Croaks when there is no finalize callback set.

=back

=cut

sub finalize {
    my $self = shift;
    my ($ok, $err) = @_;
    my $cb = $self->{+FINALIZE} or croak "Nothing to finalize!";
    $cb->($self, $ok, $err);
    delete $self->{+FINALIZE};
    return $ok;
}

sub DESTROY {
    my $self = shift;
    my $finalize = $self->{+FINALIZE} or return;
    $self->{+IN_DESTROY} = 1;
    $self->set_exception("Transaction fell out of scope");
    $finalize->($self, 0, "Transaction fell out of scope");
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
