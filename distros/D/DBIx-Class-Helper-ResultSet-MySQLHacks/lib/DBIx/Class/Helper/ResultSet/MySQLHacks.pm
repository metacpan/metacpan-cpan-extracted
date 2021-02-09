package DBIx::Class::Helper::ResultSet::MySQLHacks;

use v5.10;

use base 'DBIx::Class::ResultSet';

# ABSTRACT: Useful MySQL-specific operations for DBIx::Class
use version;
our $VERSION = 'v1.0.0'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod     # Your base resultset
#pod     package MySchema::ResultSet;
#pod
#pod     use strict;
#pod     use warnings;
#pod
#pod     use parent 'DBIx::Class::ResultSet';
#pod
#pod     __PACKAGE__->load_components('Helper::ResultSet::MySQLHacks');
#pod
#pod     # In other resultset classes
#pod     package MySchema::ResultSet::Bar;
#pod
#pod     use strict;
#pod     use warnings;
#pod
#pod     use parent 'MySchema::ResultSet';
#pod
#pod     # In code using the resultset
#pod     $rs->multi_table_delete(qw< rel1 rel2 >);
#pod     $rs->multi_table_update(\%values);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This MySQL-specific ResultSet helper contains a series of hacks for various SQL
#pod operations that only work for MySQL.  These hacks are exactly that, so it's possible that
#pod the SQL manipulation isn't as clean as it should be.
#pod
#pod =head1 METHODS
#pod
#pod =head2 multi_table_delete
#pod
#pod     my $underlying_storage_rv = $rs->multi_table_delete;  # deletes rows from the current table
#pod     my $underlying_storage_rv = $rs->multi_table_delete(qw< rel1 rel2 >);
#pod
#pod Runs a delete using the multiple table syntax, which supports join operations.  This is
#pod useful in cases with a joined ResultSet that require rows to be deleted, and using
#pod L<DBIx::Class::ResultSet/delete_all> would be too slow.
#pod
#pod Without arguments, it will delete rows from the current table, ie: L<DBIx::Class::ResultSet/current_source_alias>.
#pod Otherwise, it can take a list of B<relationships> to delete from.  These must be existing
#pod relationship aliases tied to the joins, not table names.
#pod
#pod This method works by taking a count ResultSet, removing the C<< SELECT COUNT(*) >>
#pod portion, and splicing in the C<< DELETE @aliases >> part.
#pod
#pod The return value is a pass through of what the underlying storage backend returned, and
#pod may vary.  See L<DBI/execute> for the most common case.
#pod
#pod B<NOTE:> This method will not delete from views, per MySQL limitations.
#pod
#pod =cut

sub multi_table_delete {
    my ($self, @rel_aliases) = @_;
    @rel_aliases = ( $self->current_source_alias ) unless @rel_aliases;

    my $sql_maker = $self->result_source->storage->sql_maker;

    my $alias_str = join ', ', map {
        $sql_maker->_from_chunk_to_sql($_)
    } @rel_aliases;

    my ($sql, $bind);
    ($sql, @$bind) = @${ $self->count_rs->as_query };

    # Remove (useless) outside parentheses
    $sql =~ s/^\(\s*(.+)\s*\)$/$1/s;

    # Convert "SELECT COUNT(*) FROM" to "DELETE @aliases"
    $sql =~ s/^SELECT COUNT[()*\s]+(?= FROM)/DELETE $alias_str/;

    my $rv = $self->dbh_execute($sql, $bind);
    return $rv;
}

#pod =head2 multi_table_update
#pod
#pod     my $underlying_storage_rv = $rs->multi_table_update(\%values);
#pod
#pod Runs a update using the multiple table syntax, which supports join operations.  This is
#pod useful in cases with a joined ResultSet that require rows to be updated, and using
#pod L<DBIx::Class::ResultSet/update_all> would be too slow.
#pod
#pod A values hashref is required.  It's highly recommended that the keys are named as
#pod C<alias.column> pairs, since multiple tables are involved.
#pod
#pod This method works by acquiring the C<FROM>, C<SET>, and C<WHERE> clauses separately and
#pod merging them back into a proper multi-table C<UPDATE> query.
#pod
#pod The return value is a pass through of what the underlying storage backend returned, and
#pod may vary.  See L<DBI/execute> for the most common case.
#pod
#pod =cut

sub multi_table_update {
    my ($self, $values) = @_;

    $self->throw_exception('Values for multi_table_update must be a hash')
        unless ref $values eq 'HASH';

    my $rsrc      = $self->result_source;
    my $storage   = $rsrc->storage;
    my $sql_maker = $storage->sql_maker;

    ### NOTE: Much of this is based on deep-analysis of DBIx::Class::Storage::DBI, especially
    ### $result->update / $result->single and how that eventually ends up to their respective
    ### $storage->_execute calls.

    ### XXX: This FROM/WHERE piece might be replaced with a less private-heavy count_rs->query
    ### hack, similar to multi_table_delete.  However, the SET is going to be going
    ### *in-between* the FROM/WHERE piece, so binds and SQL insertion might make things more
    ### difficult.  If this code breaks hard, we might have to revert to that model.

    # Collect attrs for various calls
    my $resolved_attrs = { %{$self->_resolved_attrs} };

    # Use the resolved SELECT args here, since prune_unused_joins may be turned on, and
    # we don't want that overtrimming the FROM/WHERE lists.
    my $select_args = delete $resolved_attrs->{select} // ['*'];
    push @$select_args, keys %$values;

    # Need a more complex set than just $rsrc->columns_info, since relationship
    # aliases are probably being used.
    my $colinfo = $storage->_resolve_column_info($resolved_attrs->{from});

    # Get the SQL/binds for the SET part
    my ($set_sql, $set_bind);
    ($set_sql, @$set_bind) = $sql_maker->update('DUAL', $values);  # no WHERE
    $set_sql =~ s/^UPDATE `?DUAL`? //;  # no UPDATE header

    $set_bind = $storage->_resolve_bindattrs( $rsrc, $set_bind, $colinfo );

    # Get the SQL/binds for the FROM part
    my $from_attrs   = (
        $storage->_select_args( $resolved_attrs->{from}, $select_args, {}, $resolved_attrs )
    )[4];  # just get the $attrs hash back again

    my ($from_sql, $from_bind);
    ($from_sql, @$from_bind) = $sql_maker->select($from_attrs->{from});  # no WHERE, just * for the column list
    $from_sql =~ s/^\(\s*(.+)\s*\)$/$1/s;  # remove (useless) outside parentheses
    $from_sql =~ s/^SELECT \* FROM //;

    $from_bind = $storage->_resolve_bindattrs( $from_attrs->{from}, $from_bind );

    # Get the SQL/binds for the WHERE part
    my $where_attrs   = (
        $storage->_select_args( $resolved_attrs->{from}, $select_args, $resolved_attrs->{where}, $resolved_attrs )
    )[4];  # just get the $attrs hash back again

    my ($where_sql, $where_bind);
    ($where_sql, @$where_bind) = $sql_maker->where($where_attrs->{where});  # just the WHERE clause
    $where_sql =~ s/^ //;

    $where_bind = $storage->_resolve_bindattrs( $from_attrs->{from}, $where_bind );

    # Mash them together!
    my $update_sql  = join ' ', 'UPDATE', $from_sql, $set_sql, $where_sql;
    $update_sql =~ s/^\s+|\s+$//g;

    my $update_bind = [ @$from_bind, @$set_bind, @$where_bind ];

    my $rv = $self->dbh_execute($update_sql, $update_bind);
    return $rv;
}

#pod =head2 dbh_execute
#pod
#pod     my $rv                = $rs->dbh_execute($sql, $bind);
#pod     my ($rv, $sth, @bind) = $rs->dbh_execute($sql, $bind);
#pod
#pod Sends any SQL statement to the C<$dbh> via L<DBIx::Class::Storage::DBI/dbh_do> while
#pod running the usual query loggers and re-connection protections that come with DBIC.
#pod
#pod This runs code similar to L<DBIx::Class::Storage::DBI>'s C<_execute> method, except that
#pod it takes SQL and binds as input.  Like C<_dbh_execute> and C<_execute>, it returns
#pod different outputs, depending on the context.
#pod
#pod =cut

sub dbh_execute {
    my ($self, $sql, $bind) = @_;

    my $rsrc    = $self->result_source;
    my $storage = $rsrc->storage;

    $storage->_populate_dbh unless $storage->_dbh;

    return $storage->dbh_do( _dbh_execute =>     # retry over disconnects
        $sql,
        $bind,
        $storage->_dbi_attrs_for_bind($rsrc, $bind),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::ResultSet::MySQLHacks - Useful MySQL-specific operations for DBIx::Class

=head1 VERSION

version v1.0.0

=head1 SYNOPSIS

    # Your base resultset
    package MySchema::ResultSet;

    use strict;
    use warnings;

    use parent 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components('Helper::ResultSet::MySQLHacks');

    # In other resultset classes
    package MySchema::ResultSet::Bar;

    use strict;
    use warnings;

    use parent 'MySchema::ResultSet';

    # In code using the resultset
    $rs->multi_table_delete(qw< rel1 rel2 >);
    $rs->multi_table_update(\%values);

=head1 DESCRIPTION

This MySQL-specific ResultSet helper contains a series of hacks for various SQL
operations that only work for MySQL.  These hacks are exactly that, so it's possible that
the SQL manipulation isn't as clean as it should be.

=head1 METHODS

=head2 multi_table_delete

    my $underlying_storage_rv = $rs->multi_table_delete;  # deletes rows from the current table
    my $underlying_storage_rv = $rs->multi_table_delete(qw< rel1 rel2 >);

Runs a delete using the multiple table syntax, which supports join operations.  This is
useful in cases with a joined ResultSet that require rows to be deleted, and using
L<DBIx::Class::ResultSet/delete_all> would be too slow.

Without arguments, it will delete rows from the current table, ie: L<DBIx::Class::ResultSet/current_source_alias>.
Otherwise, it can take a list of B<relationships> to delete from.  These must be existing
relationship aliases tied to the joins, not table names.

This method works by taking a count ResultSet, removing the C<< SELECT COUNT(*) >>
portion, and splicing in the C<< DELETE @aliases >> part.

The return value is a pass through of what the underlying storage backend returned, and
may vary.  See L<DBI/execute> for the most common case.

B<NOTE:> This method will not delete from views, per MySQL limitations.

=head2 multi_table_update

    my $underlying_storage_rv = $rs->multi_table_update(\%values);

Runs a update using the multiple table syntax, which supports join operations.  This is
useful in cases with a joined ResultSet that require rows to be updated, and using
L<DBIx::Class::ResultSet/update_all> would be too slow.

A values hashref is required.  It's highly recommended that the keys are named as
C<alias.column> pairs, since multiple tables are involved.

This method works by acquiring the C<FROM>, C<SET>, and C<WHERE> clauses separately and
merging them back into a proper multi-table C<UPDATE> query.

The return value is a pass through of what the underlying storage backend returned, and
may vary.  See L<DBI/execute> for the most common case.

=head2 dbh_execute

    my $rv                = $rs->dbh_execute($sql, $bind);
    my ($rv, $sth, @bind) = $rs->dbh_execute($sql, $bind);

Sends any SQL statement to the C<$dbh> via L<DBIx::Class::Storage::DBI/dbh_do> while
running the usual query loggers and re-connection protections that come with DBIC.

This runs code similar to L<DBIx::Class::Storage::DBI>'s C<_execute> method, except that
it takes SQL and binds as input.  Like C<_dbh_execute> and C<_execute>, it returns
different outputs, depending on the context.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
