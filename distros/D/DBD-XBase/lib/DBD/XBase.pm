
=head1 NAME

DBD::XBase - DBI driver for XBase compatible database files

=cut

# ##################################
# Here starts the DBD::XBase package

package DBD::XBase;

use strict;
use DBI ();		# we want DBI
use XBase;		# and we want the basic XBase handling modules
use XBase::SQL;		# including the SQL parsing routines
use Exporter;

use vars qw( $VERSION @ISA @EXPORT $err $errstr $drh $sqlstate );
			# a couple of global variables that may come handy

$VERSION = '1.08';

$err = 0;
$errstr = '';
$sqlstate = '';
$drh = undef;

# The driver method creates the drivers instance; we store it in the
# global $drh variable to only load the driver once
sub driver {
	return $drh if $drh;
	my ($class, $attr) = @_;
	$class .= '::dr';
	$drh = DBI::_new_drh($class, {
		'Name'		=> 'XBase',
		'Version'	=> $VERSION,
		'Err'		=> \$DBD::XBase::err,
		'Errstr'	=> \$DBD::XBase::errstr,
		'State'		=> \$DBD::XBase::sqlstate,
		'Attribution'	=> 'DBD::XBase by Jan Pazdziora',
	});
}

# The data_sources method should return list of possible "databases"
# for the driver. With DBD::XBase, the database is in fact a directory.
# So should we return all direcoties in current? Right now, we only
# return the current directory.
sub data_sources {
	'dbi:XBase:.';
}


# ##################
# The driver package

package DBD::XBase::dr;
use strict;
$DBD::XBase::dr::imp_data_size = 0;

# The connect method returns a dbh; we require that the directory we
# want to search for tables exists.
sub connect {
	my ($drh, $dsn) = @_;
	$dsn = '.' if $dsn eq '';
	if (not -d $dsn) {
		$drh->DBI::set_err(1, "Connect failed: directory `$dsn' doesn't exist");
		return;
	}
	DBI::_new_dbh($drh, { 'Name' => $dsn } );
}

# We do not want to do anything upon disconnecting, but we might in
# the future (flush, close files)
sub disconnect_all {
	1;
}


# ####################
# The database package

package DBD::XBase::db;
use strict;
$DBD::XBase::db::imp_data_size = 0;

# The prepare method takes dbh and a SQL query and should return
# statement handler
sub prepare {
	my ($dbh, $statement) = @_;

	# we basically call XBase::SQL parsing and get an object
	my $parsed_sql = parse XBase::SQL($statement);
		### use Data::Dumper; print Dumper $parsed_sql;
	
	if (defined $parsed_sql->{'errstr'}) {
		$dbh->DBI::set_err(2, $parsed_sql->{'errstr'});
		return;
	}

	# we create a new statement handler; the only thing the the
	# specs requires us to do here (except parsing the query) is
	# to se the number of bind parameters found, which we do;
	# we do not set NUM_OF_FIELDS (which the specs doesn't require)
	# since for select * we do not know the number yet, for example
	DBI::_new_sth($dbh, {
		'Statement' => $statement,
		'xbase_parsed_sql' => $parsed_sql,
		'NUM_OF_PARAMS' => scalar(keys %{$parsed_sql->{'binds'}}),
	});
}

# Storing and fetching attributes in the database handler
sub STORE {
	my ($dbh, $attrib, $value) = @_;
	if ($attrib eq 'AutoCommit') {
		unless ($value) {
			die "Can't disable AutoCommit";
		}
		return 1;
	} elsif ($attrib =~ /^xbase_/) {
		$dbh->{$attrib} = $value; return 1;
	}
	$dbh->DBD::_::db::STORE($attrib, $value);
}
sub FETCH {
	my ($dbh, $attrib) = @_;
	if ($attrib eq 'AutoCommit') {
		return 1;
	} elsif ($attrib =~ /^xbase_/) {
		return $dbh->{$attrib};
	}
	$dbh->DBD::_::db::FETCH($attrib);
}

# Method tables provides a list of tables in the directory
sub tables {
	my $dbh = shift;
	opendir DIR, $dbh->{'Name'} or return;
	my @result = ();
	while (defined(my $item = readdir DIR)) {
		next unless $item =~ s/\.dbf$//i;
		push @result, $item;
	}
	closedir DIR;
	@result;
}

# Quoting method
sub quote {
	my $text = $_[1];
	return 'NULL' unless defined $text;
	$text =~ s/\\/\\\\/sg;
	$text =~ s/\'/\\\'/sg;
	return "'$text'";
	### return "'\Q$text\E'";
}

# Commit and rollback do not do anything usefull
sub commit {
	warn "Commit ineffective while AutoCommit is on"
		if $_[0]->FETCH('Warn');
	1;
}
sub rollback {
	warn "Rollback ineffective while AutoCommit is on"
		if $_[0]->FETCH('Warn');
	0;
}

# Upon disconnecting we close all tables
sub disconnect {
	my $dbh = shift;
	foreach my $table (keys %{$dbh->{'xbase_tables'}}) {
		$dbh->{'xbase_tables'}->{$table}->close;
		delete $dbh->{'xbase_tables'}{$table};
	}
	1;
}

# Table_info is a strange method that returns information about
# tables. There is not much we could say about the files so we only
# return list of them.
sub table_info {
	my $dbh = shift;
	my $xbase_lines = [ map { [ undef, undef, $_, 'TABLE', undef ] } $dbh->tables ];
	my $sth = DBI::_new_sth($dbh, {
		'xbase_lines' => $xbase_lines,
		'xbase_nondata_name' => [ qw! TABLE_QUALIFIER TABLE_OWNER
					TABLE_NAME TABLE_TYPE REMARKS !],
		},
	);
	$sth->STORE('NUM_OF_FIELDS', 5);
	$sth->DBD::XBase::st::_set_rows(scalar @$xbase_lines);
	return $sth;
}

# Very unreadable structure that the specs requires us to keep. It
# summarizes information about various data types we support. I do not
# hide the fact that this is not polished and probably not correct.
my @TYPE_INFO_ALL = (
	[ qw( TYPE_NAME DATA_TYPE PRECISION LITERAL_PREFIX LITERAL_SUFFIX CREATE_PARAMS NULLABLE CASE_SENSITIVE SEARCHABLE UNSIGNED_ATTRIBUTE MONEY AUTO_INCREMENT LOCAL_TYPE_NAME MINIMUM_SCALE MAXIMUM_SCALE ) ],
	[ 'VARCHAR', DBI::SQL_VARCHAR, 65535, "'", "'", 'max length', 0, 1, 2, undef, 0, 0, undef, undef, undef ],
	[ 'CHAR', DBI::SQL_CHAR, 65535, "'", "'", 'max length', 0, 1, 2, undef, 0, 0, undef, undef, undef ],
	[ 'INTEGER', DBI::SQL_INTEGER, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'FLOAT', DBI::SQL_FLOAT, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'NUMERIC', DBI::SQL_NUMERIC, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'BOOLEAN', DBI::SQL_BINARY, 0, '', '', undef, 1, 0, 2, 0, 0, 0, undef, 1, 1 ],
	[ 'DATE', DBI::SQL_DATE, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'TIME', DBI::SQL_TIME, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'BLOB', DBI::SQL_LONGVARBINARY, 0, '', '', undef, 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	);

my %TYPE_INFO_TYPES = map { ( $TYPE_INFO_ALL[$_][0] => $_ ) } ( 1 .. $#TYPE_INFO_ALL );
my %REVTYPES = qw( C char N numeric F float L boolean D date M blob T time );
my %REVSQLTYPES = map { ( $_ => $TYPE_INFO_ALL[  $TYPE_INFO_TYPES{ uc $REVTYPES{$_} } ][1] ) } keys %REVTYPES;

### use Data::Dumper; print STDERR Dumper \@TYPE_INFO_ALL, \%TYPE_INFO_TYPES, \%REVTYPES, \%REVSQLTYPES;

sub type_info_all {
	my $dbh = shift;
	my $result = [ @TYPE_INFO_ALL ];
	my $i = 0;
	my $hash = { map { ( $_ => $i++) } @{$result->[0]} };
	$result->[0] = $hash;
	$result;
}
sub type_info {
	my ($dbh, $type) = @_;
	my @result = ();
	for my $row ( 1 .. $#TYPE_INFO_ALL ) {
		if ($type == DBI::SQL_ALL_TYPES or $type == $TYPE_INFO_ALL[$row][1])
			{ push @result, { map { ( $TYPE_INFO_ALL[0][$_] => $TYPE_INFO_ALL[$row][$_] ) } ( 0 .. $#{$TYPE_INFO_ALL[0]} ) } }
	}
	@result;
}

sub DESTROY {
	# To avoid autoloaded DESTROY
}


# #####################
# The statement package

package DBD::XBase::st;
use strict;
$DBD::XBase::st::imp_data_size = 0;

# Binding of parameters: numbers are converted to :pnumber form,
# values are stored in the sth->{'xbase_bind_values'}->name of the
# parameter hash
sub bind_param {
	my ($sth, $parameter) = (shift, shift);
	if ($parameter =~ /^\d+$/) { $parameter = ':p'.$parameter; }
	$sth->{'xbase_bind_values'}{$parameter} = shift;
	1;
}

# Returns number of rows fetched until now
sub rows {
	defined $_[0]->{'xbase_rows'} ? $_[0]->{'xbase_rows'} : -1;
}

sub _set_rows {
	my $sth = shift;
	if (not @_ or not defined $_[0]) {
		$sth->{'xbase_rows'} = undef; return -1;
	}
	$sth->{'xbase_rows'} = ( $_[0] ? $_[0] : '0E0' );
}
# Execute the current statement, possibly binding parameters. For
# nonselect commands the actions needs to be done here, for select we
# just create the cursor and wait for fetchrows
sub execute {
	my $sth = shift;

	# the binds_order arrayref holds the conversion from the first
	# occurence of the named parameter to its name;
	# we bind the parameters here
	my $parsed_sql = $sth->{'xbase_parsed_sql'};
	for (my $i = 0; $i < @_; $i++) {
		$sth->bind_param($parsed_sql->{'binds_order'}[$i], $_[$i]);
	}

	# binded parameters
	my $bind_values = $sth->{'xbase_bind_values'};

	# cancel the count of rows done in the previous run, this is a
	# new execute
	$sth->{'xbase_rows'} = undef;
	delete $sth->{'xbase_lines'};
	
	# we'll nee dbh, table name and to command to do with them	
	my $dbh = $sth->{'Database'};
	my $table = $parsed_sql->{'table'}[0];
	my $command = $parsed_sql->{'command'};
		
	# create table first; we just create it and are done
	if ($command eq 'create') {
		my $filename = $dbh->{'Name'} . '/' . $table;
		my %opts;
		# get the name and the fields info
		@opts{ qw( name field_names field_types field_lengths
				field_decimals ) } =
			( $filename, @{$parsed_sql}{ qw( createfields
				createtypes createlengths createdecimals ) } );
		# try to create the table (and memo automatically)
		my $xbase = XBase->create(%opts) or do {
			$sth->DBI::set_err(10, XBase->errstr());
			return;
		};
		# keep the table open
		$dbh->{'xbase_tables'}->{$table} = $xbase;	
		return $sth->DBD::XBase::st::_set_rows(0);	# return true
	}

	# let's see if we've already opened the table
	my $xbase = $dbh->{'xbase_tables'}->{$table};
	if (not defined $xbase) {
		# if not, open the table now
		my $filename = $dbh->{'Name'} . '/' . $table;
		my %opts = ('name' => $filename);
		$opts{'ignorememo'} = 1 if $dbh->{'xbase_ignorememo'};
		# try to open the table using XBase.pm
		$xbase = new XBase(%opts) or do {
			$sth->DBI::set_err(3, "Table $table not found: "
							. XBase->errstr());
			return;
		};
		$dbh->{'xbase_tables'}->{$table} = $xbase;	
	}

	# the following is not multiple-statements safe -- I'd overwrite
	# the attribute here; but I do not think anybody needs
	# ChopBlanks = 0 anyway
	if (defined $parsed_sql->{'ChopBlanks'}) {
		$xbase->{'ChopBlanks'} = $parsed_sql->{'ChopBlanks'};
	}
	$parsed_sql->{'ChopBlanks'} = \$xbase->{'ChopBlanks'};
			# I cannot see what I meant by this line -- never mind

	# the array usedfields holds a list of field names that were
	# explicitely mentioned somewhere in the SQL query -- select
	# fields list, where clause, set clauses in update ...
	# we'll try to make a list of those that do not exist in the table
	my %nonexist;
	for my $field (@{$parsed_sql->{'usedfields'}}) {
		$nonexist{$field} = 1 unless defined $xbase->field_type($field);
	}
	if (keys %nonexist) {
		$sth->DBI::set_err(4,
			sprintf 'Field %s not found in table %s',
				join(', ', sort keys %nonexist), $table);
		return;
	}

	# inserting values means appending a new row with reasonable
	# values; the insertfn function expects the TABLE object and
	# the BIND hash (it doesn' make use of them at the moment,
	# AFAIK, because only constants are supported), it returns list
	# of values
	if ($command eq 'insert') {
		my $last = $xbase->last_record;
		my @values = &{$parsed_sql->{'insertfn'}}($xbase, $bind_values);
		
		### here, we'd really need a check for too many or too
		### few values
		if (defined $parsed_sql->{'insertfields'}) {
			my %newval;
			@newval{ @{$parsed_sql->{'insertfields'} } } = @values;
			@values = @newval{ $xbase->field_names };
		}
		$xbase->set_record($last + 1, @values) or do {
			$sth->DBI::set_err(49,'Insert failed: '.$xbase->errstr);
			return;
		};
		return $sth->DBD::XBase::st::_set_rows(1);	# we've added one row
	}


	# rows? what do we need rows here for? never mind.
	my $rows;

	# wherefn is defined if the statement had where clause; it
	# should be called with $TABLE, $VALUES and $BIND parameters
	my $wherefn = $parsed_sql->{'wherefn'};

	# we expand selectall to list of fields
	if (defined $parsed_sql->{'selectall'} and not defined $parsed_sql->{'selectfieldscount'}) {
		$parsed_sql->{'selectnames'} = [ $xbase->field_names ];
		push @{$parsed_sql->{'usedfields'}}, $xbase->field_names;
		$parsed_sql->{'selectfieldscount'} = scalar $xbase->field_names;
	}

	# we only set NUM_OF_FIELDS for select command -- which is
	# exactly what selectfieldscount means
	if (not $sth->FETCH('NUM_OF_FIELDS')) {
		$sth->STORE('NUM_OF_FIELDS', $parsed_sql->{'selectfieldscount'});
	}
		
	# this cursor will be needed, because both select and update and
	# delete with where clause need to fetch the data first
	my $cursor = $xbase->prepare_select(@{$parsed_sql->{'usedfields'}});

	
	# select with order by clause will be done using "substatement"
	if ($command eq 'select' and defined $parsed_sql->{'orderfields'}) {
		my @orderfields = @{$parsed_sql->{'orderfields'}};

		# make a copy of the $parsed_sql hash, but delete the
		# orderfields value
		my $subparsed_sql = { %$parsed_sql };
		delete $subparsed_sql->{'orderfields'};
		delete $subparsed_sql->{'selectall'};

		my $selectfn = $parsed_sql->{'selectfn'};
		$subparsed_sql->{'selectfn'} = sub {
			my ($TABLE, $VALUES, $BINDS) = @_;
			return map({ XBase::SQL::Expr->field($_, $TABLE, $VALUES)->value } @orderfields), &{$selectfn}($TABLE, $VALUES, $BINDS);
		};
### use Data::Dumper; print STDERR Dumper $subparsed_sql;
		$subparsed_sql->{'selectfieldscount'} += scalar(@orderfields);

		# make new $sth
		my $substh = DBI::_new_sth($dbh, {
			'Statement' => $sth->{'Statement'},
			'xbase_parsed_sql' => $subparsed_sql,
			}); 
		
		# bind all parameters in the substh
		for my $key (keys %$bind_values) {
			$substh->bind_param($key, $bind_values->{$key});
		}
		
		# execute and fetch all rows
		$substh->execute;
### use Data::Dumper; print STDERR Dumper $substh->{'xbase_parsed_sql'};
		my $data = $substh->fetchall_arrayref;

		my $sortfn = '';
		for (my $i = 0; $i < @orderfields; $i++) {
			$sortfn .= ' or ' if $i > 0;
			if ($xbase->field_type($orderfields[$i]) =~ /^[CML]$/) {
				if (lc($parsed_sql->{'orderdescs'}[$i]) eq 'desc') {
					$sortfn .= "\$_[1]->[$i] cmp \$_[0]->[$i]";
				} else {
					$sortfn .= "\$_[0]->[$i] cmp \$_[1]->[$i]";
				}
			} else {
				if (lc($parsed_sql->{'orderdescs'}[$i]) eq 'desc') {
					$sortfn .= "\$_[1]->[$i] <=> \$_[0]->[$i]";
				} else {
					$sortfn .= "\$_[0]->[$i] <=> \$_[1]->[$i]";
				}
			}
		}
		my $fn = eval "sub { $sortfn }";
		# sort them and store in xbase_lines
		$sth->{'xbase_lines'} =
			[ map { [ @{$_}[scalar(@orderfields) .. scalar(@$_) - 1 ] ] }
				sort { &{$fn}($a, $b) } @$data ];
	} elsif ($command eq 'select') {
		$sth->{'xbase_cursor'} = $cursor;
	} elsif ($command eq 'delete') {
		if (not defined $wherefn) {
			my $last = $xbase->last_record;
			for (my $i = 0; $i <= $last; $i++) {
				if (not (($xbase->get_record_nf($i, 0))[0])) {
					$xbase->delete_record($i);
					$rows = 0 unless defined $rows;
					$rows++;
				}
			}
		} else {
			my $values;
			while (defined($values = $cursor->fetch_hashref)) {
				next unless &{$wherefn}($xbase, $values,
				$bind_values, 0);
				$xbase->delete_record($cursor->last_fetched);
				$rows = 0 unless defined $rows;
				$rows++;
			}
		}
	} elsif ($command eq 'update') {
		my $values;
		while (defined($values = $cursor->fetch_hashref)) {
			next if defined $wherefn and not
			&{$wherefn}($xbase, $values, $bind_values);
			my %newval;
			@newval{ @{$parsed_sql->{'updatefields'}} } =
			&{$parsed_sql->{'updatefn'}}($xbase, $values,
			$bind_values);
			$xbase->update_record_hash($cursor->last_fetched, %newval);
			$rows = 0 unless defined $rows;
			$rows++;
		}
	} elsif ($command eq 'drop') {
		# dropping the table is really easy
		$xbase->drop or do {
			$sth->DBI::set_err(60, "Dropping table $table failed: "
							. $xbase->errstr);
			return;
		};
		delete $dbh->{'xbase_tables'}{$table};
		$rows = -1;
	}
	
	# finaly, set the number of rows (what if somebody will ask) and
	# return it to curious crowds
	return $sth->DBD::XBase::st::_set_rows($rows);
}



sub fetch {
        my $sth = shift;
	my $retarray;
	if (defined $sth->{'xbase_lines'}) {
		$retarray = shift @{$sth->{'xbase_lines'}};
	} elsif (defined $sth->{'xbase_cursor'}) {
		my $cursor = $sth->{'xbase_cursor'};
		my $wherefn = $sth->{'xbase_parsed_sql'}{'wherefn'};

		my $xbase = $cursor->table;
		my $values;
		while (defined($values = $cursor->fetch_hashref)) {
			### use Data::Dumper; print Dumper $sth->{'xbase_bind_values'};
			next if defined $wherefn and not
			&{$wherefn}($xbase, $values,
					$sth->{'xbase_bind_values'});
			last;
		}
		$retarray = [ &{$sth->{'xbase_parsed_sql'}{'selectfn'}}($xbase, $values, $sth->{'xbase_bind_values'}) ]
			if defined $values;
	}

### use Data::Dumper; print Dumper $retarray;

	return unless defined $retarray;

### print STDERR "sth->{'NUM_OF_FIELDS'}: $sth->{'NUM_OF_FIELDS'} sth->{'NUM_OF_PARAMS'}: $sth->{'NUM_OF_PARAMS'}\n";


	$sth->_set_fbav($retarray); return $retarray;

	my $i = 0;
	for my $ref ( @{$sth->{'xbase_bind_col'}} ) {
		next unless defined $ref;
		$$ref = $retarray->[$i];
	} continue {
		$i++;
	}
	
	return $retarray;
}
*fetchrow_arrayref = \&fetch;

sub FETCH {
	my ($sth, $attrib) = @_;
	my $parsed_sql = $sth->{'xbase_parsed_sql'};
	if ($attrib =~ /^xbase_/) {
		return $sth->{$attrib};
	}
	if ($attrib eq 'NAME') {
		if (defined $sth->{'xbase_nondata_name'}) {
			return $sth->{'xbase_nondata_name'};
		}
		return [ @{$parsed_sql->{'selectnames'}} ];
	} elsif ($attrib eq 'NULLABLE') {
		return [ (1) x scalar(@{$parsed_sql->{'selectnames'}}) ];
	} elsif ($attrib eq 'TYPE') {
		return [ map { ( $REVSQLTYPES{$_} or undef ) }
			map { ( $sth->{'Database'}->{'xbase_tables'}->{$parsed_sql->{'table'}[0]}->field_type($_)  or undef ) }
				@{$parsed_sql->{'selectnames'}} ];
	} elsif ($attrib eq 'PRECISION') {
		return [ map { $sth->{'Database'}->{'xbase_tables'}->{$parsed_sql->{'table'}[0]}->field_length($_) }
			@{$parsed_sql->{'selectnames'}} ];
	} elsif ($attrib eq 'SCALE') {
		return [ map { $sth->{'Database'}->{'xbase_tables'}->{$parsed_sql->{'table'}[0]}->field_decimal($_) }
			@{$parsed_sql->{'selectnames'}} ];
	} elsif ($attrib eq 'ChopBlanks') {
		return $parsed_sql->{'ChopBlanks'};
	} else {
		return $sth->DBD::_::st::FETCH($attrib);
	}
}
sub STORE {
	my ($sth, $attrib, $value) = @_;
	if ($attrib =~ /^xbase_/) {
		$sth->{$attrib} = $value;
	}
	if ($attrib eq 'ChopBlanks') {
		$sth->{'xbase_parsed_sql'}->{'ChopBlanks'} = $value;
	}
	return $sth->DBD::_::st::STORE($attrib, $value);
}
    
sub finish { 1; }

sub DESTROY { }

1;

__END__

=head1 SYNOPSIS

    use DBI;
    my $dbh = DBI->connect("DBI:XBase:/directory/subdir")
    				or die $DBI::errstr;
    my $sth = $dbh->prepare("select MSG from test where ID != 1")
    				or die $dbh->errstr();
    $sth->execute() or die $sth->errstr();

    my @data;
    while (@data = $sth->fetchrow_array())
		{ ## further processing }

    $dbh->do('update table set name = ? where id = 45', {}, 'krtek');

=head1 DESCRIPTION

DBI compliant driver for module XBase. Please refer to DBI(3)
documentation for how to actually use the module. In the B<connect>
call, specify the directory containing the dbf files (and other, memo,
etc.) as the third part of the connect string. It defaults to the
current directory.

Note that with dbf, there is no database server that the driver
would talk to. This DBD::XBase calls methods from XBase.pm module to
read and write the files on the disk directly, so any limitations and
features of XBase.pm apply to DBD::XBase as well. DBD::XBase basically
adds SQL, DBI compliant interface to XBase.pm.

The DBD::XBase doesn't make use of index files at the moment. If you
really need indexed access, check XBase(3) for notes about support for
variour index types.

=head1 SUPPORTED SQL COMMANDS

The SQL commands currently supported by DBD::XBase's prepare are:

=head2 select

    select fields_or_expressions from table [ where condition ]
					[ order by field ]

Fields_or_expressions is a comma separated list of fields or arithmetic
expressions, or a C<*> for all fields from the table. The
C<where> condition specifies which rows will be returned, you can
have arbitrary arithmetic and boolean expression here, compare fields
and constants and use C<and> and C<or>. Match using C<like> is also
supported. Examples:

    select * from salaries where name = "Smith"	
    select first,last from people where login = "ftp"
						or uid = 1324
    select id,first_name,last_name from employ
		where last_name like 'Ki%' order by last_name
    select id + 1, substr(name, 1, 10) from employ where age > 65
    select id, name from employ where id = ?

You can use bind parameters in the where clause, as the last example
shows. The actual value has to be supplied via bind_param or in the
call to execute or do, see DBI(3) for details. To check for NULL
values in the C<where> expression, use C<id is null> and C<id is
not null>, not C<id == null>.

Please note that you can only select from one table, joins are not
supported and are not planned to be supported. If you need them, get
a real RDBMS (or send me a patch).

In the arithmetic expressions you can use a couple of SQL functions --
currently supported are concat, substr (and substring), trim, ltrim and
rtrim, length. I do not have an exact idea of which and how many
functions I want to support. It's easy to write them in a couple of
minutes now the interface is there (check the XBase::SQL module if you
want to send a patch containing support for more), it's just that I do
not really need them and sometimes it's hard to tell what is usefull and
what is SQL92 compatible. Comment welcome.

The select command may contain and order by clause. Only one column is
supported for sorting at the moment, patches are welcome.

The group by clause is not supported (and I do not plan them), nor are
the aggregate functions.

=head2 delete

    delete from table [ where condition ]

The C<where> condition is the same as for B<select>. Examples:

    delete from jobs		## emties the table
    delete from jobs where companyid = "ISW"
    delete from jobs where id < ?

=head2 insert

    insert into table [ ( fields ) ] values ( list of values )

Here fields is a (optional) comma separated list of fields to set,
list of values is a list of constants to assign. If the fields are
not specified, sets the fields in the natural order of the table.
You can use bind parameters in the list of values. Examples:

    insert into accounts (login, uid) values ("guest", 65534)
    insert into accounts (login, uid) values (?, ?)
    insert into passwd values ("user","*",4523,100,"Nice user",
				"/home/user","/bin/bash")

=head2 update

    update table set field = new value [ , set more fields ]
					[ where condition ]

Example:

    update passwd set uid = 65534 where login = "guest"
    update zvirata set name = "Jezek", age = 4 where id = 17

Again, the value can also be specified as bind parameter.

    update zvirata set name = ?, age = ? where id = ?

=head2 create table

    create table table name ( columns specification )

Columns specification is a comma separated list of column names and
types. Example:

    create table rooms ( roomid int, cat char(10), balcony boolean )

The allowed types are

    char num numeric int integer float boolean blob memo date time
    datetime

Some of them are synonyms. They are of course converted to appropriate
XBase types.

=head2 drop table

    drop table table name

Example:

    drop table passwd

=head1 ATTRIBUTES

Besides standard DBI attribudes, DBD::XBase supports database handle
attribute xbase_ignorememo:

	$dbh->{'xbase_ignorememo'} = 1;

Setting it to 1 will cause subsequent tables to be opened while
ignoring the memo files (dbt, fpt). So you can read dbf files for
which you don't have (you have lost them, for example) the memo files.
The memo fields will come out as nulls.

=head1 VERSION

1.08

=head1 AVAILABLE FROM

http://www.adelton.com/perl/DBD-XBase/

=head1 AUTHOR

(c) 1997--2017 Jan Pazdziora.

Contact the author at jpx dash perl at adelton dot com.

=head1 SEE ALSO

perl(1); DBI(3), XBase(3); dbish(1)

Translation into Japanese (older version)
at http://member.nifty.ne.jp/hippo2000/perltips/DBD/XBase.htm
by Kawai Takanori.

=cut

