package DB::Introspector::CommonRDB::Introspector;

use strict;

use base qw( DB::Introspector );

use constant TABLE_NAME_COL => 'TABLE_NAME';
use constant OWNER_NAME_COL => 'OWNER_NAME';


## ABSTRACT METHODS

sub get_single_table_lookup_statement {
    die("get_table_lookup_statement not defined");
}

sub get_all_tables_lookup_statement {
    die("get_all_tables_lookup_statement not defined");
}

sub get_table_class {
    die("get_table_class not defined");
}


## DEFINED METHODS

sub lookup_table {
    my $self = shift;
    my $table_name = shift;

    my $sth = $self->get_single_table_lookup_statement($table_name);
    my $row = $sth->fetchrow_hashref('NAME_uc');
    $sth->finish();
    return undef unless( defined $row );

    return $self->get_table_instance($row->{TABLE_NAME_COL()},
                                     $row->{OWNER_NAME_COL()});
}

sub lookup_all_tables {
    my $self = shift;
    my $table_name = shift;

    my $sth = $self->get_all_tables_lookup_statement();

# TODO: use cache
    my @results; 
    while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
        my $table = $self->get_table_instance($row->{TABLE_NAME_COL()},
                                              $row->{OWNER_NAME_COL});
        push(@results, $table);
    }
    $sth->finish();

    return @results; 
}

sub get_table_instance {
    my $self = shift;
    my $table_name = shift;
    my $owner_name = shift;

    return $self->get_table_class->new($table_name, $owner_name, $self);
}


package DB::Introspector::CommonRDB::Table;

use base qw( DB::Introspector::Base::Table );

use strict;


use constant COLUMN_NAME_COL => 'COLUMN_NAME';


## ABSTRACT METHODS

sub get_column_lookup_statement {
    die("get_column_lookup_statement not defined");
}

sub get_indexes_lookup_statement {
    die("get_indexes_lookup_statement not defined");
}

sub get_foreign_keys_lookup_statement {
    die("get_foreign_keys_lookup_statement not defined");
}

sub get_dependencies_lookup_statement {
    die("get_dependencies_lookup_statement not defined");
}

sub get_functional_index_class {
    my $self = shift;
    return $self->get_index_class(@_);
}

sub get_column_instance {
    my $self = shift;
    my $name = shift;
    my $type = shift;
    die("get_column_instance not defined");
}

sub get_foreign_key_class {
    die("get_foreign_key_class not defined");
}

sub get_dependency_class {
    die("get_dependency_class not defined");
}

sub get_primary_key_column_ids {
    die("get_primary_key_column_ids not defined");
}

## DEFINED METHODS

sub primary_key {
    my $self = shift;
    
    unless(defined $self->{_primary_key}) {
        my @primary_key;
        my @column_ids = $self->get_primary_key_column_ids;
        my @columns = $self->columns;

        foreach my $column_id (@column_ids) {
            push(@primary_key, $columns[$column_id]); 
        }
        $self->{_primary_key} = \@primary_key;
    }
    return @{$self->{_primary_key}};
} 

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $introspector = $_[2];

    unless( UNIVERSAL::isa($introspector, 'DB::Introspector') ) {
        die("$class constructor requires introspector");
    }

    $self->{_introspector} = $introspector;
    $self;
}

sub _introspector {
    my $self = shift;
    return $self->{_introspector};
}

use DB::Introspector::Base::SpecialColumn;
sub columns {
    my $self = shift;

    unless( defined $self->{'columns'} ) { 
        my $sth = $self->get_column_lookup_statement();

        my @columns;
        while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
            my $column = $self->get_column_instance(
                $row->{NAME}, $row->{TYPE}, $row) 
            || DB::Introspector::Base::SpecialColumn
               ->new($row->{NAME}, $row->{TYPE});
            
            push(@columns, $column);
        }
        $sth->finish();

        $self->{'columns'} = \@columns;
    }

    return @{$self->{'columns'}};
}

sub foreign_keys {
    my $self = shift;

    unless( defined $self->{'foreign_keys'} ) { 
        $self->{'foreign_keys'} = $self->_lookup_foreign_keys;
    }

    return @{$self->{'foreign_keys'}};
}

sub indexes {
    my $self = shift;

    unless( defined $self->{'indexes'} ) { 
        $self->{'indexes'} = $self->_lookup_indexes;
    }

    return @{$self->{'indexes'}};
}

sub dependencies {
    my $self = shift;

    unless( defined $self->{'dependencies'} ) {
        $self->{'dependencies'} = $self->_lookup_dependencies;
    }

    return @{$self->{'dependencies'}};
}

sub _lookup_foreign_keys {
    my $self = shift;
    my $sth = $self->get_foreign_keys_lookup_statement();

    my @foreign_keys;
    while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
        my $foreign_key = $self->get_foreign_key_class()->new($self,0, %$row);
        push(@foreign_keys, $foreign_key);
    }
    $sth->finish();

    return \@foreign_keys;
}

use constant FUNCTIONAL => 'FUNCTIONAL';
sub _lookup_indexes {
    my $self = shift;
    my $sth = $self->get_indexes_lookup_statement();

    my @indexes;
    while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
        if(defined($row->{INDEX_TYPE}) && $row->{INDEX_TYPE} eq FUNCTIONAL()) {
          push(@indexes,$self->get_functional_index_class()->new($self, %$row));
        } else {
          push(@indexes, $self->get_index_class()->new($self, %$row));
        }
    }
    $sth->finish();

    return \@indexes;
}

sub _lookup_dependencies {
    my $self = shift;
    my $sth = $self->get_dependencies_lookup_statement();

    my @dependencies;
    while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
        my $local_table = 
            $self->_introspector->find_table( $row->{CHILD_TABLE_NAME} )
            || die("no child table found for dependency");
        my $dependency = $self->get_foreign_key_class()->new($local_table, 1,
                                                             %$row);
        push(@dependencies, $dependency);
    }
    $sth->finish();

    return \@dependencies;
}


package DB::Introspector::CommonRDB::ForeignKey;

use strict;

use base qw( DB::Introspector::Base::ForeignKey );


## ABSTRACT METHODS

sub get_local_column_name_lookup_statement {
    die("get_local_column_name_lookup_statement not defined");
}

sub get_foreign_column_name_lookup_statement {
    die("get_foreign_column_name_lookup_statement not defined");
}

sub get_foreign_table_name_lookup_statement {
    die("get_foreign_table_name_lookup_statement not defined");
}


## DEFINED METHODS

sub local_column_names {
    my $self = shift;

    unless( defined $self->{'local_column_names'} ) {
        my $sth = $self->get_local_column_name_lookup_statement();

        my @local_column_names;
        while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
            push(@local_column_names, $row->{NAME});
        }
        $sth->finish();

        $self->{'local_column_names'} = \@local_column_names;
    }

    return @{$self->{'local_column_names'}};
} 

sub foreign_column_names {
    my $self = shift;

    unless( defined $self->{'foreign_column_names'} ) {
        $self->{'foreign_column_names'} = $self->_populate_foreign_column_names;
    }

    return @{$self->{'foreign_column_names'}};
} 

sub _populate_foreign_column_names {
   my $self = shift;

   my $sth = $self->get_foreign_column_name_lookup_statement();

   my @foreign_column_names;
   while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
            push(@foreign_column_names, $row->{NAME});
   }
   $sth->finish();

   return \@foreign_column_names;
}

sub set_foreign_column_names {
    my $self = shift;
    return unless(@_);

    $self->{foreign_column_names} = shift;
}

sub set_local_column_names {
    my $self = shift;
    return unless(@_);

    $self->{local_column_names} = shift;
}

sub set_foreign_table_name {
    my $self = shift;
    return unless(@_);

    $self->{foreign_table_name} = shift;
}

sub foreign_table_name {
    my $self = shift;

    unless( defined $self->{'foreign_table_name'} ) {
        my $sth = $self->get_foreign_table_name_lookup_statement();

        my $row = $sth->fetchrow_hashref('NAME_uc');
        $sth->finish();

        $self->set_foreign_table_name($row->{NAME});
    }

    return $self->{'foreign_table_name'};
} 

sub foreign_table {
    my $self = shift;

    unless( defined $self->{'foreign_table'} ) {
        $self->{'foreign_table'} = $self->local_table
                                        ->_introspector
                                        ->find_table($self->foreign_table_name);
    }
    return $self->{'foreign_table'};
} 



package DB::Introspector::CommonRDB::Index;

use strict;

use base qw( DB::Introspector::Base::Index );


sub get_column_name_lookup_statement {
    die("get_column_name_lookup_statement not defined");
}

## DEFINED METHODS

sub column_names {
    my $self = shift;

    unless( defined $self->{'column_names'} ) {
        my $sth = $self->get_column_name_lookup_statement();

        my @column_names;
        while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {
            push(@column_names, $row->{NAME});
        }
        $sth->finish();

        $self->{'column_names'} = \@column_names;
    }

    return @{$self->{'column_names'}};
} 

sub set_column_names {
    my $self = shift;
    return unless(@_);

    $self->{column_names} = shift;
}


1;
