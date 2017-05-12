package DBIx::ObjectMapper::Metadata::Table;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use overload
    '""' => sub {
        my $self = shift;
        my $table_name = $self->table_name;
        $table_name .= ' AS ' . $self->alias_name if $self->is_clone;
        return $table_name;
    },
    fallback => 1
    ;

use Params::Validate qw(:all);
use Scalar::Util;
use List::MoreUtils;

use DBIx::ObjectMapper::Utils;
use DBIx::ObjectMapper::Metadata::Table::Column;
use DBIx::ObjectMapper::Query;
use DBIx::ObjectMapper::Metadata::Table::Column::TypeMap;

sub DEFAULT_NAMESEP          {'.'}
sub DEFAULT_COLUMN_METACLASS {'DBIx::ObjectMapper::Metadata::Table::Column'}
sub DEFAULT_QUERY_CLASS      {'DBIx::ObjectMapper::Query'}

sub new {
    my $class = shift;

    my ( $table_name, $column, $param ) = validate_pos(
        @_,
        { type => SCALAR|ARRAYREF },
        { type => ARRAYREF|SCALAR },
        { type => HASHREF, optional => 1 },
    );

    my @init_attr = (
        +{ table_name  => $table_name },
        +{ engine      => undef },
        +{ primary_key => +[] },
        +{ unique_key  => +[] },
        +{ foreign_key => +[] },
        +{ readonly    => +[] },
        +{ utf8        => +[] },
        +{ default     => +{} },
        +{ on_update   => +{} },
        +{ coerce      => +{} },
        +{ validation  => +{} },
        +{ autoload    => undef },
    );

    my $self = bless +{}, $class;

    my $DEFAULT_COLUMN_METACLASS = DEFAULT_COLUMN_METACLASS();
    $self->{column_metaclass} = $param->{column_metaclass}
        || $DEFAULT_COLUMN_METACLASS;

    confess
        "column_metaclass is not $DEFAULT_COLUMN_METACLASS (or a subclass)"
        unless $self->{column_metaclass}->isa($DEFAULT_COLUMN_METACLASS);

    $self->{query_class} = $param->{query_class} || DEFAULT_QUERY_CLASS();

    for my $attr ( @init_attr ) {
        my @key = keys %$attr;
        my $meth = $key[0];
        $self->{$meth} = $attr->{$meth};
        $self->${meth}($param->{$meth}) if exists $param->{$meth};
    }

    if( $column and $column eq 'autoload') {
        $self->{autoload} = 1;
        $self->autoload();
        $column = [];
    }

    $self->column( $column );

    return $self;
}


=head2 table_name

=cut

sub table_name {
    my $self = shift;

    if( $self->is_clone ) {
        return $self->{table_name}->[0];
    }
    else {
        return $self->{table_name};
    }
}

=head2 alias_name

=cut

sub alias_name {
    my $self = shift;
    return $self->{table_name}->[1] if $self->is_clone;
    return;
}


=head2 engine

=cut

sub engine {
    my $self = shift;

    if( @_ ) {
        my ($engine) = validate_pos(
            @_,
            { type => OBJECT, isa => 'DBIx::ObjectMapper::Engine' }
        );

        $self->{engine} = $engine;
    }

    return $self->{engine};
}

=head2 primary_key

=cut

sub primary_key {
    my $self = shift;
    $self->__array_accessor('primary_key', @_);
}

=head2 unique_key

=cut

sub unique_key {
    my $self = shift;

    if( @_ == 2 ) {
        my ( $name, $keys ) = validate_pos(
            @_,
            { TYPE => SCALAR },
            { TYPE => ARRAYREF },
        );

        my $exists = 0;
        my $exists_elm = 0;
        for my $uk ( @{$self->{unique_key}} ) {
            $exists_elm++;
            if ($uk->[0] eq $name
                || DBIx::ObjectMapper::Utils::is_deeply(
                    [ sort @{ $uk->[1] } ],
                    [ sort @$keys ]
                )
            ) {
                $exists = 1;
                last;
            }
        }

        if( $exists ) {
            return splice(
                @{ $self->{unique_key} },
                ( $exists_elm - 1 ),
                1,
                [ $name, $keys ]
            );
        }
        else {
            push @{$self->{unique_key}}, [ $name, $keys ];
        }

        return [ $name, $keys ];
    }
    elsif( @_ == 1 and !ref($_[0]) ) {
        my $name = shift;
        for my $uk ( @{$self->{unique_key}} ) {
            return $uk->[1] if $uk->[0] eq $name;
        }
    }
    elsif( @_ == 1 and ref($_[0]) eq 'ARRAY' and ref($_[0]->[0]) eq 'ARRAY') {
        return [ map{ $self->unique_key(@$_) } @{$_[0]} ];
    }
    elsif( @_ == 1 && ref($_[0]) eq 'ARRAY' and !ref($_[0]->[0]) ) {
        return $self->unique_key( @{$_[0]} );
    }
    else {
        return $self->{unique_key};
    }
}

=head2 foreign_key

=cut

sub foreign_key {
    my $self = shift;

    if( $_[0] and ref($_[0]) eq 'HASH' ) {
        my @param = %{$_[0]};
        my %foreign_key = validate(
            @param,
            {
                keys  => { type => ARRAYREF },
                table => { type => SCALAR },
                refs  => { type => ARRAYREF},
            }
        );
        push @{$self->{foreign_key}}, \%foreign_key;
    }
    elsif( $_[0] and ref($_[0]) eq 'ARRAY' ) {
        $self->foreign_key($_) for @{$_[0]};
    }

    return $self->{foreign_key};
}

=head2 get_foreign_key_by_col

=cut

sub get_foreign_key_by_col {
    my $self = shift;
    my $col  = shift || return;

    my @foreign_key;
    for my $fk ( @{$self->{foreign_key}} ) {
        if( @{$fk->{keys}} == 1 and !ref($col) ) {
            push( @foreign_key, $fk ) if $fk->{keys}->[0] eq $col;
        }
        elsif( ref($col) eq 'ARRAY' ) {
            my %col_map = map{ $_ => 1 } @$col;
            push( @foreign_key, $fk )
                if List::MoreUtils::all { exists $col_map{$_} }
                @{ $fk->{keys} };
        }
    }

    return \@foreign_key;
}

=head2 get_foreign_key_by_table

=cut

sub get_foreign_key_by_table {
    my $self = shift;
    my $table = shift || return;

    my $table_name = $table->table_name;
    for my $fk ( @{$self->{foreign_key}} ) {
        return $fk if $fk->{table} eq $table_name;
    }
    return;
}

sub __array_accessor {
    my $self = shift;
    my $accessor = shift;

    if( @_ ) {
        my ($array_val) = validate_pos( @_, { type => ARRAYREF } );
        $self->{$accessor} = $array_val;
        my $i = 0;
        $self->{$accessor . '_map'} = +{ map{ $_ => ++$i } @$array_val };
    }

    return $self->{$accessor};
}

sub readonly {
    my $self = shift;
    return $self->__array_accessor('readonly', @_);
}

sub readonly_map { $_[0]->{readonly_map} ||= +{} }

sub utf8 {
    my $self = shift;
    return $self->__array_accessor('utf8', @_);
}

sub utf8_map { $_[0]->{utf8_map} ||= +{} }

sub __hash_accessor {
    my $self = shift;
    my $accessor = shift;

    if( @_ ) {
        my ($hash_val) = validate_pos( @_, { type => HASHREF } );
        my $new_val = DBIx::ObjectMapper::Utils::merge_hashref(
            $self->{$accessor}, $hash_val,
        );
        $self->{$accessor} = $new_val;
    }
    return $self->{$accessor};
}

sub default {
    my $class = shift;
    $class->__hash_accessor('default', @_);
}

sub on_update {
    my $class = shift;
    $class->__hash_accessor('on_update', @_);
}

sub coerce {
    my $class = shift;
    $class->__hash_accessor('coerce', @_);
}

sub validation {
    my $class = shift;
    $class->__hash_accessor('validation', @_);
}



=head2 autoload

=cut

sub autoload {
    my $self = shift;

    confess "autoload needs engine."    unless $self->engine;
    confess "autoload needs table_name" unless $self->table_name;
    my $engine = $self->engine;
    $self->{column_map} ||= +{};

    my @primary_key = $self->engine->get_primary_key( $self->table_name );
    $self->primary_key(\@primary_key);

    my $uniq_key = $self->engine->get_unique_key( $self->table_name );
    $self->unique_key($uniq_key);

    my $foreign_key = $self->engine->get_foreign_key( $self->table_name );
    $self->foreign_key($foreign_key);

    for my $conf ( @{$engine->get_column_info( $self->table_name )} ) {
        my $type_class
            = DBIx::ObjectMapper::Metadata::Table::Column::TypeMap->get(
            $conf->{type} );
        my $realtype = $conf->{type};
        $conf->{type} = $type_class->new();
        $conf->{type}->size($conf->{size});
        $conf->{type}->realtype($realtype);
        $conf->{server_default} = delete $conf->{default};
        $self->column( $conf );
    }
}

sub column {
    my $self = shift;

    if( @_ == 1 and !ref($_[0]) ) {
        my $name = shift;
        if( exists $self->column_map->{$name} ) {
            return $self->{columns}->[ $self->column_map->{$name} - 1 ];
        }
        else {
            return;
        }
    }
    elsif( @_ == 1 and ref($_[0]) eq 'HASH' ) {
        $self->_set_column($_[0]);
    }
    elsif( @_ == 1 and ref($_[0]) eq 'ARRAY' ) {
        $self->_set_column($_) for @{$_[0]};
    }
    elsif( @_ == 0 ) {
        return @{$self->columns};
    }
    else {
        confess '$obj->column(HashRef|Scalar|Void)';
    }
}

*c = \&column;

sub namesep {
    my $self = shift;
    if( $self->engine ) {
        return $self->engine->namesep;
    }
    else {
        return DEFAULT_NAMESEP();
    }
}

sub _set_column {
    my $self = shift;

    my $c = shift || return;
    ( ref($c) eq 'HASH' ) || return;

    my $override_column = $self->column_map->{ $c->{name} };
    if ( defined $override_column ) {
        my $org = $self->column( $c->{name} );
        $c = DBIx::ObjectMapper::Utils::merge_hashref( { %$org }, $c );
    }

    my $name = delete $c->{name} || confess 'column name not found.';

    if( delete $c->{primary_key} ) {
        my $primary_key = $self->primary_key;
        push @{$primary_key}, $name;
        $self->primary_key($primary_key);
    }

    if( delete $c->{unique} ) {
        $self->unique_key( 'c_uniq_' . $name . '' => [$name] );
    }

    if( my $fk = delete $c->{foreign_key} ) {
        $self->foreign_key({
            keys  => [ $name ],
            table => $fk->[0],
            refs  => [ $fk->[1] ],
        });
    }

    my $to_storage;
    if( $c->{to_storage} ) {
        $to_storage = $c->{to_storage};
    }
    elsif( $self->coerce->{$name} ) {
        $to_storage = $self->coerce->{$name}{to_storage};
    }

    my $from_storage;
    if( $c->{from_storage} ) {
        $from_storage = $c->{from_storage};
    }
    elsif( $self->coerce->{$name} ) {
        $from_storage = $self->coerce->{$name}{from_storage};
    }

    my $default = $self->default->{$name} || do {
        if( $c->{default} ) {
            $self->default->{$name} = $c->{default};
        }
        else {
            undef;
        }
    };

    my $on_update = $self->on_update->{$name} || do {
        if( $c->{on_update} ) {
            $self->on_update->{$name} = $c->{on_update};
        }
        else {
            undef;
        }
    };

    $c->{type}->utf8(1) if $self->utf8_map->{$name};

    my $readonly = $self->readonly_map->{$name} || do {
        if ( $c->{readonly} ) {
            push @{ $self->readonly }, $name;
            $self->readonly_map->{$name}
                = scalar( @{ $self->readonly } );
        }
        else {
            undef;
        }
    };

    my $validation = $self->validation->{$name} || do {
        if( $c->{validation} ) {
            $self->validation->{$name} = $c->{validation};
        }
        else {
            undef;
        }
    };

    $c->{is_nullable} = 1 unless exists $c->{is_nullable};

    if( my $engine = $self->engine ) {
        $c->{type}->set_engine_option($engine);
    }

    my $column_obj = $self->column_metaclass->new(
        name           => $name,
        table          => $self->table_name,
        sep            => $self->namesep,
        type           => $c->{type} || undef,
        is_nullable    => $c->{is_nullable},
        default        => $default,
        server_default => $c->{server_default} || undef,
        server_check   => $c->{server_check}   || undef,
        on_update      => $on_update,
        readonly       => $readonly,
        to_storage     => $to_storage || undef,
        from_storage   => $from_storage || undef,
        validation     => $validation,
    );

    if ($override_column) {
        splice( @{ $self->{columns} }, $override_column - 1, 1, $column_obj );
    }
    else {
        push @{ $self->{columns} }, $column_obj;
        $self->column_map->{$name} = scalar( @{ $self->{columns} } );
    }

    return $column_obj;
}

sub columns          { $_[0]->{columns} }
sub column_map       { $_[0]->{column_map} ||= +{} }
sub column_metaclass { $_[0]->{column_metaclass} }

sub query_object {
    my $self = shift;
    return $self->{query_object} ||= $self->{query_class}->new($self->engine);
}

sub select {
    my $self = shift;
    return $self->query_object->select( $self->_select_query_callback )
        ->column(@{$self->columns})->from( $self );
}

sub _select_query_callback {
    my $self = shift;
    return sub {
        my ( $result, $query ) = @_;

        my $column = @{$query->column} > 0 ? $query->column : $self->columns;
        my %result;

        for my $i ( 0 .. $#{$column} ) {
            next unless defined $result->[$i];
            if( ref $column->[$i] eq 'ARRAY' ) { # AS(alias)
                my $col_obj
                    = $self->_get_column_object_from_query( $column->[$i] );
                if( $col_obj ) {
                    $self->_select_query_callback_core(
                        $col_obj,
                        $column->[$i][1],
                        \%result,
                        $result,
                        $i
                    );
                }
                else {
                    $result{$column->[$i][1]} = $result->[$i];
                }
            }
            elsif( ref $column->[$i] eq 'HASH' ) { # Function
                $result{( keys %{ $column->[$i] } )[0]} = $result->[$i];
            }
            # Function 2
            elsif( ref $column->[$i] eq $self->{column_metaclass} . '::Func' ){
                my @funcs = @{$column->[$i]{func}};
                $result{$funcs[$#funcs]} = $result->[$i];
            }
            else {
                my $col_obj
                    = $self->_get_column_object_from_query( $column->[$i] );
                $self->_select_query_callback_core(
                    $col_obj,
                    $col_obj->name,
                    \%result,
                    $result,
                    $i
                );
            }
        }

        return \%result;
    };
}

sub _select_query_callback_core {
    my ( $self, $col_obj, $col_name, $result, $row, $i ) = @_;
    if ($col_obj->table eq $self->table_name
        or (    $self->alias_name
            and $col_obj->table eq $self->alias_name )
        )
    {
        $result->{ $col_name } = $col_obj->from_storage( $row->[$i] );
    }
    else {
        $result->{ $col_obj->table }->{ $col_name }
            = $col_obj->from_storage( $row->[$i] );
    }
}

sub _get_column_object_from_query {
    my ( $self, $c ) = @_;

    if( ref($c) eq $self->column_metaclass ) {
        return $c;
    }
    elsif ( ref($c) eq 'ARRAY' ) { # alias
        return $self->_get_column_object_from_query( $c->[0] );
    }
    elsif( ref($c) eq 'HASH' ) { # function
        my $val = ( values %$c )[0];
        if( ref $val eq 'ARRAY' ) {
            for my $v ( @$val ) {
                if( my $r = $self->_get_column_object_from_query($v) ) {
                    return $r;
                }
            }
        }
        else {
            return $self->_get_column_object_from_query($val);
        }
    }
    elsif( ref($c) eq $self->column_metaclass . '::Func' ) {
        return $c;
    }
    elsif( !ref($c) && $self->c($c) ) {
        return $self->c($c)
    }
    else {
        return;
    }
}

sub count {
    my $self = shift;
    return $self->query_object->count->from( $self );
}

sub find {
    my $self = shift;
    my $cond = shift;
    my @cond = $self->cast_condition($cond);
    my ( $type, @uniq_cond ) = $self->get_unique_condition(\@cond);
    confess "condition is not unique." unless @uniq_cond;
    $self->_find(@cond);
}

sub _find {
    my $self = shift;
    return $self->select->where(@_)->execute->first;
}

sub cast_condition {
    my ( $self, $cond ) = @_;

    if ( !ref $cond and defined $cond and @{ $self->primary_key } == 1 ) {
        return  map { $self->c($_) == $cond } @{ $self->primary_key };
    }
    elsif ( ref $cond eq 'HASH' ) {
        return map { $self->c($_) == $cond->{$_} } keys %$cond;
    }
    elsif ( ref $cond eq 'ARRAY'
        and !ref $cond->[0]
        and @$cond == @{ $self->primary_key } )
    {
        return  map { $self->c($_) == shift(@$cond) } @{ $self->primary_key };
    }
    elsif ( ref $cond eq 'ARRAY'
        and ref $cond->[0] eq 'ARRAY'
        and ref $cond->[0][0] eq $self->column_metaclass )
    {
        return @$cond;
    }
    else {
        return;
    }
}

sub get_unique_condition {
    my ( $self, $casted_cond ) = @_;

    confess "use cast_condition()." unless ref $casted_cond eq 'ARRAY';

    my %col;
    for my $c (@$casted_cond) {
        return unless $c->[1] eq '=';
        $col{ $c->[0]->name } = $c->[2];
    }

    my ( $type, @cond );
    if ( List::MoreUtils::all { exists $col{$_} } @{ $self->primary_key } ) {
        $type = undef;
        @cond = map{ $self->c($_) == $col{$_} } @{$self->primary_key};
    }
    else {
        for my $uinfo ( @{ $self->unique_key } ) {
            if ( List::MoreUtils::all { exists $col{$_} } @{ $uinfo->[1] } ) {
                $type = $uinfo->[0];
                @cond = map { $self->c($_) == $col{$_} } @{ $uinfo->[1] };
            }
        }
    }

    return( $type, @cond );
}

sub insert {
    my $self = shift;
    my $query = $self->query_object->insert(
        $self->_insert_query_callback,
        $self->primary_key
    )->into( $self->table_name );
    $query->values(@_) if @_;
    return $query;
}

sub _insert_query_callback {
    my $self = shift;

    return sub {
        my $query = shift;
        my $dbh = shift;
        my $input_val = $query->values;
        return unless ref($input_val) eq 'HASH'; # XXXXX

        my %context = %$input_val;
        for my $c ( @{ $self->columns } ) {
            my $val = $c->to_storage(
                \%context,
                $dbh,
            );
            if( defined $val ) {
                $input_val->{ $c->name } = $val;
            }
            elsif( exists $input_val->{ $c->name } ) {
                delete $input_val->{ $c->name };
            }
        }
    };
}

sub delete {
    my $self = shift;
    my $query = $self->query_object->delete( $self->_delete_query_callback )
        ->table( $self->table_name );
    $query->where(@_) if @_;
    return $query;
}

sub _delete_query_callback { undef } # TODO cascade delete

sub update {
    my $self = shift;
    my ( $data, $cond ) = @_;
    my $query = $self->query_object->update( $self->_update_query_callback )
        ->table( $self->table_name );
    $query->set(%$data) if $data;
    $query->where( @$cond ) if $cond;
    return $query;
}

sub _update_query_callback {
    my $self = shift;

    return sub {
        my $query = shift;
        my $engine = shift;

        my %context = %{$query->set};
        for my $c ( @{ $self->columns } ) {
            my $val = $c->to_storage_on_update(
                \%context,
                $self->engine->dbh,
            );
            $query->set->{ $c->name } = $val if defined $val;
        }
    };
}

=head2 clone

=cut

sub clone {
    my $self = shift;
    my $alias = shift;

    my %data = %$self;
    my $obj = bless \%data, ref $self;

    if( $alias ) {
        $obj->{table_name} = [ $obj->table_name, $alias ];
        my @columns;
        for my $c ( @{$obj->columns} ) {
            my $new_col = $c->clone;
            $new_col->{table} = $alias;
            push @columns, $new_col;
        }
        $obj->{columns} = \@columns;
    }

    return $obj;
}

*as =\&clone;

=head2 is_clone

=cut

sub is_clone { ref($_[0]->{table_name}) eq 'ARRAY' }

sub DESTROY {
    my $self = shift;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

1;

__END__
