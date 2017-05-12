package Alzabo::Runtime::InsertHandle;

use strict;

use Alzabo::Exceptions ( abbr => [ qw( exception params_exception ) ] );
use Alzabo::Runtime;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { params_exception join '', @_ } );

use constant NEW_SPEC => { table => { isa => 'Alzabo::Runtime::Table' },
                           sql   => { isa => 'Alzabo::SQLMaker' },
                           columns => { type => ARRAYREF },
                           values  => { type => HASHREF, default => {} },
                         };

sub new
{
    my $class = shift;

    my %p = validate( @_, NEW_SPEC );

    my $self = bless \%p, $class;

    $self->{handle} =
        $self->{table}->schema->driver->statement_no_execute( sql => $p{sql}->sql );

    return $self;
}

sub insert
{
    my $self = shift;

    my %p = @_;
    %p = validate( @_,
                   { ( map { $_ => { optional => 1 } } keys %p ),
                     values => { type => HASHREF, default => {} },
                   },
                 );

    my $vals = { %{ $self->{values} },
                 %{ $p{values} },
               };

    my $schema = $self->{table}->schema;
    my $driver = $schema->driver;

    my %ph = $self->{sql}->placeholders;
    my @val_order;
    while ( my ( $name, $i ) = each %ph )
    {
        $val_order[$i] = $name;
    }

    foreach my $name ( keys %$vals )
    {
        params_exception
            "Cannot provide a value for a column that was not specified ".
            "when the insert handle was created ($name)."
                unless exists $ph{$name};
    }

    my @pk = $self->{table}->primary_key;
    foreach my $pk (@pk)
    {
        unless ( exists $vals->{ $pk->name } )
        {
            if ( $pk->sequenced )
            {
                $vals->{ $pk->name } = $driver->next_sequence_number($pk);
            }
            else
            {
                params_exception
                    ( "No value provided for primary key (" .
                      $pk->name . ") and no sequence is available." );
            }
        }
    }

    foreach my $c ( @{ $self->{columns} } )
    {
        delete $vals->{ $c->name }
            if ! defined $vals->{ $c->name } && defined $c->default;
    }

    my @fk = $self->{table}->all_foreign_keys;

    my %id;

    $schema->begin_work if @fk;
    eval
    {
        foreach my $fk (@fk)
        {
            $fk->register_insert( map { $_->name => $vals->{ $_->name } } $fk->columns_from );
        }

        $self->{sql}->debug(\*STDERR) if Alzabo::Debug::SQL;
        print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

        $self->{handle}->execute_no_result
            ( map { exists $vals->{$_} ? $vals->{$_} : undef } @val_order );

        foreach my $pk (@pk)
        {
            $id{ $pk->name } = ( defined $vals->{ $pk->name } ?
                                 $vals->{ $pk->name } :
                                 $driver->get_last_id($self) );
        }

        # must come after call to ->get_last_id for MySQL because the
        # id will no longer be available after the transaction ends.
        $schema->commit if @fk;
    };
    if (my $e = $@)
    {
        eval { $schema->rollback };

        rethrow_exception $e;
    }

    return unless defined wantarray;

    return $self->{table}->row_by_pk( pk => \%id,
                                      no_cache => $self->{no_cache},
                                      %p,
                                    );
}

1;

__END__

=head1 NAME

Alzabo::Runtime::InsertHandle - A handle representing an insert

=head1 SYNOPSIS

 my $handle =
     $table->insert_handle
         ( columns => [ $table->columns( 'name', 'job' ) ] );

 my $faye_row =
     $handle->insert( values =>
                      { name => 'Faye',
                        job => 'HK Pop Chanteuse' } );

 my $guesch_row =
     $handle->insert( values =>
                      { name => 'Guesch',
                        job => 'French Chanteuse and Dancer' } );

=head1 DESCRIPTION

This object is analogous to a DBI statement handle, and can be used to
insert multiple rows into a table more efficiently than repeatedly
calling C<< Alzabo::Runtime::Table->insert() >>.

=head1 METHODS

Objects of this class provide one public method:

=head2 insert

This method is used to insert a new row into a table.

It accepts the following parameters:

=over 4

=item * values

This should be a hash reference containing the values to be inserted
into the table.

If no value is given for a primary key column and the column is
L<"sequenced"|Alzabo::Column/sequenced> then the primary key will be
auto-generated.

If values are not provided for other columns which were given when C<<
Alzabo::Runtime::Table->insert_handle >> was called, this method first
checks to see if a value was provided for the column when C<<
Alzabo::Runtime::Table->insert_handle >> was called.  If none was
provided, then the column's default value is used.

If column values were passed to C<<
Alzabo::Runtime::Table->insert_handle >>, then these can be overridden
by values passed to this method.

It is not possible to override column values that were given as SQL
functions when C<< Alzabo::Runtime::Table->insert_handle >> was
called.

=back

This method returns a new
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> object.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=cut
