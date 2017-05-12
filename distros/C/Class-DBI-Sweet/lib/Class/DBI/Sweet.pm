package Class::DBI::Sweet;

use strict;
use base 'Class::DBI';
use Class::DBI::Iterator;    # For the resultset cache

use Data::Page;
use DBI;
use List::Util;
use Carp qw/croak/;

BEGIN {                      # Use Time::HiRes' time() if possible
    eval "use Time::HiRes";
    unless ($@) {
        import Time::HiRes qw/time/;
    }
}

if ( $^O eq 'MSWin32' ) {
    eval "require Win32API::GUID;";
}
else {
    eval "require Data::UUID;";
}

our $UUID_Is_Available = ( $@ ? 0 : 1 );

our $VERSION = '0.11';

#----------------------------------------------------------------------
# RETRIEVING
#----------------------------------------------------------------------

__PACKAGE__->data_type(
    __ROWS   => DBI::SQL_INTEGER,
    __OFFSET => DBI::SQL_INTEGER
);

__PACKAGE__->set_sql( Join_Retrieve_Count => <<'SQL' );
SELECT COUNT(*)
FROM   %s
WHERE  %s
SQL

__PACKAGE__->set_sql( Join_Retrieve => <<'SQL' );
SELECT __ESSENTIAL(me)__%s
FROM   %s
WHERE  %s
SQL

__PACKAGE__->mk_classdata( default_search_attributes => {} );
__PACKAGE__->mk_classdata( profiling_data            => {} );
__PACKAGE__->mk_classdata( _live_resultset_cache     => {} );

sub retrieve_next {
    my $self  = shift;
    my $class = ref $self
      || croak("retrieve_next cannot be called as a class method");

    my ( $criteria, $attributes ) = $class->_search_args(@_);
    $attributes = { %{$attributes} };    # Local copy to fiddle with

    my $o_by = $attributes->{order_by} || ( $self->columns('Primary') )[0];
    my $is_desc = $o_by =~ s/ +DESC//;    # If it's previous we'll add it back

    my $o_val = (
        $o_by =~ m/(.*)\.(.*)/
        ? $self->$1->$2
        : $self->$o_by
    );

    $criteria->{$o_by} = { ( $is_desc ? '<' : '>' ) => $o_val };

    $attributes->{rows} ||= 1;

    return wantarray()
      ? @{ [ $class->_do_search( $criteria, $attributes ) ] }
      : $class->_do_search( $criteria, $attributes );
}

sub retrieve_previous {
    my $self  = shift;
    my $class = ref $self
      || croak("retrieve_previous cannot be called as a class method");

    my ( $criteria, $attributes ) = $class->_search_args(@_);
    $attributes = { %{$attributes} };    # Local copy to fiddle with

    my $o_by = $attributes->{order_by} || ( $self->columns('Primary') )[0];
    my $is_desc = $o_by =~ s/ +DESC//;    # If it's previous we'll add it back

    my $o_val = (
        $o_by =~ m/(.*)\.(.*)/
        ? $self->$1->$2
        : $self->$o_by
    );

    $criteria->{$o_by} = { ( $is_desc ? '>' : '<' ) => $o_val };

    $attributes->{order_by} = ${o_by} . ( $is_desc ? "" : " DESC" );
    $attributes->{rows} ||= 1;

    return wantarray()
      ? @{ [ $class->_do_search( $criteria, $attributes ) ] }
      : $class->_do_search( $criteria, $attributes );
}

sub count {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    unless (@_) {
        return $class->count_all;
    }

    my ( $criteria, $attributes ) = $class->_search_args(@_);

    # make sure we take copy of $attribues since it can be reused
    my $count = { %{$attributes} };

    # no need for LIMIT/OFFSET and ORDER BY in COUNT(*)
    delete @{$count}{qw( rows offset order_by )};

    my ( $sql_parts, $classes, $columns, $values ) =
      $proto->_search( $criteria, $count );

    my $sql_method = 'sql_' . ( $attributes->{sql_method} || 'Join_Retrieve' );
    $sql_method .= '_Count';

    my $sth = $class->$sql_method( @{$sql_parts}{qw/ from where /} );

    $class->_bind_param( $sth, $columns );

    return $sth->select_val(@$values);
}

*pager = \&page;

sub page {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ( $criteria, $attributes ) = $proto->_search_args(@_);

    $attributes->{rows} ||= 10;
    $attributes->{page} ||= 1;
    $attributes->{_pager} = '';    # Flag that we need a pager.  How ugly!

    # No point doing a count(*) if fetching all anyway
    unless ( $attributes->{disable_sql_paging} ) {

        my $page = Data::Page->new( $class->count( $criteria, $attributes ),
            $attributes->{rows}, $attributes->{page}, );

        $attributes->{offset} = $page->skipped;
        $attributes->{_pager} = $page;

    }

    my $iterator = $class->search( $criteria, $attributes );

    return ( $attributes->{_pager}, $iterator );
}

sub retrieve_all {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    unless ( @_ || keys %{ $class->default_search_attributes } ) {
        return $class->SUPER::retrieve_all;
    }

    return $class->search( {}, ( @_ > 1 ) ? {@_} : ( shift || () ) );
}

sub search {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ( $criteria, $attributes ) = $class->_search_args(@_);

    $class->_do_search( $criteria, $attributes );
}

sub search_like {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ( $criteria, $attributes ) = $class->_search_args(@_);

    $attributes->{cmp} = 'like';

    $class->_do_search( $criteria, $attributes );
}

sub _do_search {
    my ( $class, $criteria, $attributes ) = @_;

    foreach my $pre ( @{ $attributes->{prefetch} || [] } ) {
        unless ( $class->meta_info( has_a => $pre )
            or $class->meta_info( might_have => $pre ) )
        {
            croak "$pre is not a has_a or might_have rel on $class";
        }
    }

    my ( $sql_parts, $classes, $columns, $values ) =
      $class->_search( $criteria, $attributes );

    my $cache_key;

    if ( $class->cache && $attributes->{use_resultset_cache} ) {

        my $sql = join '', @{$sql_parts}{qw/ where from order_by limit /};

        $cache_key =
          $class->_resultset_cache_key( $sql, $values,
            $attributes->{prefetch} );
        my $cache_entry;

        my ($latest_stale) = sort { $b <=> $a }
          grep defined, map { $class->cache->get($_) }
          grep defined, map { $_->_staleness_cache_key } values %{$classes};

        if ($cache_key) {

            if ( $cache_entry = $class->_live_resultset_cache->{$cache_key} ) {

                if ( $cache_entry->{created} <= ( $latest_stale || 0 ) ) {

                    delete $class->_live_resultset_cache->{$cache_key};
                    undef $cache_entry;
                }
                else {

                    # So reset doesn't screw the original copy
                    # (which might still be in scope and in use)

                    $cache_entry =

                      {
                        %$cache_entry,
                        iterator => bless(
                            { %{ $cache_entry->{iterator} } },
                            ref $cache_entry->{iterator}
                        )
                      };

                    $cache_entry->{iterator}->reset;
                }
            }

            if ( !( defined $cache_entry )
                and $cache_entry = $class->cache->get($cache_key) )
            {

                if ( $cache_entry->{created} <= ( $latest_stale || 0 ) ) {

                    $class->cache->remove($cache_key);
                    undef $cache_entry;
                }
                else {

                    $class->_live_resultset_cache->{$cache_key} = $cache_entry;
                }

            }
        }

        if ($cache_entry) {

            push (
                @{ $class->profiling_data->{resultset_cache} },
                [ 'HIT', $cache_key ]
              )
              if $attributes->{profile_cache};
            my $iterator =
              $class->_slice_iter( $attributes, $cache_entry->{iterator} );
            return map $class->construct($_), $iterator->data if wantarray;
            return $iterator;
        }
        push (
            @{ $class->profiling_data->{resultset_cache} },
            [ 'MISS', $cache_key ]
          )
          if $attributes->{profile_cache};
    }

    my $pre_fields = '';    # Used in SELECT
    my $pre_names  = '';    # for use in GROUP BY

    if ( $attributes->{prefetch} ) {
        $pre_fields .= ", '"
          . join ( ' ', @{ $attributes->{prefetch} } )
          . "' AS sweet__joins";

        my $jnum = 0;
        foreach my $pre ( @{ $attributes->{prefetch} } ) {
            $jnum++;
            my $f_class = $classes->{$pre};
            foreach my $col ( $f_class->columns('Essential') ) {
                $pre_names .= ", ${pre}.${col}";
                $pre_fields .= ", ${pre}.${col} AS sweet__${jnum}_${col}";
            }
        }
    }

    $sql_parts->{prefetch_cols}  = $pre_fields;
    $sql_parts->{prefetch_names} = $pre_names;

    my $sql_method = 'sql_' . ( $attributes->{sql_method} || 'Join_Retrieve' );

    my $statement_order = $attributes->{statement_order}
      || [qw/ prefetch_cols from sql /];

    my @sql_parts;
    for my $part (@$statement_order) {

        # For backward compatibility
        if ( $part eq 'sql' ) {
            push @sql_parts, join ' ',
              @{$sql_parts}{qw/ where order_by limit/};
            next;
        }
        if ( exists $sql_parts->{$part} ) {
            push @sql_parts, $sql_parts->{$part};
            next;
        }
        die "'statement_order' setting of [$part] is invalid";
    }

    my $sth = $class->$sql_method(@sql_parts);

    $class->_bind_param( $sth, $columns );

    my $iterator = $class->sth_to_objects( $sth, $values );

    if ( $class->cache && $attributes->{use_resultset_cache} ) {

        my $cache_entry = {
            created  => time(),
            iterator => bless( { %{$iterator} }, ref $iterator )
        };

        $class->cache->set( $cache_key, $cache_entry );
        $class->_live_resultset_cache->{$cache_key} = $cache_entry;
    }

    $iterator = $class->_slice_iter( $attributes, $iterator );

    return map $class->construct($_), $iterator->data if wantarray;
    return $iterator;
}

sub _slice_iter {
    my ( $class, $attributes, $iterator ) = @_;

    # Create pager if doesn't already exist
    if ( exists $attributes->{_pager} && !$attributes->{_pager} ) {

        $attributes->{_pager} =
          Data::Page->new( $iterator->count, $attributes->{rows},
            $attributes->{page}, );

        $attributes->{offset} = $attributes->{_pager}->skipped;
    }

    # If RDBM is not ROWS/OFFSET supported, slice iterator
    if ( $attributes->{rows} && $iterator->count > $attributes->{rows} ) {

        my $rows   = $attributes->{rows};
        my $offset = $attributes->{offset} || 0;

        $iterator = $iterator->slice( $offset, $offset + $rows - 1 );
    }

    return $iterator;
}

sub _search {
    my $proto      = shift;
    my $criteria   = shift;
    my $attributes = shift;
    my $class      = ref($proto) || $proto;

    # Valid SQL::Abstract params
    my %params = map { $_ => $attributes->{$_} } qw(case cmp convert logic);

    $params{cdbi_class}    = $class;
    $params{cdbi_me_alias} = 'me';

    # Overide bindtype, we need all columns and values for deflating
    my $abstract =
      Class::DBI::Sweet::SQL::Abstract->new( %params, bindtype => 'columns' );

    my ( $sql, $from, $classes, @bind ) =
      $abstract->where( $criteria, '', $attributes->{prefetch} );

    my ( @columns, @values, %cache );

    foreach my $bind (@bind) {
        push ( @columns, $bind->[0] );
        push ( @values,  @{$bind}[ 1 .. $#$bind ] );
    }

    unless ( $sql =~ /^\s*WHERE/i )
    {    # huh? This is either WHERE.. or empty string.
        $sql = "WHERE 1=1 $sql";
    }

    $sql =~ s/^\s*(WHERE)\s*//i;

    my %sql_parts = (
        where    => $sql,
        from     => $from,
        limit    => '',
        order_by => '',
    );

    $sql_parts{order_by} = $abstract->_order_by( $attributes->{order_by} )
      if $attributes->{order_by};

    if ( $attributes->{rows} && !$attributes->{disable_sql_paging} ) {

        my $rows   = $attributes->{rows};
        my $offset = $attributes->{offset} || 0;
        my $driver = lc $class->db_Main->{Driver}->{Name};

        if ( $driver =~ /^(maxdb|mysql|mysqlpp)$/ ) {
            $sql_parts{limit} = ' LIMIT ?, ?';
            push ( @columns, '__OFFSET', '__ROWS' );
            push ( @values, $offset, $rows );
        }

        elsif ( $driver =~ /^(pg|pgpp|sqlite|sqlite2)$/ ) {
            $sql_parts{limit} = ' LIMIT ? OFFSET ?';
            push ( @columns, '__ROWS', '__OFFSET' );
            push ( @values, $rows, $offset );
        }

        elsif ( $driver =~ /^(interbase)$/ ) {
            $sql_parts{limit} = ' ROWS ? TO ?';
            push ( @columns, '__ROWS', '__OFFSET' );
            push ( @values, $rows, $offset + $rows );
        }
    }

    return ( \%sql_parts, $classes, \@columns, \@values );
}

sub _search_args {
    my $proto = shift;

    my ( $criteria, $attributes );

    if (   @_ == 2
        && ref( $_[0] ) =~ /^(ARRAY|HASH)$/
        && ref( $_[1] ) eq 'HASH' )
    {
        $criteria   = $_[0];
        $attributes = $_[1];
    }
    elsif ( @_ == 1 && ref( $_[0] ) =~ /^(ARRAY|HASH)$/ ) {
        $criteria   = $_[0];
        $attributes = {};
    }
    else {
        $attributes = @_ % 2 ? pop (@_) : {};
        $criteria = {@_};
    }

    # Need to pass things in $attributes, so don't create a new hash
    for my $key ( keys %{ $proto->default_search_attributes } ) {
        $attributes->{$key} ||= $proto->default_search_attributes->{$key};
    }

    return ( $criteria, $attributes );
}

#----------------------------------------------------------------------
# CACHING
#----------------------------------------------------------------------

__PACKAGE__->mk_classdata('cache');

sub cache_key {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $data;

    my @primary_columns = $class->primary_columns;

    if (@_) {
        if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
            $data = $_[0];
        }
        elsif ( @_ == 1 ) {
            $data = { $primary_columns[0] => $_[0] };
        }
        else {
            $data = {@_};
        }
    }
    else {
        @{$data}{@primary_columns} = $proto->get(@primary_columns);
    }

    unless ( @primary_columns == grep defined, @{$data}{@primary_columns} ) {
        return;
    }

    return join "|", $class, map $_ . '=' . $data->{$_}, sort @primary_columns;
}

sub _resultset_cache_key {
    my ( $class, $sql, $values, $prefetch ) = @_;

    $class = ref $class if ref $class;

    my @pre = map { "=${_}"; } @{ $prefetch || [] };

    my $it = $class->iterator_class;

    return join "|", $class, "=${sql}", "=${it}", @pre, @{ $values || [] };
}

sub _staleness_cache_key {
    my ($class) = @_;

    $class = ref $class if ref $class;

    return "${class}|+staleness_key";
}

sub _init {
    my $class = shift;

    my $data = $_[0] || {};

    unless ( $class->cache || $data->{'sweet__joins'} ) {
        return $class->SUPER::_init(@_);
    }

    my $key = $class->cache_key($data);

    my $object;

    if ( $class->cache and $key and $object = $class->cache->get($key) ) {
        push ( @{ $class->profiling_data->{object_cache} }, [ 'HIT', $key ] )
          if ( $class->default_search_attributes->{profile_cache} );

        # ensure that objects from the cache get inflated properly
        if ( ( caller(1) )[3] eq "Class::DBI::_simple_bless" ) {
            $object->call_trigger('select');
        }

        return $object;
    }

    push ( @{ $class->profiling_data->{object_cache} }, [ 'MISS', $key ] )
      if ( $class->default_search_attributes->{profile_cache} );

    $object = bless {}, $class;

    if ( my $joins = $data->{'sweet__joins'} ) {
        my $meta = $class->meta_info;
        my $jnum = 0;
        foreach my $join ( split ( / /, $joins ) ) {
            my ( $rel, $f_class );
            $jnum++;
            if ( $rel = $meta->{has_a}{$join} ) {
                $f_class = $rel->foreign_class;
                my %attrs =
                  map { ( $_ => $data->{"sweet__${jnum}_${_}"} ) }
                  $f_class->columns('Essential');
                $data->{$join} = $f_class->construct( \%attrs );
            }
            elsif ( $rel = $meta->{might_have}{$join} ) {
                $f_class = $rel->foreign_class;
                my %attrs =
                  map { ( $_ => $data->{"sweet__${jnum}_${_}"} ) }
                  $f_class->columns('Essential');
                $object->{"_${join}_object"} = $f_class->construct( \%attrs );
            }
            else {
                croak("Unable to find relationship ${join} on ${class}");
            }
        }
    }

    $object->_attribute_store(%$data);

    if ( $class->cache and $key ) {
        $object->call_trigger('deflate_for_create');
        $class->cache->set( $key, $object );
    }

    return $object;
}

sub retrieve {
    my $class = shift;

    if ( $class->cache ) {

        if ( my $key = $class->cache_key(@_) ) {

            if ( my $object = $class->cache->get($key) ) {
                $object->call_trigger('select');
                push (
                    @{ $class->profiling_data->{object_cache} },
                    [ 'HIT', $key ]
                  )
                  if ( $class->default_search_attributes->{profile_cache} );
                return $object;
            }

            push ( @{ $class->profiling_data->{object_cache} },
                [ 'MISS', $key ] )
              if ( $class->default_search_attributes->{profile_cache} );
        }
    }

    return $class->SUPER::retrieve(@_);
}

*create = \&insert;

sub insert {
    my $self = shift;

    if ( $self->cache ) {
        $self->cache->set( $self->_staleness_cache_key, time() );
    }

    return $self->SUPER::insert(@_);
}

sub update {
    my $self = shift;

    if ( $self->cache ) {
        $self->cache->remove( $self->cache_key );
        $self->cache->set( $self->_staleness_cache_key, time() );
    }

    return $self->SUPER::update(@_);
}

sub delete {
    my $self = shift;

    return $self->_search_delete(@_) if not ref $self;

    if ( $self->cache ) {
        $self->cache->remove( $self->cache_key );
        $self->cache->set( $self->_staleness_cache_key, time() );
    }

    return $self->SUPER::delete(@_);
}

#----------------------------------------------------------------------
# UNIVERSALLY UNIQUE IDENTIFIERS
#----------------------------------------------------------------------

sub _next_in_sequence {
    my $self = shift;

    if ( lc $self->sequence eq 'uuid' ) {

        die "UUID features not available" unless $UUID_Is_Available;

        if ( $^O eq 'MSWin32' ) {
            return Win32API::GUID::CreateGuid();
        }
        else {
            return Data::UUID->new->create_str;
        }
    }

    return $self->SUPER::_next_in_sequence;
}

#----------------------------------------------------------------------
# MORE MAGIC
#----------------------------------------------------------------------

package Class::DBI::Sweet::SQL::Abstract;

use base qw/SQL::Abstract/;
use Carp qw/croak/;

sub where {
    my ( $self, $where, $order, $must_join ) = @_;

    my $me = $self->{cdbi_me_alias};
    $self->{cdbi_table_aliases} = { $me => $self->{cdbi_class} };
    $self->{cdbi_join_info}     = {};
    $self->{cdbi_column_cache}  = {};

    foreach my $join ( @{ $must_join || [] } ) {
        $self->_resolve_join( $me => $join );
    }

    my $sql = '';

    my (@ret) = $self->_recurse_where($where);

    if (@ret) {
        my $wh = shift @ret;
        $sql .= $self->_sqlcase(' where ') . $wh if $wh;
    }

    $sql =~ s/(\S+)( IS(?: NOT)? NULL)/$self->_default_tables($1).$2/ge;

    my $joins  = delete $self->{cdbi_join_info};
    my $tables = delete $self->{cdbi_table_aliases};

    my $from = $self->{cdbi_class}->table . " ${me}";

    foreach my $join ( keys %{$joins} ) {
        my $table = $tables->{$join}->table;
        $from .= ", ${table} ${join}";
        my ( $l_alias, $l_key, $f_key ) =
          @{ $joins->{$join} }{qw/l_alias l_key f_key/};
        $sql .= " AND ${l_alias}.${l_key} = ${join}.${f_key}";
    }

    # order by?
    #if ($order) {
    #    $sql .= $self->_order_by($order);
    #}

    delete $self->{cdbi_column_cache};

    return wantarray ? ( $sql, $from, $tables, @ret ) : $sql;
}

sub _convert {
    my ( $self, $to_convert ) = @_;

    return $self->SUPER::_convert($to_convert) if $to_convert eq '?';
    return $self->SUPER::_convert( $self->_default_tables($to_convert) );
}

sub _default_tables {
    my ( $self, $to_convert ) = @_;

    my $alias = $self->{cdbi_me_alias};

    my @alias = split ( /\./, $to_convert );

    my $field = pop (@alias);

    foreach my $f_alias (@alias) {

        $self->_resolve_join( $alias => $f_alias )
          unless $self->{cdbi_table_aliases}{$f_alias};
        $alias = $f_alias;
    }

    if ( my $meta = $self->{cdbi_class}->meta_info( has_many => $field ) ) {

        my $f_alias = $field;
        $self->_resolve_join( $alias => $f_alias )
          unless $self->{cdbi_table_aliases}{$f_alias};

        $field = ( ( $meta->foreign_class->columns('Primary') )[0] );
        $alias = $f_alias;
    }

    return "${alias}.${field}";
}

sub _resolve_join {
    my ( $self, $l_alias, $f_alias ) = @_;
    my $l_class = $self->{cdbi_table_aliases}->{$l_alias};
    my $meta    = $l_class->meta_info;
    my ( $rel, $f_class );
    if ( $rel = $meta->{has_a}{$f_alias} ) {
        $f_class = $rel->foreign_class;
        $self->{cdbi_join_info}{$f_alias} = {
            l_alias => $l_alias,
            l_key   => $f_alias,
            f_key   => ( $f_class->columns('Primary') )[0]
        };
    }
    elsif ( $rel = $meta->{has_many}{$f_alias} ) {
        $f_class = $rel->foreign_class;
        $self->{cdbi_join_info}{$f_alias} = {
            l_alias => $l_alias,
            l_key   => ( $l_class->columns('Primary') )[0],
            f_key   => $rel->args->{foreign_key}
        };
    }
    elsif ( $rel = $meta->{might_have}{$f_alias} ) {
        $f_class = $rel->foreign_class;
        $self->{cdbi_join_info}{$f_alias} = {
            l_alias => $l_alias,
            l_key   => ( $l_class->columns('Primary') )[0],
            f_key   => ( $f_class->columns('Primary') )[0]
        };
    }
    else {
        croak("Unable to find join info for ${f_alias} from ${l_class}");
    }

    $self->{cdbi_table_aliases}{$f_alias} = $f_class;
}

sub _bindtype {
    my ( $self, $var, $val, @rest ) = @_;
    $var = $self->_default_tables($var);
    my ( $alias, $col ) = split ( /\./, $var );
    my $f_class = $self->{cdbi_table_aliases}{$alias};

    my $column = $self->{cdbi_column_cache}{$alias}{$col};

    unless ($column) {

        $column = $f_class->find_column($col)
          || ( List::Util::first { $_->accessor eq $col } $f_class->columns )
          || croak("$col is not a column of ${f_class}");

        $self->{cdbi_column_cache}{$alias}{$col} = $column;
    }

    if ( ref $val eq $f_class ) {
        my $accessor = $column->accessor;
        $val = $val->$accessor;
    }

    $val = $f_class->_deflated_column( $column, $val );

    return $self->SUPER::_bindtype( $var, $val, @rest );
}

1;

__END__

=head1 NAME

    Class::DBI::Sweet - Making sweet things sweeter

=head1 SYNOPSIS

    package MyApp::DBI;
    use base 'Class::DBI::Sweet';
    MyApp::DBI->connection('dbi:driver:dbname', 'username', 'password');

    package MyApp::Article;
    use base 'MyApp::DBI';

    use DateTime;

    __PACKAGE__->table('article');
    __PACKAGE__->columns( Primary   => qw[ id ] );
    __PACKAGE__->columns( Essential => qw[ title created_on created_by ] );

    __PACKAGE__->has_a(
        created_on => 'DateTime',
        inflate    => sub { DateTime->from_epoch( epoch => shift ) },
        deflate    => sub { shift->epoch }
    );


    # Simple search

    MyApp::Article->search( created_by => 'sri', { order_by => 'title' } );

    MyApp::Article->count( created_by => 'sri' );

    MyApp::Article->page( created_by => 'sri', { page => 5 } );

    MyApp::Article->retrieve_all( order_by => 'created_on' );


    # More powerful search with deflating

    $criteria = {
        created_on => {
            -between => [
                DateTime->new( year => 2004 ),
                DateTime->new( year => 2005 ),
            ]
        },
        created_by => [ qw(chansen draven gabb jester sri) ],
        title      => {
            -like  => [ qw( perl% catalyst% ) ]
        }
    };

    MyApp::Article->search( $criteria, { rows => 30 } );

    MyApp::Article->count($criteria);

    MyApp::Article->page( $criteria, { rows => 10, page => 2 } );

    MyApp::Article->retrieve_next( $criteria,
                                     { order_by => 'created_on' } );

    MyApp::Article->retrieve_previous( $criteria,
                                         { order_by => 'created_on' } );

    MyApp::Article->default_search_attributes(
                                         { order_by => 'created_on' } );

    # Automatic joins for search and count

    MyApp::CD->has_many(tracks => 'MyApp::Track');
    MyApp::CD->has_many(tags => 'MyApp::Tag');
    MyApp::CD->has_a(artist => 'MyApp::Artist');
    MyApp::CD->might_have(liner_notes
        => 'MyApp::LinerNotes' => qw/notes/);

    MyApp::Artist->search({ 'cds.year' => $cd }, # $cd->year subtituted
                                  { order_by => 'artistid DESC' });

    my ($tag) = $cd->tags; # Grab first tag off CD

    my ($next) = $cd->retrieve_next( { 'tags.tag' => $tag },
                                       { order_by => 'title' } );

    MyApp::CD->search( { 'liner_notes.notes' => { "!=" => undef } } );

    MyApp::CD->count(
           { 'year' => { '>', 1998 }, 'tags.tag' => 'Cheesy',
               'liner_notes.notes' => { 'like' => 'Buy%' } } );

    # Multi-step joins

    MyApp::Artist->search({ 'cds.tags.tag' => 'Shiny' });

    # Retrieval with pre-loading

    my ($cd) = MyApp::CD->search( { ... },
                       { prefetch => [ qw/artist liner_notes/ ] } );

    $cd->artist # Pre-loaded

    # Caching of resultsets (*experimental*)

    __PACKAGE__->default_search_attributes( { use_resultset_cache => 1 } );

=head1 DESCRIPTION

Class::DBI::Sweet provides convenient count, search, page, and
cache functions in a sweet package. It integrates these functions with
C<Class::DBI> in a convenient and efficient way.

=head1 RETRIEVING OBJECTS

All retrieving methods can take the same criteria and attributes. Criteria is
the only required parameter.

=head2 criteria

Can be a hash, hashref, or an arrayref. Takes the same options as the
L<SQL::Abstract> C<where> method. If values contain any objects, they
will be deflated before querying the database.

=head2 attributes

=over 4

=item case, cmp, convert, and logic

These attributes are passed to L<SQL::Abstract>'s constuctor and alter the
behavior of the criteria.

    { cmp => 'like' }

=item order_by

Specifies the sort order of the results.

    { order_by => 'created_on DESC' }

=item rows

Specifies the maximum number of rows to return. Currently supported RDBMs are
Interbase, MaxDB, MySQL, PostgreSQL and SQLite. For other RDBMs, it will be
emulated.

    { rows => 10 }

=item offset

Specifies the offset of the first row to return. Defaults to 0 if unspecified.

    { offset => 0 }

=item page

Specifies the current page in C<page>. Defaults to 1 if unspecified.

    { page => 1 }

=item prefetch

Specifies a listref of relationships to prefetch. These must be has_a or
might_haves or Sweet will throw an error. This will cause Sweet to do
a join across to the related tables in order to return the related object
without a second trip to the database. All 'Essential' columns of the
foreign table are retrieved.

    { prefetch => [ qw/some_rel some_other_rel/ ] }

Sweet constructs the joined SQL statement by aliasing the columns in
each table and prefixing the column name with 'sweet__N_' where N is a
counter starting at 1.  Note that if your database has a column length limit 
(for example, Oracle's limit is 30) and you use long column names in
your application, Sweet's addition of at least 9 extra characters to your
column name may cause database errors.

=item use_resultset_cache

Enables the resultset cache. This is a little experimental and massive gotchas
may rear their ugly head at some stage, but it does seem to work pretty well.

For best results, the resultset cache should only be used selectively on
queries where you experience performance problems.  Enabling it for every
single query in your application will most likely cause a drop in performance
as the cache overhead is greater than simply fetching the data from the
database.

=item profile_cache

Records cache hits/misses and what keys they were for in ->profiling_data.
Note that this is class metadata so if you don't want it to be global for
Sweet you need to do

    __PACKAGE__->profiling_data({ });

in either your base class or your table classes to taste.

=item disable_sql_paging

Disables the use of paging in SQL statements if set, forcing Sweet to emulate
paging by slicing the iterator at the end of ->search (which it normally only
uses as a fallback mechanism). Useful for testing or for causing the entire
query to be retrieved initially when the resultset cache is used.

This is also useful when using custom SQL via C<set_sql> and setting
C<sql_method> (see below) where a COUNT(*) may not make sense (i.e. when
the COUNT(*) might be as expensive as just running the full query and just slicing
the iterator).

=item sql_method

This sets the name of the sql fragment to use as previously set by a
C<set_sql> call.  The default name is "Join_Retrieve" and the associated
default sql fragment set in this class is:

    __PACKAGE__->set_sql( Join_Retrieve => <<'SQL' );
    SELECT __ESSENTIAL(me)__%s
    FROM   %s
    WHERE  %s
    SQL

You may override this in your table or base class using the same name and CDBI::Sweet
will use your custom fragment, instead.

If you need to use more than one sql fragment in a given class you may create a new
sql fragment and then specify its name using the C<sql_method> attribute.

The %s strings are replaced by sql parts as described in L<Ima::DBI>.  See
"statement_order" for the sql part that replaces each instance of %s.

In addition, the associated statment for COUNT(*) statement has "_Count"
appended to the sql_method name.  Only "from" and "where" are passed to the sprintf
function.

The default sql fragment used for "Join_Retrieve" is:

    __PACKAGE__->set_sql( Join_Retrieve_Count => <<'SQL' );
    SELECT COUNT(*)
    FROM   %s
    WHERE  %s
    SQL

If you create a custom sql method (and set the C<sql_method> attribute) then
you will likely need to also create an associated _Count fragment.  If you do
not have an associated _Count, and wish to call the C<page> method,  then set
C<disable_sql_paging> to true and your result set from the select will be spliced
to return the page you request.

Here's an example.

Assume a CD has_a Artist (and thus Artists have_many CDs), and you wish to
return a list of artists and how many CDs each have:

In package MyDB::Artist

    __PACKAGE__->columns( TEMP => 'cd_count');

    __PACKAGE__->set_sql( 'count_by_cd', <<'');
        SELECT      __ESSENTIAL(me)__, COUNT(cds.cdid) as cd_count
        FROM        %s                  -- ("from")
        WHERE       %s                  -- ("where")
        GROUP BY    __ESSENTIAL(me)__
        %s %s                           -- ("limit" and "order_by")

Then in your application code:

    my ($pager, $iterator) = MyDB::Artist->page(
        {
            'cds.title'    => { '!=', undef },
        },
        {
            sql_method          => 'count_by_cd',
            statement_order     => [qw/ from where limit order_by / ],
            disable_sql_paging  => 1,
            order_by            => 'cd_count desc',
            rows                => 10,
            page                => 1,
        } );

The above generates the following SQL:

    SELECT      me.artistid, me.name, COUNT(cds.cdid) as cd_count
    FROM        artist me, cd cds
    WHERE       ( cds.title IS NOT NULL ) AND me.artistid = cds.artist
    GROUP BY    me.artistid, me.name
    ORDER BY    cd_count desc

The one caveat is that Sweet cannot figure out the has_many joins unless you
specify them in the $criteria.  In the previous example that's done by asking
for all cd titles that are not null (which should be all).

To fetch a list like above but limited to cds that were created before the year
2000, you might do:

    my ($pager, $iterator) = MyDB::Artist->page(
        {
            'cds.year'  => { '<', 2000 },
        },
        {
            sql_method          => 'count_by_cd',
            statement_order     => [qw/ from where limit order_by / ],
            disable_sql_paging  => 1,
            order_by            => 'cd_count desc',
            rows                => 10,
            page                => 1,
        } );


=item statement_order

Specifies a list reference of SQL parts that are replaced in the SQL fragment (which
is defined with "sql_method" above).  The available SQL parts are:

    prefetch_cols from where order_by limit sql prefetch_names

The "sql" part is shortcut notation for these three combined:

    where order_by limit

Prefecch_cols are the columns selected when a prefetch is speccified -- use in the SELECT.
Prefetch_names are just the column names for use in GROUP BY.

This is useful when statement order needs to be changed, such as when using a
GROUP BY:

=back

=head2 count

Returns a count of the number of rows matching the criteria. C<count> will
discard C<offset>, C<order_by>, and C<rows>.

    $count = MyApp::Article->count(%criteria);

=head2 search

Returns an iterator in scalar context, or an array of objects in list
context.

    @objects  = MyApp::Article->search(%criteria);

    $iterator = MyApp::Article->search(%criteria);

=head2 search_like

As search but adds the attribute { cmp => 'like' }.

=head2 page

Retuns a page object and an iterator. The page object is an instance of
L<Data::Page>.

    ( $page, $iterator )
        = MyApp::Article->page( $criteria, { rows => 10, page => 2 );

    printf( "Results %d - %d of %d Found\n",
        $page->first, $page->last, $page->total_entries );

=head2 pager

An alias to page.

=head2 retrieve_all

Same as C<Class::DBI> with addition that it takes C<attributes> as arguments,
C<attributes> can be a hash or a hashref.

    $iterator = MyApp::Article->retrieve_all( order_by => 'created_on' );

=head2 retrieve_next

Returns the next record after the current one according to the order_by
attribute (or primary key if no order_by specified) matching the criteria.
Must be called as an object method.

=head2 retrieve_previous

As retrieve_next but retrieves the previous record.

=head1 CACHING OBJECTS

Objects will be stored deflated in cache. Only C<Primary> and C<Essential>
columns will be cached.

=head2 cache

Class method: if this is set caching is enabled. Any cache object that has a
C<get>, C<set>, and C<remove> method is supported.

    __PACKAGE__->cache(
        Cache::FastMmap->new(
            share_file => '/tmp/cdbi',
            expire_time => 3600
        )
    );

=head2 cache_key

Returns a cache key for an object consisting of class and primary keys.

=head2 Overloaded methods

=over 4

=item _init

Overrides C<Class::DBI>'s internal cache. On a cache hit, it will return
a cached object; on a cache miss it will create an new object and store
it in the cache.

=item create

=item insert 

All caches for this table are marked stale and will be re-cached on next
retrieval. create is an alias kept for backwards compability.

=item retrieve

On a cache hit the object will be inflated by the C<select> trigger and
then served.

=item update

Object is removed from the cache and will be cached on next retrieval.

=item delete

Object is removed from the cache.

=back

=head1 UNIVERSALLY UNIQUE IDENTIFIERS

If enabled a UUID string will be generated for primary column. A CHAR(36)
column is suitable for storage.

    __PACKAGE__->sequence('uuid');

=head1 MAINTAINERS

Fred Moyer <fred@redhotpenguin.com>

=head1 AUTHORS

Christian Hansen <ch@ngmedia.com>

Matt S Trout <mstrout@cpan.org>

Andy Grundman <andy@hybridized.org>

=head1 THANKS TO

Danijel Milicevic, Jesse Sheidlower, Marcus Ramberg, Sebastian Riedel,
Viljo Marrandi, Bill Moseley

=head1 SUPPORT

#catalyst on L<irc://irc.perl.org>

L<http://lists.rawmode.org/mailman/listinfo/catalyst>

L<http://lists.rawmode.org/mailman/listinfo/catalyst-dev>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>

L<Data::Page>

L<Data::UUID>

L<SQL::Abstract>

L<Catalyst>

L<http://cpan.robm.fastmail.fm/cache_perf.html>
A comparison of different caching modules for perl.

=cut
