package ActiveRecord::Simple::Find;

use 5.010;
use strict;
use warnings;
use vars qw/$AUTOLOAD/;

use Carp;

use parent 'ActiveRecord::Simple';

use ActiveRecord::Simple::Utils qw/load_module/;


our $MAXIMUM_LIMIT = 100_000_000_000;


sub new {
    my ($self_class, $class, @param) = @_;

    #my $self = $class->new();
    my $self = bless { class => $class } => $self_class;

    my $table_name = ($self->{class}->can('_get_table_name'))  ? $self->{class}->_get_table_name  : undef;
    my $pkey       = ($self->{class}->can('_get_primary_key')) ? $self->{class}->_get_primary_key : undef;

    croak 'can not get table_name for class ' . $self->{class} unless $table_name;
    #croak 'can not get primary_key for class ' . $self->{class} unless $pkey;

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
        my ($bind, $condition_pairs) = $self->_parse_hash($param[0]);

        my $where_str = join q/ AND /, @$condition_pairs;

        $fields = qq/"$table_name".*/;
        $from   = qq/"$table_name"/;
        $where  = $where_str;

        $self->{BIND} = $bind;
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

    return $self;
}

sub count {
    my $inv = shift;
    my $self = ref $inv ? $inv : $inv->new(@_);
    $self->{prep_select_fields} = [ 'COUNT(*)' ];
    if (@{ $self->{prep_group_by} || [] }) {
        my $table_name = $self->{class}->_get_table_name;
        push @{ $self->{prep_select_fields} }, map qq/"$table_name".$_/, @{ $self->{prep_group_by} };
        my @group_by = @{ $self->{prep_group_by} };
        s/"//g foreach @group_by;
        my @results;
        foreach my $item ($self->fetch) {
            push my @line, (count => $item->{'COUNT(*)'}), map { $_ => $item->{$_} } @group_by;
            push @results, { @line };
        }
        return @results;
    }
    else {
        return $self->fetch->{'COUNT(*)'};
    }
}

sub first {
    my ($self, $limit) = @_;

    $limit //= 1;

    $self->{class}->can('_get_primary_key') or croak 'Can\'t use "first" without primary key';
    my $primary_key = $self->{class}->_get_primary_key;

    return $self->order_by($primary_key)->limit($limit)->fetch;
}

sub last {
    my ($self, $limit) = @_;

    $self->{class}->can('_get_primary_key') or croak 'Can\'t use "first" without primary key';
    my $primary_key = $self->{class}->_get_primary_key;
    $limit //= 1;

    return $self->order_by($primary_key)->desc->limit($limit)->fetch;
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
    my $mixins = $self->{class}->can('_get_mixins') ? $self->{class}->_get_mixins : undef;

    my @filtered_prep_select_fields =
        grep { $_ ne qq/"$table_name".*/ } @{ $self->{prep_select_fields} };
    for my $fld (@fields) {
        if ($mixins && grep { $_ eq $fld } keys %$mixins) {
            my $mixin = $mixins->{$fld}->($self->{class});
            $mixin .= qq/ AS $fld/ unless $mixin =~ /as\s+\w+$/i;
            push @filtered_prep_select_fields, $mixin;
        }
        else {
            push @filtered_prep_select_fields, qq/"$table_name"."$fld"/;
        }
    }

    $self->{prep_select_fields} = \@filtered_prep_select_fields;

    return $self;
}

# alias to only:
sub fields { shift->only(@_) }

sub order_by {
    my ($self, @param) = @_;

    #return if not defined $self->{SQL}; ### TODO: die
    $self->{prep_order_by} ||= [];
    push @{$self->{prep_order_by}}, map qq/"$_"/, @param;
    delete $self->{prep_asc_desc};

    return $self;
}

sub desc {
    return shift->_order_by_direction('DESC');
}

sub asc {
    return shift->_order_by_direction('ASC');
}

sub group_by {
    my ($self, @param) = @_;

    $self->{prep_group_by} ||= [];
    push @{$self->{prep_group_by}}, map qq/"$_"/, @param;
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
        delete $self->{has_joined_table};

        return @objects;
    }
    else {
        my $object_data = $sth->fetchrow_hashref() or return;
        my $obj = $class->new($object_data);
        $self->_finish_object_representation($obj, $object_data, $read_only);
        delete $self->{has_joined_table};

        return $obj;
    }
}

sub upload {
    my ($self, $param) = @_;

    my $o = $self->fetch($param);
    $_[0] = $o;

    return $_[0];
}

sub next {
    my ($self, $n) = @_;

    $n ||= 1;

    $self->{prep_limit} = $n;
    $self->{prep_offset} = 0 unless defined $self->{prep_offset};
    my @result = $self->fetch;

    $self->{prep_offset} += $n;

    return wantarray ? @result : $result[0];
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

        REL_COLUMN:
        for (@$rel_columns) {
            next REL_COLUMN if ref $_;
            push @{ $self->{prep_select_fields} }, qq/"$rel_table_name"."$_" AS "JOINED_$rel_name\_$_"/;
        }

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

sub exists {
    my ($self) = @_;

    $self->{prep_select_fields} = ['1'];
    $self->_finish_sql_stmt;
    $self->_quote_sql_stmt;

    my $sth = $self->dbh->prepare($self->{SQL});
    $sth->execute(@{ $self->{BIND} });

    return $sth->fetchrow_arrayref();
}


### Private

sub _find_many_to_many {
    my ($self_class, $class, $param) = @_;

    return unless $self_class->dbh && $class && $param;

    my $mc_fkey;
    my $class_opts = {};
    my $root_class_opts = {};

    if ($param->{m_class}) {
        #eval { load $param->{m_class} };
        #if (!is_loaded $param->{m_class}) {
        #    load $param->{m_class};
        #    mark_as_loaded
        #}
        load_module $param->{m_class};


        for my $opts ( values %{ $param->{m_class}->_get_relations } ) {
            if ($opts->{class} eq $param->{root_class}) {
                $root_class_opts = $opts;
            }
            elsif ($opts->{class} eq $class) {
                $class_opts = $opts;
            }
        }

        my $self = $self_class->new($class, @{ $param->{where_statement} });

        my $connected_table_name = $class->_get_table_name;
        $self->{prep_select_from} = [ $param->{m_class}->_get_table_name ];

        push @{ $self->{prep_left_joins} },
            'JOIN ' . $connected_table_name . ' ON ' . $connected_table_name . '.' . $class->_get_primary_key . ' = '
                . $param->{m_class}->_get_table_name . '.' . $class_opts->{params}{fk};

        push @{ $self->{prep_select_where} },
            $root_class_opts->{params}{fk} . ' = ' . $param->{self}->{ $param->{root_class}->_get_primary_key };

        return $self;
    }
    else {
        my $self = $self_class->new($class, @{ $param->{where_statement} });

        my $connected_table_name = $class->_get_table_name;
        $self->{prep_select_from} = [ $param->{via_table} ];
        my $fk = ActiveRecord::Simple::Utils::class_to_table_name($class);
        $fk .= '_id';

        push @{ $self->{prep_left_joins} },
            'JOIN ' . $connected_table_name . ' ON ' . $connected_table_name . '.' . $class->_get_primary_key . ' = '
                . $param->{via_table} . '.' . $fk;

        my $fk2 = ActiveRecord::Simple::Utils::class_to_table_name($param->{root_class}) . '_id';

        push @{ $self->{prep_select_where} },
            $fk2 . ' = ' . $param->{self}->{ $param->{root_class}->_get_primary_key };

        return $self;
    }

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

    return $self;
}

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

            $obj->_delete_keys(qr/^JOINED\_$rel_name/);
        }

    }

    $obj->{read_only} = 1 if defined $read_only;
    $obj->{isin_database} = 1;

    return $obj;
}

sub _finish_sql_stmt {
    my ($self) = @_;

    ref $self->{prep_select_fields} or croak 'Invalid prepare SQL statement';
    ref $self->{prep_select_from}   or croak 'Invalid prepare SQL statement';

    my $table_name = $self->{class}->_get_table_name;
    my @add = grep { $_ !~~ $self->{prep_select_fields} } map qq/"$table_name".$_/, @{ $self->{prep_group_by}||[] };
    push @{ $self->{prep_select_fields} }, @add;

    $self->{SQL} = "SELECT " . (join q/, /, @{ $self->{prep_select_fields} }) . "\n";
    $self->{SQL} .= "FROM " . (join q/, /, @{ $self->{prep_select_from} }) . "\n";

    if (defined $self->{prep_left_joins}) {
        $self->{SQL} .= "$_\n" for @{ $self->{prep_left_joins} };
        $self->{has_joined_table} = 1;
    }

    if (@{ $self->{prep_select_where}||[] }) {
        $self->{SQL} .= "WHERE\n";
        $self->{SQL} .= join " AND ", @{ $self->{prep_select_where} };
    }

    if (@{ $self->{prep_group_by}||[] }) {
        $self->{SQL} .= ' GROUP BY ';
        $self->{SQL} .= join q/, /, @{ $self->{prep_group_by} };
    }

    if (@{ $self->{prep_order_by}||[] }) {
        $self->{SQL} .= ' ORDER BY ';
        $self->{SQL} .= join q/, /, @{ $self->{prep_order_by} };
    }

    $self->{SQL} .= ' LIMIT ' .  ($self->{prep_limit}  // $MAXIMUM_LIMIT);
    $self->{SQL} .= ' OFFSET '.  ($self->{prep_offset} // 0);

    return $self;
}

sub _parse_hash {
    my ($self, $param_hash) = @_;
    my $class = $self->{class};
    my $table_name = ($self->{class}->can('_get_table_name'))  ? $self->{class}->_get_table_name  : undef;
    my ($bind, $condition_pairs) = ([],[]);
    for my $param_name (keys %{ $param_hash }) {
        if (ref $param_hash->{$param_name} eq 'ARRAY' and !ref $param_hash->{$param_name}[0]) {
            my $instr = join q/, /, map { '?' } @{ $param_hash->{$param_name} };
            push @$condition_pairs, qq/"$table_name"."$param_name" IN ($instr)/;
            push @$bind, @{ $param_hash->{$param_name} };
        }
        elsif (ref $param_hash->{$param_name}) {
            next if !$class->can('_get_relations');
            my $relation = $class->_get_relations->{$param_name} or next;

            next if $relation->{type} ne 'one';
            my $fk = $relation->{params}{fk};
            my $pk = $relation->{params}{pk};

            if (ref $param_hash->{$param_name} eq __PACKAGE__) {
                my $object = $param_hash->{$param_name};

                my $tmp_table = qq/tmp_table_/ . sprintf("%x", $object);
                my $request_table = $object->{class}->_get_table_name;

                $object->{prep_select_fields} = [qq/"$request_table"."$pk"/];
                $object->_finish_sql_stmt;

                push @$condition_pairs, qq/"$table_name"."$fk" IN (SELECT "$tmp_table"."$pk" from ($object->{SQL}) as $tmp_table)/;
                push @$bind, @{ $object->{BIND} } if ref $object->{BIND} eq 'ARRAY';
            }
            else {
                my $object = $param_hash->{$param_name};

                if (ref $object eq 'ARRAY') {
                    push @$bind, map $_->$pk, @$object;
                    push @$condition_pairs, qq/"$table_name"."$fk" IN (@{[ join ', ', map "?", @$object ]})/;
                }
                else {
                    push @$condition_pairs, qq/"$table_name"."$fk" = ?/;
                    push @$bind, $object->$pk;
                }
            }
        }
        else {
            if (defined $param_hash->{$param_name}) {
                push @$condition_pairs, qq/"$table_name"."$param_name" = ?/;
                push @$bind, $param_hash->{$param_name};
            }
            else {
                # is NULL
                push @$condition_pairs, qq/"$table_name"."$param_name" IS NULL/;
            }
        }
    }
    return ($bind, $condition_pairs);
}

sub _order_by_direction {
    my ($self, $direction) = @_;

    # There are no fields for order yet
    return unless ref $self->{prep_order_by} eq 'ARRAY' and scalar @{ $self->{prep_order_by} } > 0;

    # asc/desc is called before: ->asc->desc
    return if defined $self->{prep_asc_desc};

    # $direction should be ASC/DESC
    return unless $direction =~ /^(ASC|DESC)$/i;

    # Add $direction to the latest field
    @{$self->{prep_order_by}}[-1] .= " $direction";
    $self->{prep_asc_desc} = 1;

    return $self;
}

sub DESTROY { }

sub AUTOLOAD {
    my $call = $AUTOLOAD;
    my $self = shift;
    my $class = ref $self;

    $call =~ s/.*:://;
    my $error = "Can't call method `$call` on class $class.\nPerhaps you have forgotten to fetch your object?";

    croak $error;
}

1;

__END__;


=head1 NAME

ActiveRecord::Simple::Find

=head1 DESCRIPTION

ActiveRecord::Simple is a simple lightweight implementation of ActiveRecord
pattern. It's fast, very simple and very light.

ActiveRecord::Simple::Find is a class to search, ordering, organize and fetch data from database.
It generates SQL-code and iteracts with DBI to execute it.

=head1 SYNOPSIS

my @customers = Customer->find({ name => 'Bill' })->fetch;
my @customers = Customer->find({ zip => [1001, 1002, 1003] })->fetch;
my @customers = Customer->find('age > ?', 21)->fetch;
my @customers = Customer->find([1, 2, 3, 4, 5])->order_by('id')->desc->fetch;


=head1 METHODS

L<ActiveRecord::Simple::Find> implements the following methods.

=head2 new

Object constructor, creates basic search pattern. Available from method "find"
of the base class:

    # SELECT * FROM log WHERE site_id = 1 AND level = 'error';
    my $f = Log->find({ id => 1, level => 'error' });

    # SELECT * FROM log WHERE site_id = 1 AND level IN ('error', 'warning');
    my $f = Log->find({ id => 1, level => ['error', 'warning'] });

    # SELECT * FROM customer WHERE age > 21;
    Customer->find('age > ?', 21);

    # SELECT * FROM customer WHERE id = 100;
    Customer->find(100);

    # SELECT * FROM customer WHERE id IN (100, 101, 191);
    Customer->find([100, 101, 191]);

=head2 last

Fetch last row from database:

    # get very last log:
    my $last_log = Log->find->last; 

    # get last error log of site number 1:
    my $last_log = Log->find({ level => 'error', site_id => 1 })->last;

=head2 first

Fetch first row:

    # get very first log:
    my $first_log = Log->find->first; 

    # get first error log of site number 1:
    my $first_log = Log->find({ level => 'error', site_id => 1 })->first;

=head2 count

Fetch number of records in the database:

    my $cnt = Log->find->count();
    my $cnt_warnings = Log->find({ level => 'warnings' })->count;

=head2 exists 

Check the record is exist:

    if (Log->find({ level => 'fatal' })->exists) {
        die "got fatal error log!";
    }

=head2 fetch

Fetch data from the database as objects:

    my @errors = Log->find({ level => 'error' })->fetch;
    my $errors = Log->find({ level => 'error' })->fetch; # the same, but returns ARRAY ref
    my $error = Log->find(1)->fetch; # only one record
    my @only_five_errors = Log->find({ level => 'error' })->fetch(5);

=head2 next

Fetch next n rows from the database:

    my $finder = Log->find({ level => 'info' });
    
    # get logs by lists of 10 elements:
    while (my @logs = $finder->next(10)) {
        print $_->id, "\n" for @logs;
    }

=head2 only 

Specify field names to get from database:

    # SELECT id, message FROM log;
    my @logs = Log->find->only('id', 'message');

=head2 fields

The same as "only":

    # SELECT id, message FROM log;
    my @logs = Log->find->fields('id', 'message');

=head2 order_by

Set "ORDER BY" command to the query:

    # SELECT * FROM log ORDER BY inserted_time;
    my @logs = Log->find->order_by('inserted_time');

    # SELECT * FROM log ORDER BY level, id;
    my @logs = Log->find->order_by('level', 'id');

=head2 asc

Set "ASC" to the query:

    # SELECT * FROM log ORDER BY id ASC;
    my @logs = Log->find->order_by('id')->asc;

=head2 desc

Set "DESC" to the query:

    # SELECT * FROM log ORDER BY id DESC;
    my @logs = Log->find->order_by('id')->desc;

=head2 limit

SET "LIMIT" to the query:

    # SELECT * FROM log LIMIT 100;
    my @logs = Log->find->limit(100);

=head2 offset

SET "OFFSET" to the query:

    # SELECT * FROM log LIMIT 100 OFFSET 99;
    my @logs = Log->find->limit(100)->offset(99);

=head2 group_by

Set "GROUP BY":

    my @logs = Log->find->group_by('level');

=head2 with 

Set "LEFT JOIN" command to the query:

    # SELECT l.*, s.* FROM logs l LEFT JOIN sites s ON s.id = l.site_id
    my @logs_and_sites = Log->find->with('sites');
    print $_->site->name, ": ", $_->mesage for @logs_and_sites;

=head2 left_join

The same as "with" method

=head2 uplod

Fetch object from database and load into ActiveRecord::Simple::Find object:

    my $logs = Log->find({ level => ['error', 'fatal'] });
    $logs->order_by('level')->desc;
    $logs->limit(100);
    $logs->upload;

    print $_->message for @$logs;

=head2 to_sql

Show SQL-query that genereted by ActiveRecord::Simple::Find class:

    my $finder = Log->frind->only('message')->order_by('level')->desc->limit(100);
    print $finder->to_sql; # prints: SELECT message FROM log ORDER BY level DESC LIMIT 100;


=head1 EXAMPLES

    # SELECT * FROM pizza WHERE name = 'pepperoni';
    Pizza->find({ name => 'pepperoni' });

    # SELECT first_name, last_name FORM customer WHERE age > 21 ORDER BY id DESC LIMIT 100;
    Customer->find('age > ?', 21)->only('first_name', 'last_name')->order_by('id')->desc->limit(100);

    # SELECT p.filename, p.id, pp.* FROM photo p LEFT JOIN person pp ON p.person_id = pp.id WHERE p.size = '1020x768';
    Photo->find({ size => '1020x768' })->with('person')->only('filename', 'id');

    # SELECT t.* FROM topping_pizza tp LEFT JOIN topping t ON t.id = tp.topping_id  WHERE tp.pizza_id = <$val>;
    Pizza->get(<$val>)->toppings();

=head1 AUTHOR

shootnix, C<< <shootnix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<shootnix@cpan.org>, or through
the github: https://github.com/shootnix/activerecord-simple/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ActiveRecord::Simple


You can also look for information at:

=over 1

=item * Github wiki:

L<https://github.com/shootnix/activerecord-simple/wiki>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2018 shootnix.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
