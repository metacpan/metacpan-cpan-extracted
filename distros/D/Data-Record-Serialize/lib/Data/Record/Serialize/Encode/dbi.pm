package Data::Record::Serialize::Encode::dbi;

# ABSTRACT:  store a record in a database

use Moo::Role;

use Data::Record::Serialize::Error { errors =>
  [ qw( param
        connect
        schema
        create
        insert
   )] }, -all;

our $VERSION = '0.23';

use Data::Record::Serialize::Types -types;

use SQL::Translator;
use SQL::Translator::Schema;
use Types::Standard -types;

use List::Util qw[ pairmap ];

use DBI;

use namespace::clean;



















has dsn => (
    is       => 'ro',
    required => 1,
    coerce   => sub {

        my $arg = 'ARRAY' eq ref $_[0] ? $_[0] : [ $_[0] ];
        my @dsn;
        for my $el ( @{$arg} ) {

            my $ref = ref $el;
            push( @dsn, $el ), next
              unless $ref eq 'ARRAY' || $ref eq 'HASH';

            my @arr = $ref eq 'ARRAY' ? @{$el} : %{$el};

            push @dsn, pairmap { join( '=', $a, $b ) } @arr;
        }

        unshift @dsn, 'dbi' unless $dsn[0] =~ /^dbi/;

        return join( ':', @dsn );
    },
);








has table => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);










has schema => (
    is        => 'ro',
    predicate => 1,
    isa       => Str,
);







has drop_table => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);








has create_table => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);









has primary => (
    is      => 'ro',
    isa     => ArrayOfStr,
    coerce  => 1,
    default => sub { [] },
);







has db_user => (
    is      => 'ro',
    isa     => Str,
    default => '',
);







has db_pass => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has _sth => (
    is       => 'rwp',
    init_arg => undef,
);
has _dbh => (
    is       => 'rwp',
    init_arg => undef,
);

has column_defs => (
    is       => 'rwp',
    lazy     => 1,
    clearer  => 1,
    init_arg => undef,
    builder  => sub {

        my $self = shift;

        my @column_defs;
        for my $field ( @{ $self->output_fields } ) {

            push @column_defs,
              join( ' ',
                $field,
                $self->output_types->{$field},
                ( 'primary key' )x!!( $self->primary eq $field ) );
        }

        return join ', ', @column_defs;
    },

);










has batch => (
    is      => 'ro',
    isa     => Int,
    default => 100,
    coerce  => sub { $_[0] > 1 ? $_[0] : 0 },
);







has dbitrace => ( is => 'ro', );













has queue => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
);

has '+_use_integer' => ( is => 'rwp', default => 1 );

has '+_need_types' => ( is => 'rwp', default => 1 );

has '+_map_types' => (
    is      => 'rwp',
    default => sub { {S => 'text', N => 'real', I => 'integer'} },
);

before '_build__nullify' => sub {

    my $self = shift;
    $self->_set__nullify( $self->type_index->{'numeric'} );

};

sub _table_exists {

    my $self = shift;

    return
      defined $self->_dbh->table_info( '%', $self->schema, $self->table,
        'TABLE' )->fetch;
}

sub _fq_table_name {

    my $self = shift;

    join( '.', ( $self->has_schema ? ( $self->schema ) : () ), $self->table );
}





my %producer = (
    DB2       => 'DB2',
    MySQL     => 'mysql',
    Oracle    => 'Oracle',
    Pg        => 'PostgreSQL',
    SQLServer => 'SQLServer',
    SQLite    => 'SQLite',
    Sybase    => 'Sybase',
);

sub setup {

    my $self = shift;

    return if $self->_dbh;

    my @dsn = DBI->parse_dsn( $self->dsn )
      or error( 'param', "unable to parse DSN: ", $self->dsn );
    my $dbi_driver = $dsn[1];

    my $producer = $producer{$dbi_driver} || $dbi_driver;

    my %attr = (
        AutoCommit => !$self->batch,
        RaiseError => 1,
        PrintError => 0,
    );

    $attr{sqlite_allow_multiple_statements} = 1
      if $dbi_driver eq 'SQLite';

    $self->_set__dbh(
        DBI->connect( $self->dsn, $self->db_user, $self->db_pass, \%attr ) )
      or error( 'connect', 'error connecting to ', $self->dsn, "\n" );

    $self->_dbh->trace( $self->dbitrace )
      if $self->dbitrace;

    if ( $self->drop_table || ( $self->create_table && !$self->_table_exists ) )
    {
        my $tr = SQL::Translator->new(
            from => sub {
                my $schema = $_[0]->schema;
                my $table = $schema->add_table( name => $self->_fq_table_name )
                  or error( 'schema', $schema->error );

                for my $field_name ( @{ $self->output_fields } ) {

                    $table->add_field(
                        name      => $field_name,
                        data_type => $self->output_types->{$field_name}
                    ) or error( 'schema',  $table->error );
                }

                if ( @{ $self->primary } ) {
                    $table->primary_key( @{ $self->primary } )
                      or error( 'schema', $table->error );
                }

                1;
            },
            to             => $producer,
            producer_args  => { no_transaction => 1 },
            add_drop_table => $self->drop_table && $self->_table_exists,
        );


        my $sql = $tr->translate
          or error( 'schema', $tr->error );

        # print STDERR $sql;
        eval { $self->_dbh->do( $sql ); };

        error( 'create', { msg => "error in table creation: $@", payload => $sql } )
          if $@;

        $self->_dbh->commit if $self->batch;
    }

    my $sql = sprintf(
        "insert into %s (%s) values (%s)",
        $self->_fq_table_name,
        join( ',', @{ $self->output_fields } ),
        join( ',', ( '?' ) x @{ $self->output_fields } ),
    );

    $self->_set__sth( $self->_dbh->prepare( $sql ) );

    return;
}




















































sub flush {

    my $self = shift;

    my $queue = $self->queue;

    if ( @{ $queue } ) {

        my $last;
        eval {
            $self->_sth->execute( @$last )
              while $last = shift @{ $queue };
        };

        my $error = $@;
        $self->_dbh->commit;

        if ( $error ) {
            unshift @{ $queue }, $last;

            my %query;
            @query{ @{ $self->output_fields } } = @$last;
            error( "insert", { msg => "Transaction aborted: $error", payload => \%query } );
        }
    }

    1;
}


















sub send {

    my $self = shift;

    if ( $self->batch ) {

        push @{ $self->queue }, [ @{ $_[0] }{ @{ $self->output_fields } } ];

        $self->flush
          if @{ $self->queue } == $self->batch;

    }
    else {

        eval {
            $self->_sth->execute( @{ $_[0] }{ @{ $self->output_fields } } );
        };
        error( "insert", { msg => "record insertion failed: $@", payload => $_[0] } )
          if $@;
    }

}


after '_trigger_output_fields' => sub {
    $_[0]->clear_column_defs;
};

after '_trigger_output_types' => sub {
    $_[0]->clear_column_defs;
};























sub close {

    my $self = shift;

    $self->flush
      if $self->batch;

    $self->_dbh->disconnect
      if defined $self->_dbh;

    1;
}












sub DEMOLISH {

    my $self = shift;

    warnings::warnif( 'Data::Record::Serialize::Encode::dbi::queue', __PACKAGE__.": record queue is not empty in object destruction" )
        if @{ $self->queue };

    $self->_dbh->disconnect
      if defined $self->_dbh;

}


# these are required by the Sink/Encode interfaces but should never be
# called in the ordinary run of things.









sub say    { error( 'Encode::stub_method', 'internal error: stub method <say> invoked' ) }
sub print  { error( 'Encode::stub_method', 'internal error: stub method <print> invoked' ) }
sub encode { error( 'Encode::stub_method', 'internal error: stub method <encode> invoked' ) }

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';


1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::dbi - store a record in a database

=head1 VERSION

version 0.23

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'sqlite', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::dbi> writes a record to a database using
L<DBI>.

It performs both the L<Data::Record::Serialize::Role::Encode> and
L<Data::Record::Serialize::Role::Sink> roles.

B<You cannot construct this directly>. You must use
L<Data::Record::Serialize/new>.

=head2 Types

Field types are recognized and converted to SQL types via the following map:

  S => 'text'
  N => 'real'
  I => 'integer'

=head2 NULL values

By default numeric fields are set to C<NULL> if they are empty.  This
can be changed by setting the C<nullify> attribute.

=head2 Performance

Records are by default written to the database in batches (see the
C<batch> attribute) to improve performance.  Each batch is performed
as a single transaction.  If there is an error during the transaction,
record insertions during the transaction are I<not> rolled back.

=head2 Errors

Transaction errors result in an exception in the
C<Data::Record::Serialize::Error::Encode::dbi::insert> class. See
L<Data::Record::Serialize::Error> for more information on exception
objects.

=head1 ATTRIBUTES

These attributes are available in addition to the standard attributes
defined for L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

=head2 C<dsn>

I<Required> The DBI Data Source Name (DSN) passed to B<L<DBI>>.  It
may either be a string or an arrayref containing strings or arrayrefs,
which should contain key-value pairs.  Elements in the sub-arrays are
joined with C<=>, elements in the top array are joined with C<:>.  For
example,

  [ 'SQLite', { dbname => $db } ]

is transformed to

  SQLite:dbname=$db

The standard prefix of C<dbi:> will be added if not present.

=head2 C<table>

I<Required> The name of the table in the database which will contain the records.
It will be created if it does not exist.

=head2 C<schema>

The schema to which the table belongs.  Optional.

=head2 C<drop_table>

If true, the table is dropped and a new one is created.

=head2 C<create_table>

If true, a table will be created if it does not exist.

=head2 C<primary>

A single output column name or an array of output column names which
should be the primary key(s).  If not specified, no primary keys are
defined.

=head2 C<db_user>

The name of the database user

=head2 C<db_pass>

The database password

=head2 C<batch>

The number of rows to write to the database at once.  This defaults to 100.

If greater than 1, C<batch> rows are cached and then sent out in a
single transaction.  See L</Performance> for more information.

=head2 C<dbitrace>

A trace setting passed to  L<DBI>.

=head1 METHODS

=head2 C<queue>

  $queue = $obj->queue;

The queue containing records not yet successfully transmitted
to the database.  This is only of interest if L</batch> is not C<0>.

Each element is an array containing values to be inserted into the database,
in the same order as the fields in L<Data::Serialize/output_fields>.

=head2 flush

  $s->flush;

Flush the queue of records to the database. It returns true if
all of the records have been successfully written.

If writing fails:

=over

=item *

Writing of records ceases.

=item *

The failing record is left at the head of the queue.  This ensures
that it is possible to retry writing the record.

=item *

an exception object (in the
C<Data::Record::Serialize::Error::Encode::dbi::insert> class) will be
thrown.  The failing record (in its final form after formatting, etc)
is available via the object's C<payload> method.

=back

If a record fails to be written, it will still be queued for the next
attempt at writing to the database.  If this behavior is undesired,
make sure to remove it from the queue:

  use Data::Dumper;

  if ( ! eval { $output->flush } ) {
      warn "$@", Dumper( $@->payload );
      shift $output->queue->@*;
  }

As an example of completely flushing the queue while notifying of errors:

  use Data::Dumper;

  until ( eval { $output->flush } ) {
      warn "$@", Dumper( $@->payload );
      shift $output->queue->@*;
  }

=head2 send

  $s->send( \%record );

Send a record to the database.
If there is an error, an exception object (with class
C<Data::Record::Serialize::Error::Encode::dbi::insert>) will be
thrown, and the record which failed to be written will be available
via the object's C<payload> method.

If in L</batch> mode, the record is queued for later transmission.
When the number of records queued reaches that specified by the
L</batch> attribute, the C<flush> method is called.  See L</flush> for
more information on how errors are handled.

=head2 close

  $s->close;

Close the database handle. If writing is batched, records in the queue
are written to the database via L</flush>. An exception will be thrown
if a record cannot be written.  See L</flush> for more details.

As an example of draining the queue while notifying of errors:

  use Data::Dumper;

  until ( eval { $output->close } ) {
      warn "$@", Dumper( $@->payload );
      shift $output->queue->@*;
  }

=head2 DEMOLISH

This method is called when the object is destroyed.  It closes the
database handle B<but does not flush the record queue>.

A warning is emitted if the record queue is not empty; turn off the
C<Data::Record::Serialize::Encode::dbi::queue> warning to silence it.

=for Pod::Coverage has_schema

=for Pod::Coverage setup

=for Pod::Coverage say
  print
  encode

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
