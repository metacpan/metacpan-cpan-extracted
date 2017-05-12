package DBIx::ObjectMapper::Session::Search;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Log::Any qw($log);
use List::MoreUtils;
use DBIx::ObjectMapper::Iterator;

sub new {
    my $class = shift;
    my ( $uow, $mapped_class, $option ) = @_;

    bless {
        mapped_class     => $mapped_class,
        unit_of_work     => $uow,
        option           => $option,
        is_multi         => 0,
        filter           => [],
        lazy             => [],
        eager            => [],
        order_by         => [],
        group_by         => [],
        joined_table     => {},
        eager_table      => {},
        join             => [],
        limit            => undef,
        offset           => undef,
        add_lazy_column  => [],
        with_polymorphic => [],
    }, $class;
}

sub unit_of_work { $_[0]->{unit_of_work} }
sub mapper       { $_[0]->{mapped_class}->__class_mapper__ }

sub with_polymorphic {
    my $self = shift;
    my @classes = @_;
    my @tree = $self->mapper->get_polymorphic_tree;

    my @child_poly;
    if( grep { $_ eq '*' } @classes ) {
        push @{$self->{with_polymorphic}}, @tree;
    }
    else {
        my %classes = map { $_ => 1 } @classes;
        for my $t ( @tree ) {
            if( $classes{$t->[0]} ) {
                push @{$self->{with_polymorphic}}, $t;
            }
        }
    }

    return $self;
}

sub _via {
    my ( $self, $table, $attr, $depth, @via ) = @_;

    my $target    = $via[$depth];
    my $alias     = join( '_', @via[ 0 .. $depth ] );
    my $rel       = $attr->property($target);
    my $rel_table = $rel->table->clone($alias);

    unless( $self->{joined_table}{$alias} ) {
        my @rel_cond  = $rel->relation_condition( $table, $rel_table );
        if( $rel->type eq 'many_to_many' ) {
            my ( $relation_cond, $associate_cond ) = @rel_cond;
            @rel_cond = @$relation_cond;
            push @{ $self->{join} }, $associate_cond;
        }

        push @{ $self->{join} }, [ $rel_table => \@rel_cond ];
        $self->{is_multi} = 1 if $rel->is_multi;
        $self->{joined_table}{$alias} = $rel;
    }

    if ( $depth < $#via ) {
        return $self->_via( $rel_table, $rel, ++$depth, @via );
    }
    else {
        return $alias;
    }
}

sub filter {
    my $self = shift;

    my @filters;
    for my $filter ( @_ ) {
        if( my $r_filter = $self->_filter($filter) ) {
            push @filters, $r_filter;
        }
    }
    push @{$self->{filter}}, @filters;

    return $self;
}

sub _filter {
    my ( $self, $filter ) = @_;
    if( ref $filter eq 'ARRAY' ) {
        my ( $col, $op, $val ) = @$filter;
        if( $col->{via} and my @via = @{$col->{via}} ) {
            my $alias = $self->_via(
                $self->mapper->table,
                $self->mapper->attributes,
                0,
                @via
            );
            return [ $col->as_alias($alias), $op, $val ];
        }
        else {
            return $filter;
        }
    }
    elsif( ref $filter eq 'HASH' ) {
        my %filters;
        for my $k ( keys %$filter ) {
            $filters{$k} = [ map { $self->_filter($_) } @{$filter->{$k}} ];
        }
        return \%filters;
    }
    else {
        return $filter;
    }
}

sub eager {
    my $self = shift;

    my @eager_column;
    for my $eager ( @_ ) {
        if ( $eager->isa('DBIx::ObjectMapper::Relation') ) {
            if( $eager->{via} and my @via = @{$eager->{via}} ) {
                my $alias = $self->_via(
                    $self->mapper->table,
                    $self->mapper->attributes,
                    0,
                    @via
                );

                push @eager_column, @{$eager->table->clone($alias)->columns};
                $self->{eager_table}->{$alias} = 1;
                if( my @eager_cond = @{$eager->mapper->default_condition} ) {
                    for my $cond ( @eager_cond ) {
                        my ( $col, $op, $val ) = @$cond;
                         push @{$self->{filter}},
                             [ $col->as_alias($alias), $op, $val ];
                    }
                }
            }
            else {
                push @eager_column, $eager->mapper->load_properties;
            }
        }
        else {
            push @eager_column, $eager;
        }
    }

    push @{$self->{eager}}, @eager_column if @eager_column;
    return $self;
}

*eagerload = \&eager;

sub lazy {
    my $self = shift;

    my @lazy_column;
    for my $lazy ( @_ ) {
        unless ( $lazy->isa('DBIx::ObjectMapper::Relation') ) {
            push @lazy_column, $lazy;
        }
    }

    push @{$self->{lazy}}, @lazy_column if @lazy_column;
    return $self;
}

*lazyload = \&lazy;

{
    no strict 'refs';
    my $pkg = __PACKAGE__;

    for my $meth ( qw( order_by group_by ) ) {
        *{"$pkg\::$meth"} = sub {
            my $self = shift;
            push @{$self->{$meth}}, @_;
            return $self;
        };
    }

    for my $meth ( qw(limit offset) ) {
        *{"$pkg\::$meth"} = sub {
            my $self = shift;
            $self->{$meth} = shift;
            return $self;
        };
    }
};

sub _finalize {
    my $self  = shift;
    my $query = $self->mapper->select;

    my $is_eager = 0;
    my @group_by = @{$self->{group_by}};

    my @where = @{$self->mapper->default_condition};
    push @where, @{ $self->{filter} } if @{ $self->{filter} };
    $query->add_where( @where ) if @where;

    my @join;
    if( @{ $self->{join} } ) {
        push @join, @{ $self->{join} };
        if( $self->{is_multi} and !@{$self->{eager}} ) {
            push @group_by, $self->mapper->load_properties;
        }
    }

    my @column = $self->mapper->load_properties;
    if( @{ $self->{eager} } ) {
        push @column, @{ $self->{eager} };
    }

    my @column_tmp = @column;
    for my $lazy ( @{ $self->{lazy} } ) {
        for my $i ( 0 .. $#column_tmp ) {
            my $col = $column[$i];
            if( $lazy->name eq $col->name and $lazy->table eq $col->table ) {
                splice(@column_tmp, $i, 1);
                push @{$self->{add_lazy_column}}, $col;
            }
        }
    }
    @column = @column_tmp;

    if( my @polymorphic = @{$self->{with_polymorphic}} ) {
        my %polymorphic_table;
        for my $p ( @polymorphic ) {
            my $mapper = $p->[0]->__class_mapper__;
            my $table  = $mapper->table;
            if( $table->{polymorphic_columns} ) {
                next if $polymorphic_table{$table->child_table};
                push @join, [ $table->child_table, $table->{rel_cond} ];
                push @column, @{$table->{polymorphic_columns}};
                $polymorphic_table{$table->child_table} = 1;
            }
            else {
                next if $polymorphic_table{$table};
                push @column, @{$table->columns};
                push @column, $table->c($mapper->polymorphic_on);
                $polymorphic_table{$table} = 1;
            }
        }
        @column = List::MoreUtils::uniq(@column);
    }

    $query->column(@column);
    $query->add_join(@join) if @join;
    $query->add_group_by(@group_by) if @group_by;
    $query->add_order_by(@{$self->{order_by}}) if @{$self->{order_by}};

    for my $meth (qw(limit offset)) {
        $query ->${meth}( $self->{$meth} ) if $self->{$meth};
    }

    return $query;
}

sub execute {
    my $self = shift;
    my $query = $self->_finalize;

    if( @{ $self->{eager} } and $self->{is_multi} ) {
        my $uow = $self->unit_of_work;
        if( $self->{limit} ) {
            # limitメソッドはeager_joinメソッドと一緒に使った場合、期待通りにならない可能性があります。
            cluck "There is a possibility of not becoming it according to the expectation when the limit method is used with the eager_join method.";
        }

        my $result = [];
        my $check  = +{};
        my %rel_cache_keys;
        $uow->{query_cnt}++;

        for my $r ( $query->execute->all ) {
            $self->_join_result_to_object($r);
            $self->_marge( $check, $result, $r, $self->mapper );
        }

        return DBIx::ObjectMapper::Iterator->new(
            $result,
            $query,
            sub {
                my $mapper = $self->get_mapper($_[0]);
                my $obj = $mapper->mapping( $_[0], $uow );
                push @{ $obj->__mapper__->{add_lazy_column} },
                    @{ $self->{add_lazy_column} };
                return $obj;
            }
        );
    }
    else {
        return $self->_exec_query( $query, 'execute' );
    }
}

sub get_mapper {
    my ( $self, $d ) = @_;

    my $mapper;
    if( my @polymorphic = @{$self->{with_polymorphic}} ) {
        for my $p ( @polymorphic ) {
            my ( $key, $val ) = @{$p->[1]};
            if( $key->table eq $self->mapper->table->table_name ) {
                if( defined $d->{$key->name} and $d->{$key->name} eq $val ) {
                    $mapper = $p->[0]->__class_mapper__;
                }
            }
            else {
                my $table_name = $key->table;
                if (    defined $d->{$table_name}
                    and defined $d->{$table_name}->{ $key->name }
                    and $d->{$table_name}->{ $key->name } eq $val )
                {
                    $mapper = $p->[0]->__class_mapper__;
                }
            }
            last if $mapper;
        }
    }

    $mapper ||= $self->mapper;

    $self->_shift_inherit_data($mapper->table, $d);
    return $mapper;
}

sub _shift_inherit_data {
    my ( $self, $table, $d ) = @_;
    if( $table->{polymorphic_columns} ) {
        my $child_table = $table->child_table->table_name;
        $d->{$_} = $d->{$child_table}->{$_}
            for keys %{ $d->{$child_table} };
        delete $d->{$child_table};
        $self->_shift_inherit_data($table->parent_table, $d);
    }
}

sub _exec_query {
    my ( $self, $query, $meth ) = @_;
    my $uow = $self->unit_of_work;
    my $orig_callback = $query->callback;
    my $is_eager = @{$self->{eager}};
    local $query->{callback} = sub {
        my $result = $orig_callback->(@_);
        $self->_join_result_to_object($result) if $is_eager;
        my $mapper = $self->get_mapper($result);
        my $obj = $mapper->mapping( $result, $uow );
        push @{ $obj->__mapper__->{add_lazy_column} },
            @{ $self->{add_lazy_column} };
        return $obj;
    };
    $self->unit_of_work->{query_cnt}++;
    return $query->$meth;
}

sub first {
    my $self = shift;
    if( @{ $self->{eager} } and $self->{is_multi} ) {
        return $self->execute->first;
    }
    else {
        return $self->_exec_query( $self->_finalize, 'first' );
    }
}

sub page {
    my $self = shift;
    if( @{ $self->{eager} } and $self->{is_multi} ) {
        confess "the page method is not suppurted with eagerloading.";
    }
    elsif( !$self->{limit} ) {
        confess "the page method requies limit number.";
    }
    else {
        my $query = $self->_finalize;
        my $pager = $query->pager(@_);
        my $it    = $self->_exec_query( $query, 'execute' );
        return ( $it, $pager );
    }
}

sub count {
    my $self = shift;
    if( @{ $self->{eager} } and $self->{is_multi} ) {
        return $self->execute->size;
    }
    else {
        return $self->_exec_query( $self->_finalize, 'count' );
    }
}

sub _join_result_to_object {
    my ( $self, $r ) = @_;
    my $uow    = $self->unit_of_work;
    my $mapper = $self->mapper;
    for my $key ( reverse sort keys %{ $self->{eager_table} } ) {
        next unless $r->{$key};
        my $rel = $self->{joined_table}->{$key};
        my $obj = delete $r->{$key};
        my @via = @{$rel->{via}};
        my $data = $r;
        for my $depth ( 0 .. $#via ) {
            if( $depth == $#via ) {
                if( $rel->is_multi ) {
                    $data->{$via[$depth]} = [ $obj ];
                }
                else {
                    $data->{$via[$depth]} = $obj;
                }
            }
            else {
                $data = $r->{$via[$depth]};
            }
        }
    }
}

sub _marge {
    my ( $self, $check, $data, $input, $mapper, $name ) = @_;
    my $checkkey = $mapper->primary_cache_key($input) . ( $name || '' );

    if( exists $check->{$checkkey} ) {
        my $master = $data->[$check->{$checkkey}];
        for my $prop_name ( $mapper->attributes->property_names ) {
            my $prop = $mapper->attributes->property_info($prop_name) || next;
            my $next_key = $name ? $name . '_' . $prop_name : $prop_name;
            if ( exists $master->{$prop_name} and $prop->type eq 'relation'
                and ref( $master->{$prop_name} ) eq 'ARRAY' )
            {
                for ( @{ $input->{$prop_name} } ) {
                    $self->_marge(
                        $check,
                        $master->{$prop_name},
                        $_,
                        $prop->mapper,
                        $next_key
                    );
                }
            }
            elsif ( $self->{eager_table}->{$next_key}
                and $prop->type eq 'relation'
                and $prop->is_multi )
            {
                $input->{$prop_name} = [];
            }
        }
    }
    else {
        for my $prop_name ( $mapper->attributes->property_names ) {
            my $prop = $mapper->attributes->property_info($prop_name) || next;
            my $next_key = $name ? $name . '_' . $prop_name : $prop_name;
            if (    exists $input->{$prop_name}
                and ref( $input->{$prop_name} ) eq 'ARRAY'
                and $prop->type eq 'relation' )
            {
                for ( @{ $input->{$prop_name} } ) {
                    $self->_marge(
                        $check,
                        [],
                        $_,
                        $prop->mapper,
                        $next_key,
                    );
                }
            }
            elsif ( $self->{eager_table}->{$next_key}
                and $prop->type eq 'relation'
                and $prop->is_multi )
            {
                $input->{$prop_name} = [];
            }
        }

        push @$data, $input;
        $check->{$checkkey} = $#$data;
    }
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Session::Search

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

