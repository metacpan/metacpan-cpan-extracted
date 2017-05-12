

package DBIx::Mysql::InformationSchema;

use strict;
use warnings;
use DBI;

our $VERSION = '0.04';




#
# Get a new object, not connected to start.
#

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self,$class;
    $self->{STATUS} = 0;
    $self->{DBH} = '';  
    return $self;
}


# connectdb()
# Connect to the INFORMATION_SCHEMA database.
# You can simply put your own database handle into $obj->{DBH} if you prefer.


sub connectdb {
    my $thisthing = shift or return undef;

    my $user     = shift ;   # user,pass,host and port are all actually optional...
    my $password = shift ;   # the db might allow open access, right?

    my $host = shift;
    my $port = shift;
    

    my $mysql_information_view = 'information_schema';
    my $dsn = join ':','DBI','mysql', $mysql_information_view;

    if ($host) {
	$port = 3306 unless $port;  
	$dsn = $dsn."\@".$host.':'.$port;
    }


    
    if ($thisthing->{DBH} = DBI->connect($dsn,  $user, $password )) {
	$thisthing->{STATUS} = "connected"; 
    } else {
	$thisthing->{DBIERROR} = $DBI::errstr;
	$thisthing->{STATUS} = 0;  # false but defined.
    }
}


# given a particular value - return the value for that db,table,column
# value is one of the 

sub column_info_value {
    my $thisthing = shift or return undef;
    my $options = shift ;

    my $db     = $thisthing->{DBH}->quote($options->{DB});
    my $table  = $thisthing->{DBH}->quote($options->{TABLE});
    my $column = $thisthing->{DBH}->quote($options->{COLUMN});
    my $value =  $thisthing->{DBH}->quote($options->{VALUE});

    my $sql = "SELECT * from COLUMNS where TABLE_SCHEMA = $db AND TABLE_NAME  = $table AND COLUMN_NAME = $column";

    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;

    # this should only return one row.
    my $href = $sth->fetchrow_hashref;
    return $href->{$value};
}


#
# Column_table_rows
# 

sub column_table_rows {
    my $thisthing = shift or return undef;

    my $sql = "SELECT * from COLUMNS limit 1";
    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;

    my $href = $sth->fetchrow_hashref;
    return keys %{$href};

}





#
# Return a list of all the  databases.
#
sub databases {

    my $thisthing = shift;
    my @rows;
    my $sth = $thisthing->{DBH}->prepare("SELECT DISTINCT TABLE_SCHEMA from TABLES");
    $sth->execute;
    while (my $row  =  $sth->fetchrow_array) {
	push @rows,$row;
    }
    return (@rows);
}




# Return a list of all the tables for a given database

sub tables {
    my $thisthing = shift or return undef;

    my $db = shift  or return undef;
    $db     = $thisthing->{DBH}->quote($db);

    my $sql = "SELECT DISTINCT TABLE_NAME from COLUMNS where TABLE_SCHEMA = $db";

    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;
    my @tables;
    while (my $row  =  $sth->fetchrow_array) {
	push @tables,$row;
    }
    return (@tables);
}



# column_info returns a hash ref for the one row.
#  metadata for db,table and column.


sub column_info {

    my $thisthing = shift or return undef;

    my $db     = shift or return undef;
    my $table  = shift or return undef;
    my $column = shift or return undef;

    $db     = $thisthing->{DBH}->quote($db);
    $table  = $thisthing->{DBH}->quote($table);
    $column = $thisthing->{DBH}->quote($column);


    my $sql = "SELECT * from COLUMNS where TABLE_SCHEMA = $db AND TABLE_NAME  = $table AND COLUMN_NAME = $column";

    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;

    return $sth->fetchrow_hashref;
}




#
# Given a db and a table,, return  alist of columns
#

sub columns {
    my $thisthing = shift or return undef;

    my $db     = shift or return undef;
    my $table  = shift or return undef;

    $db    = $thisthing->{DBH}->quote($db);
    $table = $thisthing->{DBH}->quote($table);

    my $sql = "SELECT DISTINCT COLUMN_NAME from COLUMNS where TABLE_SCHEMA = $db AND TABLE_NAME  = $table";

    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;
    my @rows;
    while (my $row  =  $sth->fetchrow_array) {
	push @rows,$row;
    }
    return (@rows);
}




# information_schema_tables 
#
#  Returns a list of tables in the information_schema view.


sub information_schema_tables {
    my $thisthing = shift or return undef;

    my $sql = "select TABLE_NAME from TABLES where TABLE_SCHEMA='information_schema' ";

    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;

    my @tables;
    while (my $table = $sth->fetchrow_array) {
	push @tables,$table;
    }
    return (@tables);
}



sub table_constraints {
    my $thisthing = shift or return undef;
    my $sql = "SELECT * from TABLE_CONTRAINTS";
    my $sth = $thisthing->{DBH}->prepare($sql);
    $sth->execute;

    my @results;

    while (my $row = $sth->fetchrow_hashref) {
	push @results,$row;
    }
    return (@results);
}








sub disconnect {
    my $thisthing = shift or return undef;
    $thisthing->{DBH}->disconnect();

}


sub dbonline {
    my $thisthing = shift;
    if ($thisthing->{DBH}->{Driver}->{Name} =~ m/^mysql$/) {
	return 1;
    } else {
	return undef;
    }

}






1;
__END__


=head1 NAME

DBIx::Mysql::InformationSchema - Perl module to access the mysql INFORMATION_SCHEMA view, which contains database metadata.

=head1 SYNOPSIS

     use DBIx::Mysql::InformationSchema;


Get a new infoschema object.

     my $info_schema = new DBIx::Mysql::InformationSchema ;

Now connect it to the database.  The user must have read access to mysql's INFORMATION_SCHEMA view.
Print the status if you like.

     $info_schema->connectdb('mysqluser','!hello123');
     print "Mysql information_schema online \n" if $info_schema->{STATUS};


Get a list of all the databases:

     my @databases = $info_schema->databases();


Get a list of tables for a given database:

     my @tables    = $info_schema->tables('any_database');


Get a list of columns for a given database and table:

     my @columns   = $info_schema->tables('any_database','any_table');


Get the metadata for a given database,table and column.

     my $href = $info_schema->column_info('some_database','some_table','some_column');


Get a list of the tables that are in the INFOMATION_SCHEMA view.
This is done by querying the INFORMATION_SCHEMA Table, not statically.


     my @itables = $info_schema->information_schema_tables();

Get a list of all the fields in the COLUMNS table in the INFOMATION_SCHEMA view.
Like the information_schema_tables function, this is done by querying the 
INFORMATION_SCHEMA table COLUMNS, not statically.


    my @column_info_rows = $info_schema->column_table_rows();


All done?  Then disconnect.


    $info_schema-disconnect();





=head1 DESCRIPTION

Mysql 5 introduced a system view called INFORMATION_SCHEMA that contains metadata describing
the structure of all the databases, tables and columns.

This module provides methods to get at SOME of that data.   While you certainly can query
the INFORMATION_SCHEMA view manually, if your program uses this data frequently, you may find
this module convenient.  In order for this to run, you must already have the DBI perl module installed.

This module creates and uses its own database handle, stored in $object->{DBH}.  See the dbconnect method.
To connect, you must supply a username and password that can read INFORMATION_SCHEMA, which is just about
any valid mysql id.


Most of these methods use the COLUMNS table in the information_schema view.


This module exports no variables; all access is via defined functions, therefore I don't use the exporter.



=head1 SEE ALSO

The mysql database      --   mysql.com

Perl DBI/DBD/Mysql etc  --   cpan.org


=head1 AUTHOR

Gerry Lawrence, E<lt>gwlperl@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Gerry Lawrence

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
