#!/usr/bin/perl
#
# Name:
#	bootstrap-menus.pl.
#
# Purpose:
#	Test DBIx::HTML::PopupRadio.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use strict;
use warnings;

use DBI;
use Error qw/ :try /;

# -----------------------------------------------

sub load_campus
{
	my($dbh)	= @_;
	my($sql)	= 'drop table if exists campus';

	$dbh -> do($sql);

	$sql = 'create table campus (campus_id int auto_increment primary key, campus_name varchar(30) )';

	$dbh -> do($sql);

	print "SQL: $sql. \n";

	$sql		= 'insert into campus (campus_id, campus_name) values (?, ?)';
	my($sth)	= $dbh -> prepare($sql);
	my(@data)	= ('Melbourne', 'Geelong'); # Not in alphabetical order, please.

	for (0 .. $#data)
	{
		$sth -> execute( ($_ + 1), $data[$_]);
	}

	$sth -> finish();

	$sql = 'select campus_id, campus_name from campus';
	$sth = $dbh -> prepare($sql);

	$sth -> execute();

	my($data, %id);

	while ($data = $sth -> fetch() )
	{
		$id{$$data[1]} = $$data[0];
		print "Id: $$data[0]. Campus: $$data[1]. \n";
	}

	print "Finished inserting campus data. \n";

	\%id;

}	# End of load_campus.

# -----------------------------------------------

sub load_unit
{
	my($dbh, $id)	= @_;
	my($sql)		= 'drop table if exists unit';

	$dbh -> do($sql);

	$sql = 'create table unit (unit_id int auto_increment primary key, unit_campus_id int, unit_code varchar(10), unit_name varchar(60) )';

	$dbh -> do($sql);

	print "SQL: $sql. \n";

	$sql		= 'insert into unit values (?, ?, ?, ?)';
	my($sth)	= $dbh -> prepare($sql);
	my($count)	= 0;
	my(%data)	=
	(
		'Melbourne'		=>
		{
			'scc107m'	=> 'Concepts and Practices for Software Engineering',
			'scc108m'	=> 'Database and Information Retrieval',
			'scc109m'	=> 'World Wide Web and Internet',
			'scc110m'	=> 'MultiMedia Design',
			'scc111m'	=> 'Communication Skills for Information Technologists',
		},
		'Geelong'		=>
		{
			'scc107g'	=> 'Concepts and Practices for Software Engineering',
			'scc109g'	=> 'World Wide Web and Internet',
			'scc111g'	=> 'Communication Skills for Information Technologists',
		},
	);

	for my $campus (keys %data)
	{
		for my $unit (keys %{$data{$campus} })
		{
			$count++;
			$sth -> execute($count, $$id{$campus}, $unit, $data{$campus}{$unit});
			print "Campus: $campus. Unit: $unit. Id: $count. Name: $data{$campus}{$unit}. \n";
		}
	}

	$sth -> finish();

	print "Finished inserting unit data. \n";

}	# End of load_unit.

# -----------------------------------------------

try
{
	my($dbh) = DBI -> connect
	(
		'DBI:mysql:test:127.0.0.1',
		'root',
		'pass',
		{
			AutoCommit			=> 1,
			HandleError			=> sub {Error::Simple -> record($_[0]); 0},
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);

	load_unit($dbh, load_campus($dbh) );
}
catch Error::Simple with
{
	my($error) = 'Error::Simple: ' . $_[0] -> text();
	chomp($error);
	print "Error: $error. \n";
};
