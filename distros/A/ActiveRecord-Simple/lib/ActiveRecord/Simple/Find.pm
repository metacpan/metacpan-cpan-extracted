package ActiveRecord::Simple::Find;

use 5.010;
use strict;
use warnings;
use vars qw/$AUTOLOAD/;

use Carp;
use Storable qw/freeze/;
use Module::Load;

use parent 'ActiveRecord::Simple';


our $MAXIMUM_LIMIT = 100_000_000_000;


sub new {
    my ($self_class, $class, @param) = @_;

    #my $self = $class->new();
    my $self = { class => $class };

    my $table_name = ($self->{class}->can('_get_table_name'))  ? $self->{class}->_get_table_name  : undef;
    my $pkey       = ($self->{class}->can('_get_primary_key')) ? $self->{class}->_get_primary_key : undef;

    $self->{prep_select_fields} //= [];
    $self->{prep_select_from}   //= [];
    $self->{prep_select_where}  //= [];

    my ($fields, $from, $where);

    if (!ref $param[0] && scalar @param == 1) {
        $fields = qq/"$table_name".*/;
        $from   = qq/"$table_name"/;
        $where  = qq/"$table_name"."$pkey" = ?/;

        $self->{BIND} = \@param
    }
    elsif (!ref $param[0] && scalar @param == 0) {
        $fields = qq/"$table_name".*/;
        $from   = qq/"$table_name"/;

        $self->{BIND} = undef;
    }
    elsif (ref $param[0] && ref $param[0] eq 'HASH') {
        # find many by params
        my ($where_str, @bind, @condition_pairs);
        for my $param_name (keys %{ $param[0] }) {
            if (ref $param[0]{$param_name} eq 'ARRAY') {
                my $instr = join q/, /, map { '?' } @{ $param[0]{$param_name} };
                push @condition_pairs, qq/"$table_name"."$param_name" IN ($instr)/;
                push @bind, @{ $param[0]{$param_name} };
            }
            elsif (ref $param[0]{$param_name}) {
                next if !$class->can('_get_relations');
                my $relation = $class->_get_relations->{$param_name} or next;

                next if $relation->{type} ne 'one';
                my $fk = $relation->{params}{fk};
                my $pk = $relation->{params}{pk};

                my $object = $param[0]{$param_name};

                push @condition_pairs, qq/"$table_name"."$fk" = ?/;
                push @bind, $object->$pk;
            }
            else {
                if (defined $param[0]{$param_name}) {
                    push @condition_pairs, qq/"$table_name"."$param_name" = ?/;
                    push @bind, $param[0]{$param_name};
                }
                else {
                    # is NULL
                    push @condition_pairs, qq/"$table_name"."$param_name" IS NULL/;
                }
            }
        }
        $where_str = join q/ AND /, @condition_pairs;

        $fields = qq/"$table_name".*/;
        $from   = qq/"$table_name"/;
        $where  = $where_str;

        $self->{BIND} = \@bind;
    }
    elsif (ref $param[0] && ref $param[0] eq 'ARRAY') {
        # find many by primary keys
        my $whereinstr = join ', ', @{ $param[0] };

        $fields = qq/"$table_name".*/;
        $from   = qq/"$table_name"/;
        $where  = qq/"$table_name"."$pkey" IN ($whereinstr)/;

        $self->{BIND} = undef;
    }
    else {
        # find many by condition
        my $wherestr = shift @param;

        $fields = qq/"$table_name".*/;
        $from   = qq/"$table_name"/;
        $where  = $wherestr;

        $self->{BIND} = \@param;
    }

    push @{ $self->{prep_select_fields} }, $fields if $fields;
    push @{ $self->{prep_select_from} }, $from if $from;
    push @{ $self->{prep_select_where} }, $where if $where;

    return bless $self, $self_class;
}

sub count {
    my ($self_class, $class, @param) = @_;

    my $self = bless {}, $self_class;
    my $table_name = $class->_get_table_name;
    my ($count, $sql, @bind);
    if (scalar @param == 0) {
        $self->{SQL} = qq/SELECT COUNT(*) FROM "$table_name"/;
    }
    elsif (scalar @param == 1) {
        my $params_hash = shift @param;
        return unless ref $params_hash eq 'HASH';

        my @condition_pairs;
        for my $param_name (keys %$params_hash) {
            if (ref $params_hash->{$param_name} eq 'ARRAY') {
                my $instr = join q/, /, map { '?' } @{ $params_hash->{$param_name} };
                push @condition_pairs, qq/"$table_name"."$param_name" IN ($instr)/;
                push @bind, @{ $params_hash->{$param_name} };
            }
            elsif (ref $params_hash->{$param_name}) {
                next if !$class->can('_get_relations');
                my $relation = $class->_get_relations->{$param_name} or next;

                next if $relation->{type} ne 'one';
                my $fk = $relation->{params}{fk};
                my $pk = $relation->{params}{pk};

                my $object = $params_hash->{$param_name};

                push @condition_pairs, qq/"$table_name"."$fk" = ?/;
                push @bind, $object->$pk;
            }
            else {
                push @condition_pairs, qq/"$table_name"."$param_name" = ?/;
                push @bind, $params_hash->{$param_name};
            }
        }
        my $wherestr = (scalar @condition_pairs > 0 ) ? ' WHERE ' . join(q/ AND /, @condition_pairs) : '';
        $self->{SQL} = qq/SELECT COUNT(*) FROM "$table_name" $wherestr/;
    }
    elsif (scalar @param > 1) {
        my $wherestr = shift @param;
        @bind = @param;

        $self->{SQL} = qq/SELECT COUNT(*) FROM "$table_name" WHERE $wherestr/;
    }
    $self->_quote_sql_stmt;
    $count = $self->dbh->selectrow_array($self->{SQL}, undef, @bind);

    return $count;
}

sub first {
    my ($self_class, $class, $limit) = @_;

    $class->can('_get_primary_key') or croak 'Can\'t use "first" without primary key';
    my $primary_key = $class->_get_primary_key;
    $limit //= 1;

    return $self_class->new($class)->order_by($primary_key)->limit($limit);
}

sub last {
    my ($self_class, $class, $limit) = @_;

    $class->can('_get_primary_key') or croak 'Can\'t use "first" without primary key';
    my $primary_key = $class->_get_primary_key;
    $limit //= 1;

    return $self_class->new($class)->order_by($primary_key)->desc->limit($limit);
}

sub only {
    my ($self, @fields) = @_;

    scalar @fields > 0 or croak 'Not defined fields for method "only"';
    ref $self or croak 'Create an object abstraction before using the modifiers. Use methods like `find`, `first`, `last` at the beginning';

    if ($self->{class}->can('_get_primary_key')) {
        my $pk = $self->{class}->_get_primary_key;
        push @fields, $pk if ! grep { $_ eq $pk } @fields;
    }

    my $table_name = $self->{class}->_get_table_name;

    my @filtered_prep_select_fields =
        grep { $_ ne qq/"$table_name".*/ } @{ $self->{prep_select_fields} };
    push @filtered_prep_select_fields, map { qq/"$table_name"."$_"/ } @fields;
    $self->{prep_select_fields} = \@filtered_prep_select_fields;

    return $self;
}

# alias to only:
sub fields { shift->only(@_) }

sub order_by {
    my ($self, @param) = @_;

    #return if not defined $self->{SQL}; ### TODO: die
    return $self if exists $self->{prep_order_by};

    $self->{prep_order_by} = \@param;

    return $self;
}

sub desc {
    my ($self) = @_;

    #return if not defined $self->{SQL};
    return $self if exists $self->{prep_desc};

    $self->{prep_desc} = 1;

    return $self;
}

sub asc {
    my ($self, @param) = @_;

    #return if not defined $self->{SQL};
    return $self if exists $self->{prep_asc};

    $self->{prep_asc} = 1;

    return $self;
}

sub limit {
    my ($self, $limit) = @_;

    #return if not defined $self->{SQL};
    return $self if exists $self->{prep_limit};

    $self->{prep_limit} = $limit; ### TODO: move $limit to $self->{BIND}

    return $self;
}

sub offset {
    my ($self, $offset) = @_;

    #return if not defined $self->{SQL};
    return $self if exists $self->{prep_offset};

    $self->{prep_offset} = $offset; ### TODO: move $offset to $self->{BIND}

    return $self;
}

sub abstract {
    my ($self, $opts) = @_;

    return $self if ! ref $opts && ref $opts ne 'HASH';

    while (my ($method, $param) = each %$opts) {
        my @p = (ref $param) ? @$param : ($param);
        $self->$method(@p);
    }

    return $self;
}

sub select {
    my ($self_class, $class, @params) = @_;

    my @find_params;
    my $abstract_params_hashref;

    my $first_param = shift @params;
    push @find_params, $first_param if defined $first_param;

    for my $param (@params) {
        #push @find_params, $param if ref $param ne 'HASH';
        if (ref $param eq 'HASH') {
            $abstract_params_hashref = $param;
            last;
        }
        else {
            push @find_params, $param;
        }
    }

    my $finder = $self_class->new($class, @find_params);
    $finder->abstract($abstract_params_hashref);

    return $finder->fetch;
}


sub _finish_sql_stmt {
    my ($self) = @_;

    ref $self->{prep_select_fields} or croak 'Invalid prepare SQL statement';
    ref $self->{prep_select_from}   or croak 'Invalid prepare SQL statement';

    $self->{SQL} = "SELECT " . (join q/, /, @{ $self->{prep_select_fields} }) . "\n";
    $self->{SQL} .= "FROM " . (join q/, /, @{ $self->{prep_select_from} }) . "\n";

    if (defined $self->{prep_left_joins}) {
        $self->{SQL} .= "$_\n" for @{ $self->{prep_left_joins} };
        $self->{has_joined_table} = 1;
    }

    if (
        defined $self->{prep_select_where}
        && ref $self->{prep_select_where} eq 'ARRAY'
        && scalar @{ $self->{prep_select_where} } > 0
    ) {
        $self->{SQL} .= "WHERE\n";
        $self->{SQL} .= join " AND ", @{ $self->{prep_select_where} };
    }

    if (defined $self->{prep_order_by}) {
        $self->{SQL} .= ' ORDER BY ';
        $self->{SQL} .= join q/, /, map { q/"/.$_.q/"/ } @{ $self->{prep_order_by} };
    }

    $self->{SQL} .= ' DESC ' if defined $self->{prep_desc};
    $self->{SQL} .= ' ASC '  if defined $self->{prep_asc};

    $self->{SQL} .= ' LIMIT ' .  ($self->{prep_limit}  // $MAXIMUM_LIMIT);
    $self->{SQL} .= ' OFFSET '.  ($self->{prep_offset} // 0);

    #$self->_delete_keys(qr/^prep\_/);
}

#sub get {
#    my ($class, $pkeyval) = @_;
#
#    return $class->find($pkeyval)->fetch();
#}

sub _finish_object_representation {
    my ($self, $obj, $object_data, $read_only) = @_;

    if ($self->{has_joined_table}) {
        RELATION:
        for my $rel_name (@{ $self->{with} }) {
            my $relation = $self->{class}->_get_relations->{$rel_name} or next RELATION;
            my %pairs = map { $_, $object_data->{$_} } grep { $_ =~ /^JOINED\_$rel_name\_/ } keys %$object_data;
            next RELATION unless %pairs;

            for my $key (keys %pairs) {
                my $val = delete $pairs{$key};
                $key =~ s/^JOINED\_$rel_name\_//;
                $pairs{$key} = $val;
            }
            $obj->{"relation_instance_$rel_name"} = $relation->{class}->new(\%pairs);
                        #bless \%pairs, $relation->{class};

            $obj->_delete_keys(qr/^JOINED\_$rel_name/);
        }

        delete $self->{has_joined_table};
    }

    $obj->{read_only} = 1 if defined $read_only;
    $obj->{snapshoot} = freeze($object_data) if $obj->can('_smart_saving_used') && $obj->_smart_saving_used;
    $obj->{isin_database} = 1;

    return $obj;
}

sub fetch {
    my ($self, $param) = @_;

    my ($read_only, $limit);
    if (ref $param eq 'HASH') {
        $limit     = $param->{limit};
        $read_only = $param->{read_only};
    }
    else {
        $limit = $param;
    }

    return $self->_get_slice($limit) if $self->{_objects};

    $self->_finish_sql_stmt();
    $self->_quote_sql_stmt();

    my $class = $self->{class};
    my $sth = $self->dbh->prepare($self->{SQL}) or croak $self->dbh->errstr;
    $sth->execute(@{ $self->{BIND} }) or croak $self->dbh->errstr;
    if (wantarray) {
        my @objects;
        my $i = 0;
        while (my $object_data = $sth->fetchrow_hashref()) {
            $i++;
            my $obj = $class->new($object_data);
            $self->_finish_object_representation($obj, $object_data, $read_only);
            push @objects, $obj;

            last if $limit && $i == $limit;
        }

        return @objects;
    }
    else {
        my $object_data = $sth->fetchrow_hashref() or return;
        my $obj = $class->new($object_data);
        $self->_finish_object_representation($obj, $object_data, $read_only);

        return $obj;
    }
}

sub next {
    my ($self) = @_;

    if (!$self->{_objects}) {
        my @objects = $self->fetch();
        $self->{_objects} = \@objects;
    }

    return (scalar @{ $self->{_objects} } > 0 ) ? $self->_get_slice($self->{_objects}) : undef;
}

sub with {
    my ($self, @rels) = @_;

    return $self if exists $self->{prep_left_joins};
    return $self unless @rels;

    $self->{class}->can('_get_relations')
        or die "Class doesn't have any relations";

    my $table_name = $self->{class}->_get_table_name;

    $self->{prep_left_joins} = [];
    $self->{with} = \@rels;
    RELATION:
    for my $rel_name (@rels) {
        my $relation = $self->{class}->_get_relations->{$rel_name}
            or next RELATION;

        next RELATION unless grep { $_ eq $relation->{type} } qw/one only/;
        my $rel_table_name = $relation->{class}->_get_table_name;

        my $rel_columns = $relation->{class}->_get_columns;

        #push @{ $self->{prep_select_fields} }, qq/"$rel_table_name".*/;
        push @{ $self->{prep_select_fields} },
            map { qq/"$rel_table_name"."$_" AS "JOINED_$rel_name\_$_"/  }
                @{ $relation->{class}->_get_columns };

        if ($relation->{type} eq 'one') {
            my $join_sql = qq/LEFT JOIN "$rel_table_name" ON /;
            $join_sql .= qq/"$rel_table_name"."$relation->{params}{pk}"/;
            $join_sql .= qq/ = "$table_name"."$relation->{params}{fk}"/;

            push @{ $self->{prep_left_joins} }, $join_sql;
        }
    }

    return $self;
}

sub left_join { shift->with(@_) }

sub to_sql {
    my ($self) = @_;

    $self->_finish_sql_stmt();
    $self->_quote_sql_stmt();

    return wantarray ? ($self->{SQL}, $self->{BIND}) : $self->{SQL};
}


### Private

sub _find_many_to_many {
    my ($self_class, $class, $param) = @_;

    return unless $self_class->dbh && $class && $param;

    my $mc_fkey;
    my $class_opts = {};
    my $root_class_opts = {};

    eval { load $param->{m_class} };

    for my $opts ( values %{ $param->{m_class}->_get_relations } ) {
        if ($opts->{class} eq $param->{root_class}) {
            $root_class_opts = $opts;
        }
        elsif ($opts->{class} eq $class) {
            $class_opts = $opts;
        }
    }

    my $self = bless {
        prep_select_fields => [],
        prep_select_from   => [],
        prep_select_where  => [],
        class => $class,
    }, $self_class;

    my $connected_table_name = $class->_get_table_name;
    push @{ $self->{prep_select_from} }, $param->{m_class}->_get_table_name;
    push @{ $self->{prep_select_fields} }, '*';

    push @{ $self->{prep_left_joins} },
        'JOIN ' . $connected_table_name . ' ON ' . $connected_table_name . '.' . $class->_get_primary_key . ' = '
            . $param->{m_class}->_get_table_name . '.' . $class_opts->{params}{fk};

    push @{ $self->{prep_select_where} },
        $root_class_opts->{params}{fk} . ' = ' . $param->{self}->{ $param->{root_class}->_get_primary_key };

    return $self;
}

sub _find_many_to_many_OLD {
    my ($self_class, $class, $param) = @_;

    return unless $self_class->dbh && $class && $param;

    my $mc_fkey;
    my $class_opts = {};
    my $root_class_opts = {};

    eval { load $param->{m_class} };

    for my $opts ( values %{ $param->{m_class}->_get_relations } ) {
        if ($opts->{class} eq $param->{root_class}) {
            $root_class_opts = $opts;
        }
        elsif ($opts->{class} eq $class) {
            $class_opts = $opts;
        }
    }

    my $connected_table_name = $class->_get_table_name;
    my $sql_stm;
    $sql_stm .=
        'SELECT ' .
        "$connected_table_name\.*" .
        ' FROM ' .
        $param->{m_class}->_get_table_name .
        ' JOIN ' .
        $connected_table_name .
        ' ON ' .
        $connected_table_name . '.' . $class->_get_primary_key .
        ' = ' .
        $param->{m_class}->_get_table_name . '.' . $class_opts->{params}{fk} .
        ' WHERE ' .
        $root_class_opts->{params}{fk} .
        ' = ' .
        $param->{self}->{ $param->{root_class}->_get_primary_key };

    my $self = bless {}, $self_class;
    $self->{SQL} = $sql_stm; $self->_quote_sql_stmt;

    say 'SQL: ' . $self->{SQL};

    my $sth = $self->dbh->prepare($self->{SQL}) or croak $self->dbh->errstr;
    $sth->execute();

    delete $self->{SQL};

    my @bulk_objects;
    while (my $params = $sth->fetchrow_hashref) {
        my $obj = $class->new($params);
        $obj->{isin_database} = 1;
        push @bulk_objects, $obj;
    }

    $self->{_objects} = \@bulk_objects;
    $self->{class} = $class;\

    return $self;
}

sub _get_slice {
    my ($self, $time) = @_;

    return unless $self->{_objects}
        && ref $self->{_objects} eq 'ARRAY'
        && scalar @{ $self->{_objects} } > 0;

    if (wantarray) {
        $time ||= scalar @{ $self->{_objects} };
        return splice @{ $self->{_objects} }, 0, $time;
    }
    else {
        return shift @{ $self->{_objects} };
    }
}

sub _quote_sql_stmt {
    my ($self) = @_;

    return unless $self->{SQL} && $self->dbh;

    my $driver_name = $self->dbh->{Driver}{Name};
    $driver_name //= 'Pg';
    my $quotes_map = {
        Pg => q/"/,
        mysql => q/`/,
        SQLite => q/`/,
    };
    my $quote = $quotes_map->{$driver_name};

    $self->{SQL} =~ s/"/$quote/g;

    return 1;
}

sub AUTOLOAD {
    my $call = $AUTOLOAD;
    my $self = shift;
    my $class = ref $self;

    $call =~ s/.*:://;
    my $error = "Can't call method `$call` on class $class.\nPerhaps you have forgotten to fetch your object?";

    croak $error;
}

1;


