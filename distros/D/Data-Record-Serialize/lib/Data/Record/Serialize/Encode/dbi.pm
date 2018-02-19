package Data::Record::Serialize::Encode::dbi;

# ABSTRACT:  store a record in a database

use Moo::Role;

our $VERSION = '0.13';

use Data::Record::Serialize::Types -types;

use SQL::Translator;
use SQL::Translator::Schema;
use Types::Standard -types;

use List::Util qw[ pairmap ];

use DBI;
use Carp;

use namespace::clean;

#pod =attr C<dsn>
#pod
#pod I<Required> The DBI Data Source Name (DSN) passed to B<L<DBI>>.  It
#pod may either be a string or an arrayref containing strings or arrayrefs,
#pod which should contain key-value pairs.  Elements in the sub-arrays are
#pod joined with C<=>, elements in the top array are joined with C<:>.  For
#pod example,
#pod
#pod   [ 'SQLite', { dbname => $db } ]
#pod
#pod is transformed to
#pod
#pod   SQLite:dbname=$db
#pod
#pod The standard prefix of C<dbi:> will be added if not present.
#pod
#pod =cut

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

#pod =attr C<table>
#pod
#pod I<Required> The name of the table in the database which will contain the records.
#pod It will be created if it does not exist.
#pod
#pod =cut

has table => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr C<schema>
#pod
#pod The schema to which the table belongs.  Optional.
#pod
#pod =begin pod_coverage
#pod
#pod =head3 has_schema
#pod
#pod =end pod_coverage
#pod
#pod =cut


has schema => (
    is        => 'ro',
    predicate => 1,
    isa       => Str,
);

#pod =attr C<drop_table>
#pod
#pod If true, the table is dropped and a new one is created.
#pod
#pod =cut

has drop_table => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


#pod =attr C<create_table>
#pod
#pod If true, a table will be created if it does not exist.
#pod
#pod =cut

has create_table => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

#pod =attr C<primary>
#pod
#pod A single output column name or an array of output column names which
#pod should be the primary key(s).  If not specified, no primary keys are
#pod defined.
#pod
#pod =cut

has primary => (
    is      => 'ro',
    isa     => ArrayOfStr,
    coerce  => 1,
    default => sub { [] },
);

#pod =attr C<db_user>
#pod
#pod The name of the database user
#pod
#pod =cut

has db_user => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#pod =attr C<db_pass>
#pod
#pod The database password
#pod
#pod =cut

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

#pod =attr C<batch>
#pod
#pod The number of rows to write to the database at once.  This defaults to 100.
#pod
#pod If greater than 1, C<batch> rows are cached and then sent out in a
#pod single transaction.  See L</Performance> for more information.
#pod
#pod =cut

has batch => (
    is      => 'ro',
    isa     => Int,
    default => 100,
    coerce  => sub { $_[0] > 1 ? $_[0] : 0 },
);

#pod =attr C<dbitrace>
#pod
#pod A trace setting passed to  L<B<DBI>>.
#pod
#pod =cut

has dbitrace => ( is => 'ro', );

has _cache => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
);

before BUILD => sub {

    my $self = shift;

    $self->_set__map_types( {
        S => 'text',
        N => 'real',
        I => 'integer'
    } );

    $self->_set__use_integer( 1 );
    $self->_set__need_types( 1 );

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

#pod =begin pod_coverage
#pod
#pod =head3  setup
#pod
#pod =end pod_coverage
#pod
#pod =cut

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
      or croak( "unable to parse DSN: ", $self->dsn );
    my $dbi_driver = $dsn[1];

    my $producer = $producer{$dbi_driver} || $dbi_driver;

    my %attr = (
        AutoCommit => !$self->batch,
        RaiseError => 1,
    );

    $attr{sqlite_allow_multiple_statements} = 1
      if $dbi_driver eq 'SQLite';

    $self->_set__dbh(
        DBI->connect( $self->dsn, $self->db_user, $self->db_pass, \%attr ) )
      or croak( 'error connection to ', $self->dsn, "\n" );

    $self->_dbh->trace( $self->dbitrace )
      if $self->dbitrace;

    if ( $self->drop_table || ( $self->create_table && !$self->_table_exists ) )
    {
        my $tr = SQL::Translator->new(
            from => sub {
                my $schema = $_[0]->schema;
                my $table = $schema->add_table( name => $self->_fq_table_name )
                  or croak $schema->error;

                for my $field_name ( @{ $self->output_fields } ) {

                    $table->add_field(
                        name      => $field_name,
                        data_type => $self->output_types->{$field_name}
                    ) or croak $table->error;
                }

                if ( @{ $self->primary } ) {
                    $table->primary_key( @{ $self->primary } )
                      or croak $table->error;
                }

                1;
            },
            to             => $producer,
            producer_args  => { no_transaction => 1 },
            add_drop_table => $self->drop_table && $self->_table_exists,
        );


        my $sql = $tr->translate
          or croak $tr->error;

        # print STDERR $sql;
        eval { $self->_dbh->do( $sql ); };

        croak( "error in table creation: $@:\n$sql\n" )
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

sub _empty_cache {

    my $self = shift;

    if ( @{ $self->_cache } ) {

        eval {
            $self->_sth->execute( @$_ ) foreach @{ $self->_cache };
            $self->_dbh->commit;
        };

        # don't bother rolling back aborted transactions;
        # individual inserts are independent of each other.
        croak "Transaction aborted: $@" if $@;

        @{ $self->_cache } = ();
    }

    return;
}

#pod =begin pod_coverage
#pod
#pod =head3 send
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub send {

    my $self = shift;

    if ( $self->batch ) {

        push @{ $self->_cache }, [ @{ $_[0] }{ @{ $self->output_fields } } ];

        $self->_empty_cache
          if @{ $self->_cache } == $self->batch;

    }
    else {
        $self->_sth->execute( @{ $_[0] }{ @{ $self->output_fields } } );
    }

}


after '_trigger_output_fields' => sub {
    $_[0]->clear_column_defs;
};

after '_trigger_output_types' => sub {
    $_[0]->clear_column_defs;
};


#pod =begin pod_coverage
#pod
#pod =head3 close
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub close {

    my $self = shift;

    $self->_empty_cache
      if $self->batch;

    $self->_dbh->disconnect
      if defined $self->_dbh;
}

# these are required by the Sink/Encode interfaces but should never be
# called in the ordinary run of things.

#pod =begin pod_coverage
#pod
#pod =head3 say
#pod
#pod =head3 print
#pod
#pod =head3 encode
#pod
#pod =end pod_coverage
#pod
#pod =cut


sub say    { croak }
sub print  { croak }
sub encode { croak }

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';


1;

=pod

=head1 NAME

Data::Record::Serialize::Encode::dbi - store a record in a database

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'sqlite', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::dbi> writes a record to a database using
L<B<DBI>>.

It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
L<B<Data::Record::Serialize::Role::Sink>> roles.

B<You cannot construct this directly; you must use
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.>

=head2 Types

Field types are recognized and converted to SQL types via the following map:

  S => 'text'
  N => 'real'
  I => 'integer'

=head2 Performance

Records are by default written to the database in batches (see the
C<batch> attribute) to improve performance.  Each batch is performed
as a single transaction.  If there is an error during the transaction,
record insertions during the transaction are I<not> rolled back.

=head1 ATTRIBUTES

These attributes are available in addition to the standard attributes
defined for L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

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

A trace setting passed to  L<B<DBI>>.

=begin pod_coverage

=head3 has_schema

=end pod_coverage

=begin pod_coverage

=head3 setup

=end pod_coverage

=begin pod_coverage

=head3 send

=end pod_coverage

=begin pod_coverage

=head3 close

=end pod_coverage

=begin pod_coverage

=head3 say

=head3 print

=head3 encode

=end pod_coverage

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

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

__END__

#pod =head1 SYNOPSIS
#pod
#pod     use Data::Record::Serialize;
#pod
#pod     my $s = Data::Record::Serialize->new( encode => 'sqlite', ... );
#pod
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize::Encode::dbi> writes a record to a database using
#pod L<B<DBI>>.
#pod
#pod It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
#pod L<B<Data::Record::Serialize::Role::Sink>> roles.
#pod
#pod B<You cannot construct this directly; you must use
#pod L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.>
#pod
#pod =head2 Types
#pod
#pod Field types are recognized and converted to SQL types via the following map:
#pod
#pod   S => 'text'
#pod   N => 'real'
#pod   I => 'integer'
#pod
#pod
#pod =head2 Performance
#pod
#pod Records are by default written to the database in batches (see the
#pod C<batch> attribute) to improve performance.  Each batch is performed
#pod as a single transaction.  If there is an error during the transaction,
#pod record insertions during the transaction are I<not> rolled back.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod These attributes are available in addition to the standard attributes
#pod defined for L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
