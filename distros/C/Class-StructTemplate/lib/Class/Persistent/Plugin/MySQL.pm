#
# Class::Persistent::Plugin::MySQL - Plugin to enable persistence through the MySQL-database.
# $Id$
#
# Copyright (C) 2000 by Heiko Wundram.
# All rights reserved.
#
# This program is free software; you can redistribute and/or modify it under the same terms as Perl itself.
#
# $Log$
#

package Class::Persistent::Plugin::MySQL;
$Class::Persistent::Plugin::MySQL::VERSION = '0.01';

use DBI qw(:sql_types);

use Carp;

sub new
{
    my ($class,$dsn,$user,$passwd) = @_;
    $class = ref $class ? ref $class : $class;
    my $dbh = DBI->connect( $dsn, $user, $passwd,
			    { PrintError => 0, RaiseError => 0 } )
	or confess("Cannot connect to database: $DBI::errstr!");
    my $self = {};

    $self->{"_dbh"} = $dbh;

    bless( $self, $class );

    return $self;
}

sub normalize_pkg
{
    my ($pkg) = @_;

    $pkg =~ s/:/_/g;
    return $pkg;
}

sub get_max_id
{
    if( @_ != 2 )
    {
	confess "get_max_id can only be called with one arguments!";
    }

    my ($class,$pkg) = @_;
    ref $class or confess "get_max_id can only be called on an instance of the storage class!";
    my $dbh = $class->{"_dbh"};
    my $db_pkg = normalize_pkg($pkg);
    my $sth;
    my $ret_val;

    ( $sth = $dbh->prepare("SELECT max(_id) FROM $db_pkg") )
	or confess("Something is really wrong with the database!");

    if( !$sth->execute() )
    {
	$ret_val = 0;
    }
    else
    {
	($ret_val) = $sth->fetchrow_array;
    }
    $sth->finish();

    return $ret_val+1;
}

sub load
{
    if( @_ < 3 || @_ > 4 )
    {
	confess "load can only be called with two or three arguments!";
    }

    my ($class,$out,$pkg,$type) = @_;
    ref $class or confess "load can only be called on an instance of the storage class!";
    ref $out or confess "load can only be called on an instance of the container class!";
    my $dbh = $class->{"_dbh"};
    my $db_pkg = normalize_pkg($pkg);
    my $sth = $class->{"_sth"};
    my $ret_val;
    my $set_val;
    my ($attribs,$types);

    if( $sth )
    {
	$set_val = $sth->fetchrow_hashref();
	if( !$set_val )
	{
	    $ret_val = 1;
	    $sth->finish();
	    delete $class->{"_sth"};
	}
	else
	{
	    $ret_val = 0;
	}
    }
    else
    {
	( $sth = $dbh->prepare("SELECT * FROM $db_pkg".($type?" WHERE $type":"")) )
	    or confess("Something is really wrong with the database!");

	if( !$sth->execute() )
	{
	    $set_val = undef;
	    $ret_val = -1;
	}
	else
	{
	    $set_val = $sth->fetchrow_hashref();
	    $ret_val = 0;
	    $class->{"_sth"} = $sth;
	}
    }

    if( $ret_val == 0 )
    {
	($attribs,$types) = split_hash($set_val);
	$out->set_attributes_type($attribs,$types);
    }

    return $ret_val;
}

sub split_hash
{
    if( @_ != 1 )
    {
	confess "split_hash can only be called with one argument!";
    }

    my ($set_val) = @_;
    my $key;
    my ($attribs,$types) = ({},{});

    foreach $key (keys %$set_val)
    {
	if( $key =~ /^(.*)_type$/ )
	{
	    $types->{$1} = $set_val->{$key};
	}
	else
	{
	    $attribs->{$key} = $set_val->{$key};
	}
    }

    return ($attribs,$types);
}

sub store
{
    if( @_ != 3 )
    {
	confess "store can only be called with two arguments!";
    }

    my ($class,$out,$pkg) = @_;
    ref $class or confess "store can only be called on an instance of the storage class!";
    ref $out or confess "store can only be called on an instance of the container class!";
    my $dbh = $class->{"_dbh"};
    my $db_pkg = normalize_pkg($pkg);
    my $sth;
    my ($attribs,$types);
    my ($statement_pre,$statement_post,$statement);
    my %binds;
    my @binds;
    my ($attrib,$i);

    ($attribs,$types) = $out->get_attributes_type();

    construct_table($dbh,$db_pkg,$types);

    $statement_pre = "INSERT INTO $db_pkg (";
    $statement_post = "VALUES (";
    $i = 1;

    foreach $attrib (keys %$attribs)
    {
	$binds{$i++} = $attribs->{$attrib};
	$binds{$i++} = $types->{$attrib};

	$statement_pre .= $attrib.",".$attrib."_type,";
	$statement_post .= "?,?,";
    }

    $statement_pre =~ s/,$//;
    $statement_post =~ s/,$//;

    $statement = $statement_pre.") ".$statement_post.")";

    ( $sth = $dbh->prepare($statement) )
	or confess("Something amiss with the database!");

    foreach $attrib (keys %binds)
    {
	$sth->bind_param($attrib,$binds{$attrib},SQL_VARCHAR);
    }

    return $sth->execute(@binds);
}

sub save
{
    if( @_ != 3 )
    {
	confess "save can only be called with two arguments!";
    }

    my ($class,$out,$pkg) = @_;
    ref $class or confess "save can only be called on an instance of the storage class!";
    ref $out or confess "save can only be called on an instance of the container class!";
    my $dbh = $class->{"_dbh"};
    my $db_pkg = normalize_pkg($pkg);
    my $sth;
    my ($attribs,$types);
    my $statement;
    my %binds;
    my ($attrib,$i);

    ($attribs,$types) = $out->get_attributes_type();

    construct_table($dbh,$db_pkg,$types);

    $statement = "UPDATE $db_pkg SET ";
    $i = 1;

    foreach $attrib (keys %$attribs)
    {
	$binds{$i++} = $attribs->{$attrib};
	$binds{$i++} = $types->{$attrib};

	$statement .= $attrib."=?,".$attrib."_type=?,";
    }

    $statement =~ s/,$//;

    $statement .= " WHERE _id = ".$attribs->{"_id"};

    ( $sth = $dbh->prepare($statement) )
	or confess("Something amiss with the database!");

    foreach $attrib (keys %binds)
    {
	$sth->bind_param($attrib,$binds{$attrib},SQL_VARCHAR);
    }

    return $sth->execute();
}

sub delete
{
    if( @_ != 3 )
    {
	confess "delete requires two arguments!";
    }

    my ($class,$out,$pkg) = @_;
    ref $class or confess "delete can only be called on an instance of the storage class!";
    ref $out or confess "delete can only be called on an instance of the container class!";
    my $dbh = $class->{"_dbh"};
    my $db_pkg = normalize_pkg($pkg);
    my $sth;
    my ($attribs,$types);
    my $statement;

    ($attribs,$types) = $out->get_attributes_type();

    $statement = "DELETE FROM $db_pkg WHERE _id = ".$attribs->{"_id"};

    ( $sth = $dbh->prepare($statement) )
	or confess("Something is amiss with the database!");

    return $sth->execute();
}

sub calc_refs
{
    if( @_ != 3 )
    {
	confess "calc_refs requires two arguments!";
    }

    my ($class,$out,$pkg) = @_;
    ref $class or confess "calc_refs can only be called on an instance of the storage class!";
    ref $out or confess "calc_refs can only be called on an instance of the container class!";
    my $dbh = $class->{"_dbh"};
    my $sth;
    my ($attribs,$types);
    my $id;
    my (@tables,$table);
    my $refs;
    my $vals;
    my $key;

    ($attribs,$types) = $out->get_attributes_type();

    $id = $attribs->{"_id"}."|$pkg";

    $statement = "SELECT * FROM pkg_list";

    ( $sth = $dbh->prepare($statement) )
	or confess("Something is amiss with the database!");

    $sth->execute();

    while( ($table) = $sth->fetchrow_array() )
    {
	push @tables, $table;
    }

    foreach $table (@tables)
    {
	$statement = "SELECT * FROM $table";

	( $sth = $dbh->prepare($statement) )
	    or confess("Something is amiss with the database!");

	$sth->execute();

	while( $vals = $sth->fetchrow_hashref() )
	{
	    foreach $key (keys %$vals)
	    {
		if( $key =~ /_type$/ )
		{
		    next;
		}

		if( $vals->{$key."_type"} eq 'c' )
		{
		    if( $vals->{$key} eq $id )
		    {
			$refs++;
		    }
		}
	    }
	}
    }

    return $refs;
}

sub check_tables
{
    if( @_ != 1 )
    {
	confess "check_tables takes no arguments!";
    }

    my ($class) = @_;
    ref $class or confess "delete can only be called on an instance of the storage class!";
    my $dbh = $class->{"_dbh"};
    my $sth;
    my $statement;
    my (@tables,$table);
    my $count;
    my @delete;

    $statement = "SELECT * FROM pkg_list";

    ( $sth = $dbh->prepare($statement) )
	or confess("Something is amiss with the database!");

    $sth->execute();

    while( ($table) = $sth->fetchrow_array() )
    {
	push @tables, $table;
    }

    foreach $table (@tables)
    {
	$statement = "SELECT COUNT(*) FROM $table";

	( $sth = $dbh->prepare($statement) )
	    or confess("Something is amiss with the database!");

	$sth->execute();

	($count) = $sth->fetchrow_array();

	if( $count == 0 )
	{
	    push @delete, $table;
	}
    }

    foreach $table (@delete)
    {
	$statement = "DROP TABLE $table";

	( $sth = $dbh->prepare($statement) )
	    or confess("Something is amiss with the database!");

	$sth->execute();

	$statement = "DELETE FROM pkg_list WHERE pkg = '$table'";

	( $sth = $dbh->prepare($statement) )
	    or confess("Something is amiss with the database!");

	$sth->execute();
    }
}

sub construct_table
{
    if( @_ != 3 )
    {
	confess "construct_table can only be called with two arguments!";
    }

    my ($dbh,$db_pkg,$types) = @_;
    my $statement;
    my $field;

    $statement = "CREATE TABLE pkg_list (pkg VARCHAR(255) NOT NULL,UNIQUE (pkg))";

    ( $sth = $dbh->prepare($statement) )
	or confess("Something is amiss with the database!");

    $sth->execute();

    $statement = "INSERT INTO pkg_list VALUES (?)";

    ( $sth = $dbh->prepare($statement) )
	or confess("Something is amiss with the database!");

    $sth->bind_param(1,$db_pkg,SQL_VARCHAR);

    $sth->execute();

    $statement = "CREATE TABLE $db_pkg (";

    foreach $field (keys %$types)
    {
	$statement .= $field." ";

	if( $types->{$field} eq 'n' )
	{
	    $statement .= "BIGINT,";
	}
	elsif( $types->{$field} eq 's' || $types->{$field} eq 'c' )
	{
	    $statement .= "LONGTEXT,";
	}
	else
	{
	    $statement .= "LONGBLOB,";
	}

	$statement .= $field."_type CHAR(1),";
    }

    $statement =~ s/,$/\)/;

    ( $sth = $dbh->prepare($statement) )
	or confess("Something is amiss with the database!");

    return $sth->execute();
}

sub DESTROY
{
    my ($class) = @_;

    $class->{"_dbh"}->disconnect() or croak("Could not disconnect from Datasource!");
}

1;
