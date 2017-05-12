package Class::DBI::DB2;

=head1 NAME

Class::DBI::DB2 - Extensions to Class::DBI for DB2

=head1 SYNOPSIS

  package Music::DBI;
  use base 'Class::DBI::DB2';
  __PACKAGE__->set_db( 'Main', 'dbi:DB2:dbname', 'user', 'password', );

  package Artist;
  use base 'Music::DBI';
  __PACKAGE__->set_up_table('Artist');

  __PACKAGE__->autoinflate(dates => 'Time::Piece');

  # Somewhere else ...

  my $type = $class->column_type('column_name');
  my $colno = $class->column_no('column_name');
  my $nulls = $class->column_nulls('column_name');
  
  # ... see the Class::DBI documentation for details on Class::DBI usage

=head1 DESCRIPTION

Class::DBI::DB2 automates the setup of Class::DBI columns and primary key
for IBM DB2.

This is an extension to Class::DBI that currently implements:

	* Automatic column name discovery.
	
	* Automatic primary key(s) detection.

	* Automatic column type detection (for use with autoinflate).

	* Automatic column number detection (where column order is needed).

Instead of setting Class::DBI as your base class, use this.

=cut

use strict;
require Class::DBI;
use base 'Class::DBI';

use vars qw($VERSION);
$VERSION = '0.16';

=head1 OBJECT METHODS

=head2 set_up_table

	__PACKAGE__->set_up_table("table_name");

An optional second argument can supply your own alias for your table name.

	__PACKAGE__->set_up_table("table_name", "table_alias");

Traditionally, to use Class::DBI, you have to set up the columns:

	__PACKAGE__->columns(All => qw/list of columns/);
	__PACKAGE__->columns(Primary => 'column_name');

While this allows for more flexibility if you're going to arrange your
columns into a variety of groupings, sometimes you just want to create the
'all columns' list.  

The columns call will extract the list of all the columns, and the primary key
and set them up for you. It will die horribly if the table contains
no primary key(s).

=cut

sub _croak { require Carp; Carp::croak(@_); }

__PACKAGE__->set_sql(
	create_table => 'CREATE TABLE __TABLE__ (%s)');
__PACKAGE__->set_sql(drop_table => 'DROP TABLE __TABLE__');
__PACKAGE__->set_sql(
        desc_table => "SELECT COLNAME, COLNO, TYPENAME, NULLS FROM SYSCAT.COLUMNS WHERE TABSCHEMA = ? and TABNAME = ? order by colno");
__PACKAGE__->set_sql(
        exists => 'SELECT count(*) FROM SYSCAT.TABLES WHERE TABSCHEMA = ? and TABNAME = ?');

sub desc_table {
	my $class = shift;
        my ($tabschema,$table) = split '\.', $class->table;
	return $class->search_desc_table(uc($tabschema),uc($table));
}

sub set_up_table
{
	my $class = shift;
	$class->table( my $tabname = shift || $class->table, shift );
	my $dbh = $class->db_Main;
        my ($tabschema,$table) = split '\.', $class->table;

	# find primary key(s)
	my ( @primary );
	my $sth = $dbh->prepare(<<"SQL");
SELECT c.COLNAME FROM SYSCAT.KEYCOLUSE kc, SYSCAT.TABCONST tc,  SYSCAT.COLUMNS c
WHERE kc.CONSTNAME=tc.CONSTNAME AND kc.TABSCHEMA=tc.TABSCHEMA 
AND kc.TABNAME=tc.TABNAME AND kc.TABSCHEMA=c.TABSCHEMA AND 
kc.TABNAME=c.TABNAME AND kc.COLNAME=c.COLNAME AND kc.TABSCHEMA = ? AND 
kc.TABNAME = ? AND tc.TYPE = 'P' ORDER BY kc.COLSEQ
SQL
  	$sth->execute( uc($tabschema), uc($table) );
 	my $primaries = $sth->fetchall_arrayref; $sth->finish;
        map {push @primary, $_->[0]} @$primaries;
	$class->_croak("$table has no primary key") unless @primary;

	# find all columns
	my ( @cols );
	$sth = $dbh->prepare(<<"SQL");
SELECT COLNAME, COLNO, TYPENAME, NULLS FROM SYSCAT.COLUMNS 
WHERE TABSCHEMA = ? and TABNAME = ? order by colno 
SQL
  	$sth->execute( uc($tabschema), uc($table) );
 	my $columns = $sth->fetchall_arrayref; $sth->finish;
        map {push @cols, $_->[0]} @$columns;

	$class->columns( All     => @cols );
	$class->columns( Primary => @primary );
}

=head2 autoinflate

  __PACKAGE__->autoinflate(column_type => 'Inflation::Class');

  __PACKAGE__->autoinflate(timestamp => 'Time::Piece');
  __PACKAGE__->autoinflate(dates => 'Time::Piece');

This will automatically set up has_a() relationships for all columns of
the specified type to the given class.

It is assumed that all classes passed will be able to inflate
and deflate without needing extra has_a arguments, with the example of
Time::Piece objects, that uses Time::Piece::DB2 (which you'll have to 
have installed!).

The special type 'dates' will autoinflate all columns of type date,
time or timestamp.

=cut

sub autoinflate {
	my ($class, %how) = @_;
	$how{$_} ||= $how{dates} for qw/DATE TIME TIMESTAMP/;
	my $info = $class->_column_info;
	foreach my $col (keys %$info) {
		(my $type = $info->{$col}->{typename}) =~ s/\W.*//;
		next unless $how{$type};
		my %args;
		if ($how{$type} eq "Time::Piece") {
			eval "use Time::Piece::DB2";
			$class->_croak($@) if $@;
			$args{inflate} = "from_db2_" . lc($type);
			$args{deflate} = "db2_" . lc($type);
		}
		$class->has_a(lc($col) => $how{$type}, %args);
	}
}

sub exists {
  my $class = shift;
  my ($tabschema,$table) = split '\.', $class->table;
  return $class->sql_exists->select_val(uc($tabschema),uc($table));
}

=head2 create_table

	$class->create_table(q{
		name    VARCHAR(40)     NOT NULL,
		rank    VARCHAR(20)     NOT NULL,
		serial  INTEGER         NOT NULL
                PRIMARY KEY(name)
	});

This creates the table for the class, with the given schema. If the
table already exists we do nothing.

A typical use would be:

	Music::CD->table('cd');
	Music::CD->create_table(q{
	  cdid   INTEGER NOT NULL,
	  artist INTEGER NOT NULL,
	  title  VARCHAR(255) NOT NULL,
	  year   DATE,
          PRIMARY KEY(cdid),
          CONSTRAINT TITLE_UNIQ UNIQUE (artist,title)
	});
	Music::CD->set_up_table;

=cut

sub create_table {
  my ($class, $schema) = @_;
  if ($class->exists == 0) {
	$class->sql_create_table(uc($schema))->execute;
  }
}

=head2 drop_table

	$class->drop_table;

Drops the table for this class, if it exists. 

=cut

sub drop_table {
  my $class = shift;
  my ($tabschema,$table) = split '\.', $class->table;
  if ($class->exists == 1) {
    $class->sql_drop_table->execute;
  }
}

=head2 column_type

	my $type = $class->column_type('column_name');

This returns the 'typename' of this table's 'column_name' (VARCHAR(20), INTEGER, etc.)

=head2 column_no

	my $colno = $class->column_no('column_name');

This returns the 'colno' of this table's 'column_name' (0..n)  Useful when a column order 
is needed, for example, when loading a table from a flat-file.

=head2 column_nulls

	my $null = $class->column_nulls('column_name');

This returns the 'nulls' of this table's 'column_name' (Y,N) 

=cut

sub _column_info {
	my $class = shift;
        my ($tabschema,$table) = split '\.', $class->table;
        my @columns = $class->desc_table();
	return { map { $_->{colname} => $_ } @columns };
}

sub column_no {
	my $class = shift;
	my $col = shift or die "Need a column for column_no";
	return $class->_column_info->{uc($col)}->{colno};
}

sub column_nulls {
	my $class = shift;
	my $col = shift or die "Need a column for column_nulls";
	return $class->_column_info->{uc($col)}->{nulls};
}

sub column_type {
	my $class = shift;
	my $col = shift or die "Need a column for column_type";
	return $class->_column_info->{uc($col)}->{typename};
}

=head1 AUTHOR

Mark Ferris, E<lt>mark.ferris@geac.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2004 Mark Ferris. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>. IBM DB2 (http://www-4.ibm.com/software/data/db2/)

=cut

1;
