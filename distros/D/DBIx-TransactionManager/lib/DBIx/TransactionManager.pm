package DBIx::TransactionManager;
use strict;
use warnings;
use Carp ();
our $VERSION = '1.13';

sub new {
    my ($class, $dbh) = @_;

    unless ($dbh) {
        Carp::croak('missing mandatory parameter dbh');
    }

    bless {
        dbh => $dbh,
        active_transactions => [],
        rollbacked_in_nested_transaction => 0,
    }, $class;
}

sub txn_scope {
    DBIx::TransactionManager::ScopeGuard->new( @_ );
}

sub txn_begin {
    my ($self, %args) = @_;

    my $caller = $args{caller} || [ caller(0) ];
    my $txns   = $self->{active_transactions};
    my $rc = 1;
    if (@$txns == 0 && $self->{dbh}->FETCH('AutoCommit')) {
        $rc = $self->{dbh}->begin_work;
    }
    if ($rc) {
        push @$txns, { caller => $caller, pid => $$ };
    }
}

sub txn_rollback {
    my $self = shift;
    my $txns = $self->{active_transactions};
    return unless @$txns;

    my $current = pop @$txns; 
    if ( @$txns > 0 ) {
        # already popped, so if there's anything, we're in a nested
        # transaction, mate.
        $self->{rollbacked_in_nested_transaction}++;
    } else {
        $self->{dbh}->rollback;
        $self->_txn_end;
    }
}

sub txn_commit {
    my $self = shift;
    my $txns = $self->{active_transactions};
    return unless @$txns;

    if ( $self->{rollbacked_in_nested_transaction} ) {
        Carp::croak "tried to commit but already rollbacked in nested transaction.";
    }

    my $current = pop @$txns;
    if (@$txns == 0) {
        $self->{dbh}->commit;
        $self->_txn_end;
    }
}

sub _txn_end {
    @{$_[0]->{active_transactions}} = ();
    $_[0]->{rollbacked_in_nested_transaction} = 0;
}

sub active_transactions { $_[0]->{active_transactions} }

sub in_transaction {
    my $self = shift;
    my $txns = $self->{active_transactions};
    return @$txns ? $txns->[0] : ();
}

package DBIx::TransactionManager::ScopeGuard;
use Try::Tiny;

sub new {
    my($class, $obj, %args) = @_;

    my $caller = $args{caller} || [ caller(1) ];
    $obj->txn_begin( caller => $caller );
    bless [ 0, $obj, $caller, $$ ], $class;
}

sub rollback {
    return if $_[0]->[0]; # do not run twice.
    $_[0]->[1]->txn_rollback;
    $_[0]->[0] = 1;
}

sub commit {
    return if $_[0]->[0]; # do not run twice.
    $_[0]->[1]->txn_commit;
    $_[0]->[0] = 1;
}

sub DESTROY {
    my($dismiss, $obj, $caller, $pid) = @{ $_[0] };
    return if $dismiss;

    if ( $$ != $pid ) {
        return;
    }

    warn( "Transaction was aborted without calling an explicit commit or rollback. (Guard created at $caller->[1] line $caller->[2])" );

    try {
        $obj->txn_rollback;
    } catch {
        die "Rollback failed: $_";
    };
}

1;
__END__

=head1 NAME

DBIx::TransactionManager - Transaction handling for database.

=head1 SYNOPSIS

RAII style transaction management:

    use DBI;
    use DBIx::TransactionManager;
    my $dbh = DBI->connect('dbi:SQLite:');
    my $tm = DBIx::TransactionManager->new($dbh);
    
    # create transaction object
    my $txn = $tm->txn_scope;
    
        # execute query
        $dbh->do("insert into foo (id, var) values (1,'baz')");
        # And you can do multiple database operations here
    
    # and commit it.
    $txn->commit;

Nested transaction usage:

    use DBI;
    use DBIx::TransactionManager;
    my $dbh = DBI->connect('dbi:SQLite:');
    my $tm = DBIx::TransactionManager->new($dbh);
    
    {
        my $txn = $tm->txn_scope;
        $dbh->do("insert into foo (id, var) values (1,'baz')");
        {
            my $txn2 = $tm->txn_scope;
            $dbh->do("insert into foo (id, var) values (2,'bab')");
            $txn2->commit;
        }
        {
            my $txn3 = $tm->txn_scope;
            $dbh->do("insert into foo (id, var) values (3,'bee')");
            $txn3->commit;
        }
        $txn->commit;
    }
    
=head1 DESCRIPTION

DBIx::TransactionManager is a simple transaction manager.
like L<DBIx::Class::Storage::TxnScopeGuard>.

This module provides two futures.

=over 4

=item RAII based transaction management

=item Nested transaction management

=back

If you are writing of DBIx::* or O/R Mapper, see L<DBIx::TransactionManager::Developers>.

=head1 METHODS

=over 4

=item my $tm = DBIx::TransactionManager->new($dbh)

Creating an instance of this class.
C<$dbh> is required.

=item my $txn = $tm->txn_scope(%args)

Get DBIx::TransactionManager::ScopeGuard's instance object.

Options for this method is only for module creators, see L<DBIx::TransactionManager::Developers>.

=back

=head1 DBIx::TransactionManager::ScopeGuard's METHODS

=over 4

=item $txn->commit()

Commit the transaction.

If the C<$tm> is in a nested transaction, TransactionManager doesn't do COMMIT at here. TM just poped transaction stack and do nothing.

=item $txn->rollback()

Rollback the transaction.

If the C<$tm> is in a nested transaction, TransactionManager doesn't do ROLLBACK at here. TM just poped transaction stack and do nothing.

=back

=head1 DBIx::TransactionManager and other transaction managers

You B<cannot> use other transaction manager and DBIx::TransactionManager at once.

If you are using O/R mapper, you should use that's transaction management feature.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

L<DBIx::Class::Storage::TxnScopeGuard>

L<DBIx::Skinny::Transaction>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
