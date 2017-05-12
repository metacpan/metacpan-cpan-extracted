
=head1 NAME

DBD::XBase - DBI driver for XBase compatible database files

=cut

# ##################################
# Here starts the DBD::XBase package

package DBD::XBase;

use strict;
use DBI ();
use XBase;
use XBase::SQL;

use vars qw( $VERSION @ISA @EXPORT $err $errstr $drh $sqlstate );

require Exporter;

$VERSION = '0.130';

$err = 0;
$errstr = '';
$sqlstate = '';
$drh = undef;

sub driver
	{
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

sub data_sources
	{ 'dbi:XBase:.'; }


package DBD::XBase::dr;
use strict;
$DBD::XBase::dr::imp_data_size = 0;

sub connect
	{
	my ($drh, $dsn) = @_;
	$dsn = '.' if $dsn eq '';
	if (not -d $dsn)
		{
		$DBD::XBase::err = 1;
		$DBD::XBase::errstr = "Directory $dsn doesn't exist";
		return;
		}
	DBI::_new_dbh($drh, { 'Name' => $dsn } );
	}

sub disconnect_all
	{ 1; }

sub data_sources
	{ 'dbi:XBase:.'; }

package DBD::XBase::db;
use strict;
$DBD::XBase::db::imp_data_size = 0;

sub prepare
	{
	my ($dbh, $statement)= @_;

	my $parsed_sql = parse XBase::SQL($statement);
	### use Data::Dumper; print Dumper $parsed_sql;
	if (defined $parsed_sql->{'errstr'})
		{
		DBI::set_err($dbh, 2, 'Error in SQL parse: ' . $parsed_sql->{'errstr'});
		return;
		}

	my $sth = DBI::_new_sth($dbh,
		{
		'Statement' => $statement,
		'xbase_parsed_sql' => $parsed_sql,
		'NUM_OF_PARAMS' => ( defined($parsed_sql->{'numofbinds'})
					? $parsed_sql->{'numofbinds'} : 0),
		});
	$sth;
	}

sub STORE
	{
	my ($dbh, $attrib, $value) = @_;
	if ($attrib eq 'AutoCommit')
		{
		unless ($value) { die "Can't disable AutoCommit"; }
		return 1;
		}
	elsif ($attrib =~ /^xbase_/)
		{ $dbh->{$attrib} = $value; return 1; }
	$dbh->DBD::_::db::STORE($attrib, $value);
	}
sub FETCH
	{
	my ($dbh, $attrib) = @_;
	if ($attrib eq 'AutoCommit')	{ return 1; }
	elsif ($attrib =~ /^xbase_/)
		{ return $dbh->{$attrib}; }
	$dbh->DBD::_::db::FETCH($attrib);
	}

sub _ListTables
	{
	my $dbh = shift;
	opendir DIR, $dbh->{'Name'} or return;
	my @result = ();
	while (defined(my $item = readdir DIR))
		{
		next unless $item =~ s/\.dbf$//;
		push @result, $item;
		}
	closedir DIR;
	@result;
	}

sub tables
	{ my $dbh = shift; $dbh->DBD::XBase::db::_ListTables; }

sub quote
	{
	my $text = $_[1];
	return 'NULL' unless defined $text;
	$text =~ s/\\/\\\\/sg;
	$text =~ s/\'/\\\'/sg;
	return "'$text'";
	return "'\Q$text\E'";
	}

sub commit
	{
	warn "Commit ineffective while AutoCommit is on"
		if $_[0]->FETCH('Warn');
	1;
	}
sub rollback
	{
	warn "Rollback ineffective while AutoCommit is on"
		if $_[0]->FETCH('Warn');
	0;
	}

sub disconnect
	{
	my $dbh = shift;
	foreach my $xbase (values %{$dbh->{'xbase_tables'}}) {
		$xbase->close;
		delete $dbh->{'xbase_tables'}{$xbase};
		}
	1;
	}

sub table_info
	{
	my $dbh = shift;
	my @tables = map { [ undef, undef, $_, 'TABLE', undef ] } $dbh->tables();
	my $sth = DBI::_new_sth($dbh, { 'xbase_lines' => [ @tables ] } );
	$sth->STORE('NUM_OF_FIELDS', 5);
	$sth->execute and return $sth;
	return;
	}

my @TYPE_INFO_ALL = (
	[ qw( TYPE_NAME DATA_TYPE PRECISION LITERAL_PREFIX LITERAL_SUFFIX CREATE_PARAMS NULLABLE CASE_SENSITIVE SEARCHABLE UNSIGNED_ATTRIBUTE MONEY AUTO_INCREMENT LOCAL_TYPE_NAME MINIMUM_SCALE MAXIMUM_SCALE ) ],
	[ 'VARCHAR', DBI::SQL_VARCHAR, 65535, "'", "'", 'max length', 0, 1, 2, undef, 0, 0, undef, undef, undef ],
	[ 'CHAR', DBI::SQL_CHAR, 65535, "'", "'", 'max length', 0, 1, 2, undef, 0, 0, undef, undef, undef ],
	[ 'INTEGER', DBI::SQL_INTEGER, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'FLOAT', DBI::SQL_FLOAT, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'NUMERIC', DBI::SQL_FLOAT, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'BOOLEAN', DBI::SQL_BINARY, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'DATE', DBI::SQL_DATE, 0, '', '', 'number of digits', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	[ 'BLOB', DBI::SQL_LONGVARBINARY, 0, '', '', 'number of bytes', 1, 0, 2, 0, 0, 0, undef, 0, undef ],
	);

my %TYPE_INFO_TYPES = map { ( $TYPE_INFO_ALL[$_][0] => $_ ) } ( 1 .. $#TYPE_INFO_ALL );
my %REVTYPES = qw( C char N numeric F float L boolean D date M blob );
my %REVSQLTYPES = map { ( $_ => $TYPE_INFO_ALL[  $TYPE_INFO_TYPES{ uc $REVTYPES{$_} } ][1] ) } keys %REVTYPES;

### use Data::Dumper; print Dumper \%TYPE_INFO_TYPES, \%REVSQLTYPES;

sub type_info_all
	{
	my $dbh = shift;
	my $result = [ @TYPE_INFO_ALL ];
	my $i = 0;
	my $hash = { map { ( $_ => $i++) } @{$result->[0]} };
	$result->[0] = $hash;
	$result;
	}
sub type_info
	{
	my ($dbh, $type) = @_;
	my $result = [];
	for my $row ( 1 .. $#TYPE_INFO_ALL )
		{
		if ($type == DBI::SQL_ALL_TYPES or $type == $TYPE_INFO_ALL[$row][1])
			{ push @$result, { map { ( $TYPE_INFO_ALL[0][$_] => $TYPE_INFO_ALL[$row][$_] ) } ( 0 .. $#{$TYPE_INFO_ALL[0]} ) } }
		}
	$result;
	}

package DBD::XBase::st;
use strict;
$DBD::XBase::st::imp_data_size = 0;

sub bind_param
	{
	my ($sth, $param, $value, $attribs) = @_;
	$sth->{'param'}[$param - 1] = $value;
	1;
	}
sub rows
	{
	my $sth = shift;
	if (defined $sth->{'xbase_rows'}) { return $sth->{'xbase_rows'}; }
	return -1;
	}
sub execute
	{
	my $sth = shift;
	if (@_)	{ $sth->{'param'} = [ @_ ]; }
	my $param = $sth->{'param'};

	if (defined $sth->{'xbase_lines'})
		{ return -1; }
	delete $sth->{'xbase_rows'} if defined $sth->{'xbase_rows'};
	
	my $parsed_sql = $sth->{'xbase_parsed_sql'};
	my $command = $parsed_sql->{'command'};
	my $table = $parsed_sql->{'table'}[0];
	my $dbh = $sth->{'Database'};
		
	### if (not defined $sth->FETCH('NUM_OF_FIELDS'))
	###	{ $sth->STORE('NUM_OF_FIELDS', 0); }

	# Create table first -- we do not need to work with the table anymore
	if ($command eq 'create')
		{
		my $filename = $dbh->{'Name'} . '/' . $table;
		my %opts;
		@opts{ qw( name field_names field_types field_lengths
				field_decimals ) } =
			( $filename, @{$parsed_sql}{ qw( createfields
				createtypes createlengths createdecimals ) } );
		my $xbase = XBase->create(%opts) or do
			{ DBI::set_err($sth, 10, XBase->errstr()); return; };
		$dbh->{'xbase_tables'}->{$table} = $xbase;	
		return 1;
		}

	my $xbase = $dbh->{'xbase_tables'}->{$table};
	# If we do not have the table yet, open it
	if (not defined $xbase)
		{
		my $filename = $dbh->{'Name'} . '/' . $table;
		my %opts = ('name' => $filename);
		$opts{'ignorememo'} = 1 if $dbh->{'xbase_ignorememo'};
		$xbase = new XBase(%opts) or do
			{
			DBI::set_err($sth, 3, "Table $table not found: "
							. XBase->errstr());
			return;
			};
		$dbh->{'xbase_tables'}->{$table} = $xbase;	
		}

	if (defined $parsed_sql->{'ChopBlanks'})
		{ $xbase->{'ChopBlanks'} = $parsed_sql->{'ChopBlanks'}; }
	$parsed_sql->{'ChopBlanks'} = \$xbase->{'ChopBlanks'};

	my %nonexist;
	for my $field (@{$parsed_sql->{'usedfields'}})
		{
		$nonexist{$field} = 1 unless defined $xbase->field_type($field);
		}
	if (keys %nonexist)
		{
		my @f = sort keys %nonexist;
		DBI::set_err($sth, 4,
			sprintf 'Unknown field %s found in table %s',
				join(', ', @f), $table);
		return;
		}

	if ($command eq 'insert')
		{
		my $last = $xbase->last_record;
		my @values = &{$parsed_sql->{'insertfn'}}($xbase, $param, 0);
		if (defined $parsed_sql->{'fields'})
			{
			my %newval;
			@newval{ @{$parsed_sql->{'fields'} } } = @values;
			@values = @newval{ $xbase->field_names };
			}
		$xbase->set_record($last + 1, @values) or do {
			DBI::set_err($sth, 49, 'Insert failed: ' . $xbase->errstr);
			return;
			};
		return 1;
		}
	
	if (not defined $parsed_sql->{'fields'} and defined $parsed_sql->{'selectall'})
		{
		$parsed_sql->{'fields'} = [ $xbase->field_names ];
		for my $field (@{$parsed_sql->{'fields'}})
			{ push @{$parsed_sql->{'usedfields'}}, $field
			unless grep { $_ eq $field } @{$parsed_sql->{'usedfields'}}; }
		}
	my $cursor = $xbase->prepare_select( @{$parsed_sql->{'usedfields'}} );
	my $wherefn = $parsed_sql->{'wherefn'};
	my @fields = @{$parsed_sql->{'fields'}} if defined $parsed_sql->{'fields'};
	### use Data::Dumper; print STDERR Dumper $parsed_sql;
	my $rows;

	if ($command eq 'select')
		{
		if (defined $parsed_sql->{'orderfield'})
			{
			my $orderfield = ${$parsed_sql->{'orderfield'}}[0];

			my $subparsed_sql = { %$parsed_sql };
			delete $subparsed_sql->{'orderfield'};
			unshift @{$subparsed_sql->{'fields'}}, $orderfield;
			my $substh = DBI::_new_sth($dbh, {
				'Statement'	=> $sth->{'Statement'},
				'xbase_parsed_sql'	=> $subparsed_sql,
				});
			$substh->execute(@$param);
			my $data = $substh->fetchall_arrayref;
			my $type = $xbase->field_type($orderfield);
			my $sortfn;
			if (not defined $parsed_sql->{'orderdesc'})
				{
				if ($type =~ /^[CML]$/)
					{ $sortfn = sub { $_[0] cmp $_[1] } }
				else
					{ $sortfn = sub { $_[0] <=> $_[1] } }
				}
			else
				{
				if ($type =~ /^[CML]$/)
					{ $sortfn = sub { $_[1] cmp $_[0] } }
				else
					{ $sortfn = sub { $_[1] <=> $_[0] } }
				}
			$sth->{'xbase_lines'} =
				[ map { shift @$_; [ @$_ ] }
					sort { &{$sortfn}($a->[0], $b->[0]) } @$data ];
			shift(@{$parsed_sql->{'fields'}});
			}
		else
			{
			$sth->{'xbase_cursor'} = $cursor;
			}
		if (not $sth->FETCH('NUM_OF_FIELDS') and scalar @fields)
			{ $sth->STORE('NUM_OF_FIELDS', scalar @fields); }
		}
	elsif ($command eq 'delete')
		{
		if (not defined $wherefn)
			{
			my $last = $xbase->last_record;
			for (my $i = 0; $i <= $last; $i++)
				{
				if (not ($xbase->get_record_nf($i, 0))[0])
					{
					$xbase->delete_record($i);
					$rows = 0 unless defined $rows;
					$rows++;
					}
				}
			}
		else
			{
			my $values;
			while (defined($values = $cursor->fetch_hashref))
				{
				next unless &{$wherefn}($xbase, $values, $param, 0);
				$xbase->delete_record($cursor->last_fetched);
				$rows = 0 unless defined $rows;
				$rows++;
				}
			}
		}
	elsif ($command eq 'update')
		{
		my $values;
		while (defined($values = $cursor->fetch_hashref))
			{
			### print Dumper $values;
			next if defined $wherefn and not &{$wherefn}($xbase, $values, $param, $parsed_sql->{'bindsbeforewhere'});
			my %newval;
			@newval{ @fields } = &{$parsed_sql->{'updatefn'}}($xbase, $values, $param, 0);
			$xbase->update_record_hash($cursor->last_fetched, %newval);
			$rows = 0 unless defined $rows;
			$rows++;
			}
		}
	elsif ($command eq 'drop')
		{
		$xbase->drop;
		$rows = -1;
		}
	$sth->{'xbase_rows'} = $rows if defined $rows;
	return defined $rows ? ( $rows ? $rows : '0E0' ) : -1;
	}
sub fetch
	{
        my $sth = shift;
	my $retarray;
	if (defined $sth->{'xbase_lines'})
		{ $retarray = shift @{$sth->{'xbase_lines'}}; }
	elsif (defined $sth->{'xbase_cursor'})
		{
		my $cursor = $sth->{'xbase_cursor'};
		my $wherefn = $sth->{'xbase_parsed_sql'}{'wherefn'};

		my $xbase = $cursor->table;
		my $values;
		while (defined($values = $cursor->fetch_hashref))
			{
			next if defined $wherefn and not &{$wherefn}($xbase, $values, $sth->{'param'}, 0);
			last;
			}
		$retarray = [ @{$values}{ @{$sth->{'xbase_parsed_sql'}{'fields'}}} ]
			if defined $values;
		}

### use Data::Dumper; print Dumper $retarray;

	return unless defined $retarray;

### print STDERR "sth->{'NUM_OF_FIELDS'}: $sth->{'NUM_OF_FIELDS'} sth->{'NUM_OF_PARAMS'}: $sth->{'NUM_OF_PARAMS'}\n";


	$sth->_set_fbav($retarray); return $retarray;

	my $i = 0;
	for my $ref ( @{$sth->{'xbase_bind_col'}} )
		{
		next unless defined $ref;
		$$ref = $retarray->[$i];
		}
	continue
		{ $i++; }
	
	return $retarray;
	}
*fetchrow_arrayref = \&fetch;

sub FETCH
	{
	my ($sth, $attrib) = @_;
	my $parsed_sql = $sth->{'xbase_parsed_sql'};
	if ($attrib eq 'NAME')
		{
		return [ @{$parsed_sql->{'fields'}} ];
		}
	elsif ($attrib eq 'NULLABLE')
		{
		return [ (1) x scalar(@{$parsed_sql->{'fields'}}) ];
		}
	elsif ($attrib eq 'TYPE')
		{
		return [ map { $REVSQLTYPES{$_} }
			map { $sth->{'Database'}->{'xbase_tables'}->{$parsed_sql->{'table'}[0]}->field_type($_) }
				@{$parsed_sql->{'fields'}} ];
		}
	elsif ($attrib eq 'ChopBlanks')
		{ return $parsed_sql->{'ChopBlanks'}; }
	else
		{ return $sth->DBD::_::st::FETCH($attrib); }
	}
sub STORE
	{
	my ($sth, $attrib, $value) = @_;
	if ($attrib eq 'ChopBlanks')
		{ $sth->{'xbase_parsed_sql'}->{'ChopBlanks'} = $value; }
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
really need indexed access, check XBase(3) for notes about ndx
support.

=head1 SUPPORTED SQL COMMANDS

The SQL commands currently supported by DBD::XBase's prepare are:

=head2 select

    select fields from table [ where condition ]
					[ order by field ]

Fields is a comma separated list of fields or a C<*> for all. The
C<where> condition specifies which rows will be returned, you can
have arbitrary arithmetic and boolean expression here, compare fields
and constants and use C<and> and C<or>. Match using C<like> is also
supported. Examples:

    select * from salaries where name = "Smith"	
    select first,last from people where login = "ftp"
						or uid = 1324
    select id,first_name,last_name from employ
					where last_name like 'Ki%'
    select id,name from employ where id = ?

You can use bind parameters in the where clause, as the last example
shows. The actual value has to be supplied via bind_param or in the
call to execute or do, see DBI(3) for details. To check for NULL
values in the C<where> expression, use C<id is null> and C<id is
not null>, not C<id == null>.

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

=head1 VERSION

0.130

=head1 AUTHOR

(c) 1997--1999 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic

=head1 SEE ALSO

perl(1); DBI(3), XBase(3)

=cut

