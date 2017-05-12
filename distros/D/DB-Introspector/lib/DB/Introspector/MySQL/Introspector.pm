package DB::Introspector::MySQL::Introspector;

use strict;
use base qw( DB::Introspector );


sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_db_tables} = {};
    $self->lookup_mysql_tables;
    return $self;
}

sub lookup_table {
    my $self = shift;
    my $table_name = shift;

    return $self->{_db_tables}{$table_name} if( defined $table_name );
}

sub lookup_all_tables {
    my $self = shift;

    return values %{$self->{_db_tables}}
}

sub add_table {
    my $self = shift;
    my $table = shift;

    $self->{_db_tables} ||= {};

    $self->{_db_tables}{$table->name} = $table;
}

sub lookup_mysql_tables {
    my $self = shift;


    my $sth = $self->dbh->prepare('SHOW TABLE STATUS');
    $sth->execute();

    while( my $row = $sth->fetchrow_hashref('NAME_lc') ) {
        my $class = $self->_get_mysql_table_class_for_type($row->{type});
        my $table = $class->new($self, $row->{name});

        my @table_info = split(';', $row->{comment});
        foreach my $create_option (@table_info) {
            if( $create_option =~ /\sREFER\s/ ) {
                my ($foreign_key, $dependency) = 
                    $self->_get_foreign_key_and_dependency_for_table_option(
                    $table,
                    $create_option);
                my $foreign_table = $self->lookup_table(
                                    $foreign_key->foreign_table_name);
                unless( defined $foreign_table ) {
                    $self->_save_dependency(
                        $foreign_key->foreign_table_name, $dependency);
                } else {
                    $foreign_table->add_dependencies($dependency);
                }

                $table->add_foreign_keys($foreign_key);
            }
        }
        $table->add_dependencies(
            $self->_flush_saved_foreign_key_dependencies($table->name));

        $self->add_table($table);
    }
    $sth->finish;
}

# (column1,column2,...) REFER database/table_name(column1,column2,...)
sub _get_foreign_key_and_dependency_for_table_option {
    my $self = shift;
    my $table = shift;
    my $table_option = shift;

    die("$table_option is not a valid reference") 
        unless($table_option =~ /\sREFER\s/);

    my ($local_side, $foreign_side) = split(/\sREFER\s/, $table_option); 
    $local_side =~ s/\s+//g; 
    $local_side =~ s/.*\((.*)\)/$1/g;
    my @local_column_names = split(',', $local_side);

    $foreign_side =~ s/\s+//g;
    my ($foreign_database, $foreign_table_name, $foreign_column_list) = 
        ($foreign_side =~ /(\w+)\/(\w+)\((.*)\).*/);

    my @foreign_column_names = split(',', $foreign_column_list);


    my $foreign_key = DB::Introspector::MySQL::ForeignKey->new($self,
                            $table,
                            \@local_column_names,
                            $foreign_table_name,
                            \@foreign_column_names);
    my $dependency = $foreign_key->clone();
    $dependency->_set_is_dependency(1);

    return ($foreign_key, $dependency);
}

sub _save_dependency {
    my $self = shift;
    my $table_name = shift;
    my $dependency = shift;

    $self->{_saved_dependencies} ||= {};
    $self->{_saved_dependencies}{$table_name} ||= {};

    my $name = join(",",$dependency->local_column_names);
    $self->{_saved_dependencies}{$table_name}{$name} = $dependency;
}

sub _flush_saved_foreign_key_dependencies {
    my $self = shift;
    my $table_name = shift;

    return values %{$self->{_saved_dependencies}{$table_name}};
}


use constant CLASS_FOR_TYPE => {
    'innodb' => 'DB::Introspector::MySQL::InnoDBTable',
};
use constant DEFAULT_CLASS => 'DB::Introspector::MySQL::Table';
sub _get_mysql_table_class_for_type {
    my $self = shift;
    my $type = lc(shift);
    
    return CLASS_FOR_TYPE()->{$type} || DEFAULT_CLASS();
}



package DB::Introspector::MySQL::ForeignKey;

use strict;

use base qw( DB::Introspector::Base::ForeignKey );

sub new {
    my $class = shift;
    my $introspector = shift;
    my $self = $class->SUPER::new(shift());
   
    $self->{_introspector} = $introspector; 
    $self->{_local_column_names} = shift; 
    $self->{_foreign_table_name} = shift; 
    $self->{_foreign_column_names} = shift; 
    $self;
}

sub local_column_names {
    my $self = shift;
    return @{$self->{_local_column_names}};
}

sub foreign_column_names {
    my $self = shift;
    return @{$self->{_foreign_column_names}};
}

sub foreign_table_name {
    my $self = shift;
    return $self->{_foreign_table_name};
}

sub _introspector {
    my $self = shift;
    return $self->{_introspector};
}

sub foreign_table {
    my $self = shift;
    unless( defined $self->{_foreign_table} ) {
        $self->{_foreign_table} = 
            $self->_introspector->find_table($self->foreign_table_name);
    }
    return $self->{_foreign_table};
}

sub _set_is_dependency {
    my $self = shift;
    if(@_) {
        $self->{_is_dependency} = shift;
    }
}

sub clone {
    my $self = shift;
    my %internal_data = %$self;
    return bless(\%internal_data, ref($self)); 
}



package DB::Introspector::MySQL::Table;

use strict;
use base qw( DB::Introspector::Base::Table );

sub new {
    my $class = shift;
    my $introspector = shift;

    my $self = $class->SUPER::new(@_);

    $self->{_dependencies} = {};
    $self->{_foreign_keys} = {};
    $self->{primary_key} = [];
    $self->{columns} = [];
    $self->{introspector} = $introspector;

    $self;
}

sub introspector {
    my $self = shift;
    return $self->{introspector};
}

sub add_dependencies {
    my $self = shift;
    foreach my $dependency (@_) {
        next unless defined $dependency;
        if(UNIVERSAL::isa($dependency, 'DB::Introspector::Base::ForeignKey')) {
            die("foreign_key is not a dependency") 
                                            unless($dependency->is_dependency);
            my $id = join("|",  $dependency->local_table->name, 
                                $dependency->local_column_names);
            $self->{_dependencies}{$id} = $dependency;
        } else {
            die("found ".ref($dependency)
                    ." instance, expected DB::Introspector::Base::ForeignKey");
        }
    }
}

sub add_foreign_keys {
    my $self = shift;
    foreach my $foreign_key (@_) {
        next unless defined $foreign_key;
        if(UNIVERSAL::isa($foreign_key, 'DB::Introspector::Base::ForeignKey')) {
            my $id = join("|",  $foreign_key->local_column_names);
            $self->{_foreign_keys}{$id} = $foreign_key;
        } else {
            die("found ".ref($foreign_key)
                    ." instance, expected DB::Introspector::Base::ForeignKey");
        }
    }
}

sub indexes {
    my $self = shift;
    unless( $self->{_fetched_indexes} ) {
        $self->_fetch_indexes;
    }
    return @{$self->{_indexes}};
}

sub columns {
    my $self = shift;
    unless( $self->{_fetched_columns} ) {
        $self->_fetch_columns;
    }
    return @{$self->{columns}};
}

sub primary_key {
    my $self = shift;
    unless( $self->{_fetched_columns} ) {
        $self->_fetch_columns;
    }
    return @{$self->{primary_key}};
}

use constant COLUMN_CALLBACKS => {
    q(tinyint) => 'construct_integer_column',
    q(smallint) => 'construct_integer_column',
    q(mediumint) => 'construct_integer_column',
    q(int) => 'construct_integer_column',
    q(bigint) => 'construct_integer_column',
    q(datetime) => 'construct_datetime_column',
    q(date) => 'construct_datetime_column',
    q(timestamp) => 'construct_datetime_column',
    q(time) => 'construct_datetime_column',
    q(year) => 'construct_datetime_column',
    q(tinytext) => 'construct_clob_column',
    q(text) => 'construct_clob_column',
    q(mediumtext) => 'construct_clob_column',
    q(longtext) => 'construct_clob_column',
    q(long) => 'construct_string_column',
    q(varchar) => 'construct_string_column',
    q(char) => 'construct_char_column',
};
# TODO: add further support for time columns (year,timestamp,etc.)
# TODO: add further support for blob columns (allthe texts)

sub _fetch_columns {
    my $self = shift;

    my $sth = $self->introspector->dbh->prepare_cached(
                'SHOW COLUMNS FROM '.$self->name);
    $sth->execute();

    while( my $row = $sth->fetchrow_hashref('NAME_lc') ) {
        my ($type, $attr) = ($row->{type} =~ /(\w+)\((\d+)\)/);
        $type = lc($type);
        my $callback = COLUMN_CALLBACKS()->{$type};
        my $column = (defined $callback) 
            ? DB::Introspector::MySQL::ColumnFactory
              ->$callback($row->{field},$type, $row->{null}, $attr)
            : DB::Introspector::Base::SpecialColumn->new($row->{field}, $type); 
        push(@{$self->{columns}}, $column);
        push(@{$self->{primary_key}}, $column) if($row->{key} eq 'PRI');
    }

    $self->{_fetched_columns} = 1;
    $sth->finish;
}

sub _fetch_indexes {
    my $self = shift;

    my $sth = $self->introspector->dbh->prepare_cached(
                'SHOW INDEX FROM '.$self->name);
    $sth->execute();

    my %indexes;
    while( my $row = $sth->fetchrow_hashref('NAME_lc') ) {
        $indexes{key_name} ||= DB::Introspector::MySQL::Index->new($self, 
                                                 !$row->{non_unique},
                                                 $row->{key_name});
        $indexes{key_name}->_set_column_name_for_index(
            $row->{column_name},$row->{seq_in_index}-1);
    }

    $self->{_indexes} = [values %indexes];
    $self->{_fetched_indexes} = 1;
    $sth->finish;
}


sub foreign_keys {
    my $self = shift;
    return values %{$self->{_foreign_keys}};
}

sub dependencies {
    my $self = shift;
    return values %{$self->{_dependencies}};
}

package DB::Introspector::MySQL::InnoDBTable;
use strict;
use base qw( DB::Introspector::MySQL::Table );


package DB::Introspector::MySQL::ColumnFactory;

use strict;
use DB::Introspector::Base::BooleanColumn;
use DB::Introspector::Base::CLOBColumn;
use DB::Introspector::Base::CharColumn;
use DB::Introspector::Base::Column;
use DB::Introspector::Base::DateTimeColumn;
use DB::Introspector::Base::IntegerColumn;
use DB::Introspector::Base::SpecialColumn;
use DB::Introspector::Base::StringColumn;

use constant INTEGER_MIN_MAX => {
        'tinyint' => [ '-128', '127' ],
        'smallint' => [ '-32768', '32767' ],
        'mediumint' => [ '-8388608', '8388607' ],
        'int' => [ '-2147483648', '2147483647' ],
        'bigint' => [ '-9223372036854775808', '9223372036854775807']
};
sub construct_integer_column {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $nullable = shift;
    my $default_padding_attr = shift;

    # normally I would calculate the min and max values for this int; however
    # there are some values that are too large to deal with so i am going to
    # hardcode this info
    my ($min,$max) = @{ INTEGER_MIN_MAX()->{$type} };
    my $column = new DB::Introspector::Base::IntegerColumn->new($name, $min, $max);
    $column->nullable($nullable);
    return $column;
}

sub construct_datetime_column {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $nullable = shift;
    my $default_padding_attr = shift;

    my $column = new DB::Introspector::Base::DateTimeColumn($name);
    $column->nullable($nullable);
    return $column;
}


sub construct_clob_column {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $nullable = shift;
    my $default_padding_attr = shift;

    my $column = new DB::Introspector::Base::CLOBColumn($name);
    $column->nullable($nullable);
    return $column;
}

sub construct_string_column {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $nullable = shift;
    my $max_width = shift;

    my $column = new DB::Introspector::Base::StringColumn($name, 0, $max_width);
    $column->nullable($nullable);
    return $column;
}

sub construct_char_column {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $nullable = shift;
    my $max_width = shift;

    my $column = new DB::Introspector::Base::CharColumn($name, 0, $max_width);
    $column->nullable($nullable);
    return $column;
}

package DB::Introspector::MySQL::Index;

use strict;
use base qw( DB::Introspector::Base::Index );


sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->{_name} = pop(@_);
    $self->{_column_names} = [];
    $self;
}

sub name { my $self = shift; return $self->{_name}; }

sub column_names {
    my $self = shift;
    return @{$self->{_column_names}};
}

sub _set_column_name_for_index {
    my $self = shift;
    my $column_name = shift;
    my $index = shift;
    $self->{_column_names}[$index] = $column_name;
}

1;
