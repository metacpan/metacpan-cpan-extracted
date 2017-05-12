package Class::DBI::mysql;

$VERSION = '1.00';

=head1 NAME

Class::DBI::mysql - Extensions to Class::DBI for MySQL

=head1 SYNOPSIS

  package Film;
  use base 'Class::DBI::mysql';
  __PACKAGE__->set_db('Main', 'dbi:mysql:dbname', 'user', 'password');
  __PACKAGE__->set_up_table("film");

  __PACKAGE__->autoinflate(dates => 'Time::Piece');

  # Somewhere else ...

  my $type = $class->column_type('column_name');
  my @allowed = $class->enum_vals('column_name');

  my $tonights_viewing  = Film->retrieve_random;

=head1 DESCRIPTION

This is an extension to Class::DBI, containing several functions and
optimisations for the MySQL database. Instead of setting Class::DBI
as your base class, use this instead.

=cut

use strict;
use base 'Class::DBI';

=head1 METHODS

=head2 set_up_table

	__PACKAGE__->set_up_table("table_name");

Traditionally, to use Class::DBI, you have to set up the columns:

	__PACKAGE__->columns(All => qw/list of columns/);
	__PACKAGE__->columns(Primary => 'column_name');

Whilst this allows for more flexibility if you're going to arrange your
columns into a variety of groupings, sometimes you just want to create the
'all columns' list. Well, this information is really simple to extract
from MySQL itself, so why not just use that?

This call will extract the list of all the columns, and the primary key
and set them up for you. It will die horribly if the table contains
no primary key, or has a composite primary key.

=cut

__PACKAGE__->set_sql(desc_table => 'DESCRIBE __TABLE__');

sub set_up_table {
	my $class = shift;
	$class->table(my $table = shift || $class->table);
	(my $sth = $class->sql_desc_table)->execute;
	my (@cols, @pri);
	while (my $hash = $sth->fetch_hash) {
		my ($col) = $hash->{field} =~ /(\w+)/;
		push @cols, $col;
		push @pri, $col if $hash->{key} eq "PRI";
	}
	$class->_croak("$table has no primary key") unless @pri;
	$class->columns(Primary => @pri);
	$class->columns(All     => @cols);
}

=head2 autoinflate

  __PACKAGE__->autoinflate(column_type => 'Inflation::Class');

  __PACKAGE__->autoinflate(timestamp => 'Time::Piece');
  __PACKAGE__->autoinflate(dates => 'Time::Piece');

This will automatically set up has_a() relationships for all columns of
the specified type to the given class.

We currently assume that all classess passed will be able to inflate
and deflate without needing extra has_a arguments, with the example of
Time::Piece objects, which we deal with using Time::Piece::mysql (which
you'll have to have installed!).

The special type 'dates' will autoinflate all columns of type date,
datetime or timestamp.

=cut

sub autoinflate {
	my ($class, %how) = @_;
	$how{$_} ||= $how{dates} for qw/date datetime timestamp/;
	my $info = $class->_column_info;
	foreach my $col (keys %$info) {
		(my $type = $info->{$col}->{type}) =~ s/\W.*//;
		next unless $how{$type};
		my %args;
		if ($how{$type} eq "Time::Piece") {
			eval "use Time::Piece::MySQL";
			$class->_croak($@) if $@;
			$args{inflate} = "from_mysql_$type";
			$args{deflate} = "mysql_$type";
		}
		$class->has_a($col => $how{$type}, %args);
	}
}

=head2 create_table

	$class->create_table(q{
		name    VARCHAR(40)     NOT NULL PRIMARY KEY,
		rank    VARCHAR(20)     NOT NULL DEFAULT 'Private',
		serial  INTEGER         NOT NULL
	});

This creates the table for the class, with the given schema. If the
table already exists we do nothing.

A typical use would be:

	Music::CD->table('cd');
	Music::CD->create_table(q{
	  cdid   MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	  artist MEDIUMINT UNSIGNED NOT NULL,
		title  VARCHAR(255),
		year   YEAR,
		INDEX (artist),
		INDEX (title)
	});
	Music::CD->set_up_table;

=head2 drop_table

	$class->drop_table;

Drops the table for this class, if it exists. 

=cut

__PACKAGE__->set_sql(
	create_table => 'CREATE TABLE IF NOT EXISTS __TABLE__ (%s)');
__PACKAGE__->set_sql(drop_table => 'DROP TABLE IF EXISTS __TABLE__');

sub drop_table { shift->sql_drop_table->execute }

sub create_table {
	my ($class, $schema) = @_;
	$class->sql_create_table($schema)->execute;
}

=head2 column_type

	my $type = $class->column_type('column_name');

This returns the 'type' of this table (VARCHAR(20), BIGINT, etc.)

=cut

sub _column_info {
	my $class = shift;
	(my $sth = $class->sql_desc_table)->execute;
	return { map { $_->{field} => $_ } $sth->fetchall_hash };
}

sub column_type {
	my $class = shift;
	my $col = shift or die "Need a column for column_type";
	return $class->_column_info->{$col}->{type};
}

=head2 enum_vals

	my @allowed = $class->enum_vals('column_name');

This returns a list of the allowable values for an ENUM column.

=cut

sub enum_vals {
	my $class  = shift;
	my $col    = shift or die "Need a column for enum_vals";
	my $series = $class->_column_info->{$col}->{type};
	$series =~ /enum\((.*?)\)/ or die "$col is not an ENUM column";
	(my $enum = $1) =~ s/'//g;
	return split /,/, $enum;
}

=head2 retrieve_random

	my $film = Film->retrieve_random;

This will select a random row from the database, and return you
the relevant object.

(MySQL 3.23 and higher only, at this point)

=cut

__PACKAGE__->add_constructor(_retrieve_random => '1 ORDER BY RAND() LIMIT 1');

sub retrieve_random { shift->_retrieve_random->first }

=head1 SEE ALSO

L<Class::DBI>. MySQL (http://www.mysql.com/)

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-mysql@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;
