package Data::HandyGen::mysql;

use strict;
use warnings;

use 5.008;
our $VERSION = '0.0.2';
$VERSION = eval $VERSION;


#  precision and scale of float value.
#  They may be changed from outside this module.
our $FLOAT_PRECISION = 4;
our $FLOAT_SCALE     = 2;

our $DISTINCT_VAL_FETCH_LIMIT = 100;

our $RANGE_YEAR_YEAR = 20;
our $RANGE_YEAR_DATETIME = 2;

use DBI;
use DateTime;
use Carp;
use SQL::Maker;
use DateTime;
use Data::Dumper;
use Class::Accessor::Lite (
    new     => 1,
    rw      => [
        'dbh',          #  Database handle
        'fk',           #  1: Creates record on other table referenced by main table
        'debug'         #  debug mode
    ],
    ro      => [
        'inserted',     #  All inserted ids
        'defs',         #  Table definitions
                        #    $self->defs->{ $table_name } = (Data::HandyGen::mysql::TableDef object)
    ],
);

use Data::HandyGen::mysql::TableDef;


###############
#
#  Constants
#
###############

my $ONE_YEAR_SEC = 86400 * 365;

my @VARCHAR_LIST = ( 0..9, 'a'..'z', 'A'..'Z', '_' );
my $COUNT_VARCHAR_LIST = scalar @VARCHAR_LIST;

my $MAX_TINYINT_SIGNED       = 127;
my $MAX_TINYINT_UNSIGNED     = 255;
my $MAX_SMALLINT_SIGNED      = 32767;
my $MAX_SMALLINT_UNSIGNED    = 65535;
my $MAX_INT_SIGNED           = 2147483647;
my $MAX_INT_UNSIGNED         = 4294967295;

my $LENGTH_LIMIT_VARCHAR     = 20;

my %VALUE_DEF_FUNC = (
    char        => \&_val_varchar,
    varchar     => \&_val_varchar,
    text        => \&_val_varchar,
    tinyint     => \&_val_tinyint,
    smallint    => \&_val_smallint,
    int         => \&_val_int,
    integer     => \&_val_int,
    bigint      => \&_val_int,
    numeric     => \&_val_numeric,
    decimal     => \&_val_numeric,
    float       => \&_val_float,
    double      => \&_val_float,
    datetime    => \&_val_datetime,
    timestamp   => \&_val_datetime,
    date        => \&_val_datetime,
    year        => \&_val_year,
);


=head1 NAME

Data::HandyGen::mysql - Generates test data for mysql easily.


=head1 VERSION

This documentation refers to Data::HandyGen::mysql version 0.0.2


=head1 SYNOPSIS

    use DBI;
    use Data::HandyGen::mysql;
       
    my $dbh = DBI->connect('dbi:mysql:test', 'user', 'pass');
    
    my $hd = Data::HandyGen::mysql->new( fk => 1 );
    $hd->dbh($dbh);
     
    
    #  -- table definitions --
    #
    #  create table category (
    #      id           integer primary key,
    #      name         varchar(20) not null
    #  ); 
    #
    #  create table item (
    #      id           integer primary key auto_increment,
    #      category_id  interger not null,
    #      name         varchar(20) not null,
    #      price        integer not null,
    #      constraint foreign key (category_id) references category(id)
    #  );
    
    
    #  1.
    #  Insert one row to 'item'.
    #  'category_id', 'name' and 'price' will be random values.
    #  category_id refers to category.id, so the value will be selected one of values in category.id.
    #  If table 'category' has no record, new record will be added to 'category'. 
    
    my $id = $hd->insert('item');
    
    #  Result example:
    #  [item]
    #           id: 1
    #  category_id: 497364651
    #         name: name_1
    #        price: 597348646
    #
    #  [category]
    #           id: 497364651
    #         name: name_497364651
    #    
    
    print "ID: $id\n";      #  'ID: 1'
    
        
    #  2.
    #  Insert one row to 'item' with name = 'Banana'.
    #  category_id and price will be random values. 
    
    $id = $hd->insert('item', { name => 'Banana' });  #  Maybe $id == 2
    
    #  Result example:
    #  [item]
    #           id: 2
    #  category_id: 497364651
    #         name: Banana
    #        price: 337640949
    #
    #  [category]
    #           id: 497364651
    #         name: name_497364651
    
     
    #  3.      
    #  Insert one row to 'item' with category_id one of 10, 20 or 30 (selected randomly).
    #  If table 'category' has no record with id = 10, 20 nor 30, 
    #  a record having one of those ids will be generated on 'category'.
    
    $hd->insert('item', { category_id => [ 10, 20, 30 ] });
    
    #  Result example:
    #  [item] 
    #           id: 3
    #  category_id: 20
    #         name: name_3
    #        price: 587323402
    #
    #  [category]
    #           id: 20
    #         name: name_20


    #  4.
    #  If you're interested also in category name, do this.

    $cat_id = $hd->insert('category', { name => 'Fruit' });
    $item_id = $hd->insert('item', { category_id => $cat_id, name => 'Coconut' });    

   
    #  Delete all records inserted by $hd
    $hd->delete_all();     
    
    #  ...Or retrieve all IDs for later deletion.
    my $ids = $hd->inserted();


=head1 DESCRIPTION

This module generates test data and insert it into mysql tables. You only have to specify values of columns you're really interested in. Other necessary values are generated automatically.

When we test our product, sometimes we need to create test records, but generating them is a tedious task. We should consider many constraints (not null, foreign key, etc.) and set values to many columns in many tables, even if we want to do small tests, are interested in only a few columns and don't want to care about others. Maybe this module get rid of much of those unnecessary task.


=head1 METHODS 


=head2 new(dbh => $dbh, fk => $fk)

Constructor. C<dbh> is required to be specified at here, or by calling C<< $obj->dbh($dbh) >> later. C<fk> is optional.


=head2 dbh($dbh)

set a database handle


=head2 fk($flag)

If specified 1, it also creates records on other tables referred by foreign key columns in main table, if necessary.

Default is 0 (doesn't add records to other tables), so if you want to use this functionality, you need to specify 1 explicitly.


=cut

sub _sql_maker {
    my ($self) = @_;
    $self->{_sql_maker} ||= SQL::Maker->new( driver => 'mysql' );
    return $self->{_sql_maker};
}


#  distinct values for each referenced tables/columns
#     $self->{_distinct_val}{$table}{$column} = {
#       'value1'    => 1,
#       'value2'    => 1,
#     }
sub _distinct_val {
    my ($self) = @_;

    $self->{_distinct_val} ||= {};

    return $self->{_distinct_val};
}


=head2 insert($table_name, $valspec)

Inserts a record to a table named $table_name.

You can specify values of each column(s) with $valspec, a hashref which keys are columns' names in $table_name.

    $hd->insert('table1', {
        id      => 5,
        price   => 300
    });

=head3 format

=over 4

=item * colname => $scalar

specifies a value of 'colname'

    $hd->insert('table1', { id => 5 });      #  id will become 5


=item * colname => [ $val1, $val2, ... ]

value of 'colname' will be randomly chosen from $val1, $val2, ...

    $hd->insert('table1', { id => [ 10, 20, 30 ] })      #  id will become one of 10, 20 or 30


=item * colname => { random => [ $val1, $val2, ... ] }

verbose expression of above

=item * colname => { range => [ $min, $max ] }

value of 'colname' is determined between $min and $max ($min inclusive, $max exclusive). Can be used only for number(int, double, numeric, etc.).

=item * colname => { dt_range => [ $start_datetime, $end_datetime ] }

value of 'colname' is determined between $start_datetime and $end_datetime ($start_datetime inclusive, $end_datetime exclusive). Can be used only for date or datetime type.

    $hd->insert('table1', { 
        purchase_datetime => { dt_range => [ '2013-07-20 12:00:00', '2013-7-21 14:00:00' ] } 
    });

    $hd->insert('table2', {
        exec_datetime => { dt_range => [ '2013-08-01', '2013-08-05' ] }     #  time can be ommitted
    });


=back

=head3 return value

Returns a value of primary key. (Only when primary key exists and it contains only a single column. Otherwise returns undef.)

=cut

#  XXX: I commented out lines below, because this function does not work properly.
# 
#=head3 column name in other tables
#
#If you want to specify values of other tables (maybe referenced by foreign key), join table name and column name with dot(.)
#
#    $valspec = {
#        column1                  => 50,           #  Column in the same table
#        'another_table.column2'  => [10, 20, 30]  #  Column in referenced table
#    }

sub insert {
    my ($self, $table_name, $table_valspec) = @_;

    $table_valspec
        and $self->_set_user_valspec($table_name, $table_valspec);

    return $self->process_table($table_name);
}



sub process_table {
    my ($self, $table, $tmpl_valspec) = @_;
    my $dbh = $self->dbh();

    #  Reads an additional spec
    $tmpl_valspec 
        and $self->_add_user_valspec($table, $tmpl_valspec);
    $self->_print_debug("tmpl_valspec : " . Dumper($self->_valspec()));

    my $table_def = $self->_table_def($table);

    #  Determines ID value.
    #  $exp_id  : Expected ID. User specified value if specified, or auto_increment value if auto_increment column.
    #  $real_id : User specified value if specified. Otherwise undef.
    my ($exp_id, $real_id) = $self->get_id($table, $tmpl_valspec);
    $self->_print_debug("id is (" . ($exp_id || '(undef)') . ", " . ($real_id || '(undef)') . ")");
    

    #  columns to which we need to specify values.
    my @colnames = $self->get_cols_requiring_value($table, $table_def->def);


    my %values = ();

    for my $col (@colnames) {

        my $value;
    
        #  (1)Primary key, and a value is specified by user.
        if ( $table_def->is_pk($col) and defined($real_id) ) {
            $values{$col} = $real_id;
            next;
        }

        my $col_def = $table_def->column_def($col) 
            or confess "No column def found. $col";


        #  (2)If $self->fk = 1 and the column is a foreign key.
        if ( $self->fk ) {
            if ( my $referenced_table_col = $table_def->is_fk($col) ) {     #  ret = { table => 'table name, column => 'column name' }
                if ( ref $referenced_table_col eq 'HASH' ) { 
                    $value = $self->determine_fk_value($table, $col, $referenced_table_col);
                }
                else {
                    warn "Currently only one foreign key per column is supported.";
                }
            }
        }

        #  (3)If user specified a value, use it.
        if ( !defined($value) and defined( my $valspec_col = $self->_valspec()->{$table}{$col} ) ) {
            $value = $self->determine_value( $valspec_col );
        }
        
        #  (3.5)If column default is available, use it.
        if ( !defined($value) and defined($col_def->column_default) ) {
            $value = $col_def->column_default;
        }            

        #  (4)Otherwise, decide a value randomly.
        if ( !defined($value) ) {

            my $type = $col_def->data_type;
            my $func = $VALUE_DEF_FUNC{$type};

            #  If this data type is not supported, leave it NULL.
            unless ($func) {
                warn "Type $type for $col is not supported.";
                next;
            }
            
            $value = $self->$func($col_def, $exp_id);
            $self->_print_debug("No rule found. Generates random value.($value)");

        }

        $values{$col} = $value;

        if ( $table_def->is_pk($col) ) {
            $real_id = $value;
        }
    }

    eval {
        my ($sql, @bind) = $self->_sql_maker->insert($table, \%values);
        $self->_print_debug($sql .  ", binds [" . (join ', ', @bind) . "]");

        my $sth = $dbh->prepare($sql);
        $sth->execute(@bind);
        $sth->finish;
    };
    if ($@) {
        confess $@
    }
        
    my $inserted_id = undef;
   
    
    #  Handles PK value only when the table has single pk column.
    if ( @{ $table_def->pk_columns() } == 1 ) {
        $inserted_id = $real_id || $dbh->{'mysql_insertid'};
        $self->add_inserted_id($table, $inserted_id);
   
        $self->_print_debug("Inserted. table = $table, id = $inserted_id");
    }
    
    return $inserted_id;
}


sub _valspec {
    my ($self, $_valspec) = @_;

    if ( defined $_valspec ) {
        if ( ref $_valspec eq 'HASH' ) {
            $self->{_valspec} = $_valspec;
        }
        else {
            confess "Invalid valspec.";
        }
    }

    $self->{_valspec} ||= {};
    return $self->{_valspec};
}


#  Records an ID of inserted record.
sub add_inserted_id {
    my ($self, $table, $id) = @_;

    $table or confess "Missing table name";
    defined $id or confess "Missing ID. table = $table";

    $self->{inserted}{$table} ||= [];
    push @{ $self->{inserted}{$table} }, $id;
}



#  Determine a value of column according to (user-specified) rules.
sub determine_value {
    my ($self, $valspec_col) = @_;

    ref $valspec_col eq 'HASH'
        or confess "Invalid valspec type." . ref($valspec_col);

    my $value;

    if ( exists($valspec_col->{random}) ) {
        my $values = $valspec_col->{random};

        ref $values eq 'ARRAY'
            or confess "Value of 'random' is invalid. type = " . (ref $values);
        scalar(@$values) > 0
            or confess "Value of 'random' is an empty arrayref";

        my $ind = rand() * scalar(@$values);
        $value = $values->[$ind]; 

    }
    elsif ( exists($valspec_col->{fixval}) ) {
        my $fixval = $valspec_col->{fixval};
        ref $fixval eq ''
            or confess "Value of 'fixval' is invalid";

        $value = $fixval;
    }
    elsif ( exists($valspec_col->{any}) ) {
        #  Leave it null. Value will be assigned later.
        return undef;
    }
    elsif ( exists($valspec_col->{range} ) ) {
        my $spec = $valspec_col->{range};
        ref $spec eq 'ARRAY' and @$spec == 2 
            or confess "Value of 'range' must be an arrayref with (begin, end) values";
        $value = _get_random_range(@$spec);
    }
    elsif ( exists($valspec_col->{dt_range}) ) {
        my $spec = $valspec_col->{dt_range};
        ref $spec eq 'ARRAY' and @$spec == 2 
            or confess "Value of 'dt_range' must be an arrayref with (start, end) values";
        $value = _get_random_dt_range(@$spec);
    }        

    return $value;
}


sub _get_random_range {
    my ($begin, $end) = @_;

    my $value = $begin + rand($end - $begin);
    return $value;
}


sub _get_random_dt_range {
    my ($start, $end) = @_;

    my $start_epoch = _get_epoch($start);
    my $end_epoch   = _get_epoch($end);
    
    my $value = DateTime
                ->from_epoch( epoch => $start_epoch + rand($end_epoch - $start_epoch) )
                ->strftime("%Y-%m-%d %H:%M:%S");

    return $value;
}


sub _get_epoch {
    my ($timestr) = @_;

    #  time format is expected to 'yyyy-mm-dd hh:mm:ss'
    my @ymdhms = split /\D/, $timestr;     
    my $dt = DateTime->new(
        year    => $ymdhms[0],
        month   => $ymdhms[1] || 1,
        day     => $ymdhms[2] || 1,
        hour    => $ymdhms[3] || 0,
        minute  => $ymdhms[4] || 0,
        second  => $ymdhms[5] || 0,
    );

    return $dt->epoch();
}



#  Check if a record with specified column value exists.
#  Return value is a count of record(s).
sub _value_exists_in_table_col {
    my ($self, $table, $col, $value) = @_;

    defined($table) and defined($col) and defined($value)
         or confess "Invalid args (requires 3 arg)";

    my ($sql, @binds) = $self->_sql_maker->select( $table, [\'count(*)'], { $col => $value } );
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute(@binds);
    my $row = $sth->fetchrow_arrayref();

    $self->_print_debug("Record count : $row->[0]");
    return $row->[0];       #  count(*)
}


sub determine_fk_value {
    my ($self, $table, $col, $ref) = @_;

    my $value = undef;

    my $ref_table = $ref->{table};
    my $ref_col   = $ref->{column};

    $table and $col and $ref_table and $ref_col 
        or confess "Invalid args. (requires 3 args)";

    $self->_print_debug("Column $col is a foreign key references $ref_table.$ref_col.");

    if ( my $valspec_col = $self->_valspec()->{$table}{$col} || $self->_valspec()->{$ref_table}{$ref_col} ) {
        $self->_print_debug("Value is specified.");

        # 
        #  (1)If a rule of determining the value is specified by user, apply the rule.
        #
        $value = $self->determine_value( $valspec_col );

        #  If a referenced record does not exist in a referenced table, 
        #  insert a record having the value at first.
        #  
        #  * I haven't thought it would be efficient to query every time which values
        #    in a given column in a referenced table exist. At first I used to believe
        #    it would be a good idea to query only for the first time, and cache those values
        #    for later use. But I suspected it wouldn't be a good idea. Sometimes the number of values
        #    becomes very huge, requiring big memory space. Furthermore, those values may change.
        #    So I've changed my mind to query current values every time.
        $self->_add_record_if_not_exist($ref_table, $ref_col, $value);

    }
    elsif ( defined( my $column_default = $self->_table_def($table)->column_def($col)->column_default ) ) {
        $self->_print_debug("Column default is specified. value = $column_default");
        $value = $column_default;
        $self->_add_record_if_not_exist($ref_table, $ref_col, $value);

    }
    else {
        $self->_print_debug("No value is specified. Trying to retrieve list of ids from $ref_table");

        #
        #  (2)Case when no rule for the value definition specified by user
        #

        #  Retrieve values of primary key in the referenced table.
        #  Its result is like...
        #  $ref_ids => { (id1)  => 1, (id2) => 1, ... }
        #
        my $ref_ids = $self->_get_current_distinct_values($ref_table, $ref_col); 
    

        #  Pick up one of referenced values randomly, if at least one record exists.
        my @_ref_ids = keys %$ref_ids;
        if ( @_ref_ids ) {
            $value = $_ref_ids[ int(rand() * scalar(@_ref_ids)) ];
            $self->_print_debug("Referenced record id = $value");

        }
        else {
            #  No record found in the referenced table, so insert here.
            $value = $self->process_table($ref_table);      #  ID value would be determined randomly.
            $self->_distinct_val()->{$ref_table}{$ref_col}{$value} = 1;            #  Add the ID value
            $self->_print_debug("Referenced record created. id = $value");
            
        }
    }

    return $value;

}


#  Determines ID value.
#  Returns 2 values. One if exp_id(expected ID), which is used to determine column values
#  other than primary key (for example, when expected id is 4001, values of column named 'foo'
#  will be 'foo_4001' if possible.
#  Another is real_id, which is a final value of ID column. It may be undef if no value is 
#  specified by user.
#  
#  TODO: Currently it works properly only when primary key consists of one column, 
#  and its type is integer.
sub get_id {
    my ($self, $table) = @_;

    my $table_def = $self->_table_def($table);
    my $pks = $table_def->pk_columns();

    my ($exp_id, $real_id);
    for my $col (@$pks) {   #  for each pk columns

        my $col_def = $table_def->column_def($col);
        

        #  Verifies if PK value can be determined by the user-specified rule.
        #  If possible, $real_id will be a value determined by the rule.
        if (    $self->_valspec()->{$table} 
                and defined( $self->_valspec()->{$table}{$col} )
                and defined( $real_id = $self->determine_value( $self->_valspec()->{$table}{$col} ) )
        ) 
        {

            #  exp_id will be the same of real_id when user-specified rule exists.
            $exp_id = $real_id;

        }
        else {

            #  When no user-rule specified
            $self->_print_debug("user value is not specified");

            if ( $col_def->is_auto_increment() ) {

                #  If the PK has auto_increment attribute, retrieve a value from it.
                $self->_print_debug("Column $col is an auto_increment");
                $exp_id = $table_def->get_auto_increment_value();
                
                #  real_id won't be determined until insert operation executes, so leaves it undef.

            }
            else {
                #  There's no auto_increment attribute, so generates random value and uses it as a value of primary key.
                $self->_print_debug("Column $col is not an auto_increment");
                my $type = $col_def->data_type;
                my $size = $col_def->character_maximum_length;
                my $func = $VALUE_DEF_FUNC{$type}
                    or die "Type $type for $col not supported";
                
                $exp_id = $real_id = $self->$func($col_def);

            }
        }
    }

    return ($exp_id, $real_id);             
}



#  Make a list of columns which need a value at an insert operation.
sub get_cols_requiring_value {
    my ($self, $table) = @_;

    my $table_def = $self->_table_def($table);

    my @cols = ();
    for my $col ( $table_def->colnames ) {

        #  When user specifies a rule of determining value, uses it every time.
        #  If not, checks if any column definition (like 'auto_increment') can be used
        #  as a rule.
        if ( defined( $self->_valspec()->{$table}{$col} ) ) {
            $self->_print_debug("column $col has a valspec, so value is needed");
            push @cols, $col;
        }
        else {

            my $col_def = $table_def->column_def($col);

            #  we do not need to specify a value of auto_increment column. Skip it.
            if ( $col_def->is_auto_increment ) {
                $self->_print_debug("column $col is auto_increment, so no need to assign value.");
                next;
            }

            #
            #  I used to believe that DEFAULT value could be used if exists, so 
            #  I should skip the column having DEFAULT value.
            #  But I found it wouldn't work properly when the column has
            #  foreign key constraint too, because it seemes there would be 
            #  no way to add a record to referenced table.
            #  So I've changed the way assuming the user rule would be specified
            #  as the DEFAULT value.
            #  
            #  Skip only when the column isn't a foreign key and has default value.
            if ( defined($col_def->column_default) and not $table_def->is_fk($col) ) {
                $self->_print_debug("column $col has default value and not FK, so no need to assign value");
                next;
            }

            #  When NULL value is accetable, skip the column.
            if ( $col_def->is_nullable eq 'YES' ) {
                $self->_print_debug("column $col is nullable, so no need to assign a value");
                next;
            }

            $self->_print_debug("column $col needs a value");
            push @cols, $col;
        }

    }

    return wantarray ? @cols : [ @cols ];
}


sub _table_def {
    my ($self, $table) = @_;

    $self->{_table_def}{$table} 
        ||= Data::HandyGen::mysql::TableDef->new( dbh => $self->dbh, table_name => $table );

    return $self->{_table_def}{$table};
}



#  _val_varchar($col_def, $exp_id)
#
#  Creates a new varchar value.
#  
#  $col_def : ColumnDef object.
#  $exp_id  : an expected value of primary key.
#
sub _val_varchar {
    my ($self, $col_def, $exp_id) = @_;

    my $maxlen = $col_def->character_maximum_length;
    $self->_print_debug("Maxlen is $maxlen");

    if ( defined $exp_id ) {
        my $pk_length = length($exp_id);
        my $colname = $col_def->name;
        my $colname_length = length($colname);

        if ( $colname_length + $pk_length + 1 <= $maxlen ) {       #  (colname)_(num)
            return sprintf("%s_%d", $colname, $exp_id);
        }
        elsif ( $pk_length + 1 <= $maxlen ) {                      #  (part_of_colname)_(num)
            my $part_of_colname = substr($colname, 0, $maxlen - $pk_length - 1);
            return sprintf("%s_%d", $part_of_colname, $exp_id);
        }
        elsif ( $pk_length == $maxlen ) {
            return $exp_id;
        }   
    }

    $maxlen > $LENGTH_LIMIT_VARCHAR 
        and $maxlen = $LENGTH_LIMIT_VARCHAR;
    $self->_print_debug("Maxlen is $maxlen");

    my $string = '';
    for (1 .. $maxlen) {
        $string .= $VARCHAR_LIST[ int( rand() * $COUNT_VARCHAR_LIST ) ];
    }
    $self->_print_debug("Result string is $string");

    return $string;

}


sub _val_tinyint {
    my ($self, $col_def) = @_;

    my $type = $col_def->column_type;

    return (($type || '') =~ /unsigned/) ? int(rand() * $MAX_TINYINT_UNSIGNED) : int(rand() * $MAX_TINYINT_SIGNED);
}


sub _val_smallint {
    my ($self, $col_def) = @_;

    my $type = $col_def->column_type;

    return (($type || '') =~ /unsigned/) ? int(rand() * $MAX_SMALLINT_UNSIGNED) : int(rand() * $MAX_SMALLINT_SIGNED);
}

sub _val_int {
    my ($self, $col_def) = @_;

    my $type = $col_def->column_type;

    return (($type || '') =~ /unsigned/) ? int(rand() * $MAX_INT_UNSIGNED) : int(rand() * $MAX_INT_SIGNED);
}


sub _make_float {
    my ($precision, $scale) = @_;
    
    my $num = '';
    $num .= int(rand() * 10) for 1 .. $precision - $scale;
    if ( $num =~ /^0+$/ ) {
        $num = '0'
    }
    else {
        $num =~ s/^0+//; 
    }

    if ( $scale > 0 ) {
        $num .= '.';
        my $frac = '';
        $frac .= int(rand() * 10) for 1 .. $scale;
        if ( $frac =~ /^0+$/ ) {
            $frac = '0';
        }
        else {
            $frac =~ s/0+$//;
        }

        $num .= $frac;
    }

    return $num;
}


sub _val_numeric {
    my ($self, $col_def) = @_;

    my $precision = $col_def->numeric_precision;
    my $scale     = $col_def->numeric_scale;

    return _make_float($precision, $scale);
}


sub _val_float {
    my ($self, $col_def) = @_;

    my $type = $col_def->column_type;

    return _make_float($FLOAT_PRECISION, $FLOAT_SCALE);
}



sub _val_datetime {
    my ($self, $col_def) = @_;

    my $dt = DateTime->from_epoch( epoch => time + rand() * $RANGE_YEAR_DATETIME * $ONE_YEAR_SEC - $ONE_YEAR_SEC );

    if ($col_def->data_type eq 'date') {
        return $dt->ymd('-');
    }
    else {
        return $dt->ymd('-') . ' ' . $dt->hms(':');
    }
}


sub _val_year {
    my $dt = DateTime->from_epoch( epoch => time + rand() * $RANGE_YEAR_YEAR * $ONE_YEAR_SEC - $ONE_YEAR_SEC );

    return $dt->year();
}


#
#  _get_current_distinct_values($table, $col)
#
#  Returns some distinct values in the specified $table and specified $col.
#
sub _get_current_distinct_values {
    my ($self, $table, $col) = @_;

    my $current;

    #  At first, I tried to cache distinct values, but when user delete records, 
    #  those cached values are incorrect, and this module has no idea
    #  which records have been already deleted.
    #  So I decide not to cache distinct values and query them every time. 

    #my $current = $self->_distinct_val()->{$table}{$col};
    #if ( !defined $current or keys %$current == 0 ) {

        #  SELECT DISTINCT $col FROM $table LIMIT $DISTINCT_VAL_FETCH_LIMIT;
        my $select = $self->_sql_maker->new_select(distinct => 1);
        my ($sql, @bind) = $select->add_select($col)
                            ->add_from($table)
                            ->limit($DISTINCT_VAL_FETCH_LIMIT)
                            ->as_sql();

        my $res = $self->dbh()->selectall_arrayref($sql, undef, @bind);

        my %values = map { $_->[0] => 1 } @$res;

        $current = $self->_distinct_val()->{$table}{$col} = { %values };
    #}

    return $current;
}


#
#  _set_user_valspec($table_name, $valspec)
#
#  Specifies user-defined rules for determining values of columns.
#  Previous rules will be cleared.
#
sub _set_user_valspec {
    my ($self, $table, $table_valspec) = @_;

    #  Clear previous valspec
    $self->_valspec({});

    $self->_add_user_valspec($table, $table_valspec);
}


#
#  _add_user_valspec($table, $table_valspec)
#
#  Specifies user-defined rules for determining values of columns.
#  Previous rules will remain and new rules will be added.
#
sub _add_user_valspec {
    my ($self, $table, $table_valspec) = @_;

    defined $table and length($table) > 0
        or confess "Missing table name";

    defined $table_valspec and ref $table_valspec eq 'HASH'
        or confess "Invalid user valspec.";


    for my $col (keys %$table_valspec) {
         
        my $_table = $table;
        my $_col   = $col;

        if ( $col =~ /\./ ) {
            ($_table, $_col, my @_dummy) = split '\.', $col;

            #  column name may include only one dot.
            defined($_table) and length($_table) > 0 
            and defined($_col) and length($_col) > 0
            and @_dummy == 0 
                or confess "Invalid column name : $col"; 
        }

        my $val = $table_valspec->{$col};

        #  At first, clear all values with the same key.
        delete $self->_valspec()->{$_table}{$_col};

        if ( ref $val eq 'ARRAY' ) {
            #  arrayref : select one from the list randomly.
            $self->_valspec()->{$_table}{$_col}{random} = $val;

        }
        elsif ( ref $val eq 'HASH' ) {
            #  hash : 
            #  currently { random => [ ... ] } or { fixval => $scalar } 
            #  may be specified.
            for (keys %$val) {
                $self->_valspec()->{$_table}{$_col}{$_} = $val->{$_};
            }

        }
        elsif ( ref $val eq 'SCALAR' and $$val eq 'any' ) {
            #  scalarref to string 'any'
            #  determine value randomly.
            $self->_valspec()->{$_table}{$_col}{any} = 1;
        }
        elsif ( ref $val eq '' ) {
            #  scalar : fix value
            $self->_valspec()->{$_table}{$_col}{fixval} = $val;

        }
        else {
            confess "NOTREACHED";
        }

    }

}   


=head2 inserted()

Returns all primary keys of inserted records by this instance. Returned value is a hashref like this:

    my $ret = $hd->inserted();
    
    #  $ret = {
    #    'table_name1' => [ 10, 11 ],
    #    'table_name2' => [ 100, 110, 120 ],
    #  };

CAUTION: inserted() ignores records with no primary key, or primary key with multiple columns.

=cut



=head2 delete_all()

deletes all rows inserted by this instance.

CAUTION: delete_all() won't delete rows in tables which don't have primary key, or which have primary key with multiple columns.

=cut

sub delete_all {
    my ($self) = @_;

    my $dbh = $self->dbh();

    my $fk_check = $self->_check_fk_check_status();

    if ( $fk_check eq 'ON' or $fk_check == 1 ) {
        $dbh->do('SET FOREIGN_KEY_CHECKS = 0');
    }

    for my $table ( keys %{ $self->inserted() } ) {
        my $pk_name = $self->_table_def($table)->pk_columns()->[0];

        for my $val ( @{ $self->inserted->{$table} } ) {
            my ($sql, @bind) = $self->_sql_maker->delete($table, { $pk_name => $val });
            $dbh->do($sql, undef, @bind);
            $self->_print_debug(qq{DELETE FROM `$table` WHERE `$pk_name` = "$val"});
        }
    }

    if ( $fk_check eq 'ON' or $fk_check == 1 ) {
        $dbh->do('SET FOREIGN_KEY_CHECKS = 1');
    }
}


sub _check_fk_check_status {
    my ($self) = @_;

    my @rows = $self->dbh->selectrow_array(q{SHOW VARIABLES LIKE '%foreign_key_checks%'});

    return $rows[1];
}


#
#  _add_record_if_not_exist($table, $col, $value)
#
#  Inserts a record only if record(s) which value of column $col is $value doesn't exist.
#
sub _add_record_if_not_exist {
    my ($self, $table, $col, $value) = @_;

    if ( 0 == $self->_value_exists_in_table_col($table, $col, $value) ) {     #  No record exists
        $self->process_table($table, { $col => $value });
        $self->_print_debug("A referenced record created. id = $value");
    }
}



sub _print_debug {
    my ($self, $message) = @_;

    if ( $self->debug ) {
        print "$message\n";
    }
}


1;



__END__


=head1 BUGS AND LIMITATIONS

There are still many limitations with this module. I'll fix them later.

Please report problems to Egawata C<< (egawa.takashi at gmail com) >>
Patches are welcome.

=head3 Only primary key with single column is supported.

Although it works when inserting a record into a table which primary key consists of multiple columns, C<< insert() >> won't return a value of primary key just inserted.


=head3 Foreign key constraint which has multiple columns is not supported.

For now, if you want to use this module with such a table, specify those values explicitly.


=head3 Multiple foreign key constraints to the same column are not supported.

For now, if you want to use this module with such a table, specify those values explicitly.


=head3 Some data types are not supported.

For example, C<< blob >> or C<< set >> aren't supported. The values of those columns won't be auto-generated.


=head1 AUTHOR

Takashi Egawa (C<< egawa.takashi at gmail com >>)


=head1 LICENCE AND COPYRIGHT

Copyright (c)2012-2014 Takashi Egawa (C<< egawa.takashi at gmail com >>). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

