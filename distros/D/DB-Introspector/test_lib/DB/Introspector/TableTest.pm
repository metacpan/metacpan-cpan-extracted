package DB::Introspector::TableTest;

use strict;
use base qw( DB::IntrospectorBaseTest );

sub users_table {
    my $self = shift;
    unless( $self->{_users_table} ) {
        $self->{_users_table} = $self->_introspector->find_table("users");
        $self->assert(  defined $self->{_users_table}, 
                        "users table could not be found" );
    }
    return $self->{_users_table};
}



{
    my %table_primary_key = (
        'users' => {
            'order' => [qw(user_id)],
            'name_to_type' => {
                'user_id' => 'DB::Introspector::Base::IntegerColumn'
            }
        },
        'groups' => {
            'order' => [qw(group_id)],
            'name_to_type' => {
                'group_id' => 'DB::Introspector::Base::IntegerColumn'
            }
        },
        'grouped_users' => {
            'order' => [qw(group_id user_id)],
            'name_to_type' => {
                'group_id' => 'DB::Introspector::Base::IntegerColumn',
                'user_id' => 'DB::Introspector::Base::IntegerColumn'
            }
        },
        'grouped_user_images' => {
            'order' => [qw(group_id user_id)],
            'name_to_type' => {
                'group_id' => 'DB::Introspector::Base::IntegerColumn',
                'user_id' => 'DB::Introspector::Base::IntegerColumn'
            }
        },
    );

    sub test_primary_key {
        my $self = shift;

        foreach my $table_name ( keys %table_primary_key ) {
            my $table = $self->_introspector->find_table($table_name);
            $self->assert(defined $table, 
                          "table $table_name could not be found");

            my $key = $table_primary_key{$table_name};
            my @ordered_names = @{$key->{order}};
            my @real_names = map{ $_->name; } $table->primary_key;

            foreach my $i (0..$#ordered_names) {
                $self->assert($ordered_names[$i] eq $real_names[$i],
                   "expected ".$ordered_names[$i]." found ".$real_names[$i]);

                $self->assert(
                      ref($table->primary_key_column($real_names[$i]))
                   eq $key->{name_to_type}{$real_names[$i]},
                        "found "
                        .ref($table->primary_key_column($real_names[$i]))
                      ." expected " 
                        .$key->{name_to_type}{$real_names[$i]});
            }

        }
    }

}

{
    my @ordered_column_names = qw( user_id username signup active );
    my %users_column_names = (
        'user_id' => 'DB::Introspector::Base::IntegerColumn',
        'username' => 'DB::Introspector::Base::StringColumn',
        'signup' => 'DB::Introspector::Base::DateTimeColumn',
        'active' => 'DB::Introspector::Base::BooleanColumn',
    );
    sub test_column_names {
        my $self = shift;
    
        my @names = $self->users_table->column_names();

        $self->assert( scalar(keys %users_column_names) == scalar(@names) );

        # making sure the driver preserves order in their list
        foreach my $index (0..$#ordered_column_names) {
            $self->assert( $ordered_column_names[$index] eq $names[$index], 
                $names[$index]." when expected ".$ordered_column_names[$index]);
        }
    }


    sub test_columns {
        my $self = shift;

        my @columns = $self->users_table->columns();

        $self->assert( scalar(keys %users_column_names) == scalar(@columns) );

        # making sure the driver preserves order in their column list
        foreach my $index (0..$#columns) {
            my $column = $columns[$index];
            my $name = $column->name;

            $self->assert( $ordered_column_names[$index] eq $name,
                "found $name when expected $ordered_column_names[$index]");

            $self->assert( UNIVERSAL::isa($column, $users_column_names{$name}),
                            "$name is not a valid type: ".ref($column));
        }

        foreach my $column (@columns) {
            my $name = $column->name();

        }
    }

    sub test_column {
        my $self = shift;
        my $table = $self->users_table;

        foreach my $name (keys %users_column_names) {
            my $column = $table->column($name);
            $self->assert( defined $column, "$name is not defined" );
            $self->assert( UNIVERSAL::isa(  $table->column($name), 
                                            $users_column_names{$name} ),
                "$name has an invalid type");
        }
    }
}

{
    my %foreign_keys = (
        'grouped_users' => {
            'groups|group_id' => {
                local_column_names => [qw(group_id)],
                foreign_column_names => [qw(group_id)],
                foreign_table => q(groups)
            },
            'users|user_id' => {
                local_column_names => [qw(user_id)],
                foreign_column_names => [qw(user_id)],
                foreign_table => q(users)
            },
        },
        'grouped_user_images' => {
            'grouped_users|group_id|user_id' => {
                local_column_names => [qw(group_id user_id)],
                foreign_column_names => [qw(group_id user_id)],
                foreign_table => q(grouped_users),
            }
        }
    );

    sub test_foreign_keys {
        my $self = shift;

        foreach my $table_name (keys %foreign_keys) {
            my $table = $self->_introspector->find_table($table_name);
            foreach my $foreign_key ($table->foreign_keys) {

                my $local_columns = join("|", $foreign_key->local_column_names);
                my $foreign_table = $foreign_key->foreign_table->name;
                my $key = "$foreign_table|$local_columns";
                my $test_data = $foreign_keys{$table_name}{$key};

                $self->assert(defined $test_data, 
                            "$key foreign key not found for table $table_name");

                foreach my $method (keys %$test_data) {
                    my (@values, @response);
                    # if we have a reference we are dealing with an array
                    if( ref($test_data->{$method}) ) { 
                        @values = @{$test_data->{$method}};
                        @response = $foreign_key->$method;
                    # otherwise, we are dealing with a table name
                    } else {
                        @values = ($test_data->{$method});
                        @response = $foreign_key->$method->name;
                    }
                    for my $index (0..$#values) {
                     $self->assert($values[$index] eq $response[$index],
                      "found $response[$index] when expecting $values[$index]");
                    }
                }
            }
        }
    }

}


{
    my %dependencies = (
        'users' => {
            'grouped_users|user_id' => {
                local_table => q(grouped_users),
                local_column_names => [qw(user_id)],
                foreign_column_names => [qw(user_id)],
                foreign_table => q(users)
            },
        },
        'grouped_users' => {
            'grouped_user_images|group_id|user_id' => {
                local_column_names => [qw(group_id user_id)],
                foreign_column_names => [qw(group_id user_id)],
                foreign_table => q(grouped_users),
                local_table => q(grouped_user_images),
            }
        }
    );

    sub test_dependencies {
        my $self = shift;

        foreach my $table_name (keys %dependencies) {
            my $table = $self->_introspector->find_table($table_name);
#warn($table->name, " <- ", map {$_->local_table->name} $table->dependencies);
#use Data::Dumper;
#warn( Dumper [$table->dependencies] ); 

            $self->assert(
                $table->dependencies == keys %{$dependencies{$table_name}},
                "incorrect number of dependencies for table ".$table->name."."
                ." Found:"
                    .scalar($table->dependencies)
                ." Expected:".scalar(keys %{$dependencies{$table_name}}));

            foreach my $foreign_key ($table->dependencies) {

                my $local_columns = join("|", $foreign_key->local_column_names);
                my $foreign_table = $foreign_key->foreign_table->name;
                my $local_table = $foreign_key->local_table->name;
                my $key = "$local_table|$local_columns";
                my $test_data = $dependencies{$table_name}{$key};

                $self->assert(defined $test_data, 
                            "$key foreign key not found for table $table_name");

                foreach my $method (keys %$test_data) {
                    my (@values, @response);
                    # if we have a reference we are dealing with an array
                    if( ref($test_data->{$method}) ) { 
                        @values = @{$test_data->{$method}};
                        @response = $foreign_key->$method;
                    # otherwise, we are dealing with a table name
                    } else {
                        @values = ($test_data->{$method});
                        @response = $foreign_key->$method->name;
                    }
                    for my $index (0..$#values) {
                     $self->assert($values[$index] eq $response[$index],
                      "found $response[$index] when expecting $values[$index]");
                    }
                }
            }
        }
    }

}




1;
