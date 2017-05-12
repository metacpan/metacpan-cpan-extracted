use strict;
use DBI;

package DBD::mysql::SimpleMySQL;
use Exporter;
use vars qw/$VERSION $MOD_DATE $NAME $DEBUG $DEBUG_FILE  @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;
@ISA = qw|Exporter|;
@EXPORT_OK = qw|
	dbinsert
	dbconnect
	dbselect
	dbselect_arrayref
	dbinsert
	dbupdate
	dbdo
	where_struct
	join_struct
	build_joins
	build_wheres
	build_select
	build_insert
	build_delete
	find_dup
|;

%EXPORT_TAGS = (
	all	=> [
		'dbinsert',
		'dbconnect',
		'dbselect',
		'dbselect_arrayref',
		'dbinsert',
		'dbupdate',
		'dbdo',
		'where_struct',
		'join_struct',
		'build_joins',
		'build_wheres',
		'build_select',
		'build_insert',
		'build_delete',
		'find_dup'
	]
);


$VERSION = q|$Revision: 1.8 $|;
$MOD_DATE = q|$Date: 2004/04/28 20:07:27 $|;
$NAME = "SimpleMySQL.pm";
$DEBUG = 0;
$DEBUG_FILE = 0;



#####
# Methods
###
#
#


sub pnl () {
	print "\n";
}

sub nl () {
	return "\n";
}

sub debug {
	my $message = shift;
	my $level = shift;
		
	$DEBUG = 0 unless $DEBUG;
	$level = 1 unless $level;
	if ($DEBUG >= $level) {
		my $tabs = '';
		my $i = 0;
		my @lines = ();
		while (my @info = caller($i)) {
			push @lines, "$info[0], $info[2], $info[3]";
			$lines[$i] .= "    $message" if ($i == 1);
			$tabs .= "\t" if ($i > 0);
			$i++;
		}
		$lines[0] .= "    $message" if ($i < 2);
		push @lines, "END DEBUG";
		
		my $fh = 0;
		if (-f $DEBUG_FILE and -w $DEBUG_FILE) {
			open FILE, ">>$DEBUG_FILE" or warn "Could not open $DEBUG_FILE:$!";
			$fh = \*FILE;
		} else {
			$fh = \*STDERR;
		}
		for my $line (@lines) {
			print $fh $tabs, $line, "\n" if($line);
		}
		close $fh if (-f $DEBUG_FILE and -w $DEBUG_FILE);
	}
}
		

sub dbconnect ($) {
	my $dbinfo = shift;

	${$dbinfo}{host} = 'localhost' unless(defined(${$dbinfo}{host}));
	${$dbinfo}{user} = scalar(getpwuid($<)) unless(defined(${$dbinfo}{user}));
	${$dbinfo}{pass} = '' unless(defined(${$dbinfo}{pass}));
	${$dbinfo}{port} = '3306' unless(defined(${$dbinfo}{port}));
	${$dbinfo}{RaiseError} = 0 unless(defined(${$dbinfo}{RaiseError}));
	${$dbinfo}{AutoCommit} = 1 unless(defined(${$dbinfo}{AutoCommit}));
	
	unless(defined(${$dbinfo}{dsh})) {
		${$dbinfo}{dsh} .= "DBI";
		${$dbinfo}{dsh} .= ":mysql";
		${$dbinfo}{dsh} .= ":host=${$dbinfo}{host}";
		${$dbinfo}{dsh} .= ":datasbase=${$dbinfo}{database}" unless(defined(${$dbinfo}{database}));;
		${$dbinfo}{dsh} .= ":port=${$dbinfo}{port}";
	}

	my $dbh = DBI->connect(
		$$dbinfo{dsh}, 
		$$dbinfo{user}, 
		$$dbinfo{pass}, 
		{ 
			RaiseError => ${$dbinfo}{RaiseError}, 
			AutoCommit => ${$dbinfo}{AutoCommit} 
		}
	);
	unless(ref($dbh)){
		debug("dbconnect error: $DBI::errstr", 0);
		return 0;
	}
	return $dbh;
}

sub dbselect ($$) {
	my $dbh = shift;
	my $query = shift;

	debug("executing query \n$query", 3);
	my $sth = $dbh->prepare($query);
	$sth->execute;
	if ($DBI::errstr) {
		debug("dbselect error: $DBI::errstr\n\tQuery is $query", 0);
		$sth = 0;
	}

        return $sth;
}

sub dbselect_arrayref ($$) {
	my $dbh = shift;
	my $sql = shift;

	my $sth = dbselect($dbh, $sql);

	return 0 unless ($sth);
	my @return = ();
	while (my $r = $sth->fetchrow_hashref) {
		push @return, $r;
	}

	return \@return;
}

sub dbdo ($$) {
	my $dbh = shift;
	my $sql = shift;

	debug("Running sql command: $sql", 3);
	my $rv = $dbh->do($sql);
	if ($DBI::errstr) {
		debug("$DBI::errstr",0);
		return 0;
	}
		
	return $rv;
}
		
sub dbupdate ($$$$) {
	my $dbh = shift;
	my $table = shift;
	my $pairs = shift;
	my $id = shift;
		
	unless ($id and ref($pairs)) {
		return 0;
	}
	my @tmp;
	for my $key (keys(%{$pairs})) {
		next if ($key eq $id);
		push @tmp, qq|$key = "${$pairs}{$key}"|;
	}
	my $set = join ",", @tmp;
	my $where = qq|$id = "${$pairs}{$id}"|;
		
	my $sql = qq|UPDATE $table SET $set WHERE $where|;
		
	my $return = dbdo($dbh, $sql);
		
	return $return;
}

sub where_struct ($$$) {
	my $key = shift;
	my $type = shift;
	my $value = shift;

	my $return = {
		key	=> $key,
		value	=> $value,
		type	=> $type,
	};

	return $return;
}


sub join_struct ($$$) {
	my $table = shift;
	my $tableid = shift;
	my $joinid = shift;

	my $return = {
		table	=> $table,
		tableid	=> $tableid,
		joinid	=> $joinid,
	};

	return $return;
}

sub build_joins ($) {
	my $joins = shift;

	my $return = '';
	if (ref($joins)) {
		for my $join (@{$joins}) {
			if (ref($join)) {
				$return .= " LEFT JOIN ";
				$return .= ${$join}{table};
				$return .= " ON ";
				$return .= ${$join}{tableid};
				$return .= " = ";
				$return .= ${$join}{joinid};
			} else {
				$return .= $join;
			}
		}
	} else {
		$return .= $joins;
	}

	return $return;
}

sub build_wheres ($) {
	my $wheres = shift;

	my $return;
	if (ref($wheres)) {
		$return = ' WHERE ';
		my @and;
		for my $where (@{$wheres}) {
			my $tmp = qq/${$where}{key} ${$where}{type} "${$where}{value}"/;
			$tmp = qq/${$where}{key} ${$where}{type} (${$where}{value})/ if (${$where}{type} =~ /^in$/i);
			push @and, $tmp;
		}
		$return .= join " AND ", @and;
	} else {
		unless ($wheres =~ m/WHERE/i) {
			$return = ' WHERE ';
		}
		$return .= $wheres;
	}

	return $return;
}

sub build_delete ($$$) {
	my $from = shift;
	my $joins = shift;
	my $wheres = shift;

	my $return = "DELETE FROM ";
	
	$return .= join ",", @{$from};
	$return .= build_joins($joins) if ($joins);
	$return .= build_wheres($wheres) if ($wheres);

	return $return;
}

sub overload ($$) {
	my $at = shift;
	my $argc = shift;
}

sub build_select {
	my $select;
	my $from;
	my $joins;
	my $wheres;
	my $order;
	my $ref;
	my $limit;
	
	if (scalar(@_) == 5) {
		$select = shift;
		$from = shift;
		$joins = shift;
		$wheres = shift;
		$order = shift;
	} elsif (scalar(@_) == 1) {
		$ref = shift;
		
		$select = ${$ref}{'select'};
		$from = ${$ref}{from};
		$joins = ${$ref}{joins};
		$wheres = ${$ref}{wheres};
		$order = ${$ref}{order};
		$limit = ${$ref}{limit};
	} else {
		die "build_select must be passed 1 or 5 args";
	}

	my $return = "SELECT ";

	$return .= join ",", @{$select};
	$return .= " FROM ";
	$return .= join ",", @{$from};
	$return .= build_joins($joins) if ($joins);
	$return .= build_wheres($wheres) if ($wheres);
	$return .= " $order" if ($order);

	return  $return;
}

sub build_insert ($$) {
	my $table = shift;
	my $pairs = shift;

	return 0 unless (ref($pairs));
	my $return = "INSERT INTO $table SET ";
	my @tmp;
	for my $key (keys(%{$pairs})) {
		push @tmp, qq/$key = '${$pairs}{$key}'/;
	}

	$return .= join ",", @tmp;

	return $return;
}

sub find_dup ($$$$) {
	my $dbh = shift;
	my $table = shift;
	my $pairs = shift;
	my $matchon = shift;

	my $select = ['*'];
	my $from = [$table];
	my $wheres = [];
	for my $match (@{$matchon}) {
		push @{$wheres}, wheres_struct($match, 'like', ${$pairs}{$match});
	}

	my $rows = dbselect_arrayref($dbh, build_select($select, $from, 0, $wheres, 0));

	if (scalar(@{$rows}) > 0) {
		return $rows;
	} else {
		return 0;
	}
}

sub add_hashs ($$) {
	my $hash1 = shift;
	my $hash2 = shift;

	my $return = {};
	return $return unless (ref($hash1) and ref($hash2));

	for my $key (keys(%{$hash1})) {
		${$return}{$key} = ${$hash1}{$key};
	}
	
	for my $key (keys(%{$hash2})) {
		${$return}{$key} = ${$hash2}{$key};
	}

	return $return;
}
	
sub dbinsert ($$$) {
	my $dbh = shift;
	my $table = shift;
	my $pairs = shift;

	my $sql = build_insert($table, $pairs);

	my @r;
	debug("$sql", 3);
	$dbh->do($sql);
	if ($DBI::errstr) {
		debug("$DBI::errstr",0);
		return 0;
	}
	@r = $dbh->selectrow_array("select last_insert_id()");

	return $r[0];
}

#####
# End Functions
###
#
#

1;

## Documentation
#
=head1 NAME

DBD::mysql::SimpleMySQL - A simple interface to DBD::mysql

=head1 SYNOPSIS

	my %dbinfo = (
		user    => 'user',
		pass    => 'password',
		dsh   => "DBI:mysql:database=DB:host=127.0.0.1:port=3307"
	);

	OR 
	
	my %dbinfo = (
		user		=> 'user',
		pass		=> 'password',
		database	=> 'DB',
		host		=> '127.0.0.1',
		port		=> '3307'
	);

	$my $dbh = dbconnect(\%dbinfo);

	my $select = ['Passwd.*', 'UsrGrp.UsrGrpName'];
	my $from = ['Passwd'];
	my $joins = [];
	push @{$joins}, join_struct("PasswdHostGrp", "Passwd.PasswdID", "PasswdHostGrp.PasswdID");
	push @{$joins}, join_struct("UsrGrp", "Passwd.PrimaryGroupID", "UsrGrp.UsrGrpID");
	my $wheres = "PasswdHostGrp.HostGrpID IN ('group1', 'group2')";
		
	my $arrayref = dbselect_array($dbh, build_select($select, $from, $joins, $wheres, 0));

=head1 EXAMPLE

	#!/usr/bin/perl -w
	#
	use strict;
	use DBD::mysql::SimpleMySQL qw/:all/;

	my %dbinfo = (
		user		=> 'user',
		pass		=> 'password',
		database	=> 'DB',
		host		=> '127.0.0.1',
		port		=> '3307'
	);

	$my $dbh = dbconnect(\%dbinfo);

	my $select = ['Passwd.*', 'UsrGrp.UsrGrpName'];
	my $from = ['Passwd'];
	my $joins = [];
	push @{$joins}, join_struct("PasswdHostGrp", "Passwd.PasswdID", "PasswdHostGrp.PasswdID");
	push @{$joins}, join_struct("UsrGrp", "Passwd.PrimaryGroupID", "UsrGrp.UsrGrpID");
	my $wheres = "PasswdHostGrp.HostGrpID IN ('group1', 'group2')";
		
	my $arrayref = dbselect_array($dbh, build_select($select, $from, $joins, $wheres, 0));


	my $i = 1;
	for my $row (@{$arrayref}) {
		print "Row $i\n";
		for my $key (keys(%{$row})) {
			print "\t$key = ${$row}{$key}\n";
		}
		$i++;
	}
	
=head1 DESCRIPTION

DBD::mysql::SimpleMySQL is an extention of the DBI mysql driver. It simplifies getting the data you want out of your DB. I wrote it because I found that everytime I put together a DBI based app I ended up writing these functions anyway.

=head1 Public Methods
dbinsert
dbconnect($)
	Takes a hash ref, return a DBI database handle.

dbselect($$)
	Takes a DBI db handle and a MySQL query string.

dbselect_arrayref($$)
	Takes a DBI db handle and a MySQL query string.

dbinsert
dbupdate($$$$)
	Takes a DBI db handle, table name string, a hash ref of Columns to update including an "ID" column, and the "ID" column string

dbdo($$)
	Takes a DBI db handle and a SQL command string. This string is pretty much passed directly to $dbh->do

where_struct($$$)
	Takes a key, type and value argument.
		Key is the column name or function in a where clause.
		Type is the comparison, "LIKE", "IN", "=" etc.
		Value is the value. "WHERE Key = Value."
	Returns a reference to be used in "build_wheres"

join_struct($$$)
	Takes a table, tableid and joinid.
		Table is the table to join to query.
		Tableid is the key to join the table on. "JOIN table ON tableid = joinid."
		Joinid is the key to join the table on. "JOIN table ON tableid = joinid."
	Returns a reference to be used in "build_joins"

build_joins($)
	Takes a "join_struct" reference. Builds a LEFT JOIN query string.
	OR
	Takes a JOIN string directly including the "JOIN".
	Returns a LEFT JOIN string to be passed to "build_*"

build_wheres($)
	Takes a reference to an array of "where_struct" references. Builds a WHERE query string.
	OR
	Takes a WHERE string directly not including the "WHERE".
	Returns a WHERE string to be passed to "build_*"

build_select($$$$$)

build_insert($$)

build_delete($$$)

find_dup($$$$)

=head1 AUTHOR

Jacob Boswell

=head1 COPYRIGHT

DBD::mysql::SimpleMySQL is Copyright(c) 2004 Jacob Boswell. All rights reserved
You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.

=back

=cut

