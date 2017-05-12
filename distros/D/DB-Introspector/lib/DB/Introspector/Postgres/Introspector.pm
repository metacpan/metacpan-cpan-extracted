package DB::Introspector::Postgres::Introspector;


use strict;

use base qw( DB::Introspector::CommonRDB::Introspector );

use constant SINGLE_TABLE_QUERY => 
'SELECT LOWER(relname) AS %s, relowner AS %s FROM pg_class 
 WHERE LOWER(relname)=?';

use constant ALL_TABLES_QUERY => 
q(SELECT LOWER(relname) AS %s, relowner AS %s FROM pg_class 
  WHERE relowner>1 AND relkind='r');

sub get_single_table_lookup_statement {
    my $self = shift;
    my $table_name = lc(shift);

    my $query = sprintf(SINGLE_TABLE_QUERY, 
                   &DB::Introspector::CommonRDB::Introspector::TABLE_NAME_COL,
                   &DB::Introspector::CommonRDB::Introspector::OWNER_NAME_COL);
    my $sth = $self->dbh->prepare_cached($query);
    $sth->execute($table_name);
    return $sth;
}


sub _cached_table {
    my $self = shift;
    my $table_name = lc(shift);
    $self->SUPER::_cached_table($table_name);
}

sub get_all_tables_lookup_statement {
    my $self = shift;

    my $query = sprintf(ALL_TABLES_QUERY, 
                   &DB::Introspector::CommonRDB::Introspector::TABLE_NAME_COL,
                   &DB::Introspector::CommonRDB::Introspector::OWNER_NAME_COL);
    my $sth = $self->dbh->prepare_cached($query);
    $sth->execute();
    return $sth;
}

sub get_table_class {
    return q(DB::Introspector::Postgres::Table);
}



package DB::Introspector::Postgres::Table;

use strict;

use base qw( DB::Introspector::CommonRDB::Table );


use DB::Introspector::Base::BooleanColumn;
use DB::Introspector::Base::IntegerColumn;
use DB::Introspector::Base::CharColumn;
use DB::Introspector::Base::StringColumn;
use DB::Introspector::Base::DateTimeColumn;
use DB::Introspector::Base::CLOBColumn;

use constant COLUMN_CLASS_MAPPING => {
    'bool' => 'DB::Introspector::Base::BooleanColumn',
    'int2' => 'DB::Introspector::Base::IntegerColumn',
    'int4' => 'DB::Introspector::Base::IntegerColumn',
    'int8' => 'DB::Introspector::Base::IntegerColumn',
    'bpchar' => 'DB::Introspector::Base::CharColumn',
    'varchar' => 'DB::Introspector::Base::StringColumn',
    'timestamptz' => 'DB::Introspector::Base::DateTimeColumn',
    'timestamp' => 'DB::Introspector::Base::DateTimeColumn',
    'text' => 'DB::Introspector::Base::CLOBColumn',
};



use constant COLUMN_QUERY =>
'SELECT LOWER(a.attname) AS NAME, t.typname AS TYPE 
    FROM pg_attribute a, pg_type t, pg_type r
    WHERE a.attrelid=r.typrelid 
        AND t.oid=a.atttypid
        AND a.attnum > 0 AND LOWER(r.typname)=?
    ORDER BY a.attnum';

use constant FOREIGN_KEYS_QUERY => 
'SELECT tr.tgnargs AS LENGTH, tr.tgargs AS ARGUMENTS 
 FROM pg_trigger tr, pg_type t 
 WHERE tr.tgisconstraint 
    AND tr.tgenabled 
    AND tr.tgrelid=t.typrelid 
    AND tr.tgargs like ? 
    GROUP BY tr.tgnargs, tr.tgargs';

use constant PRIMARY_KEYS_QUERY =>
'SELECT indkey AS IDS FROM  pg_index i, 
                            pg_type c 
 WHERE i.indisprimary and i.indrelid=c.typrelid and LOWER(c.typname)=?'; 

use constant INDEX_LOOKUP_QUERY =>
q(select i.relname AS name,        
         ind.indkey AS column_ids,
         ind.indisunique AS unique 
  FROM pg_class t, 
       pg_class i, 
       pg_index ind 
  WHERE ind.indexrelid=i.oid   
    AND ind.indrelid=t.oid
    AND t.relname=?);


use constant COLUMN_ARG_DELIM => '\0';

sub get_primary_key_column_ids {
    my $self = shift;

    unless( $self->{_primary_key_column_ids} ) {
        my $sth = $self->_introspector->dbh->prepare_cached(PRIMARY_KEYS_QUERY);
        $sth->execute(lc($self->name));
        my $fetched_row = $sth->fetchrow_hashref('NAME_lc');
        $sth->finish();
        my @ids = map { $_-1; } split(/\s+/, $fetched_row->{ids});
        $self->{_primary_key_column_ids} = \@ids;
    }
    return @{$self->{_primary_key_column_ids}};
} 

sub get_column_lookup_statement {
    my $self = shift;

    my $sth = $self->_introspector->dbh->prepare_cached(COLUMN_QUERY);

    $sth->execute(lc($self->name));

    return $sth;
}

sub get_indexes_lookup_statement {
    my $self = shift;

    my $sth = $self->_introspector->dbh->prepare_cached(INDEX_LOOKUP_QUERY);

    $sth->execute(lc($self->name));

    return $sth;
}

sub get_foreign_keys_lookup_statement {
    my $self = shift;

    my $sth = $self->_introspector->dbh->prepare_cached(FOREIGN_KEYS_QUERY);

    $sth->execute('%\000'.$self->name.'\000%');

    return $sth;
}

sub _lookup_dependencies {
    my $self = shift;

    my ($foreign_keys, $dependencies) = $self->_lookup_fk_triggers;

    return $dependencies;
}

sub _lookup_foreign_keys {
    my $self = shift;
    my ($foreign_keys, $dependencies) = $self->_lookup_fk_triggers;

    return $foreign_keys;
}


sub _lookup_fk_triggers {
    my $self = shift;

    my $sth = $self->get_foreign_keys_lookup_statement();

    my @foreign_keys;
    my @dependencies;

    my %visited_trigger;

    # I think the only way for us to know if we have a foreign key (as opposed
    # to another table referencing us) is to parse the arguments of the trigger
    # implementation and make sure that the 2nd element is equal to our table
    # name.  With the new dictionary tables (like pg_constraints) in Postgres
    # 7.3, I don't think we will have to do this.
    while( my $row = $sth->fetchrow_hashref('NAME_uc') ) {

        # Since triggers appear more than once, but with different ids, this
        # hack acts as a way to make these triggers unique.
        if( $visited_trigger{$row->{ARGUMENTS}} ) {
            next;
        } else {
            $visited_trigger{$row->{ARGUMENTS}} = 1;
        }
        
        my @column_args = split(COLUMN_ARG_DELIM, $row->{'ARGUMENTS'});
        if( lc($column_args[1]) eq lc($self->name) ) {
            # dealing with foreign keys referencing other tables
            my $foreign_key = $self->get_foreign_key_class()
                                                        ->new($self,0,%$row);
            push(@foreign_keys, $foreign_key);
        } elsif( lc($column_args[2]) eq lc($self->name) ) {
            # dealing with dependencies referencing us
            my $t = $self->_introspector->find_table($column_args[1]); 
            my $foreign_key = $self->get_foreign_key_class()->new($t,1,%$row);
            push(@dependencies, $foreign_key);
        }

    }

    $sth->finish();

    return (\@foreign_keys, \@dependencies);
}

sub get_column_instance {
    my $self = shift;
    my $name = shift;
    my $type_name = lc(shift);

    my $class = COLUMN_CLASS_MAPPING()->{$type_name} || return;
    return $class->new($name);
}

sub get_foreign_key_class { return 'DB::Introspector::Postgres::ForeignKey'; }

sub get_index_class { return 'DB::Introspector::Postgres::Index'; }



package DB::Introspector::Postgres::ForeignKey;

use strict;

use base qw( DB::Introspector::CommonRDB::ForeignKey );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(shift(), shift());

    my %args = @_;

    $self->_parse_foreign_key_data($args{LENGTH}, $args{ARGUMENTS});
    return $self;
}


# Parsing a string like the following:
#<unnamed>\000news_articles\000users\000UNSPECIFIED\000created_by\000user_id\000
sub _parse_foreign_key_data {
    my $self = shift;

    # subtracting 4 from our arg length to get the number of column name args
    # we have
    my $length = shift() - 4;
    my $arg_string = shift;

    # parse the trigger arguments
    my @data = split(DB::Introspector::Postgres::Table::COLUMN_ARG_DELIM, 
                    $arg_string);

    # the very first string is useless to us
    shift(@data); 

    # the first two arguments are table names.
    my $local_table_name = shift(@data);
    my $foreign_table_name = shift(@data);

    # if our local table name doesn't match our local table's name then 
    # we have a problem.
    unless( lc($local_table_name) eq lc($self->local_table->name) ) {
        die("INVALID FOREIGN KEY: local table $local_table_name "
        ."doesn't match local table ".$self->local_table->name);
    }

    # setting the foreign table name
    $self->set_foreign_table_name($foreign_table_name);

    # the fourth argument is useless to us so we will toss it.
    shift(@data);

    # since each argument is grouped in pairs, we will walk through and pull
    # out two at a time, the first for the local table and the second for the 
    # remote table. 
    my (@local_column_names, @foreign_column_names);
    while( @data ) {
        push(@local_column_names, shift(@data));
        push(@foreign_column_names, shift(@data));
    }
    $self->set_local_column_names(\@local_column_names);
    $self->set_foreign_column_names(\@foreign_column_names);
}


package DB::Introspector::Postgres::Index;

use strict;

use base qw( DB::Introspector::CommonRDB::Index );

use constant COLUMN_ARG_DELIM => ' ';

sub new {
    my $class = shift;
    my $table = shift;
    my %row = @_;
    my $self = $class->SUPER::new($table, $row{UNIQUE});
    $self->{_name} = $row{NAME} || "";
    $self->set_column_names([$self->_resolve_column_names($row{COLUMN_IDS})]);
    $self;
}

sub name {
    my $self = shift;
    return $self->{_name};
}

sub _resolve_column_names {
    my $self = shift;
    my $column_ids = shift;
    my @ids = split(COLUMN_ARG_DELIM, $column_ids);
    my @columns = $self->table->columns;
    return map { $columns[$_-1]->name; } @ids;
}

sub column_names {
    my $self = shift;
    return @{$self->{column_names}};
}

1;
