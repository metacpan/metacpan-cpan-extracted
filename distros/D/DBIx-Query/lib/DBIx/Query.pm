package DBIx::Query;
# ABSTRACT: Simplified abstracted chained DBI subclass

use strict;
use warnings;

our $VERSION = '1.06'; # VERSION

use parent 'DBI';
*errstr = \*DBI::errstr;
our $_dq_parser_cache = {};

#-----------------------------------------------------------------------------

{
    package DBIx::Query::_Common;
    use strict;
    use warnings;

    sub _param {
        my $self = shift;
        my $name = shift;

        return unless ($name);
        $self->{'private_dq_stash'}{$name} = shift if (@_);
        return $self->{'private_dq_stash'}{$name};
    }
}

#-----------------------------------------------------------------------------

{
    package DBIx::Query::db;
    use strict;
    use warnings;
    use SQL::Parser;
    use SQL::Abstract::Complete;
    use vars '@ISA';
    @ISA = qw( DBI::db DBIx::Query::_Common );

    sub connected {
        my $self = shift;

        my $connection = {};
        @{$connection}{qw( dsn user pass attr )} = @_;

        $self->_param( 'connection'   => $connection );
        $self->_param( 'sql_abstract' => SQL::Abstract::Complete->new() );

        $self->_param(
            'sql_parser' => SQL::Parser->new(
                'ANSI', { 'RaiseError' => 0, 'PrintError' => 0 }
            )
        );

        return;
    }

    sub connection {
        my $self = shift;

        return
            ( @_ == 0 and wantarray() )     ? @{ $self->_param('connection') }{ qw( dsn user pass attr ) } :
            ( @_ == 0 and not wantarray() ) ? $self->_param('connection')                                  :
            ( @_ > 1 and wantarray() )      ? @{ $self->_param('connection') }{@_}                         :
            ( @_ > 1 and not wantarray() )  ? [ @{ $self->_param('connection') }{@_} ]                     :
            @{ $self->_param('connection') }{@_};
    }

    sub sql {
        my ( $self, $sql, $attr, $cache_type, $variables ) = @_;

        my $sth = $self->sql_fast( $sql, $attr, $cache_type, $variables );

        $sql =~ s/(\r?\n|\s+)/ /g;
        $sql =~ s/^\s+|\s+$//g;

        $DBIx::Query::_dq_parser_cache->{$sql} ||= $self->_param('sql_parser')->structure()
            if ( not $DBIx::Query::_dq_parser_cache->{$sql} and $self->_param('sql_parser')->parse($sql) );

        if ( $DBIx::Query::_dq_parser_cache->{$sql} ) {
            my $structure    = $DBIx::Query::_dq_parser_cache->{$sql};
            my $column_index = 0;
            my %aliases;

            {
                no warnings;
                $structure->{'column_lookup'} = {
                    map {
                        my $index = $column_index++;
                        $aliases{ $_->{'alias'} } = $index if ( $_->{'alias'} );
                        $sth->_param( 'wildcard_column' => 1 ) if ( $_->{'value'} eq '*' );
                        $_->{'value'} => $index;
                    } @{ $structure->{'column_defs'} }
                };
            };

            $structure->{'column_invert_lookup'} = {
                map { $structure->{'column_lookup'}->{$_} => $_ } keys %{ $structure->{'column_lookup'} }
            };
            foreach ( keys %aliases ) {
                $structure->{'column_lookup'}{$_}                    = $aliases{$_};
                $structure->{'column_invert_lookup'}{ $aliases{$_} } = $_;
            }

            $sth->_param( 'structure' => $structure );
        }

        return $sth;
    }

    sub _get_prep {
        my ( $self, $method, $tables, $columns, $where, $meta, $attr, $cache_type ) = @_;
        my ( $sql, @variables ) = $self->_param('sql_abstract')->select( $tables, $columns, $where, $meta );

        return {
            'method'     => $method,
            'tables'     => $tables,
            'columns'    => $columns,
            'where'      => $where,
            'meta'       => $meta,
            'attr'       => $attr,
            'cache_type' => $cache_type,
            'sql'        => $sql,
            'variables'  => \@variables,
        };
    }

    sub get {
        my $self = shift;
        my $query = $self->_get_prep( 'get', @_ );
        my $sth = $self->sql( @{$query}{ qw( sql attr cache_type variables ) } );
        $sth->_param( 'query' => $query );
        return $sth;
    }

    sub sql_cached {
        my ( $self, @params ) = @_;
        push( @params, undef ) while ( @params < 2 );
        return $self->sql( @params, 0 );
    }

    sub get_cached {
        my ( $self, @params ) = @_;
        push( @params, undef ) while ( @params < 5 );
        return $self->get( @params, 0 );
    }

    sub sql_fast {
        my ( $self, $sql, $attr, $cache_type, $variables ) = @_;

        my $sth = ( not defined $cache_type )
            ? $self->SUPER::prepare( $sql, $attr )
            : $self->SUPER::prepare_cached( $sql, $attr, $cache_type );

        $sth->_param( 'sql'       => $sql       );
        $sth->_param( 'dq'        => $self      );
        $sth->_param( 'variables' => $variables );

        return $sth;
    }

    sub get_fast {
        my $self = shift;
        my $query = $self->_get_prep( 'get_fast', @_ );

        my $sth = ( not defined $query->{'cache_type'} )
            ? $self->SUPER::prepare( $query->{'sql'}, $query->{'attr'} )
            : $self->SUPER::prepare_cached( $query->{'sql'}, $query->{'attr'}, $query->{'cache_type'} );

        $sth->_param( 'sql'       => $query->{'sql'}       );
        $sth->_param( 'dq'        => $self                 );
        $sth->_param( 'variables' => $query->{'variables'} );
        $sth->_param( 'query'     => $query                );

        return $sth;
    }

    sub add {
        my ( $self, $table_name, $params, $attr, $cache_type ) = @_;
        my ( $sql, @variables ) = $self->_param('sql_abstract')->insert( $table_name, $params );

        my $sth = $self->sql_fast( $sql, $attr, $cache_type, \@variables );
        $sth->execute( @{ $sth->_param('variables') || [] } );

        my $pk;

        local $@;
        eval {
            $pk = $self->last_insert_id(
                undef,
                undef,
                delete $attr->{'last_insert_table'} || $table_name,
                undef,
                $attr,
            );
        };

        $self->_param( 'table' => $table_name );

        return $pk;
    }

    sub rm {
        my ( $self, $table_name, $params, $attr, $cache_type ) = @_;

        my ( $sql, @variables ) = $self->_param('sql_abstract')->delete( $table_name, $params );
        my $sth = $self->sql( $sql, $attr, $cache_type, \@variables );

        $sth->run();
        return $self;
    }

    sub update {
        my ( $self, $table_name, $params, $where, $attr, $cache_type ) = @_;

        my ( $sql, @variables ) = $self->_param('sql_abstract')->update( $table_name, $params, $where );
        my $sth = $self->sql( $sql, $attr, $cache_type, \@variables );

        $sth->run();
        return $self;
    }

    sub get_run {
        my $self = shift;
        my $sth = $self->get_fast(@_);
        $sth->execute( @{ $sth->_param('variables') || [] } );
        return $sth;
    }

    sub fetch_value {
        my $self = shift;
        my $sth  = $self->get_run(@_);
        return ( $sth->fetchrow_array )[0];
    }

    sub fetchall_arrayref {
        my $self = shift;
        my $sth  = $self->get_run(@_);
        return $sth->fetchall_arrayref;
    }

    sub fetchall_hashref {
        my $self = shift;
        my $sth  = $self->get_run(@_);
        return $sth->fetchall_arrayref({});
    }

    sub fetch_column_arrayref {
        my $self = shift;
        return [ map { $_->[0] } @{ $self->fetchall_arrayref(@_) } ];
    }

    sub fetchrow_hashref {
        my ( $self, $sql, @variables ) = @_;
        my $sth = $self->SUPER::prepare_cached($sql);
        $sth->execute(@variables);
        my $row = $sth->fetchrow_hashref;
        $sth->finish;
        return $row;
    }
}

#-----------------------------------------------------------------------------

{
    package DBIx::Query::st;
    use strict;
    use warnings;
    use vars '@ISA';
    @ISA = qw( DBI::st DBIx::Query::_Common );
    use Carp 'croak';

    sub where {
        my $self = shift;

        croak('Unable to call where() because upstream query not originated with get()')
            unless ( $self->_param('query') );

        croak('where() requires a hashref or an even number of items in a list')
            if ( ref( $_[0] ) ne 'HASH' and @_ % 2 );

        my $query  = $self->_param('query');
        my $method = $query->{'method'};

        $query->{'where'} = { %{ $query->{'where'} || {} }, ( ref( $_[0] ) eq 'HASH' ) ? %{ $_[0] } : @_ };

        return $self->up()->$method( @{$query}{ qw( tables columns where meta attr cache_type ) } );
    }

    sub run {
        my $self = shift;
        $self->execute( (@_) ? @_ : @{ $self->_param('variables') || [] } );
        return DBIx::Query::_Dq::RowSet->new($self);
    }

    sub sql {
        my ( $self, $sql ) = @_;
        return ($sql) ? $self->_param('dq')->sql($sql) : $self->_param('sql');
    }

    sub structure {
        return shift->_param('structure');
    }

    sub table {
        return shift->_param('structure')->{'table_names'}[0];
    }

    sub up {
        return shift->_param('dq');
    }
}

#-----------------------------------------------------------------------------

{
    package DBIx::Query::_Dq::RowSet;
    use strict;
    use warnings;
    use Carp 'croak';

    sub new {
        my ( $self, $sth ) = @_;
        return bless( { 'sth' => $sth }, $self );
    }

    sub next {
        my ( $self, $skip ) = @_;
        $skip ||= 0;

        my $method = ( $self->{'sth'}->_param('wildcard_column') ) ? 'fetchrow_hashref' : 'fetchrow_arrayref';
        $self->{'sth'}->fetchrow_arrayref() while ( $skip-- );

        if ( my $row = $self->{'sth'}->$method() ) {
            return DBIx::Query::_Dq::Row->new( $row, $self );
        }
    }

    sub all {
        return shift->{'sth'}->fetchall_arrayref(@_);
    }

    sub each {
        my ( $self, $code ) = @_;
        my $method = ( $self->{'sth'}->_param('wildcard_column') ) ? 'fetchrow_hashref' : 'fetchrow_arrayref';
        $code->( DBIx::Query::_Dq::Row->new( $_, $self ) ) while ( $_ = $self->{'sth'}->$method() );
        return $self;
    }

    sub value {
        my $self  = shift;
        my @value = $self->{'sth'}->fetchrow_array();
        $self->{'sth'}->finish();

        my $wantarray = wantarray;
        if (not defined $wantarray) {
            croak('value() must not be called in void context');
        }
        elsif ( not wantarray ) {
            if ( @value < 2 ) {
                return $value[0];
            }
            else {
                croak('value() called in scalar context but multiple values fetched');
            }
        }
        else {
            return @value;
        }
    }

    sub up {
        return shift->{'sth'};
    }
}

#-----------------------------------------------------------------------------

{
    package DBIx::Query::_Dq::Row;
    use strict;
    use warnings;
    use Carp 'croak';

    sub new {
        my ( $self, $row, $set ) = @_;
        return bless(
            {
                'row' => $row,
                'set' => $set,
            },
            $self,
        );
    }

    sub cell {
        my ( $self, $index, $new_value ) = @_;
        my ( $name, $structure, $value ) = ( $index, $self->up()->up()->structure(), undef );

        croak('Query used earlier in chain failed to parse, so cell() cannot be called')
            unless ( ref($structure) eq 'HASH' );

        if ( ref( $self->{'row'} ) eq 'ARRAY' ) {
            unless ( $index =~ /^\d+$/ ) {
                $name  = $index;
                $index = $structure->{'column_lookup'}{$index};
            }
            return undef unless ( defined $index and $index < @{ $self->{'row'} } );
            $value = $self->{'row'}[$index];
        }
        else {
            croak('cell() called with integer index but query does not support integer indexing')
                if ( $index =~ /^\d+$/ );

            return undef unless ( exists $self->{'row'}{$index} );
            $value = $self->{'row'}{$index};
        }

        if ( defined $new_value ) {
            if ( ref( $self->{'row'} ) eq 'ARRAY' ) {
                $self->{'row'}[$index] = $new_value;
            }
            else {
                $self->{'row'}{$name} = $new_value;
            }
            $value = $new_value;
        }

        return DBIx::Query::_Dq::Cell->new( $name, $value, $index, $self );
    }

    sub each {
        my ( $self, $code ) = @_;

        croak('each() called on a row object that does not have columns defined')
            if ( ref( $self->{'row'} ) ne 'ARRAY' );

        for ( my $i = 0 ; $i < @{ $self->{'row'} } ; $i++ ) {
            $code->(
                DBIx::Query::_Dq::Cell->new(
                    $self->up()->up()->structure()->{'column_lookup'}{$i},
                    $self->{'row'}[$i],
                    $i, $self,
                )
            );
        }

        return $self;
    }

    sub data {
        my ($self) = @_;

        if ( ref( $self->{'row'} ) eq 'ARRAY' ) {
            my $structure = $self->up()->up()->structure();
            if ( ref($structure) eq 'HASH' and $structure->{'column_invert_lookup'} ) {
                return {
                    map {
                        $structure->{'column_invert_lookup'}->{$_} => $self->{'row'}[$_]
                    } ( 0 .. scalar( @{ $self->{'row'} } ) - 1 )
                };
            }
            else {
                croak('Unable to parse SQL, therefore data() unavailable; use row() instead');
            }
        }
        else {
            return $self->{'row'};
        }
    }

    sub row {
        my ($self) = @_;
        croak('For this particular query, use data() instead')
            unless ( ref( $self->{'row'} ) eq 'ARRAY' );
        return $self->{'row'};
    }

    sub save {
        my ( $self, $key, $params, $cache_type ) = @_;

        croak('save() called without a key or set of keys') unless ($key);

        my $data = $self->data();
        if ( ref($params) eq 'HASH' ) {
            $data->{$_} = $params->{$_} foreach ( keys %{$params} );
        }

        my $dq = $self->up()->up()->up();

        my ( $sql, @variables ) = $dq->_param('sql_abstract')->update(
            $self->up()->up()->table(),
            $data,
            { map { $_ => delete $data->{$_} } ( ref($key) ? @{$key} : $key ) },
        );
        my $sth = $dq->sql( $sql, undef, $cache_type, \@variables );

        $sth->run();
        return $self;
    }

    sub up {
        return shift->{'set'};
    }
}

#-----------------------------------------------------------------------------

{
    package DBIx::Query::_Dq::Cell;
    use strict;
    use warnings;

    sub new {
        my ( $self, $name, $value, $index, $row ) = @_;
        return bless(
            {
                'name'  => $name,
                'value' => $value,
                'index' => $index,
                'row'   => $row,
            },
            $self,
        );
    }

    sub name {
        return shift->{'name'};
    }

    sub value {
        my ( $self, $new_value ) = @_;
        return ( defined $new_value ) ? $self->up()->cell( $self->name(), $new_value ) : $self->{'value'};
    }

    sub index {
        return shift->{'index'};
    }

    sub save {
        return shift->up()->save(@_);
    }

    sub up {
        return shift->{'row'};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Query - Simplified abstracted chained DBI subclass

=head1 VERSION

version 1.06

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/DBIx-Query.svg)](https://travis-ci.org/gryphonshafer/DBIx-Query)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/DBIx-Query/badge.png)](https://coveralls.io/r/gryphonshafer/DBIx-Query)

=for test_synopsis my( $db_name, $db_host, $user, $pwd );

=head1 SYNOPSIS

    use DBIx::Query;

    my $dq = DBIx::Query->connect( "dbi:Pg:dbname=$db_name;host=$db_host", $user, $pwd );

    # get stuff, things, and everything easily
    my $everything = $dq->get('things')->run()->all({});
    my $things     = $dq->get( 'things', ['stuff'], { 'value' => 42 } )->run()->all();
    my $stuff      = $dq->sql('SELECT stuff FROM things WHERE value = ?')->run(42)->all();

    # can use DBI methods at any point
    my $sth = $dq->get('things');
    $sth->execute();
    $stuff = $sth->fetchall_arrayref();

    # get all from data where a is 42 (as an arrayref of hashrefs)
    my $data = $dq->get('data')->where( 'a' => 42 )->run()->all({});

    my $row_set = $dq->sql('SELECT a, b FROM data WHERE x = ?')->run(42);
    my $row_0   = $row_set->next();
    my $a_value = $row_0->cell('a')->value();

    use Data::Dumper 'Dumper';
    $dq->sql('SELECT a, b, c FROM data')->run()->each( sub {
        my ($row) = @_;
        print Dumper( $row->data() ), "\n";
    } );

    my $row = $dq->sql('SELECT id, name FROM data')->run()->next();

    $row->cell( 'name', 'New Value' )->up()->save('id');
    $row->save( 'id', { 'name' => 'New Value' } );
    $row->save( 'id', { 'name' => 'New Value' }, 0 );

    $dq->add( 'user', { 'id' => 'thx1138' } );
    $dq->update( 'user', { 'id' => 'thx1138' }, { 'id' => 'lv427' }, 0 );
    $dq->rm( 'user', { 'id' => 'thx1138' } );

=head1 DESCRIPTION

This module provides a simplified abstracted chained DBI subclass. It's sort of
like jQuery for L<DBI>, or sort of like DBIx::Class only without objects, or sort
of like cookies without a glass of milk. With DBIx::Query, you can construct
queries either with SQL or abstract Perl data structures described by
L<SQL::Abstract::Complete>.

    my $stuff  = $dq->sql('SELECT stuff FROM things WHERE value = ?')->run(42)->all();
    my $things = $dq->get( 'things', ['stuff'], { 'value' = 42 } )->run()->all();

The overall point being that you can chain various parts of the query prepare,
execute, and data retrieval process to dramatically reduce repeated code in
most programs.

    my $c_value    = $dq->sql('SELECT a FROM b WHERE c = ?')->run($c)->value();
    my $everything = $dq->get('things')->run()->all({});

DBIx::Query is a pure subclass of DBI, so it can be used exactly like DBI. At
any point, you can drop out of DBIx::Query-specific methods and use DBI methods.

    my $sth = $dq->get('things');
    $sth->execute();
    my $stuff = $sth->fetchall_arrayref();

Like L<DBI>, there are multiple sub-classes each with a set of methods related
to its level. In L<DBI>, there is: DBI (the parent class), db (the object
created from a connect call), and st (the statement handle). DBIx::Query adds
the following additional: rowset, row, and cell.

=head1 PARENT CLASS METHODS

The following methods exists at the "parent class" level.

=head2 connect()

This method is inherritted from L<DBI>. I only mention it here to point out
that since DBIx::Query is a true subclass of L<DBI>, typically the only thing
you have to do to switch from L<DBI> to DBIx::Query is to change the
C<connect()> method's package name.

    my $dq = DBIx::Query->connect(
        "dbi:Pg:dbname=$db_name;host=$db_host", $username, $password,
        { 'RaiseError' => 1 },
    );

The object returned is a database object and so will support both L<DBI> and
DBIx::Query methods associated with database objects.

=head2 errstr()

This method is inherritted from L<DBI>.

=head1 DATABASE CLASS PRIMARY METHODS

The following methods are "primary" methods of the database class, the object
returned from a C<connect()> call. "Primary" in this case means common use
methods you'll probably want to know about.

=head2 connection()

Once you have established a connection, you can retrieve information about that
connection using this method. It expects either no input or a list of strings
that consist of: dsn, user, pass, attr. If a string is provided, the value is
returned.

    my $dsn = $dq->connection('dsn');

If multiple strings are provided, values for those are returned either as an
arrayref or array depending on context.

    my $arrayref = $dq->connection( qw( dsn user ) );
    my @array    = $dq->connection( qw( dsn user ) );

If no values are provided, this method returns a hashref or an array of values
depending on the context.

    my $hashref  = $dq->connection();
    my @array    = $dq->connection();

=head2 sql()

This method accepts SQL and optional attributes, cache type definition, and
variables and returns a DBIx::Query statement handle.

    my $sth = $db->sql('SELECT alpha, beta, COUNT(*) FROM things WHERE delta > ?');

If the cache type definition is C<undef>, then DBIx::Query calls L<DBI>'s
C<prepare()>, else it calls C<prepare_cached()> and uses the cache type as the
C<$if_active>. (See the L<DBI> documentation.)

The attributes value is passed through to the C<prepare()> or
C<prepare_cached()> call. The values (if any are provided) are stored in the
statement handle and used as default values if none are provided later during
C<run()>.

    my $sth = $db->sql(
        'SELECT alpha, beta, COUNT(*) FROM things WHERE delta > ?',
        { 'Columns' => [ 1, 2 ] },
        1,
        10,
    )->run();

=head2 get()

The second way to build a statement handle is through the use of C<get()>,
which expects some number of input parameters that are fed into
L<SQL::Abstract::Complete> to generate SQL.

    my $sth = $dq->get(
        $table || \@tables, # a table or set of tables and optional aliases
        \@columns,          # fields and optional aliases to fetch
        \%where,            # where clause
        \%other,            # order by, group by, having, and pagination
        \%attr,             # attributes
        $cache_type,        # cache type
    );

The first 4 inputs are passed directly to L<SQL::Abstract::Complete>, so
consult that documentation for details. The last 2 inputs are the same as what
is used for C<sql()>. If the cache type definition is C<undef>, then
DBIx::Query calls L<DBI>'s C<prepare()>, else it calls C<prepare_cached()> and
uses the cache type as the C<$if_active>. (See the L<DBI> documentation.)

=head2 sql_cached() and get_cached()

These are simple wrapper methods around C<sql()> and C<get()> that explicitly
set caching on and cache type set to 0. This is the normal behavior if you're
calling L<DBI>'s C<prepare_cached()>.

=head2 add()

Inserts a row into the database and returns the primary key for that row if
available.

    my $pk0 = $dq->add( $table_name, $params, $attr, $cache_type );
    my $pk1 = $dq->add( 'user', { 'id' => 'thx1138' } );

The C<$params> value is either an arrayref or hashref of fields and values for
the insert. The C<$attr> value is any attribute set that would get passed to
L<DBI>'s C<last_insert_id()> to obtain the primary key. If the cache type
definition is C<undef>, then DBIx::Query calls L<DBI>'s C<prepare()>, else it
calls C<prepare_cached()> and uses the cache type as the C<$if_active>.
(See the L<DBI> documentation.)

=head2 rm()

Deletes a row from the database and returns the object from which the method
was called.

    my $dq0 = $dq->rm( $table_name, $params, $attr, $cache_type );
    my $dq1 = $dq->rm( 'user', { 'id' => 'thx1138' } );

The C<$params> value is a hashref of fields and values for the delete. If the
cache type definition is C<undef>, then DBIx::Query calls L<DBI>'s C<prepare()>,
else it calls C<prepare_cached()> and uses the cache type as the C<$if_active>.
(See the L<DBI> documentation.)

=head2 update()

Updates a row in the database and returns the object from which the method
was called.

    my $dq0 = $dq->update( $table_name, $params, $where, $attr, $cache_type );
    my $dq1 = $dq->update(
        'user',
        { 'id' => 'thx1138' },
        { 'id' => 'lv427' },
        0,
    );

The C<$params> value is a hashref of fields and values for the update. The
C<$where> value is a hashref of fields and values to be used as a where clause
for the update. If the cache type definition is C<undef>, then DBIx::Query calls
L<DBI>'s C<prepare()>, else it calls C<prepare_cached()> and uses the cache type
as the C<$if_active>. (See the L<DBI> documentation.)

=head1 DATABASE CLASS HELPER METHODS

The following methods are "helper" methods of the database class, the object
returned from a C<connect()> call.

=head2 sql_fast() and get_fast()

Returns a statement handle given a set of inputs pretty much exactly as
C<sql()> and C<get()> would, except it do so without parsing the input or
generated SQL. The result being that C<get_fast()> runs faster than C<get()>
by a fair margin, but any method requiring SQL structure data (like
C<structure()>) won't work.

=head2 get_run()

Takes the same parameters as C<get>. It internally calls C<get_fast()> followed
by C<execute()>, then returns the executed statement handle.

=head2 fetch_value()

Takes the same parameters as C<get>. It internally calls C<get_run()> and
returns the first row, first column value.

=head2 fetchall_arrayref()

Takes the same parameters as C<get>. It internally calls C<get_run()> followed
by C<execute()>, then returns the results of a C<fetchall_arrayref()> on the
executed statement handle.

=head2 fetchall_hashref()

Basically the same thing as C<fetchall_arrayref()> called on the database class
except it returns an array of hashrefs. (It just calls C<fetchall_arrayref({})>
on the statement handle.)

=head2 fetch_column_arrayref()

Takes the same parameters as C<get>. It internally calls C<fetchall_arrayref()>
against the database class and returns the first column's values as an arrayref.

=head2 fetchrow_hashref()

Accepts some SQL and optional variables (as a list). It internally calls
C<prepare_cached>, C<execute()> with the variables passed in, and then returns
the first C<fetchrow_hashref()> result (C<fetchrow_hashref()> being called
against the executed statement handle).

=head1 STATEMENT HANDLE METHODS

The following methods are available from statement handle objects. These along
with inherritted L<DBI> statement handle methods are available from statement
handle objects returned from a variety of L<DBIx::Query> methods.

=head2 where()

If and only if you use C<get()> or C<get_fast()> to construct your statement
handle, you can optionally use C<where()> to add or alter the where clause.

    # data where a = 42
    $dq->get('data')->where( 'a' => 42 )->run()->all({});

    # data where a = 13 (original where is altered)
    $dq->get( 'data', undef, { 'a' => 42 } )->where( 'a' => 13 )->run()->all({});

    # data where a = 42 and b = 13 (original where is appended to)
    $dq->get( 'data', undef, { 'a' => 42 } )->where( 'b' => 13 )->run()->all({});

=head2 run()

Executes the statement handle. It will execute the handle with whatever
parameters are passed in as variables. If no variables are provided, it will
execute the handle based on variables previously provided. Otherwise, it'll
execute the handle without input. Then C<run()> will return a "row set" back.
(See below for more details on row sets.)

    my $row_set_0 = $dq->sql('SELECT a, b FROM data WHERE x = 42')->run();
    my $row_set_1 = $dq->sql('SELECT a, b FROM data WHERE x = ?')->run(42);
    my $row_set_2 = $dq->sql('SELECT a, b FROM data WHERE x = ?', undef, undef, [42] )->run();
    my $row_set_3 = $dq->get( 'data', [ 'a', 'b' ], { 'x' => 42 } )->run();

=head2 sql()

Returns a string consisting of the SQL the statement handle has.

=head2 structure()

Returns a data structure consisting of the parsed SQL the statement handle has,
if that structure is available. This is fulfilled using L<SQL::Parser>. Parsing
SQL is not particularly fast, so if you used something like C<sql_fast()>
instead of C<sql()>, then C<structure()> will return undef. (See C<SQL::Parser>
for details of the returned data.)

=head2 table()

Returns the primary table of the SQL for the statement handle. This is just a
short-cut to:

    $sth->structure()->{'table_names'}[0]

=head2 up()

When called against a statement handle, returns the database object.

=head1 ROW SET OBJECT METHODS

Row sets are returned from C<run()> called on a statement handle. The represent
a group or set of rows the database has or will return.

=head2 next()

If you consider that a row set is a container for some number of rows, this
method returns the next row of the set.

    my $row = $db->sql($sql)->run()->next();

You can pass an integer into C<next()> to tell it to skip a certain number of
rows and return to you the next after that skip.

=head2 all()

A simple dumper of data for the given row set. This operates like L<DBI>'s
C<fetchall_arrayref()> on an executed statement handle.

    my $arrayref_of_arrayrefs = $db->sql($sql)->run()->all();
    my $arrayref_of_hashrefs = $db->sql($sql)->run()->all({});

=head2 each()

This is a row iterator that lets you run a block of code against each row in a
row set. After running the code block against each row, the method returns a
reference to the object from which the method was called. The code block will
get passed to it a row object. (See below.)

    use Data::Dumper 'Dumper';
    my $dq0 = $dq->sql('SELECT a, b, c FROM data')->run()->each( sub {
        my ($row) = @_;
        print Dumper( $row->data() ), "\n";
    } );

=head2 value()

This method returns the value (or values) of the first row of a returned data
set. The assumption is that the query is expecting only a single returned row
of data.

    my $value  = $dq->sql('SELECT a FROM data LIMIT 1')->run()->value();
    my @values = $dq->sql('SELECT a, b FROM data LIMIT 1')->run()->value();

If in scalar context, the method assumes there is only a column returned and
returns that value only. If there are multiple columns but the method is called
in scalar context, the method throws an error. (If there are multiple rows
found, only the first row's data will be returned, and no error will be thrown.)

=head2 up()

When called against a row set object, returns the statement handle.

=head1 ROW OBJECT METHODS

Row objects are returned from row set methods like C<next()>. They represent
a single row of returned database data.

=head2 cell()

Returns a cell object of the cell requested by index. The index can be
the name of the column (which is usually but not always available) or the
integer index (which is available if columns are specified in the query).

    print $dq->sql('SELECT * FROM data WHERE a = ?')->run(42)->next()->cell('b')->value(), "\n";
    print $dq->get('data')->run()->next()->cell('b')->value(), "\n";

    # returns column "b" value
    print $dq->sql('SELECT a, b FROM data WHERE a = ?')->run(42)->next()->cell(1)->value(), "\n";

If columns are not specified in the query and an integer index is used, an
error will be thrown.

    # don't do this...
    eval { $dq->sql('SELECT * FROM data WHERE a = ?')->run(42)->next()->cell(1)->value() };

Optionally, this method will set the value of the cell (in memory only, not in
the database yet) based on an index and new value.

    print $dq->get('data')->run()->next()->cell( 'b', 'New Value' )->value(), "\n";

=head2 each()

Similar to C<each()> from the row set object, C<each()> on a row object will
execute a subroutine on each cell of the row. The subroutine reference is passed
a cell object.

    $dq->sql('SELECT a, b, c FROM data')->run()->next()->each( sub {
        my ($cell) = @_;
        print $cell->value(), "\n";
    } );

This method will only work if the query in question has some form of columns
defined, either through C<sql()> or C<get()> with a column reference. Otherwise,
it will throw an error.

=head2 data()

Returns the data of the row as a hashref.

    my $hashref = $dq->get('data')->run()->next()->data();

In some situations with very complex SQL, the SQL parser will fail. In those
cases, C<data()> cannot be used. Instead, use C<row()>.

=head2 row()

Returns the data of the row as an arrayref.

    my $arrayref = $dq->get('data')->run()->next()->data();

=head2 save()

Saves back to the database the row. It requires a scalar or arrayref "key"
representing the primary key or keys (or enough data that a where clause will
know how to find the record in the database).

You can change data for the row using C<cell()> before the C<save()> call or
within the C<save()> call by passing in a second parameter, a hashref of
parameters.

Once the update is complete, the method will return a fresh row object pulled
from the database using the where clause generated based on the key or keys.
The third argument is an optional cache type for the inner SQL execution call.

    my $row = $dq->sql('SELECT id, name FROM data')->run()->next();

    $row->cell( 'name', 'New Value' )->up()->save('id');
    $row->save( 'id', { 'name' => 'New Value' } );
    $row->save( 'id', { 'name' => 'New Value' }, 0 );

=head2 up()

When called against a row object, returns the row set handle.

=head1 CELL OBJECT METHODS

Cell objects are returned by calling C<cell()> on a row. They represent a
single cell of returned database data.

=head2 name()

Returns the name of the cell.

    my $cell = $dq->sql('SELECT id, name FROM data')->run()->next()->cell('id');
    $cell->name(); # returns "id"

=head2 value()

Returns the value of the cell.

    my $cell = $dq->sql('SELECT id, name FROM data')->run()->next()->cell('name');
    $cell->value();

=head2 index()

Returns the index of the cell.

=head2 save()

Saves any changes to the row the cell is part of by calling C<save()> on that
row. For example, the last two lines here are identical:

    my $row = $dq->sql('SELECT id, name FROM data')->run()->next();

    $row->cell( 'name' => 'New Value' )->up()->save('id');
    $row->cell( 'name' => 'New Value' )->save('id');

=head2 up()

When called against a cell object, returns the row object to which it belongs.

=head1 SEE ALSO

L<SQL::Abstract::Complete>, L<DBI>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/DBIx-Query>

=item *

L<CPAN|http://search.cpan.org/dist/DBIx-Query>

=item *

L<MetaCPAN|https://metacpan.org/pod/DBIx::Query>

=item *

L<AnnoCPAN|http://annocpan.org/dist/DBIx-Query>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/DBIx-Query>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/DBIx-Query>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
