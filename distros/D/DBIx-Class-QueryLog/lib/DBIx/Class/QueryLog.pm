package DBIx::Class::QueryLog;
$DBIx::Class::QueryLog::VERSION = '1.005001';
# ABSTRACT: Log queries for later analysis.

use Moo;
use Types::Standard qw( Str Maybe ArrayRef Bool InstanceOf );

has bucket => (
    is => 'rw',
    isa => Str,
    default => sub { 'default' }
);

has current_query => (
    is => 'rw',
    isa => Maybe[InstanceOf['DBIx::Class::QueryLog::Query']]
);

has current_transaction => (
    is => 'rw',
    isa => Maybe[InstanceOf['DBIx::Class::QueryLog::Transaction']]
);

has log => (
    traits => [qw(Array)],
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
);

sub add_to_log { push @{shift->log}, @_ }
sub reset { shift->log([]) }

has passthrough => (
    is => 'rw',
    isa => Bool,
    default => 0
);

has __time => (
    is => 'ro',
    default => sub { \&Time::HiRes::time },
);

sub _time { shift->__time->() }

before 'add_to_log' => sub {
    my ($self, $thing) = @_;

    $thing->bucket($self->bucket);
};

use base qw(DBIx::Class::Storage::Statistics);

use Time::HiRes;

use DBIx::Class::QueryLog::Query;
use DBIx::Class::QueryLog::Transaction;

sub time_elapsed {
    my $self = shift;

    my $total = 0;
    foreach my $t (@{ $self->log }) {
        $total += $t->time_elapsed;
    }

    return $total;
}

sub count {
    my $self = shift;

    my $total = 0;
    foreach my $t (@{ $self->log }) {
        $total += $t->count;
    }

    return $total;
}


sub txn_begin {
    my $self = shift;

    $self->next::method(@_) if $self->passthrough;
    $self->current_transaction(
        $self->transaction_class()->new({
            start_time => $self->_time,
        })
    );
}


sub txn_commit {
    my $self = shift;

    $self->next::method(@_) if $self->passthrough;
    if(defined($self->current_transaction)) {
        my $txn = $self->current_transaction;
        $txn->end_time($self->_time);
        $txn->committed(1);
        $txn->rolledback(0);
        $self->add_to_log($txn);
        $self->current_transaction(undef);
    } else {
        warn('Unknown transaction committed.')
    }
}


sub txn_rollback {
    my $self = shift;

    $self->next::method(@_) if $self->passthrough;
    if(defined($self->current_transaction)) {
        my $txn = $self->current_transaction;
        $txn->end_time($self->_time);
        $txn->committed(0);
        $txn->rolledback(1);
        $self->add_to_log($txn);
        $self->current_transaction(undef);
    } else {
        warn('Unknown transaction committed.')
    }
}


sub query_start {
    my $self = shift;
    my $sql = shift;
    my @params = @_;

    $self->next::method($sql, @params) if $self->passthrough;
    $self->current_query(
        $self->query_class()->new({
            start_time  => $self->_time,
            sql         => $sql,
            params      => \@params,
        })
    );
}


sub query_end {
    my $self = shift;

    $self->next::method(@_) if $self->passthrough;
    if(defined($self->current_query)) {
        my $q = $self->current_query;
        $q->end_time($self->_time);
        $q->bucket($self->bucket);
        if(defined($self->current_transaction)) {
            $self->current_transaction->add_to_queries($q);
        } else {
            $self->add_to_log($q)
        }
        $self->current_query(undef);
    } else {
        warn('Completed unknown query.');
    }
}


sub query_class       { 'DBIx::Class::QueryLog::Query' }

sub transaction_class { 'DBIx::Class::QueryLog::Transaction' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::QueryLog - Log queries for later analysis.

=head1 VERSION

version 1.005001

=head1 SYNOPSIS

DBIx::Class::QueryLog 'logs' each transaction and query executed so you can
analyze what happened in the 'session'.  It must be installed as the debugobj
in DBIx::Class:

    use DBIx::Class::QueryLog::NotifyOnMax;
    use DBIx::Class::QueryLog::Analyzer;

    my $schema = ... # Get your schema!
    my $ql = DBIx::Class::QueryLog::NotifyOnMax->new(
        max_count => 100,
    );
    $schema->storage->debugobj($ql);
    $schema->storage->debug(1);
      ... # do some stuff!
    my $ana = DBIx::Class::QueryLog::Analyzer->new({ querylog => $ql });
    my @queries = $ana->get_sorted_queries;

Every transaction and query executed will have a corresponding Transaction
and Query object stored in order of execution, like so:

    Query
    Query
    Transaction
    Query

This array can be retrieved with the log method.  Queries executed inside
a transaction are stored inside their Transaction object, not inside the
QueryLog directly.

See L<DBIx::Class::QueryLog::Analyzer> for options on digesting the results
of a QueryLog session.

If you wish to have the QueryLog collecting results, and the normal trace
output of SQL queries from DBIx::Class, then set C<passthrough> to 1

  $ql->passthrough(1);

Note that above the example uses L<DBIx::Class::QueryLog::NotifyOnMax> instead
of the vanilla C<DBIx::Class::QueryLog>, this is simply to encourage users to
use that and hopefully avoid leaks.

=head1 BUCKETS

Sometimes you want to break your analysis down into stages.  To segregate the
queries and transactions, simply set the bucket and run some queries:

  $ql->bucket('selects');
  $schema->resultset('Foo')->find(..);
  # Some queries
  $ql->bucket('updates');
  $foo->update({ name => 'Gorch' });
  $ql->bucket('something else);
  ...

Any time a query or transaction is completed the QueryLog's current bucket
will be copied into it so that the Analyzer can later use it.  See
the get_totaled_queries method and it's optional parameter.

=head1 METHODS

=head2 new

Create a new DBIx::Class::QueryLog.

=head2 bucket

Set the current bucket for this QueryLog.  This bucket will be copied to any
transactions or queries that finish.

=head2 time_elapsed

Returns the total time elapsed for ALL transactions and queries in this log.

=head2 count

Returns the number of queries executed in this QueryLog

=head2 reset

Reset this QueryLog by removing all transcations and queries.

=head2 add_to_log

Add this provided Transaction or Query to the log.

=head2 txn_begin

Called by DBIx::Class when a transaction is begun.

=head2 txn_commit

Called by DBIx::Class when a transaction is committed.

=head2 txn_rollback

Called by DBIx::Class when a transaction is rolled back.

=head2 query_start

Called by DBIx::Class when a query is begun.

=head2 query_end

Called by DBIx::Class when a query is completed.

=head2 query_class

Returns the name of the class to use for storing queries, by default
C<DBIx::Class::QueryLog::Query>.  If you subclass C<DBIx::Class::QueryLog>,
you may wish to override this.  Whatever you override it to must be a
subclass of DBIx::Class::QueryLog::Query.

=head2 transaction_class

As query_class but for the class for storing transactions.  Defaults to
C<DBIx::Class::QueryLog::Transaction>.

=head2 SEE ALSO

=over

=item * L<DBIx::Class::QueryLog::NotifyOnMax>

=item * L<DBIx::Class::QueryLog::Tee>

=item * L<DBIx::Class::QueryLog::Conditional>

=back

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Cory G Watson <gphat at cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Cory G Watson <gphat at cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
