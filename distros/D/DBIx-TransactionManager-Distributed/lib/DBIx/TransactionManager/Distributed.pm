package DBIx::TransactionManager::Distributed;

use strict;
use warnings;

use Exporter qw(import export_to_level);

=head1 NAME

DBIx::TransactionManager::Distributed;

=head1 VERSION

  0.02

=cut

our $VERSION = "0.02";

=head1 DESCRIPTION

Generic database handling utilities.

Currently provides a minimal database handle tracking facility, allowing code
to request a transaction against all active database handles.

=head1 SYNOPSIS

    use DBIx::TransactionManager::Distributed qw(register_dbh release_dbh txn);
    my $dbh1 = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});
    my $dbh2 = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});
    my $dbh3 = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});

    register_dbh(category1 => $dbh1);
    register_dbh(category1 => $dbh2);
    register_dbh(category2 => $dbh2);
    register_dbh(category2 => $dbh3);

    txn { $dbh1->do('update ta set name = "a"'); $dbh2->do('insert into tb values (1)') } 'category1';
    txn { $dbh2->do('update tc set name = "b"'); $dbh3->do('insert into td values (2)') } 'category2';

    release_dbh(category1 => $dbh1);
    release_dbh(category1 => $dbh1);
    release_dbh(category2 => $dbh2);
    release_dbh(category3 => $dbh3);

=cut

use Scalar::Util qw(weaken refaddr);
use List::UtilsBy qw(extract_by);

our @EXPORT_OK = qw(register_dbh release_dbh dbh_is_registered txn register_cached_dbh);

# List of all retained handles by category. Since we don't expect to update
# the list often, and the usual action is to iterate through them all in
# sequence, we're using an array rather than a hash.
# Each $dbh will be stored as a weakref: all calls to register_dbh should
# be matched with a release_dbh or global destruction, but we can recover
# (and complain) if that doesn't happen.
my %DBH;

# Where we registered the dbh originally - top level key is category, second
# level is refaddr.
my %DBH_SOURCE;

# Last PID we saw - used for invalidating stale DBH on fork
my $PID = $$;

our $IN_TRANSACTION = 0;

=head2 register_dbh

Records the given database handle as being active and available for running transactions against.

Expects a category (string value) and L<DBI::db> instance.

Returns the database handle.

Example:

    sub _dbh {
        my $dbh = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});
        return DBIx::TransactionManager::Distributaed::register_dbh(category => $dbh);
    }

=cut

sub register_dbh {
    my ($category, $dbh) = @_;
    die "too many parameters to register_dbh: @_" if @_ > 2;
    my $addr = refaddr $dbh;
    if (dbh_is_registered($category, $dbh)) {
        warn "already registered this database handle at " . $DBH_SOURCE{$category}{$addr};
        return;
    }
    push @{$DBH{$category}}, $dbh;
    weaken($DBH{$category}[-1]);
    # filename:line (package::sub)
    $DBH_SOURCE{$category}{$addr} = sprintf "%s:%d (%s::%s)", (caller 1)[1, 2, 0, 3];
    # We may be connecting partway through a transaction - if so, we want to join this handle onto the list of
    # active transactions
    $dbh->begin_work if $IN_TRANSACTION && $dbh->{AutoCommit};
    $dbh;
}

=head2 release_dbh

Marks the given database handle as no longer active - it will not be used for any further transaction requests
via L</txn>.

Returns the database handle.

Example:

    sub DESTROY {
        my $self = shift;
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        DBIx::TransactionManager::Distributaed::release_dbh($self->dbh)->disconnect;
    }

=cut

sub release_dbh {
    my ($category, $dbh) = @_;
    die "too many parameters to release_dbh: @_" if @_ > 2;
    # At destruction we may have an invalid handle
    my $addr = refaddr $dbh or return $dbh;
    unless (dbh_is_registered($category, $dbh)) {
        my @other_categories = grep exists $DBH_SOURCE{$_}{$addr}, sort keys %DBH_SOURCE;
        warn "releasing unregistered dbh $dbh for category $category"
            . (@other_categories ? " (but found it in these categories instead: " . join ', ', @other_categories, ')' : '');
        # If we did find it elsewhere, make sure we do cleanup to reduce confusion
        _remove_dbh_from_category($_ => $dbh) for @other_categories;
    }
    _remove_dbh_from_category($category => $dbh);
    return $dbh;
}

=head2 _remove_dbh_from_category

Helper function to reduce common code - removes the given C<$dbh> from a single category.

Used internally.

=cut

sub _remove_dbh_from_category {
    my ($category, $dbh) = @_;
    my $addr = refaddr $dbh or return $dbh;
    delete $DBH_SOURCE{$category}{$addr};
    # avoiding grep here because these are weakrefs and we want them to stay that way.
    # since they're weakrefs, some of these may be undef
    extract_by { $addr == (defined($_) ? refaddr($_) : 0) } @{$DBH{$category}};
    return $dbh;
}

=head2 dbh_is_registered

Returns true if the provided database handle has been registered already.

Used when registering a handle acquired via L<DBI/connect_cached>.

    register_dbh($category => $dbh) unless dbh_is_registered($category => $dbh);

=cut

sub dbh_is_registered {
    my ($category, $dbh) = @_;
    die "too many parameters to register_dbh: @_" if @_ > 2;
    _check_fork();
    my $addr = refaddr $dbh;
    return exists $DBH_SOURCE{$category}{$addr} ? 1 : 0;
}

=head2 register_cached_dbh

Records the given database handle created via L<DBI/connect_cached> as being active and available for running transactions against.

Expects a category (string value) and L<DBI::db> instance.

Returns the database handle.

Example:

    sub _dbh {
        my $dbh = DBI->connect_cached('dbi:Pg', '', '', { RaiseError => 1});
        return register_cached_dbh('category' => $dbh);
    }

=cut

sub register_cached_dbh {
    my ($category, $dbh) = @_;
    register_dbh($category => $dbh) unless dbh_is_registered($category => $dbh);
    $dbh->begin_work if $IN_TRANSACTION && $dbh->{AutoCommit};
    $dbh;
}

=head2 txn

Runs the given coderef in a transaction.

Expects a coderef and one or more database handle categories.

Will call L<DBI/begin_work> for every known database handle in the given category,
run the code, then call L<DBI/commit> on success, or L<DBI/rollback> on failure.

Will raise an exception on failure, or return an empty list on success.

Example:

    txn { dbh()->do('NOTIFY something') } 'category';

WARNING: This only applies transactions to known database handles. Anything else -
Redis, cache layers, files on disk - is out of scope. Transactions are a simple
L<DBI/begin_work> / L<DBI/commit> pair, there's no 2-phase commit or other
distributed transaction co-ordination happening here.

=cut

sub txn(&;@) {
    my ($code, @categories) = @_;
    die "Need a database category" unless @categories;
    _check_fork();
    my $wantarray = wantarray;
    for my $category (@categories) {
        if (my $count = () = extract_by { !defined($_) } @{$DBH{$category}}) {
            warn "Had $count database handles that were not released via release_dbh, probable candidates follow:\n";
            my %addr = map { ; refaddr($_) => 1 } @{$DBH{$category}};
            warn "unreleased dbh in $_\n" for sort delete @{$DBH_SOURCE{$category}}{grep !exists $addr{$_}, keys %{$DBH_SOURCE{$category}}};
        }
    }

    my @rslt;
    eval {
        for my $category (@categories) {
            $_->{AutoCommit} && $_->begin_work for @{$DBH{$category}};
        }
        local $IN_TRANSACTION = 1;
        # We want to pass through list/scalar/void context to the coderef
        if ($wantarray) {
            @rslt = $code->();
        } elsif (defined $wantarray) {
            $rslt[0] = $code->();
        } else {
            $code->();
        }
        _check_fork();
        for my $category (@categories) {
            # Note that we may hit exceptions here, and we want to raise them since it means the
            # database activity did not complete as expected
            $_->commit for grep defined, @{$DBH{$category}};    # might have closed database handle(s) in $code
        }
        1;
    } or do {
        my $err = $@;
        warn "Error in transaction: $err";
        for my $category (@categories) {
            eval {
                $_->rollback;
                1;
            } or warn "after $err also had failure in rollback for dbh in category $category: $@" for grep defined, @{$DBH{$category}};
        }
        die $err;
    };
    return $wantarray ? @rslt : $rslt[0];
}

=head2 _check_fork

Test whether we have forked recently, and invalidate all our caches if we have.

Returns true if there has been a fork since last check, false otherwise.

=cut

sub _check_fork {
    return 0 if $PID == $$;
    $PID        = $$;
    %DBH        = ();
    %DBH_SOURCE = ();
    return 1;
}

1;

=head1 SEE ALSO

=over

=item L<DBIx::TransactionManager>

=item L<DBIx::ScopedTransaction>

=item L<DBIx::Class::Storage::TxnScopeGuard>

=back

These modules are also handling scope-based transaction. The main difference is this one operates across database handles with different categories.

=cut
