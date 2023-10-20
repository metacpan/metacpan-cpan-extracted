package Data::Record::Serialize::Encode::dbi;

# ABSTRACT:  store a record in a database

use v5.12;
use Moo::Role;

use Data::Record::Serialize::Error {
    errors => [
        qw( param
          connect
          schema
          create
          insert
          sqlite_backend
        ),
    ],
  },
  -all;

our $VERSION = '1.05';

use Data::Record::Serialize::Types -types;

use SQL::Translator;
use SQL::Translator::Schema;
use Types::Standard -types;
use Types::Common::String qw( NonEmptySimpleStr );

use List::Util 1.33 qw[ pairmap any ];

use DBI;

use namespace::clean;







has dsn => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my $arg = 'ARRAY' eq ref $_[0] ? $_[0] : [ $_[0] ];
        my @dsn;
        my @args;
        for my $el ( @{$arg} ) {

            my $ref = ref $el;
            unless ( $ref eq 'ARRAY' || $ref eq 'HASH' ) {
                push( @dsn, $el );
                next;
            }

            my @arr = $ref eq 'ARRAY' ? @{$el} : %{$el};

            push @args, pairmap { join( q{=}, $a, $b ) } @arr;
        }
        my $args = join( q{;}, @args );
        push @dsn, $args if length $args;
        unshift @dsn, 'dbi' unless $dsn[0] =~ /^dbi/;
        return join( q{:}, @dsn );
    },
);

has _cached => (
    is       => 'ro',
    default  => 0,
    init_arg => 'cached',
);








has table => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);











has schema => (
    is  => 'ro',
    isa => Maybe [NonEmptySimpleStr],
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
    default => q{},
);







has db_pass => (
    is      => 'ro',
    isa     => Str,
    default => q{},
);

has _sth => (
    is       => 'rwp',
    init_arg => undef,
);

has _dbh => (
    is        => 'rwp',
    init_arg  => undef,
    clearer   => 1,
    predicate => 1,
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
              join( q{ },
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

around '_build__nullified' => sub {
    my $orig = shift;
    my $self = $_[0];

    my $nullified = $self->$orig( @_ );

    # defer to the caller
    return $nullified if $self->has_nullify;

    # add all of the numeric fields
    [ @{ $self->numeric_fields } ];

};

my %MapTypes = (
    Pg      => { S => 'text', N => 'real', I => 'integer', B => 'boolean' },
    SQLite  => { S => 'text', N => 'real', I => 'integer', B => 'integer' },
    Default => { S => 'text', N => 'real', I => 'integer', B => 'integer' },
);

sub _map_types {
    $MapTypes{ $_[0]->_dbi_driver } // $MapTypes{Default};
}









sub to_bool { $_[0] ? 1 : 0 }

sub _table_exists {
    my $self = shift;

    # DBD::Sybase doesn't filter, so need to search
    my $matches
      = $self->_dbh->table_info( q{%}, $self->schema, $self->table, 'TABLE' )->fetchall_arrayref;
    return any { $_->[2] eq $self->table } @{$matches};
}

sub _fq_table_name {
    my $self = shift;
    defined $self->schema ? $self->schema . q{.} . $self->table : $self->table;
}

has _dsn_components => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub {
        my @dsn = DBI->parse_dsn( $_[0]->dsn )
          or error( 'param', 'unable to parse DSN: ', $_[0]->dsn );
        \@dsn;
    },
);

sub _dbi_driver {
    $_[0]->_dsn_components->[1];
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

has _producer => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub {
        my $dbi_driver = $_[0]->_dbi_driver;
        $producer{$dbi_driver} || $dbi_driver;
    },
);







sub setup {
    my $self = shift;

    return if $self->_has_dbh;

    my %attr = (
        AutoCommit                   => !$self->batch,
        RaiseError                   => 1,
        PrintError                   => 0,
        ( 'private_' . __PACKAGE__ ) => __FILE__ . __LINE__,
    );


    my $dbd = $self->_dbi_driver;

    if ( $dbd eq 'Sybase' ) {
        $attr{syb_quoted_identifier} = 1;
    }

    my $connect = $self->_cached ? 'connect_cached' : 'connect';

    $self->_set__dbh( DBI->$connect( $self->dsn, $self->db_user, $self->db_pass, \%attr ) )
      or error( 'connect', 'error connecting to ', $self->dsn, "\n" );

    $self->_dbh->trace( $self->dbitrace )
      if $self->dbitrace;

    if ( $self->drop_table || ( $self->create_table && !( my $table_exists = $self->_table_exists ) ) )
    {
        # in case the first half of the conditional in the above if
        # statement is true, the call to $self->_table_exists isn't
        # made, so $table_exists is not defined.
        $table_exists //= $self->_table_exists;

        ## no critic (Variables::ProhibitUnusedVarsStricter)
        my @guards = $dbd eq 'Sybase' ? _patch_sqlt_producer_sybase() : ();

        my $tr = SQL::Translator->new(
            from => sub {
                my $schema = $_[0]->schema;
                my $table  = $schema->add_table( name => $self->_fq_table_name )
                  or error( 'schema', $schema->error );

                for my $field_name ( @{ $self->output_fields } ) {
                    $table->add_field(
                        name      => $field_name,
                        data_type => $self->output_types->{$field_name} ) or error( 'schema', $table->error );
                }

                if ( @{ $self->primary } ) {
                    $table->primary_key( @{ $self->primary } )
                      or error( 'schema', $table->error );
                }

                1;
            },
            to             => $self->_producer,
            producer_args  => { no_transaction => 1 },
            add_drop_table => $self->drop_table && $table_exists,
            no_comments    => 1,
        );

        my @sql = $tr->translate;
        defined $sql[0] or error( 'schema', $tr->error );

        _do_sql( $self->_dbh, 'create', @sql );
        $self->_dbh->commit if $self->batch;
    }

    my $sql = sprintf(
        'insert into %s (%s) values (%s)',
        $self->_dbh->quote_identifier( undef, $self->schema, $self->table ),
        join( q{,}, @{ $self->output_fields } ),
        join( q{,}, ( q{?} ) x @{ $self->output_fields } ),
    );

    $self->_set__sth( $self->_dbh->prepare( $sql ) );

    return;
}

# SQL::Translator::Producer::Sybase has behaviors and bugs.
sub _patch_sqlt_producer_sybase {

    require SQL::Translator::Producer::Sybase;
    require Monkey::Patch;
    my %scope;

    my @guards;

    # Behavior: It tries to be 'helpful' and renames a table if it
    # collides with a table it has already seen.  There's no way to
    # turn that off. In this case, we may dropping/creating a table
    # multiple times, and having the table name change is not useful.
    # We turn its concept of "global name space" into a local one for
    # tables/indices/constraints. args[2] is the namespace hash, and
    # mk_name is currently passed a non-empty entry *only* for fields,
    # so we make sure to only give it a hash when its not specified
    # (and thus not a field), as we don't want to mix field names and
    # the table/indices/constraints level names.

    push @guards, Monkey::Patch::patch_package(
        'SQL::Translator::Producer::Sybase',
        'mk_name',
        sub {
            my ( $orig, @args ) = @_;
            $args[2] ||= \%scope;
            $orig->( @args );
        } );

    # Bug: add_drop_table attribute doesn't add the drop table
    # command.  future proof by chcking if the Sybase producer
    # implements it correctly and only monkey-patching it if it
    # doesn't.
    my $need_to_add_drop_table = do {
        my $tr = SQL::Translator->new(
            from => sub {
                require SQL::Translator::Schema::Table;
                my $table = SQL::Translator::Schema::Table->new( name => 'foo' );
                $table->add_field( name => 'foo_id', date_type => 'integer' );
                $_[0]->schema->add_table( $table );
                1;
            },
            to             => 'Sybase',
            add_drop_table => 1,
            no_comments    => 1,
        );
        $tr->translate !~ /DROP TABLE/;
    };

    if ( $need_to_add_drop_table ) {
        push @guards, Monkey::Patch::patch_package(
            'SQL::Translator::Producer::Sybase',
            'produce',
            sub {
                my ( $orig, @args ) = @_;

                my $translator = $args[0];

                return $orig->( @args ) unless $translator->add_drop_table;

                if ( wantarray ) {    ## no critic (Community::Wantarray)
                    my @orig = $orig->( @args );
                    return map { /CREATE TABLE (\S+) [(]/ ? ( qq[DROP TABLE $1\n\n], $_ ) : $_ } @orig;
                }
                else {
                    my $output = $orig->( @args );
                    $output =~ s/CREATE TABLE\s+(\S+)\s+[(]/DROP TABLE $1\n$&/g;
                    return $output;
                }

            } );

    }

    return @guards;
}

sub _do_sql {
    my ( $dbh, $subsys, @sql ) = @_;

    my $in_txn = !$dbh->{AutoCommit};

    my $statement;
    eval {
        $dbh->begin_work unless $in_txn;
        while ( $statement = shift @sql ) {
            die if !defined $dbh->do( $statement );
        }
        $dbh->commit unless $in_txn;
        1;
    } or do {
        my $e = $@;
        $dbh->rollback unless $in_txn;
        $statement =~ s/\n/ /g;
        error( $subsys, { msg => $e, payload => $statement } );
    };

}




















































sub flush {
    my $self = shift;

    return 1 unless $self->_has_dbh;

    my $queue = $self->queue;

    if ( @{$queue} ) {
        my $last;

        my $ret   = eval { $self->_sth->execute( @$last ) while $last = shift @{$queue}; 1; };
        my $error = $@;

        $self->_dbh->commit;

        if ( !defined $ret ) {
            unshift @{$queue}, $last;

            my %query;
            @query{ @{ $self->output_fields } } = @$last;
            error( 'insert', { msg => "Transaction aborted: $error", payload => \%query } );
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
        eval { $self->_sth->execute( @{ $_[0] }{ @{ $self->output_fields } } ); 1; }
          or error( 'insert', { msg => "record insertion failed: $@", payload => $_[0] } );
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

    return 1 unless $self->_has_dbh;

    $self->flush if $self->batch;
    $self->_dbh->disconnect;
    $self->_clear_dbh;

    1;
}












sub DEMOLISH {
    my $self = shift;

    warnings::warnif( 'Data::Record::Serialize::Encode::dbi::queue',
        __PACKAGE__ . ': record queue is not empty in object destruction' )
      if @{ $self->queue };

    $self->_dbh->disconnect
      if $self->_has_dbh;

}


# these are required by the Sink/Encode interfaces but should never be
# called in the ordinary run of things.








with 'Data::Record::Serialize::Role::EncodeAndSink';

1;

#
# This file is part of Data-Record-Serialize-Encode-dbi
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory DDL DSN Postgres Sybase
msg truthy

=head1 NAME

Data::Record::Serialize::Encode::dbi - store a record in a database

=head1 VERSION

version 1.05

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

For Postgres, C<< B => 'boolean' >>. For other databases, C<< B => 'integer' >>.
This encoder handles transformation of the input "truthy" Boolean value into
a form appropriate for the database to ingest.

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

=head2 Compatibility

This module has been tested on SQLite, PostgreSQL, and Sybase.  See
F<t/encoders/dbi.t> for more information on how to test against
non-SQLite databases.

L<SQL::Translator> is used to generate the DDL; unfortunately its
Sybase DDL producer has some issues/bugs and is temporarily
monkey-patched to work around them.

=head1 OBJECT ATTRIBUTES

=head2 C<dsn>

The value passed to the constructor.

=head2 C<table>

The value passed to the constructor.

=head2 C<schema>

The value passed to the constructor.

=head2 C<drop_table>

The value passed to the constructor.

=head2 C<create_table>

The value passed to the constructor.

=head2 C<primary>

The value passed to the constructor.

=head2 C<db_user>

The value passed to the constructor.

=head2 C<db_pass>

The value passed to the constructor.

=head2 C<batch>

The value passed to the constructor.

=head2 C<dbitrace>

The value passed to the constructor.

=head1 METHODS

=head2 C<queue>

  $queue = $obj->queue;

The queue containing records not yet successfully transmitted
to the database.  This is only of interest if L</batch> is not C<0>.

Each element is an array containing values to be inserted into the database,
in the same order as the fields in L<Data::Serialize/output_fields>.

=head2 to_bool

   $bool = $self->to_bool( $truthy );

Convert a truthy value to something that the JSON encoders will recognize as a boolean.

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

=head1 INTERNALS

=for Pod::Coverage has_schema

=for Pod::Coverage _has_dbh
  _clear_dbh

=for Pod::Coverage setup

=for Pod::Coverage say
  print
  encode

=head1 CONSTRUCTOR OPTIONS

=over

=item C<dsn>

I<Required> The DBI Data Source Name (DSN) passed to B<L<DBI>>.  It
may either be a string or an arrayref containing strings or arrayrefs,
which should contain key-value pairs.  Elements in the sub-arrays are
joined with C<=>, elements in the top array are joined with C<:>.  For
example,

  [ 'SQLite', { dbname => $db } ]

is transformed to

  SQLite:dbname=$db

The standard prefix of C<dbi:> will be added if not present.

=item C<cached>

If true, the database connection is made with L<DBI::connect_cached|DBI/connect_cached> rather than
L<DBI::connect|DBI/connect>

=item C<table>

I<Required> The name of the table in the database which will contain the records.
It will be created if it does not exist.

=item C<schema>

The schema to which the table belongs.  Optional.

=item C<drop_table>

If true, the table is dropped and a new one is created.

=item C<create_table>

If true, a table will be created if it does not exist.

=item C<primary>

A single output column name or an array of output column names which
should be the primary key(s).  If not specified, no primary keys are
defined.

=item C<db_user>

The name of the database user

=item C<db_pass>

The database password

=item C<batch>

The number of rows to write to the database at once.  This defaults to 100.

If greater than 1, C<batch> rows are cached and then sent out in a
single transaction.  See L</Performance> for more information.

=item C<dbitrace>

A trace setting passed to  L<DBI>.

=back

=head1 ATTRIBUTES

These attributes are available in addition to the standard attributes
defined for L<< Data::Record::Serialize::new|Data::Record::Serialize/new >>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-dbi@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-dbi>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize-encode-dbi

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize-encode-dbi.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
