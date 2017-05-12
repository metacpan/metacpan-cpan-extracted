package Alzabo::Runtime::RowState::Live;

use strict;

use Alzabo::Exceptions;
use Alzabo::Runtime;
use Alzabo::Utils;

sub _where
{
    my $class = shift;
    my $row = shift;
    my $sql = shift;

    my ($pk1, @pk) = $row->table->primary_key;

    $sql->where( $pk1, '=', $row->{pk}{ $pk1->name } );
    $sql->and( $_, '=', $row->{pk}{ $_->name } ) foreach @pk;
}

sub _init
{
    my $class = shift;
    my $row = shift;
    my %p = @_;

    $row->{pk} = $row->_make_id_hash(%p);

    while ( my ($k, $v) = each %{ $row->{pk} } )
    {
        $row->{data}{$k} = $v;
    }

    if ( $p{prefetch} )
    {
        while ( my ($k, $v) = each %{ $p{prefetch} } )
        {
            $row->{data}{$k} = $v;
        }
    }
    else
    {
        eval { $class->_get_prefetch_data($row) };

        if ( my $e = $@ )
        {
            return if isa_alzabo_exception( $e, 'Alzabo::Exception::NoSuchRow' );

            rethrow_exception $e;
        }
    }

    unless ( keys %{ $row->{data} } > keys %{ $row->{pk} } )
    {
        # Need to try to fetch something to confirm that this row exists!
        my $sql = ( $row->schema->sqlmaker->
                    select( ($row->table->primary_key)[0] )->
                    from( $row->table ) );

        $class->_where($row, $sql);

        $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
        print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

        return
            unless defined $row->schema->driver->one_row( sql => $sql->sql,
                                                          bind => $sql->bind );
    }

    return 1;
}

sub _get_prefetch_data
{
    my $class = shift;
    my $row = shift;

    my @pre = $row->table->prefetch;

    return unless @pre;

    $class->_get_data( $row, @pre );
}

sub _get_data
{
    my $class = shift;
    my $row = shift;

    my %data;
    my @select;
    foreach my $col (@_)
    {
        if ( exists $row->{data}{$col} )
        {
            $data{$col} = $row->{data}{$col};
        }
        else
        {
            push @select, $col;
        }
    }

    return %data unless @select;

    my $sql = ( $row->schema->sqlmaker->
                select( $row->table->columns(@select) )->
                from( $row->table ) );
    $class->_where($row, $sql);

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    my %d;
    @d{@select} =
        $row->schema->driver->one_row( sql  => $sql->sql,
                                       bind => $sql->bind )
            or $row->_no_such_row_error;

    while ( my( $k, $v ) = each %d )
    {
        $row->{data}{$k} = $data{$k} = $v;
    }

    return %data;
}

sub id_as_string
{
    my $class = shift;
    my $row = shift;
    my %p = @_;

    return $row->{id_string} if exists $row->{id_string};

    $row->{id_string} = $row->id_as_string_ext( pk    => $row->{pk},
                                                table => $row->table );
    return $row->{id_string};
}

sub select
{
    my $class = shift;
    my $row = shift;

    my @cols = @_ ? @_ : map { $_->name } $row->table->columns;
    my %data = $class->_get_data( $row, @cols );

    return wantarray ? @data{@cols} : $data{ $cols[0] };
}

sub select_hash
{
    my $class = shift;
    my $row = shift;

    my @cols = @_ ? @_ : map { $_->name } $row->table->columns;

    return $class->_get_data( $row, @cols );
}

sub update
{
    my $class = shift;
    my $row = shift;
    my %data = @_;

    my $schema = $row->schema;

    my @fk; # this never gets populated unless referential integrity
            # checking is on
    my @set;

    my $includes_pk = 0;
    foreach my $k ( sort keys %data )
    {
        # This will throw an exception if the column doesn't exist.
        my $c = $row->table->column($k);

        if ( $row->_cached_data_is_same( $k, $data{$k} ) )
        {
            delete $data{$k};
            next;
        }

        $includes_pk = 1 if $c->is_primary_key;

        Alzabo::Exception::NotNullable->throw
            ( error => $c->name . " column in " . $row->table->name . " table cannot be null.",
              column_name => $c->name,
              table_name  => $c->table->name,
              schema_name => $schema->name,
            )
                unless defined $data{$k} || $c->nullable || defined $c->default;

        push @fk, $row->table->foreign_keys_by_column($c)
            if $schema->referential_integrity;

        push @set, $c => $data{$k};
    }

    return 0 unless keys %data;

    my $sql = ( $schema->sqlmaker->update( $row->table ) );

    $sql->set(@set);

    $class->_where( $row, $sql );

    # If we have foreign keys we'd like all the fiddling to be atomic.
    $schema->begin_work if @fk;

    eval
    {
        foreach my $fk (@fk)
        {
            $fk->register_update( map { $_->name => $data{ $_->name } } $fk->columns_from );
        }

        $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
        print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

        $schema->driver->do( sql  => $sql->sql,
                             bind => $sql->bind );

        $schema->commit if @fk;
    };

    if (my $e = $@)
    {
        eval { $schema->rollback };

        rethrow_exception $e;
    }

    while ( my( $k, $v ) = each %data )
    {
        # These can't be stored until they're fetched from the database again
        if ( Alzabo::Utils::safe_isa( $v, 'Alzabo::SQLMaker::Function' ) )
        {
            delete $row->{data}{$k};
            next;
        }

        $row->{data}{$k} = $v;
    }

    $row->_update_pk_hash if $includes_pk;

    return 1;
}

sub refresh
{
    my $class = shift;
    my $row = shift;

    delete $row->{data};

    $class->_get_prefetch_data($row);
}

sub delete
{
    my $class = shift;
    my $row = shift;

    my $schema = $row->schema;

    my @fk;
    if ($schema->referential_integrity)
    {
        @fk = $row->table->all_foreign_keys;
    }

    my $sql = ( $schema->sqlmaker->
                delete->from( $row->table ) );

    $class->_where($row, $sql);

    $schema->begin_work if @fk;
    eval
    {
        foreach my $fk (@fk)
        {
            $fk->register_delete($row);
        }

        $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
        print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

        $schema->driver->do( sql => $sql->sql,
                             bind => $sql->bind );

        $schema->commit if @fk;
    };

    if (my $e = $@)
    {
        eval { $schema->rollback };

        rethrow_exception $e;
    }

    $row->set_state( 'Alzabo::Runtime::RowState::Deleted' );
}

sub is_potential { 0 }

sub is_live { 1 }

sub is_deleted { 0 }


1;

__END__

=head1 NAME

Alzabo::Runtime::RowState::Live - Row objects representing rows in the database

=head1 SYNOPSIS

  my $row = $table->row_by_pk( pk => 1 );

=head1 DESCRIPTION

This state is used for live rows, rows which represent actual rows in
the database.

=head1 METHODS

See L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
