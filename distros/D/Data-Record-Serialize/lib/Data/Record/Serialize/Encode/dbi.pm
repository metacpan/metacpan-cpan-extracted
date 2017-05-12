package Data::Record::Serialize::Encode::dbi;

use Moo::Role;
use List::Util qw[ pairmap ];

use DBI;
use Carp;

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
    required => 1,
);

has drop_table => (
    is      => 'ro',
    default => 0,
);

has create_table => (
    is      => 'ro',
    default => 1,
);

has primary => (
    is      => 'ro',
    default => '',
);

has db_user => ( is => 'ro', default => '' );
has db_pass => ( is => 'ro', default => '' );


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
                ( 'primary key' ) x !!( $self->primary eq $field ) );
        }

        return join ', ', @column_defs;
    },

);

has batch => (
    is      => 'ro',
    default => 100,
    coerce  => sub { $_[0] > 1 ? $_[0] : 0 },
);

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

    # ignore catalogue and schema out of sheer ignorance, and the fact
    # that I'm not alone in that ignorance.

    return
      defined $self->_dbh->table_info( '%', '%', $self->table, 'TABLE' )->fetch;

}

sub setup {

    my $self = shift;

    return if $self->_dbh;

    $self->_set__dbh(
        DBI->connect(
            $self->dsn,
            $self->db_user,
            $self->db_pass,
            {
                AutoCommit => !$self->batch,
                RaiseError => 1,
            } ) ) or die( 'error connection to ', $self->dsn, "\n" );

    $self->_dbh->trace( $self->dbitrace )
      if $self->dbitrace;

    $self->_dbh->do( 'drop table ' . $self->table )
      if $self->drop_table && $self->_table_exists;

    $self->_dbh->commit if $self->batch;

    $self->_dbh->do(
        sprintf( "create table %s ( %s )", $self->table, $self->column_defs ) )
      if $self->drop_table || ( $self->create_table && !$self->_table_exists );

    $self->_dbh->commit if $self->batch;

    my $sql = sprintf(
        "insert into %s (%s) values (%s)",
        $self->table,
        join( ',', @{ $self->output_fields } ),
        join( ',', ( '?' ) x @{ $self->output_fields } ),
    );

    $self->_set__sth( $self->_dbh->prepare( $sql ) );

    return;

}

sub _empty_cache {

    my $self = shift;

    eval {
        $self->_sth->execute( @$_ ) foreach @{ $self->_cache };
        $self->_dbh->commit;
    };

    # don't bother rolling back aborted transactions;
    # individual inserts are independent of each other.
    croak "Transaction aborted: $@" if $@;

    @{ $self->_cache } = ();

    return;
}

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


sub cleanup {

    my $self = shift;

    $self->_empty_cache
      if $self->batch;

    $self->_dbh->disconnect;
}

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';


1;


__END__

=head1 NAME

Data::Record::Serialize::Encode::dbi - store a record in a database


=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'sqlite', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::dbi> writes a record to a database using
L<B<DBI>>.

It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
L<B<Data::Record::Serialize::Role::Sink>> roles.

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

=head1 INTERFACE

You cannot construct this directly; you must use
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

=head2 Attributes

These attributes are available in addition to the standard attributes
defined for L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

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


=item db_user

The name of the database user

=item dbitrace

A trace setting passed to  L<B<DBI>>.

=item batch

The number of rows to write to the database at once.  This defaults to 100.

If greater than 1, C<batch> rows are cached and then sent out in a
single transaction.  See L</Performance> for more information.

=item db_pass

The database password

=item C<table>

I<Required> The name of the table in the database which will contain the records.
It will be created if it does not exist.

=item C<drop_table>

If true, the table is dropped and a new one is created.

=item C<create_table>

If true, a table will be created if it does not exist.

=item C<primary>

The output name of the field which should be the primary key.
If not specified, no primary keys are defined.

=back

=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

=for author to fill in:
    Any other resources (e.g., modules or files) that are related.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 The Smithsonian Astrophysical Observatory

B<Data::Record::Serialize> is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
p
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


