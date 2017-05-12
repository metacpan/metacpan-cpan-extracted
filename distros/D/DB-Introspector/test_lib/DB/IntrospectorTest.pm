package DB::IntrospectorTest;

use strict;

use base qw( DB::IntrospectorBaseTest );

use DBI;


sub test_find_table {
    my $self = shift;
    my $table_name = 'UsErS';

    my $table = $self->_introspector->find_table($table_name);

    $self->assert( defined $table, "table: $table_name not found" );
    $self->assert( UNIVERSAL::isa($table, 'DB::Introspector::Base::Table') );
    $self->assert( lc($table->name) eq lc($table_name) );
    return 1;
}



{
    my %tables = (
        'users' => 1,
        'groups' => 1,
        'grouped_users' => 1,
        'grouped_user_images' => 1
    );
    sub test_find_all_tables {
        my $self = shift;
        my @tables = $self->_introspector->find_all_tables();  
    
        foreach my $table (@tables) {
            $self->assert(defined $tables{ lc($table->name) });
        }
    }
}



1;
