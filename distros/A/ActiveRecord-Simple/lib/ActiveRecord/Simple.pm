package ActiveRecord::Simple;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.94';

use utf8;
use Encode;
use Carp;
use Storable qw/freeze/;
use Module::Load;
use vars qw/$AUTOLOAD/;
use Scalar::Util qw/blessed/;

use ActiveRecord::Simple::Find;
use ActiveRecord::Simple::Utils;
use ActiveRecord::Simple::Connect;

our $connector;


sub new {
    my $class = shift;
    my $param = (scalar @_ > 1) ? {@_} : $_[0];

    my $accessors_fields = $class->can('_get_columns') ? $class->_get_columns : [];

    if ($class->can('_get_mixins')) {
        my @keys = keys %{ $class->_get_mixins };
        $class->_mk_ro_accessors(\@keys);
    }
    $class->_mk_accessors($accessors_fields);

    if ($class->can('_get_relations')) {
        my $relations = $class->_get_relations();

        no strict 'refs';

        RELNAME:
        for my $relname ( keys %{ $relations } ) {
            my $pkg_method_name = $class . '::' . $relname;

            next RELNAME if $class->can($pkg_method_name);

            *{$pkg_method_name} = sub {
                my ($self, @objects) = @_;


                my $rel = $class->_get_relations->{$relname};
                my $fkey = $rel->{foreign_key} || $rel->{key};
                my $relation = $relations->{$relname};
                if (@objects) {
                    if ($relation->{type} eq 'many') {
                        if ($objects[0] && blessed $objects[0]) {
                            for my $object (@objects) {
                                my $fk = $relation->{params}{fk};
                                my $pk = $self->_get_primary_key;
                                $object->$fk($self->$pk);

                                $object->save;
                            }
                        }
                        else {
                            my $rel_class = (%{ $rel->{class} })[1];
                            return $rel_class->_find_many_to_many({
                                root_class      => $class,
                                m_class         => (%{ $rel->{class} })[0],
                                self            => $self,
                                where_statement => \@objects,
                            });
                        }
                    }
                    elsif ($relation->{type} eq 'one') {
                        OBJECT:
                        for my $object (@objects) {
                            next OBJECT unless ref $object && grep { $relation->{type} eq $_ } qw/one many/;

                            $self->{"relation_instance_$relname"} = $object;
                            my $pk = $relation->{params}{pk} or next OBJECT;
                            my $fk = $relation->{params}{fk} or next OBJECT;

                            $self->$fk($object->$pk);
                        }
                    }

                    return $self;
                }
                ### else
                if (!$self->{"relation_instance_$relname"}) {
                    my $rel  = $class->_get_relations->{$relname};
                    my $fkey = $rel->{foreign_key} || $rel->{key};

                    my $type = $rel->{type} . '_to_';
                    my $rel_class = ( ref $rel->{class} eq 'HASH' ) ?
                        ( %{ $rel->{class} } )[1]
                        : $rel->{class};

                    #load $rel_class;

                    ### TODO: check for relation existing
                    while (my ($rel_key, $rel_opts) = each %{ $rel_class->_get_relations }) {
                        my $rel_opts_class = (ref $rel_opts->{class} eq 'HASH') ?
                            (%{ $rel_opts->{class} })[1]
                            : $rel_opts->{class};
                        $type .= $rel_opts->{type} if $rel_opts_class eq $class;
                    }

                    if ($type eq 'one_to_many' or $type eq 'one_to_one' or $type eq 'one_to_only') {
                        my $fkey = $rel->{params}{fk};
                        my $pkey = $rel->{params}{pk};

                        $self->{"relation_instance_$relname"} =
                            $rel_class->find("$pkey = ?", $self->$fkey)->fetch // $rel_class;
                    }
                    elsif ($type eq 'only_to_one') {
                        my $fkey = $rel->{params}{fk};
                        my $pkey = $rel->{params}{pk};

                        $self->{"relation_instance_$relname"} =
                            $rel_class->find("$fkey = ?", $self->$pkey)->fetch;
                    }
                    elsif ($type eq 'many_to_one') {
                        return $rel_class->new() if not $self->can('_get_primary_key');
                        my $fkey = $rel->{params}{fk};
                        my $pkey = $rel->{params}{pk};

                        $self->{"relation_instance_$relname"}
                            = $rel_class->find("$fkey = ?", $self->$pkey);
                    }
                    elsif ( $type eq 'many_to_many' ) {
                        $self->{"relation_instance_$relname"} =
                            $rel_class->_find_many_to_many({
                                root_class => $class,
                                m_class    => (%{ $rel->{class} })[0],
                                self       => $self,
                            });
                    }
                    elsif ($type eq 'generic_to_generic') {
                        my %find_attrs;
                        while (my ($k, $v) = each %{ $rel->{key} }) {
                            $find_attrs{$v} = $self->$k;
                        }
                        $self->{"relation_instance_$relname"} =
                            $rel_class->find(\%find_attrs);
                    }
                }

                $self->{"relation_instance_$relname"};
            }
        }
        use strict 'refs';
    }

    $class->auto_save(0);

    return bless $param || {}, $class;
}


sub auto_load {
    my ($class) = @_;

    my @class_name_parts = split q/::/, $class;
    my $class_name = $class_name_parts[-1];

    my $table_name = join '-', map {
        join('_', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/)
    } $class_name;
    $table_name .= 's';

    # 0. check the name
    my $table_info_sth = $class->dbh->table_info('', '%', $table_name, 'TABLE');
    $table_info_sth->fetchrow_hashref or croak "Can't find table '$table_name' in the database";

    # 1. columns list
    my $column_info_sth = $class->dbh->column_info(undef, undef, $table_name, undef);
    my $cols = $column_info_sth->fetchall_arrayref({});
    my @columns = ();
    push @columns, $_->{COLUMN_NAME} for @$cols;

    # 2. Primary key
    my $primary_key_sth = $class->dbh->primary_key_info(undef, undef, $table_name);
    my $primary_key_data = $primary_key_sth->fetchrow_hashref;
    my $primary_key = ($primary_key_data) ? $primary_key_data->{COLUMN_NAME} : undef;

    # 3. Foreign keys
    # TODO

    $class->table_name($table_name) if $table_name;
    $class->primary_key($primary_key) if $primary_key;
    $class->columns(\@columns) if @columns;
}

sub load_info {
    carp '[DEPRECATED] This method is deprecated and will be remowed in the feature. Use method "auto_load" instead.';
    $_[0]->auto_load;
}

sub _mk_accessors {
    my ($class, $fields) = @_;

    my $super = caller;
    return unless $fields;

    no strict 'refs';
    FIELD:
    for my $f (@$fields) {
        my $pkg_accessor_name = $class . '::' . $f;
        next FIELD if $class->can($pkg_accessor_name);
        *{$pkg_accessor_name} = sub {
            if ( scalar @_ > 1 ) {
                $_[0]->{$f} = $_[1];

                return $_[0];
            }

            return $_[0]->{$f};
        }
    }
    use strict 'refs';

    return 1;
}

sub _mk_ro_accessors {
    my ($class, $fields) = @_;

    return unless $fields;
    my $super = caller;

    no strict 'refs';
    FIELD:
    for my $f (@$fields) {
        my $pkg_accessor_name = $class . '::' . $f;
        next FIELD if $class->can($pkg_accessor_name);
        *{$pkg_accessor_name} = sub {
            croak "You can't change '$f': object is read-only"
                if scalar @_ > 1;

            return $_[0]->{$f}
        };
    }
}

sub connect {
    my ($class, $dsn, $username, $password, $options) = @_;

    eval { require DBIx::Connector };

    $options->{HandleError} = sub {
        my ($error_message, $DBI_st) = @_;

        $error_message or return;
        croak $error_message;

    } if ! exists $options->{HandleError};

    if ($@) {
        $connector = ActiveRecord::Simple::Connect->new($dsn, $username, $password, $options);
        $connector->db_connect;
    }
    else {
        $connector = DBIx::Connector->new($dsn, $username, $password, $options);
    }

    return 1;
}

sub belongs_to {
    my ($class, $rel_name, $rel_class, $params) = @_;

    my $new_relation = {
        class => $rel_class,
        type => 'one',
        #params => $params
    };

    my $primary_key = $params->{pk} ||
        $params->{primary_key} ||
        _guess(primary_key => $class);

    my $foreign_key = $params->{fk} ||
        $params->{foreign_key} ||
        _guess(foreign_key => $rel_class);

    $new_relation->{params} = {
        pk => $primary_key,
        fk => $foreign_key,
    };

    if ($class->can('_get_table_schema') && $class->can('_get_primary_key')) {
       ### load $rel_class;
        $class->_get_table_schema->add_constraint(
            type => 'foreign_key',
            fields => $params, ### TODO: !!!this is wrong!!!
            reference_fields => $class->_get_primary_key,
            reference_table => $rel_class->_table_name,
            on_delete => 'cascade'
        );
    }

    return $class->_append_relation($rel_name => $new_relation);
}

sub has_many {
    my ($class, $rel_name, $rel_class, $params) = @_;

    my $new_relation = {
        class => $rel_class,
        type => 'many',
    };

    $params ||= {};
    #my ($primary_key, $foreign_key);
    my $primary_key = $params->{pk} ||
        $params->{primary_key} ||
        _guess(primary_key => $class);

    my $foreign_key = $params->{fk} ||
        $params->{foreign_key} ||
        _guess(foreign_key => $class);

    $new_relation->{params} = {
        pk => $primary_key,
        fk => $foreign_key,
    };

    return $class->_append_relation($rel_name => $new_relation);
}

sub _guess {
    my ($what_key, $class) = @_;

    return 'id' if $what_key eq 'primary_key';

    eval { load $class };

    my $table_name = $class->_table_name;
    $table_name =~ s/s$// if $what_key eq 'foreign_key';

    return ($what_key eq 'foreign_key') ? "$table_name\_id" : undef;
}

sub _delete_keys {
    my ($self, $rx) = @_;

    map { delete $self->{$_} if $_ =~ $rx } keys %$self;
}

sub has_one {
    my ($class, $rel_name, $rel_class, $params) = @_;

    my $new_relation = {
        class => $rel_class,
        type => 'only',
    };

    $params ||= {};
    #my ($primary_key, $foreign_key);
    my $primary_key = $params->{pk} ||
        $params->{primary_key} ||
        _guess(primary_key => $class);

    my $foreign_key = $params->{fk} ||
        $params->{foreign_key} ||
        _guess(foreign_key => $class);

    $new_relation->{params} = {
        pk => $primary_key,
        fk => $foreign_key,
    };

    #$class->_mk_attribute_getter('_get_secondary_key', $key);
    ### TODO: add schema constraints
    $class->_append_relation($rel_name => $new_relation);
}

sub as_sql {
    my ($class, $producer_name, %args) = @_;

    eval { require SQL::Translator }
      || croak('Please install SQL::Translator to use this feature.');

    $class->can('_get_table_schema')
        or return;

    my $t = SQL::Translator->new;
    my $schema = $t->schema;
    $schema->add_table($class->_get_table_schema);

    $t->producer($producer_name || 'PostgreSQL', %args);

    return $t->translate;
}

sub generic {
    my ($class, $rel_name, $rel_class, $key) = @_;

    my $new_relation = {
        class => $rel_class,
        type => 'generic',
        key => $key
    };

    return $class->_append_relation($rel_name => $new_relation);
}

sub _append_relation {
    my ($class, $rel_name, $rel_hashref) = @_;

    if ($class->can('_get_relations')) {
        my $relations = $class->_get_relations();
        $relations->{$rel_name} = $rel_hashref;
        $class->relations($relations);
    }
    else {
        $class->relations({ $rel_name => $rel_hashref });
    }

    return;
}

sub columns {
    my ($class, @args) = @_;

    #return if $class->can('_get_columns');

    my $columns = [];
    if (scalar @args == 1) {
        my $arg = shift @args;
        if (ref $arg && ref $arg eq 'ARRAY') {
            $columns = $arg;
        }
        elsif (ref $arg && ref $arg eq 'HASH') {
            $columns = [keys %$arg];
            $class->fields(%$arg);
        }
        else {
            # just one column?
            push @$columns, $arg;
        }
    }
    elsif (scalar @args > 1) {
        push @$columns, @args;
    }

    $class->_mk_attribute_getter('_get_columns', $columns);
}

sub mixins {
    my ($class, %mixins) = @_;

    $class->_mk_attribute_getter('_get_mixins', \%mixins);
}

sub fields {
    my ($class, %fields) = @_;

    eval { require SQL::Translator }
      || croak('Please install SQL::Translator to use this feature. ');

    my $sql_translator = SQL::Translator->new(no_comments => 1);
    my $schema = $sql_translator->schema;
    my $table = $schema->add_table(name => $class->_table_name);

    FIELD:
    for my $field (keys %fields) {
        $table->add_field(name => $field, %{ $fields{$field} });
    }

    $class->_mk_attribute_getter('_get_table_schema', $table);
    $class->columns([keys %fields]);
}

sub index {
    my ($class, $index_name, $fields) = @_;

    if ($class->can('_get_table_schema')) {
        $class->_get_table_schema->add_index(
            name => $index_name,
            fields => $fields
        );
    }
}

sub primary_key {
    my ($class, $primary_key) = @_;

    $class->_mk_attribute_getter('_get_primary_key', $primary_key);
    $class->_get_table_schema->primary_key($primary_key)
        if $class->can('_get_table_schema')
}

sub secondary_key {
    my ($class, $key) = @_;

    $class->_mk_attribute_getter('_get_secondary_key', $key);
}

sub table_name {
    my ($class, $table_name) = @_;

    $class->_mk_attribute_getter('_get_table_name', $table_name);
}

sub _table_name {
    my $class = ref $_[0] ? ref $_[0] : $_[0];

    croak 'Invalid data class' if $class =~ /^ActiveRecord::Simple/;

    my $table_name =
        $class->can('_get_table_name') ?
            $class->_get_table_name
            : ActiveRecord::Simple::Utils::class_to_table_name($class);

    return $table_name;
}

sub auto_save {
    my ($class, $is_on) = @_;

    $is_on = 1 if not defined $is_on;

    $class->_mk_attribute_getter('_smart_saving_used', $is_on);
}

sub use_smart_saving {
    carp '[DEPRECATED] Method "use_smart_saving" is deprecated and will be removed in the future. Please, use "auto_save" method insted.';
    $_[0]->auto_save;
}

sub relations {
    my ($class, $relations) = @_;

    $class->_mk_attribute_getter('_get_relations', $relations);
}

sub _mk_attribute_getter {
    my ($class, $method_name, $return) = @_;

    my $pkg_method_name = $class . '::' . $method_name;
    if ( !$class->can($pkg_method_name) ) {
        no strict 'refs';
        *{$pkg_method_name} = sub { $return };
    }
}

sub dbh {
    my ($self, $dbh) = @_;

    if ($dbh) {
        if ($connector) {
            $connector->dbh($dbh);
        }
        else {
            $connector = ActiveRecord::Simple::Connect->new();
            $connector->dbh($dbh);
        }
    }

    return $connector->dbh;
}

sub save {
    my ($self) = @_;

    #return unless $self->dbh;
    croak "Undefined database handler" unless $self->dbh;

    return 1 if $self->_smart_saving_used
        and defined $self->{snapshoot}
        and $self->{snapshoot} eq freeze $self->to_hash;

    croak 'Object is read-only'
        if exists $self->{read_only} && $self->{read_only} == 1;

    my $save_param = {};
    my $fields = $self->_get_columns;

    my $pkey = ($self->can('_get_primary_key')) ? $self->_get_primary_key : undef;

    FIELD:
    for my $field (@$fields) {
        next FIELD if defined $pkey && $field eq $pkey && !$self->{$pkey};
        next FIELD if ref $field && ref $field eq 'HASH';
        $save_param->{$field} = $self->{$field};
    }

    ### Get additional fields from related objects:
    for my $field (keys %$self) {
        next unless ref $self->{$field};
        next unless $self->can('_get_relations');
        next unless grep { $_ eq $field } keys %{ $self->_get_relations };

        my $relation = $self->_get_relations->{$field} or next;
        next unless $relation->{type} && $relation->{type} eq 'one';

        my $fk = $relation->{params}{fk};
        my $pk = $relation->{params}{pk};

        $save_param->{$fk} = $self->{$field}->$pk;
    }

    my $result;
    if ($self->{isin_database}) {
        $result = $self->_update($save_param);
    }
    else {
        $result = $self->_insert($save_param);
    }
    $self->{need_to_save} = 0 if $result;
    delete $self->{SQL} if $result;

    return (defined $result) ? $self : undef;
}

sub update {
    my ($self, $params) = @_;

    my $fields = $self->_get_columns();
    FIELD:
    for my $field (@$fields) {
        next FIELD if ! exists $params->{$field};
        next FIELD if ! $params->{$field};

        $self->$field($params->{$field});
    }

    return $self;
}

sub _insert {
    my ($self, $param) = @_;

    return unless $self->dbh && $param;

    my $table_name  = $self->_table_name;
    my @field_names  = grep { defined $param->{$_} } sort keys %$param;
    my $primary_key = ($self->can('_get_primary_key')) ? $self->_get_primary_key :
                      ($self->can('_get_secondary_key')) ? $self->_get_secondary_key : undef;

    my $field_names_str = join q/, /, map { q/"/ . $_ . q/"/ } @field_names;

    my (@bind, @values_list);
    for (@field_names) {
        if (ref $param->{$_} eq 'SCALAR') {
            push @values_list, ${ $param->{$_} };
        }
        else {
            push @values_list, '?';
            push @bind, $param->{$_};
        }
    }
    my $values = join q/, /, @values_list;
    my $pkey_val;
    my $sql_stm = qq{
        INSERT INTO "$table_name" ($field_names_str)
        VALUES ($values)
    };

    if ( $self->dbh->{Driver}{Name} eq 'Pg' ) {
        if ($primary_key) {
            $sql_stm .= ' RETURINIG ' . $primary_key if $primary_key;
            $sql_stm = ActiveRecord::Simple::Utils::quote_sql_stmt($sql_stm, $self->dbh->{Driver}{Name});
            $pkey_val = $self->dbh->selectrow_array($sql_stm, undef, @bind);
        }
        else {
            my $sth = $self->dbh->prepare(
                ActiveRecord::Simple::Utils::quote_sql_stmt($sql_stm, $self->dbh->{Driver}{Name})
            );

            $sth->execute(@bind);
        }
    }
    else {
        my $sth = $self->dbh->prepare(
            ActiveRecord::Simple::Utils::quote_sql_stmt($sql_stm, $self->dbh->{Driver}{Name})
        );
        $sth->execute(@bind);

        if ( $primary_key && defined $self->{$primary_key} ) {
            $pkey_val = $self->{$primary_key};
        }
        else {
            $pkey_val = $self->dbh->last_insert_id(undef, undef, $table_name, undef);
        }
    }

    if (defined $primary_key && $self->can($primary_key) && $pkey_val) {
        $self->$primary_key($pkey_val);
    }
    $self->{isin_database} = 1;

    return $pkey_val;
}

sub _update {
    my ($self, $param) = @_;

    return unless $self->dbh && $param;

    my $table_name      = $self->_table_name;
    my @field_names     = sort keys %$param;
    my $primary_key     = ($self->can('_get_primary_key')) ? $self->_get_primary_key :
                          ($self->can('_get_secondary_key')) ? $self->_get_secondary_key : undef;

    my (@set_list, @bind);
    for (@field_names) {
        if (ref $param->{$_} eq 'SCALAR') {
            push @set_list, $_ . ' = ' . ${ $param->{$_} };
        }
        else {
            push @set_list, "$_ = ?";
            push @bind, $param->{$_};
        }
    }
    my $setstring = join q/, /, @set_list;
    push @bind, $self->{$primary_key};

    my $sql_stm = ActiveRecord::Simple::Utils::quote_sql_stmt(
        qq{
            UPDATE "$table_name" SET $setstring
            WHERE
                $primary_key = ?
        },
        $self->dbh->{Driver}{Name}
    );

    return $self->dbh->do($sql_stm, undef, @bind);
}

# param:
#     cascade => 1
sub delete {
    my ($self, $param) = @_;

    return unless $self->dbh;

    my $table_name = $self->_table_name;
    my $pkey = $self->_get_primary_key;

    return unless $self->{$pkey};

    my $sql = qq{
        DELETE FROM "$table_name" WHERE $pkey = ?
    };
    $sql .= ' CASCADE ' if $param && $param->{cascade};

    my $res = undef;
    $sql = ActiveRecord::Simple::Utils::quote_sql_stmt($sql, $self->dbh->{Driver}{Name});

    if ( $self->dbh->do($sql, undef, $self->{$pkey}) ) {
        $self->{isin_database} = undef;
        delete $self->{$pkey};

        $res = 1;
    }

    return $res;
}

sub is_defined {
    my ($self) = @_;

    return grep { defined $self->{$_} } @{ $self->_get_columns };
}

# param:
#     only_defined_fields => 1
###  TODO: refactor this
sub to_hash {
    my ($self, $param) = @_;

    my $field_names = $self->_get_columns;
    push @$field_names, keys %{ $self->_get_mixins } if $self->can('_get_mixins');
    my $attrs = {};

    for my $field (@$field_names) {
        next if ref $field;
        if ( $param && $param->{only_defined_fields} ) {
            $attrs->{$field} = $self->{$field} if defined $self->$field;
        }
        else {
            $attrs->{$field} = $self->{$field};
        }
    }

    return $attrs;
}

sub increment {
    my ($self, @fields) = @_;

    FIELD:
    for my $field (@fields) {
        next FIELD if not exists $self->{$field};
        $self->{$field} += 1;
    }

    return $self;
}

sub decrement {
    my ($self, @fields) = @_;

    FIELD:
    for my $field (@fields) {
        next FIELD if not exists $self->{$field};
        $self->{$field} -= 1;
    }

    return $self;
}

#### Find ####

sub find   { ActiveRecord::Simple::Find->new(shift, @_) }
sub get    { shift->find(@_)->fetch } ### TODO: move to Finder
sub count  { ActiveRecord::Simple::Find->count(shift, @_) }

sub exists {
    my $first_arg = shift;

    my ($class, @search_criteria);
    if (ref $first_arg) {
        # FOXME: Ugly solution, need some beautifulness =)
        # object method
        $class = ref $first_arg;

        if ($class eq 'ActiveRecord::Simple::Find') {
            return $first_arg->exists;
        }
        else {
            return ActiveRecord::Simple::Find->new($class, $first_arg->to_hash({ only_defined_fields => 1 }))->exists;
        }
    }
    else {
        carp '[DEPRECATED] This way of using method "exists" is deprecated. Please, see documentation to know how does it work now.';
        $class = $first_arg;
        @search_criteria = @_;
        return (defined $class->find(@search_criteria)->fetch) ? 1 : 0;
    }


}

sub first  { croak '[DEPRECATED] Using method "first" as a class-method is deprecated. Sorry about that. Please, use "first" in this way: "Model->find->first".'; }
sub last   { croak '[DEPRECATED] Using method "last" as a class-method is deprecated. Sorry about that. Please, use "last" in this way: "Model->find->last".'; }
sub select { ActiveRecord::Simple::Find->select(shift, @_) }

sub _find_many_to_many { ActiveRecord::Simple::Find->_find_many_to_many(shift, @_) }

sub DESTROY {}

### FIXME: this implementation is actually too slow, need much faster solution
sub AUTOLOAD {
    my ($self, $param) = @_;

    my $sub = $AUTOLOAD; $sub =~ s/.*:://g;
    my $error = "Unknown method: $sub";

    croak "Error while executing '$sub' method, '$self' is not a valid (blessed) object." unless blessed $self;
    croak "Undefined object for method $sub: must be not undef" unless $param;

    croak $error unless $self->can('_get_relations');
    my @many2manies;
    my $relations = $self->_get_relations;

    my $subclass = undef;
    my %class_options;
    for my $relation (values %$relations) {
        next unless $relation->{type} eq 'many' && ref $relation->{class} eq 'HASH';
        ($subclass) = keys %{ $relation->{class} };
        next if !$subclass->can('_get_relations');
        my $relations2 = $subclass->_get_relations;

        for my $rel_name (keys %$relations2) {
            next unless exists $relations2->{$rel_name};

            my $pk = $relations2->{$rel_name}{params}{pk};
            my $fk = $relations2->{$rel_name}{params}{fk};

            next unless $pk && $fk;

            $class_options{$fk} = ($rel_name eq $sub) ? $param->$pk : $self->$pk;
        }
    }

    return $subclass->new(\%class_options);
}

### Private

1;

__END__;

=head1 NAME

ActiveRecord::Simple

=head1 DESCRIPTION

ActiveRecord::Simple is a simple lightweight implementation of ActiveRecord
pattern. It's fast, very simple and very light.

=head1 SYNOPSIS

    # easy way:

    package MyModel:Person;
    use base 'ActiveRecord::Simple';

    __PACKAGE__->auto_load()

    1;

    # hardcore:

    package MyModel::Person;
    use base 'ActiveRecord::Simple';

    __PACKAGE__->table_name('persons');
    __PACKAGE__->fields(
        id_person => {
            data_type => 'int',
            is_auto_increment => 1,
            is_primary_key => 1
        },
        first_name => {
            data_type => 'varchar',
            size => 64,
            is_nullable => 0
        },
        second_name => {
            data_type => 'varchar',
            size => 64,
            is_nullable => 0,
        },
        registered => {
            data_type => 'timestamp',
            is_nullable => 0,
        });
    __PACKAGE__->primary_key('id_person');

That's it! Now you're ready to use your active-record class in the application:

    use MyModel::Person;

    # to create a new record:
    my $person = MyModel::Person->new({ name => 'Foo', registered => \'NOW()' })->save();
    # (use a scalarref to pass non-quoted data to the database, as is).

    # to update the record:
    $person->name('Bar')->save();

    # to get the record (using primary key):
    my $person = MyModel::Person->get(1);

    # to get the record with specified fields:
    my $person = MyModel::Person->find(1)->only('first_name', 'second_name')->fetch;

    # to find records by parameters:
    my @persons = MyModel::Person->find({ first_name => 'Foo' })->fetch();

    # to find records by sql-condition:
    my @persons = MyModel::Person->find('first_name = ?', 'Foo')->fetch();

    # also you can do something like this:
    my $persons = MyModel::Person->find('first_name = ?', 'Foo');
    while ( my $person = $persons->next() ) {
        say $person->name;
    }

    # You can add any relationships to your tables:
    __PACKAGE__->has_many(cars => 'MyModel::Car' => 'id_preson');
    __PACKAGE__->belongs_to(wife => 'MyModel::Wife' => 'id_person');

    # And then, you're ready to go:
    say $person->cars->fetch->id; # if the relation is one to many
    say $person->wife->name; # if the relation is one to one
    $person->wife(Wife->new({ name => 'Jane', age => '18' })->save)->save; # change wife ;-)

=head1 METHODS

ActiveRecord::Simple provides a variety of techniques to make your work with
data little easier. It contains set of operations, such as
search, create, update and delete data.

If you realy need more complicated solution, just try to expand on it with your
own methods.

=head1 Class Methods

Class methods mean that you can't do something with a separate row of the table,
but they need to manipulate of the table as a whole object. You may find a row
in the table or keep database handler etc.

=head2 new

Creates a new object, one row of the data.

    MyModel::Person->new({ name => 'Foo', second_name => 'Bar' });

It's a constructor of your class and it doesn't save a data in the database,
just creates a new record in memory.

You can pass as a parameter related object, ActiveRecord::Simple will do the rest:

    my $Adam = Customer->find({name => 'Adam'})->fetch;

    my $order = Order->new(sum => 100, customer => $Adam);
    ### This is the same:
    my $order = Order->new(sum => 100, customer_id => $Adam->id);
    ### but here you have to know primary and foreign keys.

    ### much easier using objects:
    my $order = Order->new(sum => 100, customer => $Adam); # ARS will find all keys automatically

=head2 columns

    __PACKAGE__->columns([qw/id_person first_name second_name]);
    # or
    __PACKAGE__->columns('id_person', 'first_name', 'second_name');
    # or
    __PACKAGE__->columns({
        id_person => {
            # ...
        },
        first_name => {
            # ...
        },
        second_name => {
            # ...
        }
    });
    # or
    __PACKAGE__->columns(
        id_person => {
            # ...
        },
        first_name => {
            # ...
        },
        second_name => {
            # ...
        }
    );

This method is required.
Set names of the table columns and add accessors to object of the class.
If you set a hash or a hashref with additional parameters, the method will be dispatched to
another method, "fields".

=head2 fields

    __PACKAGE__->fields(
        id_person => {
            data_type => 'int',
            is_auto_increment => 1,
            is_primary_key => 1
        },
        first_name => {
            data_type => 'varchar',
            size => 64,
            is_nullable => 0
        },
        second_name => {
            data_type => 'varchar',
            size => 64,
            is_nullable => 0,
        }
    );

This method requires L<SQL::Translator> to be installed.
Create SQL-Schema and data type validation for each specified field using SQL::Translator features.
You don't need to call "columns" method explicitly, if you use "fields".

See L<SQL::Translator> for more information about schema and L<SQL::Translator::Field>
for information about available data types.

=head2 mixins

Use this method when you need to add optional fields, computed fields etc. Method takes hash, key is a name of field,
value is a subroutine that returns SQL:

    __PACKAGE__->mixins(
        sum_of_items => sub {

            return 'SUM(`item`)';
        }
    );

    # specify mixin as a field in the query:
    my @items = Model->find->fields('id', 'name', 'sum_of_items')->fetch;

=head2 primary_key

    __PACKAGE__->primary_key('id_person');

Set name of the primary key. This method is not required to use in the child
(your model) classes.

=head2 secondary_key

    __PACKAGE__->secondary_key('some_id');

If you don't need to use primary key, but need to insert or update data, using specific
parameters, you can try this one: secondary key. It doesn't reflect schema, it's just about
the code.

=head2 index

    __PACKAGE__->index('index_id_person', ['id_person']);

Create an index and add it to the schema. Works only when method "fields" is using.

=head2 table_name

    __PACKAGE__->table_name('persons');

Set name of the table. This method is required to use in the child (your model)
classes.

=head2 auto_load

Load table info using DBI methods: table_name, primary_key, foreign_key, columns

=head2 load_info

Same as "auto_load". DEPRECATED.

=head2 belongs_to

    __PACKAGE__->belongs_to(home => 'Home');

This method describes one-to-one objects relationship. By default ARS think
that primary key name is "id", foreign key name is "[table_name]_id".
You can specify it by parameters:

    __PACKAGE__->belongs_to(home => 'Home', {
        primary_key => 'id',
        foreign_key => 'home_id'
    });

=head2 has_many

    __PACKAGE__->has_many(cars => 'Car');
    __PACKAGE__->has_many(cars => 'Car', {
        primary_key => 'id',
        foreign_key => 'car_id'
    })

This method describes one-to-many objects relationship.

=head2 has_one

    __PACKAGE__->has_one(wife => 'Wife');
    __PACKAGE__->has_one(wife => 'Wife', {
        primary_key => 'id',
        foreign_key => 'wife_id'
    });

You can specify one object via another one using "has_one" method. It works like that:

    say $person->wife->name; # SELECT name FROM Wife WHERE person_id = $self._primary_key

=head2 relations

    __PACKAGE__->relations({
        cars => {
            class => 'MyModel::Car',
            key   => 'id_person',
            type  => 'many'
        },
    });

It's not a required method and you don't have to use it if you don't want to use
any relationships in your tables and objects. However, if you need to,
just keep this simple schema in youre mind:

    __PACKAGE__->relations({
        [relation key] => {
            class => [class name],
            key   => [column that refferers to the table],
            type  => [many or one]
        },
    })

    [relation key] - this is a key that will be provide the access to instance
    of the another class (which is specified in the option "class" below),
    associated with this relationship. Allowed to use as many keys as you need:

    $package_instance->[relation key]->[any method from the related class];

=head2 generic

    __PACKAGE__->generic(photos => { release_date => 'pub_date' });

    Creates a generic relations.

    my $single = Song->find({ type => 'single' })->fetch();
    my @photos = $single->photos->fetch();  # fetch all photos with pub_date = single.release_date

=head2 auto_save

This method provides two features:

   1. Check the changes of object's data before saving in the database.
      Won't save if data didn't change.

   2. Automatic save on object destroy (You don't need use "save()" method
      anymore).

    __PACKAGE__->auto_save;

=head2 use_smart_saving

Same as "auto_save". DEPRECATED.

=head2 find

There are several ways to find someone in your database using ActiveRecord::Simple:

    # by "nothing"
    # just leave attributes blank to recieve all rows from the database:
    my @all_persons = MyModel::Person->find->fetch;

    # by primary key:
    my $person = MyModel::Person->find(1)->fetch;

    # by multiple primary keys
    my @persons = MyModel::Person->find([1, 2, 5])->fetch;

    # by simple condition:
    my @persons = MyModel::Person->find({ name => 'Foo' })->fetch;

    # by where-condtions:
    my @persons = MyModel::Person->find('first_name = ? and id_person > ?', 'Foo', 1);

If you want to get a few instances by primary keys, you should put it as arrayref,
and then fetch from resultset:

    my @persons = MyModel::Person->find([1, 2])->fetch();

    # you don't have to fetch it immidiatly, of course:
    my $resultset = MyModel::Person->find([1, 2]);
    while ( my $person = $resultset->fetch() ) {
        say $person->first_name;
    }

To find some rows by simple condition, use a hashref:

    my @persons = MyModel::Person->find({ first_name => 'Foo' })->fetch();

Simple condition means that you can use only this type of it:

    { first_name => 'Foo' } goes to "first_type = 'Foo'";
    { first_name => 'Foo', id_person => 1 } goes to "first_type = 'Foo' and id_person = 1";

If you want to use a real sql where-condition:

    my $res = MyModel::Person->find('first_name = ? or id_person > ?', 'Foo', 1);
    # select * from persons where first_name = "Foo" or id_person > 1;

You can use the ordering of results, such as ORDER BY, ASC and DESC:

    my @persons = MyModel::Person->find('age > ?', 21)->order_by('name')->desc->fetch;
    my @persons = MyModel::Person->find('age > ?', 21)->order_by('name', 'age')->fetch;
    my @persons = MyModel::Person->find->order_by('age')->desc->order_by('id')->asc->fetch;


You can pass objects as a parameters. In this case parameter name is the name of relation.
For example:

    package Person;

    # some declarations here

    __PACKAGE__->has_many(orders => Order);

    # ...

    package Order;

    # some declarations here

    __PACKAGE__->belongs_to(person => Person);

Now, get person:

    my $Bill = Person->find({ name => 'Bill' })->fetch;

    ### .. and get all his orders:
    my @bills_orders = Order->find({ customer => $Bill })->fetch;

    ### the same, but not so cool:
    my @bills_orders = Order->find({ customer_id => $Bill->id })->fetch;

=head2 fetch

When you use the "find" method to get a few rows from the table, you get the
meta-object with a several objects inside. To use all of them or only a part,
use the "fetch" method:

    my @persons = MyModel::Person->find('id_person != ?', 1)->fetch();

You can also specify how many objects you want to use at a time:

    my @persons = MyModel::Person->find('id_person != ?', 1)->fetch(2);
    # fetching only 2 objects.

Another syntax of command "fetch" allows you to make read-only objects:

    my @persons = MyModel::Person->find->fetch({ read_only => 1, limit => 2 });
    # all two object are read-only

=head2 select

Yet another way to select data from the database:

    my $criteria = { name => 'Bill' };
    my $select_options = { order_by => 'id', only => ['name', 'age', 'id'] };

    my @bills = Person->select($criteria, $select_options);

=head2 upload

Loads fetched object into the variable:

    my $finder = Person->find({ name => 'Bill' }); # now $finder isa ARS::Find
    # you can continue using this variable as an ARS::Find object:
    $finder->order_by('age');
    $finder->with('orders');
    # now, insted of creating yet another variable like this:
    my $persons = $finder->fetch;
    # .. you just upload the result into $finder:
    $finder->upload; # now $finder isa Person

=head2 count

Returns count of records that match the rule:

    say MyModel::Person->find->count;
    say MyModel::Person->find({ zip => '12345' })->count;
    say MyModel::Person->find('age > ?', 55)->count;
    say MyModel::Person->find({city => City->find({ name => 'NY' })->fetch })->count;

=head2 exists

Returns 1 if record is exists in database:

    say "Exists" if MyModel::Person->find({ zip => '12345' })->count;
    say "Exists" if MyModel::Person->find('age > ?', 55)->count;

=head2 first

Returns the first record (records) ordered by the primary key:

    my $first_person = MyModel::Person->find->first;
    my @ten_persons  = MyModel::Person->find->first(10);

=head2 last

Returns the last record (records) ordered by the primary key:

    my $last_person = MyModel::Person->find->last;
    my @ten_persons = MyModel::Person->find->last(10);

=head2 increment

Increment the field value:

    my $person = MyModel::Person->get(1);
    say $person->age;  # prints e.g. 99
    $person->increment('age');
    say $person->age; # prints 100

=head2 decrement

Decrement the field value:

    my $person = MyModel::Person->get(1);
    say $person->age;  # prints e.g. 100
    $person->decrement('age');
    say $person->age; # prints 99

=head2 as_sql

    say MyModel::Person->as_sql('PostgreSQL');

This method requires L<SQL::Translator> to be installed.
Create an SQL-schema using method "fields". See SQL::Translator for more details.

=head2 dbh

Keeps a database connection handler. It's not a class method actually, this is
an attribute of the base class and you can put your database handler in any
class:

    Person->dbh($dbh);

Or even rigth in base class:

    ActiveRecord::Simple->dbh($dht);

This decision is up to you. Anyway, this is a singleton value, and keeps only
once at the session.

=head2 connect

Creates connection to the database and shares with child classes. Simple to use:

    package MyModel;

    use parent 'ActiveRecord::Simple';
    __PACKAGE__->connect(...);

... and then:

    package MyModel::Product;

    use parent 'MyModel';

... and then:

    my @products = MyModel::Product->find->fetch; ## you don't need to set dbh() anymore!

=head2 with

Left outer join.

    my $artist = MyModel::Artist->find(1)->with('manager')->fetch;
    say $person->name; # persons.name in DB
    say $rerson->manager->name; managers.name in DB

The method can take a list of parameters:

    my $person = MyModel::Person->find(1)->with('car', 'home', 'dog')->fetch;
    say $person->name;
    say $person->dog->name;
    say $person->home->addres;

This method allows to use just one request to the database (using left outer join)
to create the main object with all relations. For example, without "with":

    my $person = MyModel::Person->find(1)->fetch; # Request no 1:
    # select * from persons where id = ?
    say $person->name; # no requests, becouse the objects is loaded already

    say $person->dog->name; # request no 2. (to create Dog object):
    # select * from dogs where person_id = ?
    say $person->dog->burk; # no requests, the object Dog is loaded too

Using "with":

    my $person = MyModel::Person->find(1)->with('dog')->fetch; # Just one request:
    # select * fom persons left join dogs on dogs.person_id = perosn.id
    #     where person.id = ?

    say $person->name; # no requests
    say $person->dog->name; # no requests too! The object Dog was loaded by "with"

=head2 left_join

Same as "with" method.

=head2 only

Get only those fields that are needed:

    my $person = MyModel::Person->find({ name => 'Alex' })->only('address', 'email')->fetch;
    ### SQL:
    ###     SELECT `address`, `email` from `persons` where `name` = "Alex";

=head2 get

This is shortcut method for "find":

    my $person = MyModel::Person->get(1);
    ### is the same:
    my $person = MyModel::Person->find(1)->fetch;

=head2 order_by

Order your results by specified fields:

    my @persons = MyModel::Person->find({ city => 'NY' })->order_by('name')->fetch();

This method uses as many fields as you want:

    my @fields = ('name', 'age', 'zip');
    my @persons = MyModel::Person->find({ city => 'NY' })->order_by(@fields)->fetch();

Use chain "order_by" if you would like to order your data in different ways:

    my @persons = Model->find->order_by('name', 'age')->asc->order_by('zip')->desc->fetch;
    # This is equal to ... ORDER BY name, age ASC, zip DESC;

=head2 asc

Use this attribute to order your results ascending:

    MyModel::Person->find([1, 3, 5, 2])->order_by('id')->asc->fetch();

=head2 desc

Use this attribute to order your results descending:

    MyModel::Person->find([1, 3, 5, 2])->order_by('id')->desc->fetch();

=head2 limit

Use this attribute to limit results of your requests:

    MyModel::Person->find()->limit(10)->fetch; # select only 10 rows

=head2 offset

Offset of results:

    MyModel::Person->find()->offset(10)->fetch; # all next after 10 rows

=head2 group_by

Group by specified fields:

    Model->find->group_by('name')->fetch;

=head1 Object Methods

Object methods are intended for management of each
row of your table separately as an object.

=head2 save

To insert or update data in the table, use only one method. It detects
automatically what do you want to do with it. If your object was created
by the new method and never has been saved before, method will insert your data.

If you took the object using the find method, "save" will mean "update".

    my $person = MyModel::Person->new({
        first_name  => 'Foo',
        second_name => 'Bar',
    });

    $person->save() # -> insert

    $person->first_name('Baz');
    $person->save() # -> now it's update!

    ### or

    my $person = MyModel::Person->find(1);
    $person->first_name('Baz');
    $person->save() # update

=head2 update

To quick update object's fields, use "update":

    $person->update({
        first_name  => 'Foo',
        second_name => 'Bar'
    });
    $person->save;

=head2 delete

    $person->delete();

Delete row from the table.

=head2 exists

Checks for a record in the database corresponding to the object:

    my $person = MyModel::Person->new({
        first_name => 'Foo',
        secnd_name => 'Bar',
    });

    $person->save() unless $person->exists;

=head2 to_hash

Convert objects data to the simple perl hash:

    use JSON::XS;

    say encode_json({ person => $peron->to_hash });

=head2 to_sql

Convert aobject to SQL-query:

    my $sql = Person->find({ name => 'Bill' })->limit(1)->to_sql;
    # select * from persons where name = ? limit 1;

    my ($sql, $binds) = Person->find({ name => 'Bill' })->to_sql;
    # sql: select * from persons where name = ? limit 1;
    # binds: ['Bill']

=head2 is_defined

Checks weather an object is defined:

    my $person = MyModel::Person->find(1);
    return unless $person->is_defined;

=head1 SEE ALSO

    L<DBIx::ActiveRecord>, L<SQL::Translator>


=head1 MORE INFO

    perldoc ActiveRecord::Simple::Tutorial

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

Copyright 2013-2017 shootnix.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
