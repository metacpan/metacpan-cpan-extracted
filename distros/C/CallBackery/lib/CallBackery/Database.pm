package CallBackery::Database;

# $Id: Database.pm 542 2013-12-12 16:36:34Z oetiker $

use Mojo::Base -base,-signatures;

use Data::Dumper;
use Carp qw(croak);
use CallBackery::Exception qw(mkerror);

=head1 NAME

CallBackery::Database - database access helpers

=head1 SYNOPSIS

 use CallBackery::Database;
 my $db = CallBackery::Database->new(app=>$self->config);
 my ($fields,$values) = $self->map2sql(table,data);
 my $selWhere = $self->map2where(table,data);
 my $rowHash = $self->fetchRow(table,{field=>val,field=>val},selExpression?);
 my $value = $self->fetchValue(table,{field=>val,field=>val},column);
 my $id = $self->matchData(table,{field=>val,field=>val});
 my $id = $self->lookUp(table,field,value);
 my $id = $self->updateOrInsertData(table,{dataField=>val,...},{matchField=>val,...}?);
 my $id = $self->insertIfNew(table,{field=>val,field=>val});

=head1 DESCRIPTION

Database access helpers.

=head2 config

object needs access to the system config to get access to the database

=cut

has app => sub {
    croak "app property is required";
}, weak => 1;

has userName => sub {
    return "* no user *";
};

has config => sub {
    shift->app->config;
}, weak => 1;


=head2 dhb

a dbi database handle

=cut

my $lastFlush = time;

has sql => sub {
    my $self = shift;
    require Mojo::SQLite;
    my $sql = Mojo::SQLite->new($self->config->cfgHash->{BACKEND}{cfg_db});

    $sql->options({
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        sqlite_unicode => 1,
        FetchHashKeyName=>'NAME_lc',
    });

    $sql->on(connection => sub ($sql, $dbh) {
      $dbh->do('PRAGMA foreign_keys = ON;');
    });

    $sql->migrations
        ->name('cbmig')
        ->from_data(__PACKAGE__,'dbsetup.sql')
        ->migrate;

    return $sql;
};

# this must be fresh ... always!
sub mojoSqlDb {
    my $self = shift;
    return $self->sql->db;
};

=over 4

=item my($fields,$values) = $self->C<map2sql(table,data)>;

Provide two hash pointers and quote the field names for inclusion into an
SQL expression. Build field names according to the table_field rule.

=cut

sub map2sql {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    my @values;
    my @fields;
    while (my($field, $value) = each %$data) {
        push @fields,$self->mojoSqlDb->dbh->quote_identifier($table."_".$field);
        push @values,$value;
    }
    return (\@fields,\@values);
}

=item my $sqlWhere = $self->C<map2where(table,data)>;

build a where statement Find a record matching the given data in a table the
data is a map. Quote field names and values.  Build field names according to
the table_field rule.

=cut

sub map2where {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    my $db = $self->mojoSqlDb;
    my @expression;
    while (my($field, $value) = each %$data) {
        my $field = $db->dbh->quote_identifier($table."_".$field);
        my $expr;
        if (defined $value){
            $expr = $field.' = '.$db->dbh->quote($value);
        }
        else {
            $expr = $field.' is null';
        }
        push @expression, $expr;
    }
    return (join ' AND ',@expression);
}

=item $hashRef = $self->C<getMap(table,column)>;

Get an array of hashes with model and label tags:

 [{model: x, label: y},{id ...},...]

=cut

sub getMap {
    my $self = shift;
    my $table = shift;
    my $column = shift;
    my $db = $self->mojoSqlDb;
    my $sqlId = $db->dbh->quote_identifier($table."_id");
    my $sqlColumn = $db->dbh->quote_identifier($table."_".$column);
    my $sqlTable = $db->dbh->quote_identifier($table);
    my $SQL = <<"SQL";
        SELECT $sqlId as model, $sqlColumn as label
          FROM $sqlTable
          ORDER by $sqlColumn
SQL
    return $db->dbh->selectall_arrayref($SQL,{Slice=>{}});
}

=item $hashRef = $self->C<getRowHash(table,{key=>value,....},$selectExpr?)>;

Get a hash with record index as key. Optionally with a list of columns to return.

 {
   2 => { a=>x, b=>y },
   3 => { a=>k, b=>r }
 }

=cut

sub getRowHash {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    my $selectCols = shift // '*';
    my $db = $self->mojoSqlDb;
    my $sqlTable = $db->dbh->quote_identifier($table);
    my $sqlWhere = $self->map2where($table,$data);
    my $SQL = <<"SQL";
        SELECT $selectCols
          FROM $sqlTable
         WHERE $sqlWhere
SQL
    return $db->dbh->selectall_hashref($SQL,$table."_id",{Slice=>{}});
}


=item $id = $self->C<fetchRow(table,{key=>value,key=>value},$selectExp ?)>;

Find a record matching the given data in a table and return a hash of the matching record.

=cut

sub fetchRow {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    my $selectCols = shift // '*';
    my $db = $self->mojoSqlDb;
    my $sqlWhere = $self->map2where($table,$data);
    my $sqlTable = $db->dbh->quote_identifier($table);
    my $SQL = <<"SQL";
        SELECT $selectCols
          FROM $sqlTable
         WHERE $sqlWhere
SQL
    return $db->dbh->selectrow_hashref($SQL);
}

=item $id = $self->C<fetchValue(table,{key=>value,key=>value},column)>;

Find a record matching the given data in a table and returns the value in column.

=cut

sub fetchValue {
    my $self = shift;
    my $table = shift;
    my $where = shift;
    my $column = shift;
    my $db = $self->mojoSqlDb;
    my $row = $self->fetchRow($table,$where,$db->dbh->quote_identifier($table.'_'.$column));
    if ($row){
        return $row->{$table.'_'.$column};
    }
    else {
        return undef;
    }
}


=item $id = $self->C<matchData(table,data)>;

Find a record matching the given data in a table
the data is a map.

=cut

sub matchData {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    my $found = $self->fetchValue($table,$data,"id");
    return $found;

}

=item $id = $self->C<lookUp(table,column,value)>

Lookup the value in table in table_column and return table_id.
Throw an exception if this fails. Use matchData if you are just looking.

=cut

sub lookUp {
    my $self = shift;
    my $table = shift;
    my $column = shift;
    my $value = shift;
    my $id = $self->matchData($table,{$column => $value})
        or die mkerror(1349,"Lookup for $column = $value in $table faild");
    return $id;
}

=item $id = $self->C<updateOrInsertData(table,data,match?)>

Insert the given data into the table. If a match map is given, try an update first
with the given match only insert when update has 0 hits.

=cut

sub updateOrInsertData {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    my $match = shift;
    my $db = $self->mojoSqlDb;
    my ($colNames,$colValues) = $self->map2sql($table,$data);
    my $sqlTable = $db->dbh->quote_identifier($table);
    my $sqlIdCol = $db->dbh->quote_identifier($table."_id");
    my $sqlColumns = join ', ', @$colNames;
    my $sqlSet = join ', ', map { "$_ = ?" } @$colNames;
    my $sqlData = join ', ', map { '?' } @$colValues;
    if ($match){ # try update first if we have an id
        my $matchWhere = $self->map2where($table,$match);
        my $SQL = <<"SQL";
        UPDATE $sqlTable SET $sqlSet
        WHERE $matchWhere
SQL
        my $count =  $db->dbh->do($SQL,{},@$colValues);
        if ($count > 0){
            return ( $data->{id} // $match->{id} );
        }
    }
    my $SQL = <<"SQL";
        INSERT INTO $sqlTable ( $sqlColumns )
        VALUES ( $sqlData )
SQL
    $db->dbh->do($SQL,{},@$colValues);

    # non serial primary key, id defined by user
    if (exists $data->{'id'}){
        return $data->{'id'};
    }
    # serial primary key
    else{
        return $db->dbh->last_insert_id(undef,undef,$table,$table."_id");
    }
}

=item $id = $self->C<insertIfNew(table,data)>

Lookup the given data. If it is new, insert a record. Returns the matching Id.

=cut

sub insertIfNew {
    my $self = shift;
    my $table = shift;
    my $data = shift;
    return ( $self->matchData($table,$data)
           // $self->updateOrInsertData($table,$data));
}

=item $id = $self->C<deleteData(table,id)>

Delete data from table. Given the record id.
Returns true if the record was deleted.

=cut

sub deleteData {
    my $self = shift;
    my $table = shift;
    my $id = shift;
    return $self->deleteDataWhere($table,{id=>$id});
}

=item $id = $self->C<deleteDataWhere(table,{key=>val,key=>val})>

Delete data from table. Given the column title and the matching value.
Returns true if the record was deleted.

=cut

sub deleteDataWhere {
    my $self = shift;
    my $table = shift;
    my $match = shift;
    my $val = shift;
    my $db = $self->mojoSqlDb;
    my $sqlTable = $db->dbh->quote_identifier($table);
    my $matchWhere = $self->map2where($table,$match);
    my $SQL = 'DELETE FROM '.$sqlTable.' WHERE '.$matchWhere;
#    say $SQL;
    return $db->dbh->do($SQL);
}

=item getConfigValue($key)

return a raw data value from the config table

=cut

sub getConfigValue {
    my $self = shift;
    my $key = shift;
    my $value = eval {
        local $SIG{__DIE__};
        $self->fetchValue('cbconfig',{id => $key},'value');
    };
    return ($@ ? undef : $value);
}

=item setConfigValue($key,$value)

write a config value

=cut

sub setConfigValue {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    # warn "SET $key -> ".Dumper([$value]);
    $self->updateOrInsertData('cbconfig',{
        id=> $key,
        value => $value
    }, { id => $key });
    return $value;
}

1;

=back

=head1 COPYRIGHT

Copyright (c) 2015 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobi Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2010-06-12 to 1.0 initial
 2013-11-19 to 1.1 converted to mojo

=cut

__DATA__
@@ dbsetup.sql

-- 1 up

CREATE TABLE IF NOT EXISTS cbconfig (
    cbconfig_id TEXT PRIMARY KEY,
    cbconfig_value TEXT
);

CREATE TABLE IF NOT EXISTS cbuser (
    cbuser_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    cbuser_login TEXT UNIQUE,
    cbuser_family TEXT,
    cbuser_given TEXT,
    cbuser_password TEXT,
    cbuser_note TEXT
);

CREATE TABLE IF NOT EXISTS cbright (
    cbright_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    cbright_key TEXT UNIQUE,
    cbright_label TEXT
);

INSERT OR IGNORE INTO cbright (cbright_key,cbright_label)
    VALUES ('admin','Administrator');

CREATE TABLE IF NOT EXISTS cbuserright (
    cbuserright_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    cbuserright_cbuser INTEGER REFERENCES cbuser(cbuser_id) ON DELETE CASCADE,
    cbuserright_cbright INTEGER REFERENCES cbright
);

CREATE UNIQUE INDEX IF NOT EXISTS cbuserright_idx
    ON cbuserright(cbuserright_cbuser,cbuserright_cbright);
