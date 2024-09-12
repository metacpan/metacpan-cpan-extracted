package DBIx::Lite::ResultSet;
$DBIx::Lite::ResultSet::VERSION = '0.34';
use strict;
use warnings;

use Carp qw(croak);
use Clone qw(clone);
use Data::Page;
use List::MoreUtils qw(uniq firstval);
use vars qw($AUTOLOAD);
$Carp::Internal{$_}++ for __PACKAGE__;

sub _new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {
        joins           => [],
        where           => [],
        select          => ['me.*'],
        rows_per_page   => 10,
    };
    
    # required arguments
    for (qw(dbix_lite table)) {
        $self->{$_} = delete $params{$_} or croak "$_ argument needed";
    }
    
    # optional arguments
    for (grep exists($params{$_}), qw(joins where select group_by having order_by
        limit offset for rows_per_page page cur_table with from)) {
        $self->{$_} = delete $params{$_};
    }
    $self->{cur_table} //= $self->{table};
    
    !%params
        or croak "Unknown options: " . join(', ', keys %params);
    
    bless $self, $class;
    $self;
}

# create setters
for my $methname (qw(group_by having order_by limit offset rows_per_page page from)) {
    no strict 'refs';
    *$methname = sub {
        my $self = shift;
        
        # we always return a new object for easy chaining
        my $new_self = $self->_clone;
        
        # set new values
        $new_self->{$methname} = $methname =~ /^(group_by|order_by|from)$/ ? [@_] : $_[0];
        $new_self->{pager}->current_page($_[0]) if $methname eq 'page' && $new_self->{pager};
        
        # return object
        $new_self;
    };
}

sub distinct {
    my ($self, $value) = @_;
    
    my $new_self = $self->_clone;
    $new_self->{distinct} = !defined($value) || $value;
    $new_self;
}

sub for_update {
    my ($self) = @_;
    
    return $self->for('UPDATE');
}

sub for {
    my ($self, $for) = @_;
    
    my $new_self = $self->_clone;
    $new_self->{for} = $for;
    $new_self;
}

# return a clone of this object
sub _clone {
    my $self = shift;
    (ref $self)->_new(
        # clone all members except for some which we copy by reference
        map { $_ => /^(?:dbix_lite|table|cur_table)$/ ? $self->{$_} : clone($self->{$_}) }
            grep !/^(?:sth|pager)$/, keys %$self,
    );
}

sub select {
    my $self = shift;

    my $new_self = $self->_clone;
    $new_self->{select} = @_ ? [@_] : undef;
    
    $new_self;
}

sub select_also {
    my $self = shift;
    return $self->select(@{$self->{select}}, @_);
}

sub with {
    my $self = shift;
    my %with = @_;
    
    croak "with() requires a hash of scalarrefs or refs to arrayrefs"
        if grep { !ref($_) eq 'SCALAR' } values %with;
    
    my $new_self = $self->_clone;
    $new_self->{with} = %with ? {%with} : undef;
    
    $new_self;
}

sub with_also {
    my $self = shift;
    return $self->with(%{$self->{with}}, @_);
}

sub pager {
    my $self = shift;
    if (!$self->{pager}) {
        $self->{pager} ||= Data::Page->new;
        $self->{pager}->total_entries($self->page(undef)->count);
        $self->{pager}->entries_per_page($self->{rows_per_page} // $self->{pager}->total_entries);
        $self->{pager}->current_page($self->{page});
    }
    return $self->{pager};
}

sub search {
    my $self = shift;
    my ($where) = @_;
    
    my $new_self = $self->_clone;
    push @{$new_self->{where}}, $where if defined $where;
    $new_self;
}

sub clear_search {
    my $self = shift;
    
    my $new_self = $self->_clone;
    @{$new_self->{where}} = ();
    $new_self;
}

sub find {
    my $self = shift;
    my ($where) = @_;
    
    # if user did not supply a search hashref, we assume the supplied
    # value(s) are the key(s) of the primary key column(s) defined for
    # this table
    if (!ref $where && (my @pk = $self->{table}->pk)) {
        # prepend table alias to all pk columns
        $_ =~ s/^[^.]+$/me\.$&/ for @pk;
        
        $where = { map +(shift(@pk) => $_), @_ };
    }
    return $self->search($where)->single;
}

sub where_sql {
    my $self = shift;
    
    my ($sql, @bind) = $self->{dbix_lite}->{abstract}->where({ -and => $self->{where} });
    return ($sql, @bind);
}

sub select_sql {
    my $self = shift;
    
    # prepare names of columns to be selected
    my @cols = ();
    my $cur_table_prefix = $self->_table_alias($self->{cur_table}{name}, 'select');
    foreach my $col (grep defined $_, @{$self->{select}}) {
        # check whether user specified an alias
        my ($expr, $as) = ref $col eq 'ARRAY' ? @$col : ($col, undef);
        
        # prepend table alias if column name doesn't contain one already
        $expr =~ s/^[^.]+$/$cur_table_prefix\.$&/ if !ref($expr) && !$self->{from};
        
        # explode the expression if it's a scalar ref
        if (ref $expr eq 'SCALAR') {
            $expr = $$expr;
        }
        
        # build the column definition according to the SQL::Abstract::More syntax
        push @cols, $expr . ($as ? "|$as" : "");
    }
    
    # joins
    my @joins = ();
    foreach my $join (@{$self->{joins}}) {
        # get table name and alias if any
        my ($table_name, $table_alias) = @{$join->{table}};
        my $left_table_prefix = $self->_table_alias($join->{cur_table}{name}, 'select');
        
        # prepare join conditions
        my %cond = ();
        while (my ($col1, $col2) = each %{$join->{condition}}) {
            # in case they have no explicit table alias,
            # $col1 is supposed to belong to the current table, and
            # $col2 is supposed to belong to the joined table
            
            # prepend table alias to the column of the first table
            $col1 =~ s/^[^.]+$/$left_table_prefix.$&/;
            
            # in case user supplied the table name as table alias, replace it
            # with the proper one (such as "me.")
            $col1 =~ s/^$join->{cur_table}{name}\./$left_table_prefix./;
            
            # prepend table alias to the column of the second table
            $col2 = ($table_alias || $self->{dbix_lite}->_quote($table_name)) . ".$col2"
                unless ref $col2 || $col2 =~ /\./;
            
            # in case the second item is a scalar reference (literal SQL)
            # or a hashref (search condition), pass it unchanged
            $cond{$col1} = ref($col2) ? $col2 : \ "= $col2";
        }
        
        # store the join definition according to the SQL::Abstract::More syntax
        push @joins, {
            operator    => $join->{join_type} eq 'inner' ? '<=>' : '=>',
            condition   => \%cond,
        };
        push @joins, $table_name . ($table_alias ? "|$table_alias" : "");
    }
    
    # from
    my @from = ();
    if ($self->{from}) {
        @from = @{$self->{from}};
    } else {
        @from = (-join => $self->{table}{name} . "|me", @joins);
    }
    
    # paging overrides limit and offset if any
    if ($self->{page} && defined $self->{rows_per_page}) {
        $self->{limit} = $self->{rows_per_page};
        $self->{offset} = $self->pager->skipped;
    }
    
    # ordering
    if ($self->{order_by}) {
        $self->{order_by} = [$self->{order_by}]
            unless ref $self->{order_by} eq 'ARRAY';
    }
    
    my ($sql, @bind) = $self->{dbix_lite}->{abstract}->select(
        -columns    => [ ($self->{distinct} ? '-distinct' : ()), uniq @cols ],
        -from       => [ @from ],
        -where      => { -and => $self->{where} },
        $self->{group_by}   ? (-group_by    => $self->{group_by})   : (),
        $self->{having}     ? (-having      => $self->{having})     : (),
        $self->{order_by}   ? (-order_by    => $self->{order_by})   : (),
        $self->{limit}      ? (-limit       => $self->{limit})      : (),
        $self->{offset}     ? (-offset      => $self->{offset})     : (),
        $self->{for}        ? (-for         => $self->{for})     : (),
    );
    
    if ($self->{with}) {
        my @with_sql = ();
        foreach my $alias (keys %{$self->{with}}) {
            my $def = $self->{with}{$alias};
            
            if (ref $$def eq 'ARRAY') {
                my ($wsql, @wbind) = @$$def;
                push @with_sql, sprintf "%s AS (%s)", $alias, $wsql;
                unshift @bind, @wbind;
            } else {
                push @with_sql, sprintf "%s AS (%s)", $alias, $$def;
            }
        }
        $sql = sprintf 'WITH %s %s', join(', ', @with_sql), $sql;
    }
    
    return ($sql, @bind);
}

sub select_sth {
    my $self = shift;
    
    my ($sql, @bind) = $self->select_sql;
    return $self->{dbix_lite}->dbh->prepare($sql) || undef, @bind;
}

sub _select_sth_for_object {
    my $self = shift;
    
    # check whether any of the selected columns is a scalar ref
    my $cur_table_prefix = $self->_table_alias($self->{cur_table}{name}, 'select');
    my $have_scalar_ref = 0;
    my $have_star = 0;
    foreach my $col (grep defined $_, @{$self->{select}}) {
        my $expr = ref($col) eq 'ARRAY' ? $col->[0] : $col;
        if (ref($expr) eq 'SCALAR') {
            $have_scalar_ref = 1;
        } elsif ($expr eq "$cur_table_prefix.*") {
            $have_star = 1;
        }
    }
    
    # always retrieve our primary key if provided and no col name is a scalar ref
    # also skip this if we are retrieving all columns (me.*)
    if (!$have_scalar_ref && !$have_star && (my @pk = $self->{cur_table}->pk)) {
        # prepend table alias to all pk columns
        $_ =~ s/^[^.]+$/$cur_table_prefix\.$&/ for @pk;
        
        # append instead of prepend, otherwise get_column() on a non-PK column 
        # would return the wrong values
        $self = $self->select_also(@pk);
    }
    
    return $self->select_sth;
}

sub insert_sql {
    my $self = shift;
    my $insert_cols = shift;
    ref $insert_cols eq 'HASH' or croak "insert_sql() requires a hashref";
    
    if (@{$self->{joins}}) {
        warn "Attempt to call ->insert() after joining other tables\n";
    }
    
    if (!%$insert_cols && $self->{dbix_lite}->driver_name eq 'Pg') {
        # Postgres doesn't support the VALUES () syntax
        return sprintf "INSERT INTO %s DEFAULT VALUES",
            $self->{dbix_lite}->_quote($self->{table}{name});
    }
    
    return $self->{dbix_lite}->{abstract}->insert(
        $self->{table}{name}, $insert_cols,
    );
}

sub insert_sth {
    my $self = shift;
    my $insert_cols = shift;
    ref $insert_cols eq 'HASH' or croak "insert_sth() requires a hashref";
    
    my ($sql, @bind) = $self->insert_sql($insert_cols);
    return $self->{dbix_lite}->dbh->prepare($sql) || undef, @bind;
}

sub insert {
    my $self = shift;
    my $insert_cols = shift;
    ref $insert_cols eq 'HASH' or croak "insert() requires a hashref";
    
    # perform operation
    my $res;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->insert_sth($insert_cols);
        $res = $sth->execute(@bind);
    });
    return undef if !$res;
    
    # populate the autopk field if any
    if (my $pk = $self->{table}->autopk) {
        $insert_cols = clone $insert_cols;
        $insert_cols->{$pk} = $self->{dbix_lite}->_autopk($self->{table}{name})
            if !exists $insert_cols->{$pk};
    }
    
    # return a DBIx::Lite::Row object with the inserted values
    return $self->_inflate_row($insert_cols);
}

sub update_sql {
    my $self = shift;
    my $update_cols = shift;
    ref $update_cols eq 'HASH' or croak "update_sql() requires a hashref";
    
    my $update_where = { -and => $self->{where} };
    
    if ($self->{cur_table}{name} ne $self->{table}{name}) {
        my @pk = $self->{cur_table}->pk
            or croak "No primary key defined for " . $self->{cur_table}{name} . "; cannot update using relationships";
        @pk == 1
            or croak "Update across relationships is not allowed with multi-column primary keys";
        
        my $fq_pk = $self->_table_alias($self->{cur_table}{name}, 'update') . "." . $pk[0];
        $update_where = {
            $fq_pk => {
                -in => \[ $self->select($pk[0])->select_sql ],
            },
        };
    }
    
    return $self->{dbix_lite}->{abstract}->update(
        -table  => $self->_table_alias_expr($self->{cur_table}{name}, 'update'),
        -set    => $update_cols,
        -where  => $update_where,
    );
}

sub update_sth {
    my $self = shift;
    my $update_cols = shift;
    ref $update_cols eq 'HASH' or croak "update_sth() requires a hashref";
    
    my ($sql, @bind) = $self->update_sql($update_cols);
    return $self->{dbix_lite}->dbh->prepare($sql) || undef, @bind;
}

sub update {
    my $self = shift;
    my $update_cols = shift;
    ref $update_cols eq 'HASH' or croak "update() requires a hashref";
    
    my $affected_rows;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->update_sth($update_cols);
        $affected_rows = $sth->execute(@bind);
    });
    return $affected_rows;
}

sub find_or_insert {
    my $self = shift;
    my $cols = shift;
    ref $cols eq 'HASH' or croak "find_or_insert() requires a hashref";
    
    my $object;
    $self->{dbix_lite}->txn(sub {
        if (!($object = $self->find($cols))) {
            $object = $self->insert($cols);
        }
    });
    return $object;
}

sub delete_sql {
    my $self = shift;
    
    my $delete_where = { -and => $self->{where} };
    
    if ($self->{cur_table}{name} ne $self->{table}{name}) {
        my @pk = $self->{cur_table}->pk
            or croak "No primary key defined for " . $self->{cur_table}{name} . "; cannot delete using relationships";
        @pk == 1
            or croak "Delete across relationships is not allowed with multi-column primary keys";
        
        my $fq_pk = $self->_table_alias($self->{cur_table}{name}, 'delete') . "." . $pk[0];
        $delete_where = {
            $fq_pk => {
                -in => \[ $self->select($pk[0])->select_sql ],
            },
        };
    }
    
    return $self->{dbix_lite}->{abstract}->delete(
        $self->_table_alias_expr($self->{cur_table}{name}, 'delete'),
        $delete_where,
    );
}

sub delete_sth {
    my $self = shift;
    
    my ($sql, @bind) = $self->delete_sql;
    return $self->{dbix_lite}->dbh->prepare($sql) || undef, @bind;
}

sub delete {
    my $self = shift;
    
    my $affected_rows;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->delete_sth;
        $affected_rows = $sth->execute(@bind);
    });
    return $affected_rows;
}

sub single {
    my $self = shift;
    
    my $row;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->_select_sth_for_object;
        $sth->execute(@bind);
        $row = $sth->fetchrow_hashref;
    });
    return $row ? $self->_inflate_row($row) : undef;
}

sub single_value {
    my $self = shift;
    
    my $value;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->select_sth;
        $sth->execute(@bind);
        ($value) = $sth->fetchrow_array;
    });
    return $value;
}

sub all {
    my $self = shift;
    
    my $rows;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->_select_sth_for_object;
        $sth->execute(@bind);
        $rows = $sth->fetchall_arrayref({});
    });
    return map $self->_inflate_row($_), @$rows;
}

sub next {
    my $self = shift;
    
    $self->{dbix_lite}->dbh_do(sub {
        ($self->{sth}, my @bind) = $self->_select_sth_for_object;
        $self->{sth}->execute(@bind);
    }) if !$self->{sth};
    
    my $row = $self->{sth}->fetchrow_hashref or return undef;
    return $self->_inflate_row($row);
}

sub count {
    my $self = shift;
    
    my $count;
    $self->{dbix_lite}->dbh_do(sub {
        # Postgres throws an error when using ORDER BY clauses with COUNT(*)
        my $count_rs = $self->select(\ "COUNT(*)")->order_by(undef);
        my ($sth, @bind) = $count_rs->select_sth;
        $sth->execute(@bind);
        $count = +($sth->fetchrow_array)[0];
    });
    return $count;
}

sub column_names {
    my $self = shift;

    $self->{dbix_lite}->dbh_do(sub {
        ($self->{sth}, my @bind) = $self->select_sth;
        $self->{sth}->execute(@bind);
    }) if !$self->{sth};

    my $c = $self->{sth}->{NAME};
    return wantarray ? @$c : $c;
}

sub get_column {
    my $self = shift;
    my $column_name = shift or croak "get_column() requires a column name";
    
    my @values = ();
    $self->{dbix_lite}->dbh_do(sub {
        my $rs = ($self->_clone)->select($column_name);
        my ($sql, @bind) = $rs->select_sql;
    
        @values = @{$self->{dbix_lite}->dbh->selectcol_arrayref($sql, {}, @bind)};
    });
    return @values;
}

sub inner_join {
    my $self = shift;
    return $self->_join('inner', @_);
}

sub left_join {
    my $self = shift;
    return $self->_join('left', @_);
}

sub _join {
    my $self = shift;
    my ($type, $table_name, $condition, $options) = @_;
    $options ||= {};
    $table_name = [ $table_name, undef ] if ref $table_name ne 'ARRAY';
    
    my $new_self = $self->_clone;
    
    # if user asked for duplicate join removal, check whether no joins
    # with the same table alias exist
    if ($options->{prevent_duplicates}) {
        foreach my $join (@{$self->{joins}}) {
            if ((defined($table_name->[1]) && defined $join->{table}[1] && $table_name->[1] eq $join->{table}[1])
                || (!defined($table_name->[1]) && $table_name->[0] eq $join->{table}[0])) {
                return $new_self;
            }
        }
    }
    
    push @{$new_self->{joins}}, {
        join_type   => $type,
        cur_table   => $self->{cur_table},
        table       => $table_name,
        condition   => $condition,
    };
    
    $new_self;
}

sub clear_joins {
    my $self = shift;
    
    my $new_self = $self->_clone;
    @{$new_self->{joins}} = ();
    $new_self;
}

sub _table_alias {
    my $self = shift;
    my ($table_name, $op) = @_;
    
    my $driver_name = $self->{dbix_lite}->driver_name;
    
    if ($table_name eq $self->{table}{name}) {
        if ($op eq 'select'
            || ($op eq 'update' && $driver_name =~ /^(?:MySQL|Pg)$/i)
            || ($op eq 'delete' && $driver_name =~ /^Pg$/i)) {
            return 'me';
        }
    }
    
    return $table_name;
}

sub _table_alias_expr {
    my $self = shift;
    my ($table_name, $op) = @_;
    
    my $table_alias = $self->_table_alias($table_name, $op);
    if ($table_name eq $table_alias) {
        # foo
        return $table_name;
    } else {
        # foo AS my_foo
        return $self->{dbix_lite}->{abstract}->table_alias($table_name, $table_alias);
    }
}

sub _inflate_row {
    my $self = shift;
    my ($hashref) = @_;
    
    # get the row package
    my $package = $self->{cur_table}{class} || 'DBIx::Lite::Row';
    
    # get the constructor, if any
    my $constructor = $self->{cur_table}{class_constructor};
    if (!defined $constructor && $package->can('new')) {
        $constructor = 'new';
    }
    
    # create the object
    my $object;
    if (defined $constructor) {
        if (ref($constructor) eq 'CODE') {
            $object = $constructor->($hashref);
        } else {
            $object = $package->$constructor;
        }
    } else {
        $object = {};
        bless $object, $package;
    }
    
    # get the hashref where we are going to store our data
    my $storage;
    if (my $method = $self->{cur_table}{class_storage}) {
        croak "No ${package}::${method} method exists"
            if !$package->can($method);
        $storage = $object->$method;
        croak "${package}::${method}() did not return a hashref"
            if ref($storage) ne 'HASH';
    } else {
        $storage = $object;
    }
    
    # store our data
    $storage->{dbix_lite}   = $self->{dbix_lite};
    $storage->{table}       = $self->{cur_table};
    $storage->{data}        = $hashref;
    
    return $object;
}

sub AUTOLOAD {
    my $self = shift or return undef;
    
    # Get the called method name and trim off the namespace
    (my $method = $AUTOLOAD) =~ s/.*:://;
	
    if (my $rel = $self->{cur_table}{has_many}{$method}) {
        my $new_self = $self->inner_join($rel->[0], $rel->[1])->select("$method.*");
        $new_self->{cur_table} = $self->{dbix_lite}->schema->table($rel->[0]);
        bless $new_self, $new_self->{cur_table}->resultset_class || __PACKAGE__;
        return $new_self;
    }
    
    croak "No $method method is provided by this " . ref($self) . " object";
}

sub DESTROY {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Lite::ResultSet

=head1 VERSION

version 0.34

=head1 OVERVIEW

This class is not supposed to be instantiated manually. You usually get your 
first ResultSet object by calling the C<table()> method on your L<DBIx::Lite>
object:

    my $books_rs = $dbix->table('books');

and then you can chain methods on it to build your query:

    my $old_books_rs = $books_rs
        ->search({ year => { '<' => 1920 } })
        ->order_by('year');

=head1 BUILDING THE QUERY

=head2 search

This method accepts a search condition using the L<SQL::Abstract> syntax and 
returns a L<DBIx::Lite::ResultSet> object with the condition applied.

    my $young_authors_rs = $authors_rs->search({ age => { '<' => 18 } });

Multiple C<search()> methods can be chained; they will be merged using the
C<AND> operator:

    my $rs = $books_rs->search({ year => 2012 })->search({ genre => 'philosophy' });

=head2 clear_search

This method returns a L<DBIx::Lite::ResultSet> object based on the current one
but with no search conditions.

=head2 select

This method accepts a list of column names to retrieve. The default is C<*>, so
all columns will be retrieved. It returns a L<DBIx::Lite::ResultSet> object to 
allow for further method chaining.

    my $rs = $books_rs->select('title', 'year');

If you want to rename a column, pass it as an arrayref:

    my $rs = $books_rs->select(['title' => 'book_title'], 'year');
    # SELECT title AS book_title, year FROM books ...

=head2 select_also

This method works like L<select> but it adds the passed columns to the ones already
selected. It is useful when joining:

    my $books_authors_rs = $books_rs
        ->left_join('authors', { author_id => 'id' })
        ->select_also(['authors.name' => 'author_name']);

=head2 order_by

This method accepts a list of columns for sorting. It returns a L<DBIx::Lite::ResultSet>
object to allow for further method chaining.
Columns can be prefixed with C<+> or C<-> to indicate sorting direction (C<+> is C<ASC>,
C<-> is C<DESC>) or they can be expressed using the L<SQL::Abstract> syntax
(C<<{-asc => $column_name}>>).

    my $rs = $books_rs->order_by('year');
    my $rs = $books_rs->order_by('+genre', '-year');

=head2 group_by

This method accepts a list of columns to insert in the SQL C<GROUP BY> clause.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $dbix
        ->table('books')
        ->select('genre', \ 'COUNT(*)')
        ->group_by('genre');

=head2 having

This method accepts a search condition to insert in the SQL C<HAVING> clause
(in combination with L<group_by>).
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $dbix
        ->table('books')
        ->select('genre', \ 'COUNT(*)')
        ->group_by('genre')
        ->having({ year => 2012 });

=head2 limit

This method accepts a number of rows to insert in the SQL C<LIMIT> clause (or whatever
your RDBMS dialect uses for that purpose). See the L<page> method too if you want an
easier interface for pagination.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $books_rs->limit(5);

=head2 offset

This method accepts the index of the first row to retrieve; it will be used in the SQL
C<OFFSET> clause (or whatever your RDBMS dialect used for that purpose).
See the L<page> method too if you want an easier interface for pagination.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $books_rs->limit(5)->offset(10);

=head2 distinct

This method sets the DISTINCT flag in the SQL query. To turn if off again, pass a false
value.

    my $authors = $dbix->table('authors')->select('name')->distinct;

=head2 for_update

This method accepts no argument. It enables the addition of the SQL C<FOR UPDATE>
clause at the end of the query, which allows to fetch data and lock it for updating.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.
Note that no records are actually locked until the query is executed with L<single()>,
L<all()> or L<next()>.

    $dbix->txn(sub {
        my $author = $dbix->table('authors')->find($id)->for_update->single
            or die "Author not found";
        
        $author->update({ age => 30 });
    });

This is actually a shortcut for the L<for> method described below:

    my $authors = $dbix->table('authors')->for('UPDATE');

=head2 for

This method accepts a string which will be appended to the C<FOR> keyword at the end
of the SQL query.

    my $authors = $dbix->table('authors')->for('UPDATE SKIP LOCKED');

=head2 inner_join

This method accepts the name of a column to join and a set of join conditions.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $books_rs->inner_join('authors', { author_id => 'id' });

The second argument (join conditions) is a normal search hashref like the one supported
by L<search> and L<SQL::Abstract>. However, values are assumed to be column names instead
of actual values.
Unless you specify your own table aliases using the dot notation, the hashref keys are
considered to be column names belonging to the left table and the hashref values are
considered to be column names belonging to the joined table:

    my $rs = $books_rs->inner_join($other_table, { $my_column => $other_table_column });

In the above example, we're selecting from the I<books> table to the I<authors> table, so 
the join condition maps I<my> C<author_id> column to I<their> C<id> column.
In order to use more sophisticated join conditions you can use the normal SQL::Abstract 
syntax including literal SQL:

    my $rs = $books_rs->inner_join('authors', { author_id => 'id', 'authors.age' => { '<' => $age } });
    my $rs = $books_rs->inner_join('authors', { author_id => 'id', 'authors.age' => \"< 18" });

The third, optional, argument can be a hashref with options. The only supported one
is currently I<prevent_duplicates>: set this to true to have DBIx::Lite check whether
you already joined the same table in this query. If you did, this join will be skipped:

    my $rs = $books_rs->inner_join('authors', { author_id => 'id' }, { prevent_duplicates => 1 });

If you want to specify a table alias, just supply an arrayref. In this case, the
I<prevent_duplicates> option will only check whether the supplied table alias was already
used, thus allowing to join the same table multiple times using different table aliases.

    my $rs = $books_rs->inner_join(['authors' => 't1'], { author_id => 'id' });

=head2 left_join

This method works like L<inner_join> except it applies a C<LEFT JOIN> instead of an
C<INNER JOIN>.

=head2 clear_joins

This method returns a L<DBIx::Lite::ResultSet> object based on the current one
but with no joins.

=head2 with

This method accepts a hash of CTE definitions supported by PostgreSQL and other
RDBMS. Definitions can be supplied as scalar refs or refs to arrayrefs:

    my $authors = $dbix->table('authors')->with(
        t  => \"SELECT * FROM foo",
        t2 => \"SELECT * FROM bar",
    );
    # The above will produce:
    # WITH (t AS (SELECT * FROM foo), t2 AS (SELECT * FROM bar))
    # SELECT * FROM authors
    
    my $authors = $dbix->table('authors')
        ->with(t => \["SELECT * FROM foo WHERE bar = ?", $bindval]);
    
    my $authors = $dbix->table('authors')
        ->with(t => \[ $dbix->table('foo')->select_sql ]);

Subsequent calls to this method will replace the entire with block.

=head2 with_also

This methods works like L<with> but it adds CTEs to the list instead of 
replacing the existing ones (except when the same alias is reused).

=head2 from

This method allows to replace the C<FROM> expression in order to use
subqueries or CTEs.

    my $books = $dbix->table('books')
        ->with(t => \[ $dbix->table('books')->select_sql ])
        ->from('t');

If you supply a scalarref, it will be treated like literal SQL.

Usage of L<from> is not currently compatible with joins.

=head1 RETRIEVING RESULTS

=head2 all

This method will execute the C<SELECT> query and will return a list of 
L<DBIx::Lite::Row> objects.

    my @books = $books_rs->all;

=head2 single

This method will execute the C<SELECT> query and will return a L<DBIx::Lite::Row> 
object populated with the first row found; if none is found, undef is returned.

    my $book = $dbix->table('books')->search({ id => 20 })->single;

=head2 find

This method is a shortcut for L<search> and L<single>. The following statement
is equivalent to the one in the previous example:

    my $book = $dbix->table('books')->find({ id => 20 });

If you specified a primary key for the table (see the docs for L<DBIx::Lite::Schema>)
you can just pass its value(s) to C<find>:

    $dbix->schema->table('books')->pk('id');
    my $book = $dbix->table('books')->find(20);

=head2 count

This method will execute a C<SELECT COUNT(*)> query and will return the resulting 
number.

    my $book_count = $books_rs->count;

=head2 next

This method is a convenient iterator to retrieve your results efficiently without 
loading all of them in memory.

    while (my $book = $books_rs->next) {
        ...
    }

Note that you have to store your query before iteratingm like in the example above.
The following syntax will always retrieve just the first row in an endless loop:

    while (my $book = $dbix->table('books')->next) {
        ...
    }

=head2 column_names

This method returns a list of column names.
It returns array on list context and array reference on scalar context.

    my @book_columns = $books_rs->column_names;
    my $book_columns = $books_rs->column_names; # array reference

=head2 get_column

This method accepts a column name to fetch. It will execute a C<SELECT> query to
retrieve that column only and it will return a list with the values.

    my @book_titles = $books_rs->get_column('title');

=head2 single_value

This method returns the value of the first cell of the first row. It's useful in
situations like this:

    my $max = $books_rs->select(\"MAX(pages)")->single_value;

=head1 MANIPULATING ROWS

=head2 insert

This method accepts a hashref with column values to pass to the C<INSERT> SQL command.
It returns the inserted L<DBIx::Lite::Row> object (note that the returned object will 
not contain any value set as default by your RDBMS such as ones populated by triggers).
If you specified an autoincrementing primary key for this table and your database driver
is supported, L<DBIx::Lite> will retrieve such value and populate the resulting object 
accordingly.

    my $book = $dbix
        ->table('books')
        ->insert({ name => 'Camel Tales', year => 2012 });

Note that joins have no effect on C<INSERT> commands and DBIx::Lite will throw a warning.

=head2 find_or_insert

This method works like L<insert> but it will perform a L<find> search to check that
no row already exists for the supplied column values. If a row is found it is returned,
otherwise a SQL C<INSERT> is performed and the inserted row is returned.

    my $book = $dbix
        ->table('books')
        ->find_or_insert({ name => 'Camel Tales', year => 2012 });

=head2 update

This method accepts a hashref with column values to pass to the C<UPDATE> SQL command.
It returns the number of affected rows.

    $dbix->table('books')
        ->search({ year => { '<' => 1920 } })
        ->update({ very_old => 1 });

=head2 delete

This method performs a C<DELETE> SQL command. It returns the number of affected rows.

    $books_rs->delete;

=head2 select_sql

This method returns a list having the SQL C<SELECT> statement as the first item, 
and bind values as subsequent values. No query is executed. This method
also works when no C<$dbh> or connection data is supplied to L<DBIx::Lite>.

    my ($sql, @bind) = $books_rs->select_sql;

=head2 select_sth

This methods prepares the SQL C<SELECT> statement and returns it along with bind values.

    my ($sth, @bind) = $books_rs->select_sth;

=head2 insert_sql

This method works like L<insert> but it will just return a list having the SQL statement
as the first item, and bind values as subsequent values. No query is executed. This method
also works when no C<$dbh> or connection data is supplied to L<DBIx::Lite>.

    my ($sql, @bind) = $dbix
        ->table('books')
        ->insert_sql({ name => 'Camel Tales', year => 2012 });

=head2 insert_sth

This methods prepares the SQL C<INSERT> statement and returns it along with bind values.

   my ($sth, @bind) = $dbix
        ->table('books')
        ->insert_sth({ name => 'Camel Tales', year => 2012 });

=head2 update_sql

This method works like L<update> but it will just return a list having the SQL statement
as the first item, and bind values as subsequent values. No query is executed. This method
also works when no C<$dbh> or connection data is supplied to L<DBIx::Lite>.

    my ($sql, @bind) = $books_rs->update_sql({ genre => 'tennis' });

=head2 update_sth

This method prepares the SQL C<UPDATE> statement and returns it along with bind values.

    my ($sth, @bind) = $books_rs->update_sth({ genre => 'tennis' });

=head2 delete_sql

This method works like L<delete> but it will just return a list having the SQL statement
as the first item, and bind values as subsequent values. No query is executed. This method
also works when no C<$dbh> or connection data is supplied to L<DBIx::Lite>.

    my ($sql, @bind) = $books_rs->delete_sql;

=head2 delete_sth

This method prepares the SQL C<DELETE> statement and returns it along with bind values.

    my ($sth, @bind) = $books_rs->delete_sth;

=head2 where_sql

This method generates just the C<WHERE> clause that you can embed in other statements.
It will return a list having the SQL string as the first item, and bind values as 
subsequent values. No query is executed. This method also works when no C<$dbh> or 
connection data is supplied to L<DBIx::Lite>.

    my ($sql, @bind) = $books_rs->where_sql;

=head1 PAGING

=head2 page

This method accepts a page number. It defaults to 0, meaning no pagination. First page
has index 1. Usage of this method implies L<limit> and L<offset>, so don't call them.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $books_rs->page(3);

=head2 rows_per_page

This method accepts the number of rows for each page. It defaults to 10, and it has
no effect unless L<page> is also called. The undef value means that all records will
be put on a single page.
It returns a L<DBIx::Lite::ResultSet> object to allow for further method chaining.

    my $rs = $books_rs->rows_per_page(50)->page(3);

=head2 pager

This method returns a L<Data::Page> object already configured for the current query.
Calling this method will execute a L<count> query to retrieve the total number of 
rows.

    my $rs = $books_rs->rows_per_page(50)->page(3);
    my $page = $rs->pager;
    printf "Showing results %d - %d (total: %d)\n",
        $page->first, $page->last, $page->total_entries;
    while (my $book = $rs->next) {
        ...
    }

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
