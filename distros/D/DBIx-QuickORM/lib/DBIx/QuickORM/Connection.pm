package DBIx::QuickORM::Connection;
use strict;
use warnings;
use feature qw/state/;

our $VERSION = '0.000020';

use Carp qw/confess croak cluck carp/;
use Scalar::Util qw/blessed weaken/;
use DBIx::QuickORM::Util qw/load_class/;

use DBIx::QuickORM::Handle;
use DBIx::QuickORM::Connection::Transaction;

use Object::HashBase qw{
    <orm
    <dbh
    <dialect
    <pid
    <schema
    <transactions
    +_savepoint_counter
    +_txn_counter
    <manager
    <in_async
    <asides
    <forks
    <default_sql_builder
    <default_internal_txn
    <default_handle_class
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Connection - ORM connection to database.

=head1 DESCRIPTION

This module is the primary interface when using the ORM to connect to a
database. This contains the database connection itself, a clone of the original
schema along with any connection specific changes (temp tables, etc). You use
this class to interact with the database, manage transactions, and get
L<DBIx::QuickORM::Handle> objects that can be used to make queries against the
database.

=head1 SYNOPSIS

    use My::Orm qw/orm/;

    # Get a connection to the orm
    # Note: This will return the same connection each time, no need to cache it yourself.
    my $orm = orm('my_orm');

    # Do something to all rows in the 'people' table.
    my $people_handle = $orm->handle('people');
    for my $person ($people_handle->all) {
        ...
    }

    # Find all people with the surname 'smith' and print their first names.
    my $smith_handle = $people_handle->where({surname => 'smith'});
    for my $person ($handle->all) {
        print $person->field('first_name') . "\n"
    }

    # Do a transaction that is managed by the ORM.
    $con->txn(sub {
        my $txn = shift;

        ...

        if (good()) {
            # Can call commit or rollback manually. Or, if all is good just let
            # the sub exit and the transaction will commit itself.
            $txn->commit; # This will exit the subroutine
        }
        else {
            # Can call rollback manually, or if the sub exits due to an
            # exception being thrown, rollback will happen automatically.
            $txn->rollback; # This will exit the subroutine
        }
    });

=head1 ATTRIBUTES

These are accessed via read-only accessors of the same name.

=over 4

=item orm

The L<DBIx::QuickORM::ORM> object this connection belongs to.

=item dbh

The C<DBI> database handle for this connection.

=item dialect

The L<DBIx::QuickORM::Dialect> subclass instance for this connection.

=item pid

The PID the connection was established under.

=item schema

The connection-local L<DBIx::QuickORM::Schema> (a clone of the ORM's schema).

=item transactions

Arrayref forming the active transaction/savepoint stack. Internal use only.

=item manager

The L<DBIx::QuickORM::RowManager> instance managing row cache and state.

=item in_async

The active L<DBIx::QuickORM::STH::Async> object, if an async query is running.

=item asides

Hashref of active "aside" queries.

=item forks

Hashref of active "forked" queries.

=item default_sql_builder

Default SQL builder, normally L<DBIx::QuickORM::SQLBuilder::SQLAbstract>.

=item default_internal_txn

Boolean default for whether handles may use internal transactions.

=item default_handle_class

Default handle class, normally L<DBIx::QuickORM::Handle>.

=back

=head1 PUBLIC METHODS

=over 4

=item $con->init

Object construction hook invoked by L<Object::HashBase>. Establishes the
database handle, dialect, schema, and row manager. Not called directly.

=cut

sub init {
    my $self = shift;

    my $orm = $self->{+ORM} or croak "An orm is required";
    my $db = $orm->db;

    $self->{+_SAVEPOINT_COUNTER} //= 1;
    $self->{+_TXN_COUNTER} //= 1;

    $self->{+PID} = $$;

    $self->{+DBH} = $db->new_dbh;

    $self->{+DIALECT} = $db->dialect->new(dbh => $self->{+DBH}, db_name => $db->db_name);

    $self->{+DEFAULT_INTERNAL_TXN} //= 1;

    $self->{+ASIDES} = {};
    $self->{+FORKS}  = {};

    $self->{+DEFAULT_HANDLE_CLASS} //= $orm->default_handle_class // 'DBIx::QuickORM::Handle';

    $self->{+DEFAULT_SQL_BUILDER} //= do {
        require DBIx::QuickORM::SQLBuilder::SQLAbstract;
        DBIx::QuickORM::SQLBuilder::SQLAbstract->new();
    };

    my $txns = $self->{+TRANSACTIONS} = [];
    my $manager = $self->{+MANAGER} // 'DBIx::QuickORM::RowManager::Cached';
    if (blessed($manager)) {
        $manager->set_connection($self);
        $manager->set_transactions($txns);
    }
    else {
        my $class = load_class($manager) or die $@;
        $self->{+MANAGER} = $class->new(transactions => $txns, connection => $self);
    }

    if (my $autofill = $orm->autofill) {
        my $schema = $self->{+DIALECT}->build_schema_from_db(autofill => $autofill);

        if (my $schema2 = $orm->schema) {
            $self->{+SCHEMA} = $schema->merge($schema2);
        }
        else {
            $self->{+SCHEMA} = $schema->clone;
        }
    }
    else {
        $self->{+SCHEMA} = $orm->schema->clone;
    }
}

########################
# {{{ Async/Aside/Fork #
########################

=pod

=item $con->set_async($async)

Change state to be inside an async query, argument must be an
L<DBIx::QuickORM::STH::Async> instance.

=item $con->add_aside($aside)

Register an "aside" query.

=item $con->add_fork($fork)

Register a "forked" query.

=item $con->clear_async($async)

Change state to be outside of an async query. The argument must be an
L<DBIx::QuickORM::STH::Async> instance, and it must be the same object as the
one returned by C<in_async()>.

=item $con->clear_aside($aside)

Clear a previously registered "aside" query.

=item $con->clear_fork($fork)

Clear a previously registered "forked" query.

=cut

sub set_async {
    my $self = shift;
    my ($async) = @_;

    croak "There is already an async query in progress" if $self->{+IN_ASYNC} && !$self->{+IN_ASYNC}->done;

    $self->{+IN_ASYNC} = $async;
    weaken($self->{+IN_ASYNC});

    return $async;
}

sub add_aside {
    my $self = shift;
    my ($aside) = @_;

    $self->{+ASIDES}->{$aside} = $aside;
    weaken($self->{+ASIDES}->{$aside});

    return $aside;
}

sub add_fork {
    my $self = shift;
    my ($fork) = @_;

    $self->{+FORKS}->{$fork} = $fork;
    weaken($self->{+FORKS}->{$fork});

    return $fork;
}

sub clear_async {
    my $self = shift;
    my ($async) = @_;

    croak "Not currently running an async query" unless $self->{+IN_ASYNC};

    croak "Mismatch, we are in an async query, but not the one we are trying to clear"
        unless $async == $self->{+IN_ASYNC};

    delete $self->{+IN_ASYNC};
}

sub clear_aside {
    my $self = shift;
    my ($aside) = @_;

    croak "Not currently running that aside query" unless $self->{+ASIDES}->{$aside};

    delete $self->{+ASIDES}->{$aside};
}

sub clear_fork {
    my $self = shift;
    my ($fork) = @_;

    croak "Not currently running that fork query" unless $self->{+FORKS}->{$fork};

    delete $self->{+FORKS}->{$fork};
}

########################
# }}} Async/Aside/Fork #
########################

#####################
# {{{ SANITY CHECKS #
#####################

=pod

=item $con->pid_and_async_check

Throws an exception if the PID does not match, or if there is an async query
running.

=item $con->pid_check

Throws an exception if the current PID does not match the connection's PID.

=item $con->async_check

Throws an exception if there is an async query running.

=cut

sub pid_and_async_check {
    my $self = shift;
    return $self->pid_check && $self->async_check;
}

sub pid_check {
    my $self = shift;
    confess "Connections cannot be used across multiple processes, you must reconnect post-fork" unless $$ == $self->{+PID};
    return 1;
}

sub async_check {
    my $self = shift;

    my $async = $self->{+IN_ASYNC} or return 1;
    confess "There is currently an async query running, it must be completed before you run another query" unless $async->done;
    delete $self->{+IN_ASYNC};
    return 1;
}

#####################
# }}} SANITY CHECKS #
#####################

########################
# {{{ SIMPLE ACCESSORS #
########################

=pod

=item $db = $con->db

Shortcut for C<< $con->orm->db >>. Returns an L<DBIx::QuickORM::DB> object.

=item $dbh = $con->aside_dbh

Returns a completely new and independent C<$dbh> connected to the database.

=cut

sub db { $_[0]->{+ORM}->db }
sub aside_dbh { $_[0]->{+ORM}->db->new_dbh }

########################
# }}} SIMPLE ACCESSORS #
########################

#####################
# {{{ STATE CHANGES #
#####################

=pod

=item $con->reconnect

Used to reconnect after forking.

=cut

sub reconnect {
    my $self = shift;

    my $dbh = delete $self->{+DBH};
    $dbh->{InactiveDestroy} = 1 unless $self->{+PID} == $$;
    $dbh->disconnect;

    $self->{+PID} = $$;
    $self->{+DBH} = $self->{+ORM}->db->new_dbh;
}

#####################
# }}} STATE CHANGES #
#####################

###########################
# {{{ TRANSACTION METHODS #
###########################

=pod

=item $txn = $con->transaction(sub { my $txn = shift; ... })

=item $txn = $con->txn(sub { my $txn = shift; ... })

=item $txn = $con->transaction(%params)

=item $txn = $con->txn(%params)

This will start a transaction or create a savepoint to emulate nested
transactions. Calls to this method can be nested.

    $con->txn(sub {
        $con->txn(sub { ... }); # Nested! uses savepoints
    });

If an action sub is provided then the transaction will be started, and the
action sub will be executed. If the action sub returns then the transaction
will be commited. If the action sub throws an exception the transaction will be
rolled back.

You can also manually commit/rollback which will exit the action subroutine.

    $txn->commmit;
    $txn->rollback;

If you need to start a transaction that is not limited to a single subroutine,
you can call this method without an action sub, it will return an
L<DBIx::QuickORM::Connection::Transaction> instance that can be used to commmit
or rollback the transaction when you are ready. If the object falls completely
out of scope and is destroyed then the transaction will be rolled back.

All possible arguments:

    my $txn = $con->txn(
        # Action sub for this transaction, transaction ends when sub does.
        action => sub { my $txn = shift; ... },

        # Used to force a transaction even if there are aside or forked queries running.
        force        => $BOOL, # Basically a combination of the next 2 options
        ignore_aside => $BOOL, # Allow a transaction even if an aside query is active
        ignore_forks => $BOOL, # Allow a transaction even if a forked query is active

        # Things to run at the end of the transaction.
        on_fail       => sub { ... }, # Only runs if the txn is rolled back
        on_success    => sub { ... }, # Only runs if the txn is commited
        on_completion => sub { ... }, # Runs whent he txn is done regardless of status.

        # Same as above, except you are adding them to a direct parent txn (if one exists, otherwise they are no-ops)
        on_parent_fail       => sub { ... },
        on_parent_success    => sub { ... },
        on_parent_completion => sub { ... },

        # Same as above, except they are applied to the root transaction, no
        # matter how deeply nested it is.
        on_root_fail       => sub { ... },
        on_root_success    => sub { ... },
        on_root_completion => sub { ... },
    );

An L<DBIx::QuickORM::Connection::Transaction> instance is always returned. If
an action callback was provided then the instance will already be complete, but
you can check and see what the status was. If you did not provide an action
callback then the txn will be "live" and you can use the instance to commit it
or roll it back.

=cut

{
    no warnings 'once';
    *transaction = \&txn;
}
sub txn {
    my $self = shift;
    $self->pid_check;

    my @caller = caller;

    my $txns = $self->{+TRANSACTIONS};

    my $cb = (@_ && ref($_[0]) eq 'CODE') ? shift : undef;
    my %params = @_;
    $cb //= $params{action};

    croak "Cannot start a transaction while there is an active async query" if $self->{+IN_ASYNC} && !$self->{+IN_ASYNC}->done;

    unless ($params{force}) {
        unless ($params{ignore_aside}) {
            my $count = grep { $_ && !$_->done } values %{$self->{+ASIDES} // {}};
            croak "Cannot start a transaction while there is an active aside query (unless you use ignore_aside => 1, or force => 1)" if $count;
        }

        unless ($params{ignore_forks}) {
            my $count = grep { $_ && !$_->done } values %{$self->{+FORKS} // {}};
            croak "Cannot start a transaction while there is an active forked query (unless you use ignore_forked => 1, or force => 1)" if $count;
        }
    }

    my $id = $self->{+_TXN_COUNTER}++;

    my $dialect = $self->dialect;

    my $sp;
    if (@$txns) {
        $sp = "SAVEPOINT_${$}_" . $self->{+_SAVEPOINT_COUNTER}++;
        $dialect->create_savepoint(savepoint => $sp);
    }
    elsif ($self->dialect->in_txn) {
        croak "A transaction is already open, but it is not controlled by DBIx::QuickORM";
    }
    else {
        $dialect->start_txn;
    }

    my $txn = DBIx::QuickORM::Connection::Transaction->new(
        id            => $id,
        savepoint     => $sp,
        trace         => \@caller,
        on_fail       => $params{on_fail},
        on_success    => $params{on_success},
        on_completion => $params{on_completion},
    );

    my ($root, $parent) = @$txns ? (@{$txns}[0,-1]) : ($txn, $txn);

    $parent->add_fail_callback($params{'on_parent_fail'})             if $params{on_parent_fail};
    $parent->add_success_callback($params{'on_parent_success'})       if $params{on_parent_success};
    $parent->add_completion_callback($params{'on_parent_completion'}) if $params{on_parent_completion};
    $root->add_fail_callback($params{'on_root_fail'})                 if $params{on_root_fail};
    $root->add_success_callback($params{'on_root_success'})           if $params{on_root_success};
    $root->add_completion_callback($params{'on_root_completion'})     if $params{on_root_completion};

    push @{$txns} => $txn;
    weaken($txns->[-1]);

    my $ran = 0;
    my $finalize = sub {
        my ($txnx, $ok, @errors) = @_;

        return if $ran++;

        $txnx->throw("Cannot stop a transaction while there is an active async query")
            if $self->{+IN_ASYNC} && !$self->{+IN_ASYNC}->done;

        $txnx->throw("Internal Error: Transaction stack mismatch")
            unless @$txns && (($txnx->in_destroy && !$txns->[-1]) || $txns->[-1] == $txnx);

        pop @$txns;

        my $aborted = $txnx->aborted;
        my $res     = $ok && !$aborted;

        if ($sp) {
            if   ($res) { $dialect->commit_savepoint(savepoint => $sp) }
            else        { $dialect->rollback_savepoint(savepoint => $sp) }
        }
        else {
            if   ($res) { $dialect->commit_txn }
            else        { $dialect->rollback_txn }
        }

        my ($ok2, $err2) = $txnx->terminate($res, \@errors);
        unless ($ok2) {
            $ok = 0;
            push @errors => @$err2;
        }

        return if $ok;

        # When the transaction fell out of scope, DESTROY runs this as a safety
        # net and has already rolled it back. We cannot propagate an exception
        # from a destructor (Perl turns it into a noisy "(in cleanup)" stack
        # trace), so warn concisely instead of confessing.
        if ($txnx->in_destroy) {
            my $trace = $txnx->trace // [];
            carp "Transaction started at $trace->[1] line $trace->[2] fell out of scope and was rolled back"
                if @$trace > 2;
            return;
        }

        $txnx->throw(join "\n" => @errors);
    };

    unless($cb) {
        $txn->set_no_last(1);
        $txn->set_finalize($finalize);
        return $txn;
    }

    local $@;
    my $ok = eval {
        QORM_TRANSACTION: { $cb->($txn) };
        1;
    };

    # The body threw - record the exception that forced the rollback.
    $txn->set_exception($@) unless $ok;

    $finalize->($txn, $ok, $@);

    return $txn;
}

=pod

=item $bool_or_txn = $con->in_transaction

=item $bool_or_txn = $con->in_txn

Returns true if there is a transaction active. If the transaction is managed by
L<DBIx::QuickORM> then the L<DBIx::QuickORM::Connection::Transaction> object
will be returned.

=cut

{
    no warnings 'once';
    *in_transaction = \&in_txn;
}
sub in_txn {
    my $self = shift;
    return $self->current_txn // $self->dialect->in_txn;
}

=pod

=item $txn = $con->current_transaction

=item $txn = $con->current_txn

Return the current L<DBIx::QuickORM::Connection::Transaction> if one is active.

B<Note:> Do not use this to check for a transaction, it will return false if
there is a transaction that is not managed by L<DBIx::QuickORM>.

=cut

{
    no warnings 'once';
    *current_transaction = \&current_txn;
}
sub current_txn {
    my $self = shift;
    $self->pid_check;

    if (my $txns = $self->{+TRANSACTIONS}) {
        return $txns->[-1] if @$txns;
    }

    return undef;
}

=pod

=item $con->auto_retry_txn(sub { my $txn = shift; ... })

=item $con->auto_retry_txn(\%params, sub { my $txn = shift; ... })

=item $con->auto_retry_txn(%params, action => sub { my $txn = shift; ... })

Run the specified action in a transaction, retry if an exception is thrown.

This is a convenience method that boils down to:

    $con->auto_retry(sub { $con->txn(sub { ... }) });

C<< count => $NUM >> can be used to specify a maximum number of retries, the default is 1.

All other params are passed to C<txn()>.

=cut

sub auto_retry_txn {
    my $self = shift;
    $self->pid_check;
    $self->async_check;

    my $count;
    my %params;

    if (!@_) {
        croak "Not enough arguments";
    }
    elsif (@_ == 1 && ref($_[0]) eq 'CODE') {
        $count = 1;
        $params{action} = $_[0];
    }
    elsif (@_ == 2) {
        my $ref = ref($_[1]);
        if ($ref eq 'CODE') {
            $count = $_[0];
            $params{action} = $_[1];
        }
        elsif ($ref eq 'HASH') {
            $count  = $_[0];
            %params = %{$_[1]};
        }
        else {
            croak "Not sure what to do with second argument '$_[0]'";
        }
    }
    else {
        %params = @_;
        $count  = delete $params{count};
    }

    $count ||= 1;

    $self->auto_retry($count => sub { $self->txn(%params) });
}

###########################
# }}} TRANSACTION METHODS #
###########################

#######################
# {{{ UTILITY METHODS #
#######################

=pod

=item $res = $con->auto_retry(sub { ... })

=item $res = $con->auto_retry($count, sub { ... })

Run the provided sub multiple times until it succeeds or the count is exceeded.
Default count is 1. An exception will be thrown if it never succeeds. Cannot be
used inside a transaction.

Returns whatever the provided coderef returns; scalar context is always
assumed.

=cut

sub auto_retry {
    my $self  = shift;
    my $cb    = pop;
    my $count = shift || 1;
    $self->pid_check;
    $self->async_check;

    croak "Cannot use auto_retry inside a transaction" if $self->in_txn;

    my ($ok, $out);
    for (0 .. $count) {
        $ok = eval { $out = $cb->(); 1 };
        last if $ok;
        warn "Error encountered in auto-retry, will retry...\n Exception was: $@\n";
        $self->reconnect unless $self->{+DBH} && $self->{+DBH}->ping;
    }

    croak "auto_retry did not succeed (attempted " . ($count + 1) . " times)"
        unless $ok;

    return $out;
}

=pod

=item $source = $con->source($in, %params)

Resolve C<$in> to an object implementing L<DBIx::QuickORM::Role::Source>. C<$in>
may be such an object, a scalar reference (treated as literal SQL), or a table
name looked up in the schema. Croaks on failure unless C<< no_fatal => 1 >> is
passed, in which case it returns undef.

This is B<NOT> like calling C<source()> from L<DBIx::Class>; you cannot use the
source directly to make queries, look at the C<handle()> method instead.

=cut

sub source {
    my $self = shift;
    my ($in, %params) = @_;

    if (blessed($in)) {
        return $in if $in->DOES('DBIx::QuickORM::Role::Source');
        return undef if $params{no_fatal};
        croak "'$in' does not implement the 'DBIx::QuickORM::Role::Source' role";
    }

    if (my $r = ref($in)) {
        if ($r eq 'SCALAR') {
            require DBIx::QuickORM::LiteralSource;
            return DBIx::QuickORM::LiteralSource->new($in);
        }

        return undef if $params{no_fatal};
        croak "Not sure what to do with '$r'";
    }

    my $source = $self->schema->table($in);
    return $source if $source;

    return undef if $params{no_fatal};
    croak "Could not find the '$in' table in the schema";
}

#######################
# }}} UTILITY METHODS #
#######################

#########################
# {{{ HANDLE OPERATIONS #
#########################

=pod

See L<DBIx::QuickORM::Handle> for more information on handles.

=item $h = $con->handle(...)

Get an L<DBIx::QuickORM::Handle> object that operates on this connection. Any
argument accepted by the C<new()> or C<handle()> methods on
L<DBIx::QuickORM::Handle> can be provided here as arguments.

B<Note:> unlike C<source()>, C<handle()> does not accept a scalar reference
(literal SQL) directly; passing one throws. Build the source first and pass
the object:

    $con->handle($con->source(\$sql))->all;

=cut

sub handle {
    my $self = shift;
    my ($in, @args) = @_;

    my $handle;
    if ((blessed($in) || !ref($in)) && ($in->isa('DBIx::QuickORM::Handle') || $in->DOES('DBIx::QuickORM::Role::Handle'))) {
        return $in unless @args;
        return $in->handle(@args);
    }

    return $self->{+DEFAULT_HANDLE_CLASS}->handle(connection => $self, @_);
}

=pod

=item $h = $con->async(@handle_constructor_args)

=item $h = $con->aside(@handle_constructor_args)

=item $h = $con->forked(@handle_constructor_args)

=item $h = $con->all(@handle_constructor_args)

=item $h = $con->iterator(@handle_constructor_args)

=item $h = $con->any(@handle_constructor_args)

=item $h = $con->first(@handle_constructor_args)

=item $h = $con->one(@handle_constructor_args)

=item $h = $con->count(@handle_constructor_args)

=item $h = $con->delete(@handle_constructor_args)

These are convenience methods that simply proxy to handle objects:

    my $h = $con->handle(@handle_constructor_args)->NAME();

See the methods in L<DBIx::QuickORM::Handle> for more info.

=item $h = $con->by_id(@handle_constructor_args, $method_arg)

=item $h = $con->iterate(@handle_constructor_args, $method_arg)

=item $h = $con->insert(@handle_constructor_args, $method_arg)

=item $h = $con->vivify(@handle_constructor_args, $method_arg)

=item $h = $con->update(@handle_constructor_args, $method_arg)

=item $h = $con->update_or_insert(@handle_constructor_args, $method_arg)

=item $h = $con->find_or_insert(@handle_constructor_args, $method_arg)

These are convenience methods that simply proxy to handle objects:

    my $h = $con->handle(@handle_constructor_args)->NAME($method_arg);

See the methods in L<DBIx::QuickORM::Handle> for more info.

=cut

sub async  { my $self = shift; $self->handle(@_)->async }
sub aside  { my $self = shift; $self->handle(@_)->aside }
sub forked { my $self = shift; $self->handle(@_)->forked }

sub all      { my $self = shift; $self->handle(@_)->all }
sub iterator { my $self = shift; $self->handle(@_)->iterator }
sub any      { my $self = shift; $self->handle(@_)->any }
sub first    { my $self = shift; $self->handle(@_)->first }
sub one      { my $self = shift; $self->handle(@_)->one }
sub count    { my $self = shift; $self->handle(@_)->count }
sub delete   { my $self = shift; $self->handle(@_)->delete }

sub by_id   { my $self = shift; my $arg = pop; $self->handle(@_)->by_id($arg) }
sub iterate { my $self = shift; my $arg = pop; $self->handle(@_)->iterate($arg) }
sub insert  { my $self = shift; my $arg = pop; $self->handle(@_)->insert($arg) }
sub vivify  { my $self = shift; my $arg = pop; $self->handle(@_)->vivify($arg) }
sub update  { my $self = shift; my $arg = pop; $self->handle(@_)->update($arg) }

sub update_or_insert { my $self = shift; my $arg = pop; $self->handle(@_)->upsert($arg) }
sub find_or_insert   { my $self = shift; my $arg = pop; my $h = $self->handle(@_); $h->one($arg) // $h->insert($arg) }

=pod

=item $rows_arrayref = $con->by_ids($source, @ids)

Fetch rows in the specified source by their ids.

B<NOTE:> If all the specified rows are already cached, no DB query will occur.

C<$source> can be a table name, or any object that implements
L<DBIx::QuickORM::Role::Source>.

C<@ids> contains one or more row primary keys. The keys may be a scalar value
such as C<12> if the primary key is a single column. If the source has a
compound primary key you may provide an arrayref with all the key field values,
or a hashref with the C<< field => val >> pairs.

An arrayref of L<DBIx::QuickORM::Row> objects will be returned.

This is a convenience method that boils down to this:

    $con->handle($source)->by_ids(@ids);

=cut

sub by_ids {
    my $self = shift;
    my ($from, @ids) = @_;

    my $handle;
    if (blessed($from) && $from->isa('DBIx::QuickORM::Handle')) {
        $handle = $from;
    }
    else {
        $handle = $self->handle(source => $from);
    }

    return $handle->by_ids(@ids);
}

#########################
# }}} HANDLE OPERATIONS #
#########################

########################
# {{{ STATE OPERATIONS #
########################

=pod

=item $bool = $con->state_does_cache

Check if the current row manager handles caching of rows.

=item $row = $con->state_cache_lookup($source, $pk)

Find an in-cache row by source and primary key. Source can be a table name or
object that implements L<DBIx::QuickORM::Role::Source>. The primary key should
be a hashref:

    {pk_field1 => $pk_val1, pk_field2 => $pk_val2, ... }

=item $con->state_delete_row(...)

=item $con->state_insert_row(...)

=item $con->state_select_row(...)

=item $con->state_update_row(...)

=item $con->state_vivify_row(...)

=item $con->state_invalidate(...)

These are shortcuts for:

    $self->manager->METHOD(connection => $self, ...);

=back

=cut

sub state_does_cache   { $_[0]->{+MANAGER}->does_cache }
sub state_delete_row   { my $self = shift; $self->{+MANAGER}->delete(connection => $self, @_) }
sub state_insert_row   { my $self = shift; $self->{+MANAGER}->insert(connection => $self, @_) }
sub state_select_row   { my $self = shift; $self->{+MANAGER}->select(connection => $self, @_) }
sub state_update_row   { my $self = shift; $self->{+MANAGER}->update(connection => $self, @_) }
sub state_vivify_row   { my $self = shift; $self->{+MANAGER}->vivify(connection => $self, @_) }
sub state_invalidate   { my $self = shift; $self->{+MANAGER}->invalidate(connection => $self, @_) }
sub state_cache_lookup {
    my $self = shift;
    my ($in, $pk) = @_;

    my $source = $self->source($in);

    if (ref($pk) eq 'HASH') {
        my $fields = $source->primary_key // [];
        $pk = [map { $pk->{$_} } @$fields];
    }

    return $self->{+MANAGER}->do_cache_lookup($source, undef, undef, $pk);
}

########################
# }}} STATE OPERATIONS #
########################

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
