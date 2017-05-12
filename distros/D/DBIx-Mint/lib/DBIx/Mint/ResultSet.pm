package DBIx::Mint::ResultSet;

use DBIx::Mint;
use DBIx::Mint::ResultSet::Iterator;
use List::MoreUtils qw(uniq);
use Clone qw(clone);
use Moo;

has instance      => ( is => 'ro', default   => sub { '_DEFAULT' });

has table         => ( is => 'rw', required  => 1 );
has target_class  => ( is => 'rw', predicate => 1 );
has columns       => ( is => 'rw', default   => sub {[]});
has where         => ( is => 'rw', default   => sub {[]});
has joins         => ( is => 'rw', default   => sub {[]});

has rows_per_page => ( is => 'rw', default   => sub {10} );
has set_limit     => ( is => 'rw', predicate => 1 );
has set_offset    => ( is => 'rw', predicate => 1 );

has list_group_by => ( is => 'rw', default   => sub {[]});
has list_having   => ( is => 'rw', default   => sub {[]});
has list_order_by => ( is => 'rw', default   => sub {[]});

has iterator      => ( is => 'rw', predicate => 1, handles => ['next'] );

around 'select', 'search', 'group_by', 'having', 'order_by', 'set_target_class', 
    'limit', 'offset', 'set_rows_per_page', 'as_iterator' => sub {
    my $orig = shift;
    my $self = shift;
    my $clone = $self->_clone;
    $clone->$orig(@_);
    return $clone;
};

sub _clone {
    my $self = shift;
    return clone $self;
}


# Query building pieces

sub select {
    my $self = shift;
    push @{ $self->columns }, @_;
}

sub search {
    my $self = shift;
    push @{ $self->where }, @_;
}

sub group_by {
    my $self = shift;
    push @{ $self->list_group_by }, @_;
}

sub having {
    my $self = shift;
    push @{ $self->list_having }, @_;
}

sub order_by {
    my $self = shift;
    push @{ $self->list_order_by }, @_;
}

sub limit {
    my ($self, $value) = @_;
    $self->set_limit($value);
}

sub offset {
    my ($self, $value) = @_;
    $self->set_offset($value);
}

sub page {
    my ($self, $page) = @_;
    $page = defined $page ? $page : 1;
    return $self->limit( $self->rows_per_page )
         ->offset($self->rows_per_page * ( $page - 1 ));
}

sub set_rows_per_page {
    my ($self, $value) = @_;
    $self->rows_per_page($value);
}

# Joins
# Input:
#   table      (array ref):        [name, alias] or name
#   conditions (array of hashes):  [{ left_field => 'right_field' }

sub inner_join {
    my $self = shift;
    return $self->_join('<=>', @_);
}

sub left_join {
    my $self = shift;
    return $self->_join('=>', @_);
}

sub _join {
    my $self   = shift;
    my ($operation, $table, $conditions) = @_;
    my $table_name;
    my $table_alias;
    if (ref $table) {
        ($table_name, $table_alias) = @$table;
    }
    else {
        $table_name  = $table;
        $table_alias = $table;
    }

    my $new_self = $self->_clone;
    my @join_conditions;
    while (my ($field1, $field2) = each %$conditions) {
        if ($field1 !~ /\./) {
            $field1 = "me.$field1";
        }
        if ($field2 !~ /\./) {
            $field2 = "$table_alias.$field2";
        }
        push @join_conditions, "$field1=$field2";
    }
    push @{$new_self->joins}, $operation . join(',', @join_conditions), join('|', $table_name, $table_alias);    
    return $new_self;
}

# Main select method
sub select_sql {
    my $self = shift;
    
    # columns
    my @cols  = @{$self->columns} ? uniq(@{$self->columns}) : ('*');
    
    # joins    
    my @joins = ($self->table.'|'.'me', @{$self->joins});
    
    return DBIx::Mint->instance( $self->instance )->abstract->select(
        -columns    => \@cols,
        -from       => [ -join => @joins ],
        -where      => [ -and  => $self->where ],
        $self->has_set_limit       ? (-limit       => $self->set_limit      ) : (),
        $self->has_set_offset      ? (-offset      => $self->set_offset     ) : (),
        @{$self->list_group_by}    ? (-group_by    => $self->list_group_by  ) : (),
        @{$self->list_having}      ? (-having      => $self->list_having    ) : (),
        @{$self->list_order_by}    ? (-order_by    => $self->list_order_by  ) : (),
    );
}

sub select_sth {
    my $self = shift;
    my ($sql, @bind) = $self->select_sql;
    my $conn = DBIx::Mint->instance( $self->instance )->connector;
    return $conn->run(fixup => sub { $_->prepare($sql) }), @bind;
}

# Fetching data

# Returns an array of inflated objects
sub all {
    my $self = shift;
    my ($sth, @bind) = $self->select_sth;
    $sth->execute(@bind);
    my $all = $sth->fetchall_arrayref({});
    return map { $self->inflate($_) } @$all;
}

# Returns a single, inflated object
sub single {
    my $self = shift;
    my ($sth, @bind) = $self->limit(1)->select_sth;
    $sth->execute(@bind);
    my $single = $sth->fetchrow_hashref;
    $sth->finish;
    return $self->inflate($single);
}

# Returns a number
sub count {
    my $self  = shift;
    my $clone = $self->_clone;
    $clone->columns([]);
    my ($sth, @bind) = $clone->select('COUNT(*)')->select_sth;
    $sth->execute(@bind);
    return $sth->fetchall_arrayref->[0][0];
}

# Creates an iterator and saves it into the ResultSet object
sub as_iterator {
    my $self         = shift;
    my ($sth, @bind) = $self->select_sth;
    $sth->execute(@bind);
    
    my $iterator = DBIx::Mint::ResultSet::Iterator->new(
        closure => sub { return $self->inflate($sth->fetchrow_hashref); },
    );
    
    $self->iterator( $iterator );
}

# Set the class we bless rows into
sub set_target_class {
    my ($self, $target) = @_;
    $self->target_class($target);
}

# Simply blesses the fetched row into the target class
sub inflate {
    my ($self, $row) = @_;
    return undef unless defined $row;
    return $row  unless $self->has_target_class;
    $row->{_name} = $self->instance;
    return bless $row, $self->target_class;
}

1;

=pod

=head1 NAME

DBIx::Mint::ResultSet - DBIx::Mint class to build database queries

=head1 SYNOPSIS

 # Create your ResultSet object:
 my $rs = DBIx::Mint::ResultSet->new( table => 'teams' );
 
 # Now, build your query:
 $rs = $rs->select( 'name', 'slogan', 'logo' )->search({ group => 'A'});
 
 # Join tables
 $rs = DBIx::Mint::ResultSet
          ->new( table => 'teams' )
          ->inner_join('players', { id => 'teams'});
 
 # Fetch data
 $rs->set_target_class( 'Bloodbowl::Team' );
 my @teams   = $rs->all;
 my $team    = $rs->single;
 
 $rs->as_iterator;
 while (my $team = $rs->next) {
     say $team->slogan;
 }
 
=head1 DESCRIPTION

Objects of this class allow you to fetch information from the database. ResultSet objects do not know about the database schema, which means that you can use them without one and that you must use table names directly (but see L<DBIx::Mint::Table> for getting objects from a specific class).

Query creation and join methods return a clone of the original ResultSet object. This makes them chaineable.

Records can be returned as hash references or they can be inflated to the target class you set. You can get a single result, a list of all results, or an iterator.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new

It expects two arguments:

=over

=item table

Used as the table to start building queries. You will join to this table or fetch data from this table. Required.

=item instance

Name of the L<DBIx::Mint> instance to use.

=back

=back

=head2 QUERY CREATION METHODS

=over

=item select

Takes a list of field names to fetch from the given table or join. This method can be called several times to add different fields.

=item search

Builds the 'where' part of the query. It takes a data structure defined per the syntax of L<SQL::Abstract>.

=item order_by, limit, offset, group_by, having

These methods feed the L<SQL::Abstract::More> select method with their respective clause.

=item page, set_rows_per_page

These methods help in pagination of query results. They let you set the number of records per page (C<set_rows_per_page>) and to fetch a given C<page>. The default for C<set_rows_per_page> is 10 records.

They work by setting LIMIT and OFFSET in the SQL query.

=back

=head2 TABLE JOINS

L<DBIx::Mint::ResultSet> offers inner and left joins between tables. The syntax is quite simple:

 $rs->new( table => 'coaches' )->inner_join( 'teams', { id => 'coach' });

The above call would produce a join between the tables 'coaches' and 'teams' using the fields 'id' from coaches and 'coach' from teams.

 $rs->new( table => 'coaches' )
    ->inner_join( ['teams',   't'], { 'me.id'  => 't.coach' })
    ->left_join(  ['players', 'p'], { 't.id'   => 'p.team'  });

You can alias the table names. 'me' always refers to the starting table (coaches in the example above).

Note that the first example does not include table aliases. In this case, the keys of the hash reference are fields of the starting table (coaches) and its values refer to the table that will be joined. If you don't use aliases, joins always refer to the initial table.

=head2 FETCHING DATA

=over

=item select_sql

This method will return a SQL select statement and a list of values to bind, most helpful when debugging:

 my ($sql, @bind) = $rs->select_sql;
 
=item set_taget_class

While not precisely a fetching method, it does define the class to bless fetched records. It is called like this:

 $rs = $rs->set_target_class('Bloodbowl::Coach');

=item single

This method will return a single record from your query. It sets LIMIT to 1 and calls finish on the DBI statement holder. It returns a blessed object if you have set a target class earlier.

=item all

Returns a list with all the records that result from your query. The records will be inflated to the target class if it was set earlier.

=item as_iterator

This will add an iterator to the ResultSet object, over which you must call 'next' to fetch a record:

 $rs->as_iterator;
 while (my $record = $rs->next ) {
     say $record->name;
 }

This is the most efficient way to retrieve records.

=item count

This method will return the number of records matching your query. Internally, it builds a new query with the same search criteria as your original one, and asks for the count of matching records. Use it before adding pagination or other result-limiting constaints:

 $rs = $rs->select( 'name', 'slogan', 'logo' )->search({ group => 'A'});
 my $count = $rs->count;
 my @records = $rs->set_rows_per_page(10)->page(5)->all;

=back

=head1 SEE ALSO

This module is part of L<DBIx::Mint>.
 
=head1 ACKNOWLEDGEMENTS

This module is heavily based on L<DBIx::Lite>, by Alessandro Ranellucci.

=head1 AUTHOR

Julio Fraire, <julio.fraire@gmail.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Julio Fraire. All rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
 
 
