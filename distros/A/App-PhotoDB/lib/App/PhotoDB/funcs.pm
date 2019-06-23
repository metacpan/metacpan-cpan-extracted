package App::PhotoDB::funcs;

=head1 Functions

This package provides reusable functions to be consumed by the rest of the PhotoDB application.

Note that some of these functions take traditional argument lists which must
be in order, while the more complex functions take a hashref of arguments
which can be passed in any order. Examples of each function are given.

=cut

use strict;
use warnings;
use experimental 'smartmatch';

use DBI;
use DBD::mysql;
use SQL::Abstract;
use Exporter qw(import);
use Config::IniHash;
use YAML;
use Image::ExifTool;
use Term::ReadLine;
use Term::ReadLine::Perl;
use File::Basename;
use Time::Piece;
use Text::TabularDisplay;

our @EXPORT_OK = qw(prompt db updaterecord deleterecord newrecord notimplemented nocommand nosubcommand listchoices lookupval lookuplist today validate ini printlist round pad lookupcol thin resolvenegid chooseneg annotatefilm keyword parselensmodel unsetdisplaylens welcome duration tag printbool hashdiff logger now choosescan basepath call untaint fsfiles dbfiles term unsci multiplechoice search tabulate runmigrations canondatecode choose_shutterspeed);

=head2 prompt

Prompt the user for an arbitrary value. Has various options for data validation and customisation of the prompt.
If the provided input fails validation, or if a blank string is given when required=1 then the prompt is repeated.

=head4 Usage

    my $camera = &prompt({prompt=>'What model is the camera?', required=>1, default=>$$defaults{model}, type=>'text'});

would give a prompt like

    What model is the camera? (text) []:

=head4 Arguments

=item * C<$default> Default value that will be used if no input from user. Default empty string.

=item * C<$prompt> Prompt message for the user

=item * C<$type> Data type that this input expects, out of C<text>, C<integer>, C<boolean>, C<date>, C<decimal>, C<time>

=item * C<$required> Whether this input is required, or whether it can return an empty value. Default C<0>

=item * C<$showtype> Whether to show the user what data type is expected, in parentheses. Default C<1>

=item * C<$showdefault> Whether to show the user what the default value is set to, in square brackets. Default C<1>

=item * C<$char> Character to print at the end of the prompt. Defaults to C<:>

=head4 Returns

The value the user provided

=cut

sub prompt {
	# Pass in a hashref of arguments
	my $href = shift;
	# Unpack the hashref and set default values
	my $default = $href->{default} // '';		# Default value that will be used if no input from user
	my $prompt = $href->{prompt};			# Prompt message for the user
	my $type = $href->{type} || 'text';		# Data type that this input expects, out of text, integer, boolean, date, decimal, time
	my $required = $href->{required} // 0;		# Whether this input is required, or whether it can return an empty value
	my $showtype = $href->{showtype} // 1;		# Whether to show the user what data type is expected
	my $showdefault = $href->{showdefault} // 1;	# Whether to show the user what the default value is
	my $char = $href->{char} // ':';		# Character to print at the end of the prompt

	die "Must provide value for \$prompt\n" if !($prompt);

	# Rewrite binary bools as strings
	if ($type eq 'boolean' && $default ne '') {
		$default = &printbool($default);
	}

	# Assemble prompt text
	my $msg = $prompt;
	$msg .= " ($type)" if $showtype;
	$msg .= " [$default]" if $showdefault;
	$msg .= "$char ";

	# Create terminal handler
	my $term = $App::PhotoDB::term;

	my $rv;
	# Repeatedly prompt user until we get a response of the correct type
	do {
		my $input = $term->readline($msg);

		# Use default value if user gave blank input
		$rv = ($input eq "") ? $default:$input;
	# Prompt again if the input doesn't pass validation, or if it's a required field that was blank
	} while (!&validate({val => $rv, type => $type}) || ($rv eq '' && $required == 1));

	# Rewrite friendly bools and then return the value
	if ($type eq 'boolean') {
		return friendlybool($rv);
	} else {
		return $rv;
	}
}

=head2 term

Set up a terminal object for use by PhotoDB

=head4 Usage

    my $term = &term;

=head4 Arguments

None

=head4 Returns

Terminal object

=cut

sub term {
	my $term = Term::ReadLine->new('PhotoDB');
	$term->ornaments(0);
	$term->MinLine(7);
	return $term;
}


=head2 validate

Validate that a value is a certain data type

=head4 Usage

    my $result = &validate({val => 'hello', type => 'text'});

=head4 Arguments

=item * C<$val> The value to be validated

=item * C<$type> Data type to validate as, out of C<text>, C<integer>, C<boolean>, C<date>, C<decimal>, C<time>. Defaults to C<text>.

=head4 Returns

Returns C<1> if the value passes validation as the requested type, and C<0> if it doesn't.

=cut

sub validate {
	# Pass in a hashref of arguments
	my $href = shift;
	# Unpack the hashref and set default values
	my $val = $href->{val};			# The value to be validated
	my $type = $href->{type} || 'text';	# Data type to validate as, out of text, integer, boolean, date, decimal, time

	die "Must provide value for \$val\n" if !defined($val);

	# Empty string always passes validation
	if ($val eq '') {
		return 1;
	}
	elsif ($type eq 'boolean') {
		if ($val =~ m/^(y(es)?|no?|false|true|1|0)$/i) {
			return 1;
		} else {
			return 0;
		}
	} elsif ($type eq 'integer') {
		if ($val =~ m/^-?\d+$/) {
			return 1;
		} else {
			return 0;
		}
	} elsif ($type eq 'text') {
		if ($val =~ m/^.+$/) {
			return 1;
		} else {
			return 0;
		}
	} elsif ($type eq 'date') {
		if ($val =~ m/^\d{4}-\d{2}-\d{2}$/) {
			return 1;
		} else {
			return 0;
		}
	} elsif ($type eq 'decimal') {
		if ($val =~ m/^\d+(\.\d+)?$/) {
			return 1;
		} else {
			return 0;
		}
	} elsif ($type eq 'time') {
		if ($val =~ m/^\d\d?:\d\d?:\d\d?$/) {
			return 1;
		} else {
			return 0;
		}
	} else {
		die "$type is not a valid data type\n";
	}
}

=head2 ini

Find PhotoDB config ini file

=head4 Usage

    my $ini = &ini;

=head4 Arguments

None

=head4 Returns

File path to the config ini file

=cut

sub ini {
	# Places to look for ini file in descending order of preference
	my @paths = (
		"$ENV{HOME}/.photodb/photodb.ini",
		"/etc/photodb.ini",
		"/photodb/photodb.ini",
	);

	# Loop through paths and checkt they're readable
	for my $path (@paths) {
		return $path if (-r $path);
	}

	# If no file was found, write one out in the preferred location
	if (&prompt({default=>'yes', prompt=>'Could not find config file. Generate one now?', type=>'boolean'})) {
		my $path = $paths[0];
		&writeconfig($path);
		return $path;
	} else {
		exit;
	}
}

=head2 db

Connect to the database, run migrations and return database handle

=head4 Usage

    my $db = &db;

=head4 Arguments

None

=head4 Returns

Variable representing the database handle

=cut

sub db {
	my $href = shift;
	my $args = $href->{args};

	my $skipmigrations = $$args{skipmigrations} // 0;

	my $connect;
	if (defined($$args{host}) && defined($$args{schema}) && defined($$args{user}) && defined($$args{password})) {
		# use args
		$$connect{'database'}{'host'} = $$args{host};
		$$connect{'database'}{'schema'} = $$args{schema};
		$$connect{'database'}{'user'} = $$args{user};
		$$connect{'database'}{'pass'} = $$args{password};

	} elsif (defined($$args{host}) || defined($$args{schema}) || defined($$args{user}) || defined($$args{password})) {
		# warn user they they must pass in ALL or NO args
		print "If configuring the database by command line arguments, you must provide all of host, schema, user, password\n";
		exit;
	} else {
		$connect = ReadINI(&ini);
	}

	# host, schema, user, pass
	if (!defined($$connect{'database'}{'host'}) || !defined($$connect{'database'}{'schema'}) || !defined($$connect{'database'}{'user'}) || !defined($$connect{'database'}{'pass'})) {
		print "Config file did not contain correct values";
		exit;
	}

	my $dbh = DBI->connect("DBI:mysql:database=$$connect{'database'}{'schema'};host=$$connect{'database'}{'host'}",
		$$connect{'database'}{'user'},
		$$connect{'database'}{'pass'},
		{
			# Required for updates to work properly
			mysql_client_found_rows => 0,
			# Required to print symbols
			mysql_enable_utf8mb4 => 1,
		}
	) or die "Couldn't connect to database: " . DBI->errstr;

	&runmigrations($dbh) unless $skipmigrations;

	return $dbh;
}

=head2 runmigrations

Run database migrations

=head4 Usage

    &runmigrations($db);

=head4 Arguments

=item * C<$db> DB handle

=head4 Returns

Nothing

=cut

sub runmigrations {
	my $dbh = shift;
	use DB::SQL::Migrations;
	my $migrator = DB::SQL::Migrations->new(dbh=>$dbh, migrations_directory=>'migrations');

	print "Checking database schema... \n";

	# Creates migrations table if it doesn't exist
	$migrator->create_migrations_table();

	# Run migrations
	$migrator->apply();

	return;
}

# Update an existing record in any table

=head2 updaterecord

Update an existing record in any table

=head4 Usage

    my $rows = &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>{film_id=>$film_id}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$data> Hash of new values to update

=item * C<$table> Name of table to update

=item * C<$where> Where clause, formatted for SQL::Abstract

=item * C<$silent> Suppress output

=item * C<$log> Write an event to the database log. Defaults to C<1>.

=head4 Returns

The number of rows updated

=cut

sub updaterecord {
	# Pass in a hashref of arguments
	my $href = shift;

	# Unpack the hashref and set default values
	my $db = $href->{db};			# DB handle
	my $data = $href->{data};		# Hash of new values to update
	my $table = $href->{table};		# Name of table to update
	my $where = $href->{where};		# Where clause, formatted for SQL::Abstract
	my $silent = $href->{silent} // 0;	# Suppress output
	my $log = $href->{log} // 1;	    # Write event to log

	# Quit if we didn't get params
	die 'Must pass in $db' if !($db);
	die 'Must pass in $data' if !($data);
	die 'Must pass in $table' if !($table);
	die 'Must pass in $where' if !($where);

	# Delete empty strings from data hash
	$data = &thin($data);

	if (scalar(keys %$data) == 0) {
		print "Nothing to update\n";
		return 0;
	}

	# Work out affected rows
	my $rowcount = &lookupval({db=>$db, col=>'count(*)', table=>$table, where=>$where});

	# Dump data for debugging
	print "\n\nThis is what I will update into $table where:\n" unless $silent;
	print Dump($where) unless $silent;
	print Dump($data) unless $silent;
	print "\n$rowcount records will be updated\n" unless $silent;
	print "\n" unless $silent;

	# Build query
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->update($table, $data, $where);

	# Final confirmation
	unless ($silent) {
		if (!&prompt({default=>'yes', prompt=>'Proceed?', type=>'boolean'})) {
		       print "Aborted!\n";
		       return;
	       }
	}

	# Execute query
	my $sth = $db->prepare($stmt);
	my $rows = $sth->execute(@bind);
	$rows = &unsci($rows);
	print "Updated $rows rows\n" unless $silent;
	&logger({db=>$db, type=>'EDIT', message=>"$table $rows rows"}) if $log;
	return $rows;
}

# Delete an existing record in any table

=head2 deleterecord

Delete an existing record from any table

=head4 Usage

    my $rows = &deleterecord({db=>$db, table=>'FILM', where=>{film_id=>$film_id}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$table> Name of table to delete from

=item * C<$where> Where clause, formatted for SQL::Abstract

=item * C<$silent> Suppress output

=item * C<$log> Write an event to the database log. Defaults to C<1>.

=head4 Returns

The number of rows deleted

=cut

sub deleterecord {
	# Pass in a hashref of arguments
	my $href = shift;

	# Unpack the hashref and set default values
	my $db = $href->{db};		   # DB handle
	my $table = $href->{table};	     # Name of table to delete from
	my $where = $href->{where};	     # Where clause, formatted for SQL::Abstract
	my $silent = $href->{silent} // 0;      # Suppress output
	my $log = $href->{log} // 1;	    # Write event to log

	# Quit if we didn't get params
	die 'Must pass in $db' if !($db);
	die 'Must pass in $table' if !($table);
	die 'Must pass in $where' if !($where);

	# Work out affected rows
	my $rowcount = &lookupval({db=>$db, col=>'count(*)', table=>$table, where=>$where});

	# Dump data for debugging
	print "\n\nI will delete from $table where:\n" unless $silent;
	print Dump($where) unless $silent;
	print "$rowcount records will be deleted\n" unless $silent;

	# Build query
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->delete($table, $where);

	# Final confirmation
	unless ($silent) {
		if (!&prompt({default=>'yes', prompt=>'Proceed?', type=>'boolean'})) {
		       print "Aborted!\n";
		       return;
	       }
	}

	# Execute query
	my $sth = $db->prepare($stmt);
	my $rows = $sth->execute(@bind);
	$rows = &unsci($rows);
	print "Deleted $rows rows\n" unless $silent;
	&logger({db=>$db, type=>'DELETE', message=>"$table $rows rows"}) if $log;
	return $rows;
}

=head2 newrecord

Insert a record into any table

=head4 Usage

    my $id = &newrecord({db=>$db, data=>\%data, table=>'FILM'});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$data> reference to hash of new values to insert

=item * C<$table> Name of table to insert into

=item * C<$silent> Suppress user output and don't ask for confirmation. Defaults to C<0>.

=item * C<$log> Write an event to the database log. Defaults to C<1>.

=head4 Returns

Primary key of inserted row

=cut

sub newrecord {
	# Pass in a hashref of arguments
	my $href = shift;

	# Unpack the hashref and set default values
	my $db = $href->{db};			# DB handle
	my $data = $href->{data};		# Hash of new values to insert
	my $table = $href->{table};		# Table to insert into
	my $silent = $href->{silent} // 0;	# Suppress output
	my $log = $href->{log} // 1;		# Log this event

	# Quit if we didn't get params
	die 'Must pass in $db' if !($db);
	die 'Must pass in $data' if !($data);
	die 'Must pass in $table' if !($table);

	# Delete empty strings from data hash
	$data = &thin($data);

	# Dump data for debugging
	print "\n\nThis is what I will insert into $table:\n" unless $silent;
	print Dump($data) unless $silent;
	print "\n" unless $silent;

	# Build query
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->insert($table, $data);

	# Final confirmation
	unless ($silent) {
		if (!&prompt({default=>'yes', prompt=>'Proceed?', type=>'boolean'})) {
		       print "Aborted!\n";
		       return;
	       }
	}

	# Execute query
	my $sth = $db->prepare($stmt);
	$sth->execute(@bind);

	# Display inserted row
	my $insertedrow = $sth->{mysql_insertid};
	print "Inserted $table $insertedrow\n" unless $silent;
	&logger({db=>$db, type=>'ADD', message=>"$table #$insertedrow"}) if $log;

	return $insertedrow;
}

=head2 notimplemented

Print a warning that this command/subcommand is not yet implemented

=head4 Usage

    &notimplemented

=head4 Arguments

None

=head4 Returns

Nothing

=cut

sub notimplemented {
	print "This command or subcommand is not yet implemented.\n";
	return;
}

=head2 nocommand

Print list of available top-level commands

=head4 Usage

    &nocommand(\%handlers);

=head4 Arguments

=item * C<$handlers> reference to hash of handlers from C<handlers.pm>

=head4 Returns

Nothing

=cut

sub nocommand {
	my $handlers = shift;
	print "<command> <subcommand>\n\n";
	print "Please enter a valid command. Valid commands are:\n";
	print "\t$_\n" for sort keys %$handlers;
	return;
}

# Print list of subcommands for a given command

=head2 nosubcommand

Print list of available subcommands for a given command

=head4 Usage

    &nosubcommand(\%{$handlers{$command}}, $command);

=head4 Arguments

=item * C<$command> name of command whose subcommands you want

=item * C<$handlers> reference to hash slice of handlers from C<handlers.pm>

=head4 Returns

Nothing

=cut

sub nosubcommand {
	my $handlers = shift;
	my $command = shift;
	print "$command <subcommand>\n\n";
	print "Please enter a valid subcommand. Valid subcommands for '$command' are:\n";
	print "\t" . &pad($_) . $$handlers{$_}{'desc'} . "\n" for sort keys %$handlers;
	return;
}

=head2 listchoices

List arbitrary choices from the DB and return ID of the selected one

=head4 Usage

    my $id = &listchoices({db=>$db, table=>$table, where=>$where});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$query> (legacy) the SQL to generate the list of choices

=item * C<$type> Data type of choice to be made. Defaults to C<text>

=item * C<$inserthandler> function ref to handler that can be used to insert a new row if necessary

=item * C<$default> ID of default choice

=item * C<$autodefault> if default not set, count number of allowed options and if there's just 1, make it the default

=item * C<$skipok> whether it is ok to return C<undef> if there are no options to choose from

=item * C<$table> table to run query against. Part of the SQL::Abstract tuple

=item * C<$cols> columns to select for the ID and the description. Defaults to C<('id', 'opt)>. Part of the SQL::Abstract tuple

=item * C<$where> where clause passed in as a hash, e.g. C<{'field'=>'value'}>. Part of the SQL::Abstract tuple

=item * C<$keyword> keyword to describe the thing being chosen, e.g. C<camera>. Defaults to attempting to figure it out with C<&keyword>

=item * C<$required> whether this is a required choice, or whether we allow the user to enter an empty input. Defaults to C<0>

=item * C<$char> character to use to signal that you want to enter a new row, if C<inserthandler> is set. Defaults to C<+>

=head4 Returns

ID of the selected option

=cut

sub listchoices {
	# Pass in a hashref of arguments
	my $href = shift;

	my $db = $href->{db};								# DB handle
	my $query = $href->{query};							# (legacy) the SQL to generate the list of choices
	my $type = $href->{type} || 'text';						# Data type of choice to be made. Often but not always integer
	my $inserthandler = $href->{inserthandler};					# ref to handler that can be used to insert a new row
	my $default = $href->{default} // '';						# id of default choice
	my $autodefault = $href->{autodefault} // 1;					# if default not set, count number of allowed options and if there's just 1, make it the default
	my $skipok = $href->{skipok} || 0;						# whether it is ok to return null if there are no options to choose from
	my $table = $href->{table};							# Part of the SQL::Abstract tuple
	my $cols = $href->{cols} // ('id, opt');					# Part of the SQL::Abstract tuple
	my $where = $href->{where} // {};						# Part of the SQL::Abstract tuple
	my $keyword = $href->{keyword} || &keyword($table) || &keyword($query);		# keyword to describe the thing being chosen
	my $required = $href->{required} // 0;						# whether we allow the user to enter an empty input
	my $char = $href->{char} // '+';						# character to use to signal that you want to enter a new row

	my ($sth, $rows);
	if ($query) {
		# Use the manual query
		$sth = $db->prepare($query) or die "Couldn't prepare statement: " . $db->errstr;
		$rows = $sth->execute();
	} elsif ($table && $cols && $where) {
		# Use SQL::Abstract
		my $sql = SQL::Abstract->new;
		my($stmt, @bind) = $sql->select($table, $cols, $where);
		$sth = $db->prepare($stmt);
		$rows = $sth->execute(@bind);
	} else {
		die "Must pass in either query OR table, cols, where\n";
	}

	# No point in proceeding if there are no valid options to choose from
	if ($rows == 0) {
		print "No valid $keyword options to choose from\n";
		if ($inserthandler && &prompt({prompt=>"Add a new $keyword?", type=>'boolean', default=>'no'})) {
			# add a new entry
			my $id = $inserthandler->({db=>$db});
			return $id;
		} elsif ($skipok) {
			return;
		} else {
			die;
		}
	}

	my @allowedvals;

	while (my $ref = $sth->fetchrow_hashref) {
		print "\t$ref->{id}\t$ref->{opt}\n";
		# Make a note of what allowed options are
		push(@allowedvals, $ref->{id});
	}

	# Add option to insert a new row, if applicable
	if ($inserthandler) {
		print "\t$char\tAdd a new $keyword\n";
		push(@allowedvals, $char);
	}

	if ($default eq '' && $autodefault) {
		# If no default is given, count number of allowed options
		# and if there's just one, make it the default
		if ($rows == 1) {
			$default = $allowedvals[0];
		}
	} else {
		# Check that the provided default is an allowed value
		# Otherwise silently unset it
		if ($default && !($default ~~ @allowedvals)) {
			$default = '';
		}
	}

	# Loop until we get valid input
	my $input;
	my $msg = "Please select a $keyword from the list";
	$msg .= ', or leave blank to skip' if ($required == 0);

	do {
		$input = &prompt({default=>$default, prompt=>$msg, type=>$type, required=>$required});
	} while ($input && !($input ~~ [ map {"$_"} @allowedvals ] || $input eq ''));

	# Spawn a new handler if that's what the user chose
	# Otherwise return what we got
	if ($input eq $char && $inserthandler) {
		my $id = $inserthandler->({db=>$db});
		return $id;
	} else {
		# Return input
		return $input;
	}
}


=head2 multiplechoice

Choose from a number of options expressed as an array, and return the index of the chosen option

=head4 Usage

    my @choices = [
        { desc => 'Do nothing' },
        { desc => 'Also do nothing' },
    ];

    my $action = &multiplechoice({choices => \@choices});

=head4 Arguments

=item * C<$choices> array of hashes of options

=head4 Returns

Integer of the chosen option

=cut

sub multiplechoice {
	my $href = shift;
	my $choices = $href->{choices};

	my @allowedvals;
	while (my ($index, $choice) = each @{$choices}) {
		print "\t$index\t$$choice{desc}\n";
		push(@allowedvals, $index);
	}

	# Loop until we get valid input
	my $input;
	my $msg = "Please select an action from the list";

	do {
		$input = &prompt({prompt=>$msg, type=>'integer'});
	} while ($input && !($input ~~ [ map {"$_"} @allowedvals ] || $input eq ''));

	return $input;
}

=head2 printlist

Print arbitrary rows from the database as an easy way of displaying data

=head4 Usage

    &printlist({db=>$db, msg=>"prints from negative $neg_id", table=>'info_print', where=>{`Negative ID`=>$neg_id}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$msg> Message to display to user to describe what is being displayed. Shows up as C<Now showing $msg\n>

=item * C<$table> Table to select from. Part of the SQL::Abstract tuple

=item * C<$cols> Columns to display. Defaults to C<(id, opt)>. Part of the SQL::Abstract tuple

=item * C<$where> Where clause for the query. Part of the SQL::Abstract tuple

=item * C<$order> Order by clause for the query. Part of the SQL::Abstract tuple

=head4 Returns

Integer representing the number of rows printed

=cut

sub printlist {
	# Pass in a hashref of arguments
	my $href = shift;

	my $db = $href->{db};				# DB handle
	my $msg = $href->{msg};				# Message to display to user
	my $table = $href->{table};			# Part of the SQL::Abstract tuple
	my $cols = $href->{cols} // ('id, opt');	# Part of the SQL::Abstract tuple
	my $where = $href->{where} // {};		# Part of the SQL::Abstract tuple
	my $order = $href->{order};			# Part of the SQL::Abstract tuple

	print "Now showing $msg\n";

	my ($sth, $rows);
	if ($table && $cols && $where) {
		# Use SQL::Abstract
		my $sql = SQL::Abstract->new;
		my($stmt, @bind) = $sql->select($table, $cols, $where, $order);
		$sth = $db->prepare($stmt);
		$rows = $sth->execute(@bind);
		$rows = &unsci($rows);
	} else {
		print "Must pass in table, cols, where\n";
		return;
	}

	while (my $ref = $sth->fetchrow_hashref) {
		print "\t$ref->{id}\t$ref->{opt}\n";
	}
	return $rows;
}

# Return values from an arbitrary column from database as an arrayref

=head2 lookupcol

Return values from an arbitrary column from database as an arrayref

=head4 Usage

    my $existing = &lookupcol({db=>$db, table=>'CAMERA', where=>{camera_id=>$camera_id}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$query> (legacy) bare SQL query to run

=item * C<$table> table to run query against. Part of the SQL::Abstract tuple

=item * C<$cols> columns to select for the ID and the description. Defaults to C<*>. Part of the SQL::Abstract tuple

=item * C<$where> where clause passed in as a hash, e.g. C<{'field'=>'value'}>. Part of the SQL::Abstract tuple

=head4 Returns

An arrayref containing a hashref of columns and values

=cut

sub lookupcol {
	# Pass in a hashref of arguments
	my $href = shift;

	my $db = $href->{db};			# DB handle
	my $query = $href->{query};		# (legacy) SQL query to run
	my $table = $href->{table};		# Part of the SQL::Abstract tuple
	my $cols = $href->{cols} // '*';	# Part of the SQL::Abstract tuple
	my $where = $href->{where} // {};	# Part of the SQL::Abstract tuple

	my ($sth, $rows);
	if ($query) {
		$sth = $db->prepare($query) or die "Couldn't prepare statement: " . $db->errstr;
		$rows = $sth->execute();
	} elsif ($table && $cols && $where) {
		# Use SQL::Abstract
		my $sql = SQL::Abstract->new;
		my($stmt, @bind) = $sql->select($table, $cols, $where);
		$sth = $db->prepare($stmt);
		$rows = $sth->execute(@bind);
	} else {
		print "Must pass in either query OR table, cols, where\n";
		return;
	}

	my @array;
	while (my $ref = $sth->fetchrow_hashref) {
		$ref = &thin($ref);
		push(@array, $ref);
	}
	return \@array;
}

# Thin out keys will null values from a sparse hash

=head2 thin

Thin out keys with empty values from a sparse hash

=head4 Usage

    $data = &thin($data);

=head4 Arguments

=item * C<$data> Hashref containing data to be thinned

=head4 Returns

Hashref containing thinned data

=cut

sub thin {
	my $data = shift;
	foreach (keys %$data) {
		delete $$data{$_} unless (defined $$data{$_} and $$data{$_} ne '');
	}
	return \%$data;
}

=head2 lookupval

Return arbitrary single value from database

=head4 Usage

    my $info = &lookupval({db=>$db, col=>'notes', table=>'FILM', where=>{film_id=>$film_id}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$query> (legacy) bare SQL query to run

=item * C<$table> table to run query against. Part of the SQL::Abstract tuple

=item * C<$col> column to select. Part of the SQL::Abstract tuple

=item * C<$where> where clause passed in as a hash, e.g. C<{'field'=>'value'}>. Part of the SQL::Abstract tuple

=head4 Returns

Single value from the database

=cut

sub lookupval {
	# Pass in a hashref of arguments
	my $href = shift;

	my $db = $href->{db};			# DB handle
	my $query = $href->{query};		# (legacy) SQL query to run
	my $table = $href->{table};		# Part of the SQL::Abstract tuple
	my $col = $href->{col};			# Part of the SQL::Abstract tuple
	my $where = $href->{where} // {};	# Part of the SQL::Abstract tuple

	my ($sth, $rows);
	if ($query) {
		# Use the manual query
		$sth = $db->prepare($query) or die "Couldn't prepare statement: " . $db->errstr;
		$rows = $sth->execute();
	} elsif ($table && $col && $where) {
		# Use SQL::Abstract
		my $sql = SQL::Abstract->new;
		my($stmt, @bind) = $sql->select($table, $col, $where);
		$sth = $db->prepare($stmt);
		$rows = $sth->execute(@bind);
	} else {
		print "Must pass in either query OR table, col, where\n";
		return;
	}

	my $row = $sth->fetchrow_array();
	return $row;
}



=head2 call

Call a stored procedure from the database

=head4 Usage

    &call({db=>$db, procedure=>'print_unarchive', args=>['123']});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$procedure> name of the database stored procedure to call

=item * C<$args> arrayref of arguments to pass to the stored procedure

=head4 Returns

Number of affected rows

=cut

sub call {
	my $href = shift;

	my $db = $href->{db};
	my $procedure = $href->{procedure};
	my $args = $href->{args};

	my $arglist;
	if (defined $args) {
		$arglist = join(',', @$args);
	} else {
		$arglist = '';
	}
	my $query = "call $procedure($arglist)";
	my $sth = $db->prepare($query);
	my $rows = $sth->execute();
	return $rows;
}

=head2 lookuplist

Return multiple values from a single database column as an arrayref

=head4 Usage

    my $values = &lookuplist({db=>$db, col=>$column, table=>$table, where{key=>value}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$table> table to run query against. Part of the SQL::Abstract tuple

=item * C<$col> column to select. Part of the SQL::Abstract tuple

=item * C<$where> where clause passed in as a hash, e.g. C<{'field'=>'value'}>. Part of the SQL::Abstract tuple

=head4 Returns

An arreyref containing a list of values

=cut

sub lookuplist {
	# Pass in a hashref of arguments
	my $href = shift;

	my $db = $href->{db};		   # DB handle
	my $table = $href->{table};	     # Part of the SQL::Abstract tuple
	my $col = $href->{col};		 # Part of the SQL::Abstract tuple
	my $where = $href->{where} // {};       # Part of the SQL::Abstract tuple

	my ($sth, $rows);
	if ($table && $col && $where) {
		# Use SQL::Abstract
		my $sql = SQL::Abstract->new;
		my($stmt, @bind) = $sql->select($table, $col, $where);
		$sth = $db->prepare($stmt);
		$rows = $sth->execute(@bind);
	} else {
		print "Must pass in table, col, where\n";
		return;
	}

	my @list;
	while (my @row = $sth->fetchrow_array()) {
		push(@list, $row[0]);
	}
	return \@list;
}

# Return today's date according to the DB

=head2 today

Return today's date according to the DB

=head4 Usage

    my $todaysdate = &today;

=head4 Arguments

=item * C<$db> DB handle

=head4 Returns

Today's date, formatted C<YYYY-MM-DD>

=cut

sub today {
	return localtime->strftime('%Y-%m-%d');
}

=head2 now

Return an SQL-formatted timestamp for the current time

=head4 Usage

    my $time = &now;

=head4 Arguments

=item * C<$db> Database handle

=head4 Returns

String containing the current time, formatted C<YYYY-MM-DD HH:MM:SS>

=cut

sub now {
	return localtime->strftime('%Y-%m-%d %H:%M:%S');
}


# Translate "friendly" bools to integers


=head2 friendlybool

Translate "friendly" bools to integers so we can accept human input and map it to binary boolean values.
y/yes/true/1 map to 1 and n/no/false/0 map to 0. See also &printbool.

=head4 Usage

    my $binarybool = &friendlybool($friendlybool);

=head4 Arguments

=item * C<$friendlybool> string representation of a boolean, e.g. C<yes>, C<y>, C<true>, C<1>, C<no>, C<n>, C<false>, C<0>, etc

=head4 Returns

C<1> if C<$bool> represents a true value and C<0> if it represents a false value

=cut

sub friendlybool {
	my $val = shift;
	if ($val =~ m/^y(es)?$/i || $val =~ m/^true$/i || $val eq 1) {
		return 1;
	} elsif ($val =~ m/^n(o)?$/i || $val =~ m/^false$/i || $val eq 0) {
		return 0;
	} else {
		return '';
	}
}

=head2 printbool

Translate numeric bools to strings for friendly printing of user messages.
See also &friendlybool.

=head4 Usage

    my $string = &printbool($bool);

=head4 Arguments

=item * C<$bool> boolean value to rewrite

=head4 Returns

Returns C<yes> if C<$bool> is true and C<no> if C<$bool> is false.

=cut

sub printbool {
	my $val = shift;
	if ($val =~ m/^y(es)?$/i || $val =~ m/^true$/i || $val eq 1) {
		return 'yes';
	} elsif ($val =~ m/^n(o)?$/i || $val =~ m/^false$/i || $val eq 0) {
		return 'no';
	} else {
		return '';
	}
}

=head2 writeconfig

Write out an initial config file by prompting the user interactively.

=head4 Usage

    &writeconfig($path);

=head4 Arguments

=item * C<$path> path to the config file that should be written

=head4 Returns

Nothing

=cut

sub writeconfig {
	my $inifile = shift;

	# Untaint
	unless ($inifile =~ m#^([\w.-\/]+)$#) {
		die "filename '$inifile' has invalid characters.\n";
	}
	$inifile = $1;

	# Check for existence of config dir
	my $dir = dirname($inifile);
	if (!-d $dir) {
		# Create it if necessary
		mkdir $dir or die "Can't create config directory $dir";
	}

	my %inidata;
	$inidata{'database'}{'host'} = &prompt({default=>'localhost', prompt=>'Database hostname or IP address', type=>'text'});
	$inidata{'database'}{'schema'} = &prompt({default=>'photodb', prompt=>'Schema name of photography database', type=>'text'});
	$inidata{'database'}{'user'} = &prompt({default=>'photodb', prompt=>'Username with access to the schema', type=>'text'});
	$inidata{'database'}{'pass'} = &prompt({default=>'', prompt=>'Password for this user', type=>'text'});
	$inidata{'filesystem'}{'basepath'} = &prompt({default=>'', prompt=>'Path to your scanned images', type=>'text'});
	WriteINI($inifile, \%inidata)
		or die "Could not write to ini file at $inifile\n";
	return;
}

=head2 round

Round a number to any precision

=head4 Usage

    my $rounded = &round($num, 3);

=head4 Arguments

=item * C<$num> Number to round

=item * C<$pow10> Number of decimal places to round to. Defaults to C<0> i.e. round to an integer

=head4 Returns

Rounded number

=cut

sub round {
	my $x = shift;		# Number to round
	my $pow10 = shift || 0;	# Number of decimal places to round to
	my $a = 10 ** $pow10;
	return int(($x * $a) + 0.5) / $a
}

=head2 pad

Pad a string with spaces up to a fixed length, to make it easier to print fixed-width tables

=head4 Usage

    my $paddedstring = &pad('Hello', 8);

=head4 Arguments

=item * C<$string> Text to pad

=item * C<$totallength> Total number of characters to pad to, defaults to C<18>

=head4 Returns

Padded string

=cut

sub pad {
	my $string = shift;		# Text to pad
	my $totallength = shift || 18;	# Total number of characters to pad to

	# Work out required pad
	my $pad = $totallength - length($string);

	if ($pad > 0) {
		# Return the padded string
		return $string . ' ' x $pad;
	} elsif ($pad = 0) {
		# No pad required, just return the original
		return $string;
	} else {
		# If the input is longer than the target, truncate it
		return substr($string, 0, $totallength);
	}
}

=head2 resolvenegid

Get a negative ID either from the neg ID or the film/frame ID

=head4 Usage

    my $negID = &resolvenegid({db=>$db, string=>'10/4'});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$string> String to represent a negative ID, either as an integer or in film/frame format, e.g. C<834> or C<10/4>

=head4 Returns

Integer negative ID

=cut

sub resolvenegid {
	my $href = shift;
	my $db = $href->{db};
	my $string = $href->{string};
	if ($string =~ m/^\d+$/) {
		# All digits - already a NegID
		return $string;
	} elsif ($string =~ m/^(\d+)\/([a-z0-9]+)$/i) {
		# 999/99A - a film/frame ID
		my $film_id = $1;
		my $frame = $2;
		my $neg_id = &lookupval({db=>$db, col=>"lookupneg($film_id, $frame)", table=>'NEGATIVE'});
		return $neg_id;
	} else {
		# Could not resolve
		die "Could not resolve $string to a negative ID\n";
	}
}

=head2 chooseneg

Select a negative by drilling down

=head4 Usage

    my $id = &chooseneg({db=>$db, oktoreturnundef=>$oktoreturnundef});

=head4 Arguments

=item * C<$db> variable containing database handle as returned by C<&db>

=item * C<$oktoreturnundef> optional boolean to specify whether it is OK to fail to find a negative

=head4 Returns

Integer representing the negative ID

=cut

sub chooseneg {
	my $href = shift;
	my $db = $href->{db};
	my $oktoreturnundef = $href->{oktoreturnundef} || 0;

	# Choose a film
	my $film_id = &prompt({default=>'', prompt=>'Enter Film ID', type=>'integer'});

	#  Choose a negative from this film
	my $frame = &listchoices({db=>$db, table=>'NEGATIVE', cols=>'frame as id, description as opt', where=>{film_id=>$film_id}, type=>'text'});
	my $neg_id = &lookupval({db=>$db, col=>"lookupneg($film_id, $frame)", table=>'NEGATIVE'});
	if (defined($neg_id) && $neg_id =~ m/^\d+$/) {
		return $neg_id;
	} elsif ($oktoreturnundef == 1) {
		return;
	} else {
		die "Could not find a negative ID for film $film_id and frame $frame\n";
	}
}

=head2 annotatefilm

Write out a text file in the film scans directory

=head4 Usage

    &annotatefilm({db=>$db, film_id=>$film_id});

=head4 Arguments

=item * C<$db> variable containing database handle as returned by C<&db>

=item * C<$film_id> integer variable containing ID of the film to be annotated

=head4 Returns

Nothing

=cut

sub annotatefilm {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id};

	my $path = &basepath;
	if (defined($path) && $path ne '' && -d $path) {
		my $filmdir = &lookupval({db=>$db, col=>'directory', table=>'FILM', where=>{film_id=>$film_id}});
		if (defined($filmdir) && $filmdir ne '' && -d "$path/$filmdir") {
			# proceed
			my $filename = "$path/$filmdir/details.txt";

			my $sth = $db->prepare('SELECT * FROM photography.info_film where `Film ID`=?') or die "Couldn't prepare statement: " . $db->errstr;
			my $rows = $sth->execute($film_id);
			my @output;

			while (my $ref = $sth->fetchrow_hashref) {
				$ref = &thin($ref);
				# Print the film header and remove it from the hash
				push(@output, "Film #$ref->{'Film ID'} \"$ref->{'Title'}\"\n\n");
				delete $ref->{'Film ID'};
				delete $ref->{'Title'};

				# Print remaining key-value pairs for the film
				foreach (sort keys %$ref) {
					push(@output, "$_: $ref->{$_}\n");
				}
			}

			# Now work out the negative details
			my $sth2 = $db->prepare('SELECT * FROM photography.info_negative where `Film ID`=?') or die "Couldn't prepare statement: " . $db->errstr;
			my $rows2 = $sth2->execute($film_id);

			# Print a block for each negative
			while (my $ref = $sth2->fetchrow_hashref) {
				$ref = &thin($ref);
				delete $ref->{'film_id'};
				# Print the negative header and remove it from the hash
				push(@output, "\n");
				push(@output, "Frame $ref->{'Frame'} \"$ref->{'Caption'}\"\n");
				delete $ref->{'Frame'};
				delete $ref->{'Caption'};

				# Print remaining key-value pairs for the negative
				foreach (sort keys %$ref) {
					push(@output, "\t$_: $ref->{$_}\n");
				}
			}
			# Write the compiled array out to a file
			open my $fh, '>', $filename or die "Cannot open $filename: $!";
			foreach (@output) {
				print $fh $_;
			}
			close $fh;
		} else {
			print "Film directory $path/$filmdir not found\n";
			return;
		}
	} else {
		print "Path $path not found\n";
		return;
	}
	return;
}

=head2 keyword

Figure out the human-readable keyword of an SQL statement, e.g. statements that select from
C<CAMERA> or C<choose_camera> would return C<camera>. Selecting from C<CAMERA_MOUNT> or
C<choose_camera_mount> would return C<camera mount>. This can be helpful when automating
user messages.

=head4 Usage

    my $keyword = &keyword($query);

=head4 Arguments

=item * C<$query> an SQL statement, e.g. C<SELECT * FROM CAMERA;>

=head4 Returns

A human-readable keyword representing the "subject" of the SQL query

=cut

sub keyword {
	my $query = shift;
	# This matches either a full SQL query, or just the table name
	if ($query =~ m/^.+ from (\w+).*$/i || $query =~ m/^(\w+)$/i) {
		my $text = $1;
		$text = lc($text);
		$text =~ s/^choose_//;
		$text =~ s/_/ /g;
		return $text;
	} else {
		print "Could not deduce valid keyword from SQL\n";
		return;
	}
}

=head2 parselensmodel

Parse lens model name to guess some data about the lens. Either specify which parameter you want
to be returned as a string, or expect a hashref of all params to be returned. Currently supports guessing
C<minfocal> (minimum focal length), C<maxfocal> (maximum focal length), C<zoom> (whether this is a zoom lens)
and C<aperture> (maximum aperture of lens).

=head4 Usage

    my $aperture = &parselensmodel($model, 'aperture');
    my $lensparams = &parselensmodel($model);

=head4 Arguments

=item * C<$model> Model name of the lens

=item * C<$param> The name of the desired parameter. Optional, choose from C<minfocal>, C<maxfocal>, C<zoom> or C<aperture>.

=head4 Returns

=item * If C<$param> is specified, returns the value of this parameter as a string

=item * If C<$param> is undefined, returns a hashref of all parameters

=cut

sub parselensmodel {
	my $model = shift;
	my $param = shift;

	# Define hash to hold results
	my %results;

	if ($model =~ m/(\d+)-?(\d+)?mm/) {
		$results{minfocal} = $1;
		$results{maxfocal} = $2;
	}
	if ($results{minfocal} && $results{maxfocal}) {
		$results{zoom} = 'yes';
	} else {
		$results{zoom} = 'no';
	}
	if ($model =~ m/(f\/|1:)([\d\.]+)/) {
		$results{aperture} = $2;
	}

	if ($param) {
		# If a specific param was requested, return it
		return $results{$param};
	} else {
		# Else return a hashref of all params
		return \%results;
	}
}

=head2 unsetdisplaylens

Unassociate a display lens from a camera by passing in either the camera ID or
the lens ID. It is not harmful to pass in both, but it is pointless.

=head4 Usage

    &unsetdisplaylens({db=>$db, camera_id=>$camera_id});
    &unsetdisplaylens({db=>$db, lens_id=>$lens_id});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$camera_id> ID of camera whose display lens you want to unassociate

=item * C<$lens_id> ID of lens you want to unassociate

=head4 Returns

Result of SQL update

=cut

sub unsetdisplaylens {
	my $href = shift;
	my $db = $href->{db};
	my %where;
	$where{camera_id} = $href->{camera_id};
	$where{display_lens} = $href->{lens_id};
	my $thinwhere = &thin(\%where);

	# Build query
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->update('CAMERA', {display_lens => undef}, $thinwhere);

	# Execute query
	my $sth = $db->prepare($stmt);
	return $sth->execute(@bind);
}

=head2 welcome

Print a friendly welcome message

=head4 Usage

    &welcome;

=head4 Arguments

None

=head4 Returns

Nothing

=cut

sub welcome {
	my $version = $App::PhotoDB::VERSION;
	my $ascii = <<'END_ASCII';
 ____  _           _        ____  ____
|  _ \| |__   ___ | |_ ___ |  _ \| __ )
| |_) | '_ \ / _ \| __/ _ \| | | |  _ \
|  __/| | | | (_) | || (_) | |_| | |_) |
|_|   |_| |_|\___/ \__\___/|____/|____/
END_ASCII
	print $ascii . ' ' x 29 . 'v' . $version . "\n\n";
	return;
}

=head2 duration

Calculate duration of a shutter speed from its string representation

=head4 Usage

    my $duration = &duration($shutter_speed);

=head4 Arguments

=item * C<$shutter_speed> string containing a representation of a shutter speed, e.g. C<1/125>, C<0.7>, C<3>, or C<3">

=head4 Returns

Numeric representation of the duration of the shutter speed, e.g. C<0.05>

=cut

sub duration {
	my $shutter_speed = shift;
	my $duration = 0;
	# Expressed like 1/125
	if ($shutter_speed =~ m/1\/(\d+)/) {
		$duration = 1 / $1;
	# Expressed like 0.3 or 1
	} elsif ($shutter_speed =~ m/((0\.)?\d+)/) {
		$duration = $1;
	}
	return $duration;
}

=head2 tag

This func reads data from PhotoDB and writes EXIF tags
to the JPGs that have been scanned from negatives

=head4 Usage

    &tag({db=>$db, where=>$where});
    &tag({db=>$db, where=>{film_id=1}});
    &tag({db=>$db, where=>{negative_id=100}});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$where> hash to specify which scans should be tagged. Tags all scans if not set!

=head4 Returns

Nothing

=cut

sub tag {

	# Read in cmdline args
	my $href = shift;
	my $db = $href->{db};
	my $where = $href->{where};

	# Make sure basepath is valid
	my $basepath = &basepath;

	# Crank up an instance of ExifTool
	my $exifTool = Image::ExifTool->new;
	$exifTool->Options(CoordFormat => q{%+.6f});

	# Specify which attributes we want to write
	# If any are specified here but not available, they will be ignored
	my @attributes = (
		'Make',
		'Model',
		'Lens',
		'LensModel',
		'ExposureTime',
		'MaxApertureValue',
		'FNumber',
		'ApertureValue',
		'FocalLength',
		'ISO',
		'Author',
		'ImageDescription',
		'DateTimeOriginal',
		'ExposureProgram',
		'MeteringMode',
		'Flash',
		'GPSLatitude',
		'GPSLongitude',
		'FocalLengthIn35mmFormat',
		'LensSerialNumber',
		'SerialNumber',
		'LensMake',
		'Copyright',
		'UserComment',
	);

	# This is the query that fetches (and calculates) values from the DB that we want to write as EXIF tags
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->select('exifdata', '*', $where);

	# Prepare and execute the SQL
	my $sth = $db->prepare($stmt) or die "Couldn't prepare statement: " . $db->errstr;
	my $rows = $sth->execute(@bind);
	$rows = &unsci($rows);

	# Get confirmation
	if ($rows == 0) {
		print "No scans be will tagged\n";
		return;
	}
	return unless &prompt({prompt=>"This will review and potentially update the tags of $rows scans. Proceed?", type=>'boolean'});

	# Set some globals
	my $foundcount=0;
	my $changedcount=0;
	my @missingfiles;

	# Loop through our result set
	while (my $ref = $sth->fetchrow_hashref()) {
		# First check the path is defined in MySQL
		if (defined($ref->{'path'})) {
			# Now make sure the path actually exists on the system
			if (-e "$basepath/$ref->{'path'}") {
				# File exists, so we go on and do stuff to it.
				# Grab the existing EXIF tags for comparison
				my $exif = $exifTool->ImageInfo("$basepath/$ref->{'path'}");
				my $changeflag = 0;
				$foundcount++;

				# For each of the attributes on our list...
				foreach my $var (@attributes) {
					#  Test if it exists in the DB
					if (defined($ref->{$var})) {
						# Test if it already exists in the file AND has the correct value, either string OR numeric format
						if (defined($exif->{$var}) && ($exif->{$var} ~~ $ref->{$var})) {
							# Tag already has correct value, skip
							next;
						} else {
							# Set the value of the tag and flag that a change was made
							if (defined($exif->{$var})) {
								# Already defined, update it
								print "\tChanging $var: $exif->{$var} => $ref->{$var}\n";
							} else {
								# Not defined, set it
								print "\tSetting $var: $ref->{$var}\n";
							}
							$exifTool->SetNewValue($var => $ref->{$var});
							$changeflag = 1;
						}
					}
				}

				# If a change has been made to the EXIF data, write out the data
				if ($changeflag == 1) {
					$exifTool->WriteInfo("$basepath/$ref->{'path'}");
					print "Wrote tags to $basepath/$ref->{'path'}\n\n";
					$changedcount++;
				}
			} else {
				print "$basepath/$ref->{'path'} not found - skipping\n";
				push (@missingfiles, "$basepath/$ref->{'path'}");
			}
		}
	}

	# Print some stats
	print "Found $foundcount images\n";
	print "Changed EXIF data in $changedcount images\n";
	print 'Found ' . ($#missingfiles + 1) . " missing files\n";
	return;
}


=head2 hashdiff

Compare new and old data to find changed keys.

=head4 Usage

    my $diff = &hashdiff(\%old, \%new);
    my $diff = &hashdiff($old, $new);

=head4 Arguments

=item * C<$old> hashref of old values

=item * C<$new> hashref of new values

=head4 Returns

Hashref containing values that are new or different.

=cut

sub hashdiff {
	my $old = shift;
	my $new = shift;

	# Strip out empty keys
	$old = &thin($old);
	$new = &thin($new);

	# Save new or changed keys
	my %diff;
	foreach my $key (keys %$new) {
		if (!defined($$old{$key}) || $$new{$key} ne $$old{$key}) {
			$diff{$key} = $$new{$key};
		}
	}
	return \%diff;
}

# Write an event to the log

=head2 logger

Record a database event in the log

=head4 Usage

    &logger({db=>$db, type=>$type, message=>$message});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$type> Type of log message. Currently C<ADD> or C<EDIT> to reflect database changes.

=item * C<$message> Message to write to the log file

=head4 Returns

ID of the log message

=cut

sub logger {
	my $href = shift;
	my $db = $href->{db};
	my $type = $href->{type};
	my $message = $href->{message};

	return &newrecord({db=>$db, data=>{datetime=>&now, type=>$type, message=>$message}, table=>'LOG', silent=>1, log=>0});
}

=head2 choosescan

Select a scan by specifying a filename. Allows user to pick if there are multiple matching filenames.

=head4 Usage

    my $id = &choosescan({db=>$db});

=head4 Arguments

=item * C<$db> variable containing database handle as returned by C<&db>

=head4 Returns

Integer representing the scan ID

=cut

sub choosescan {
	my $href = shift;
	my $db = $href->{db};
	# prompt user for filename of scan
	my $filename = &prompt({prompt=>'Please enter the filename of the scan', type=>'text'});

	# should be unique if filename is X-Y-img1234.jpg, otherwise they can choose
	return &listchoices({db=>$db, table=>'choose_scan', where=>{'filename'=>$filename}, type=>'text'});
}


=head2 basepath

Returns filesystem basepath which contains scans

=head4 Usage

    my $basepath = &basepath;

=head4 Arguments

None

=head4 Returns

Path to directory which contains scans

=cut

sub basepath {
	# Work out file path
	my $connect = ReadINI(&ini);
	if (!defined($$connect{'filesystem'}{'basepath'})) {
		die "Config file did not contain basepath";
	}
	my $basepath = $$connect{'filesystem'}{'basepath'};
	# Strip off trailing slash
	$basepath =~ s/\/$//;
	return $basepath;
}

# Untaint input

=head2 untaint

Untaint a tainted value

=head4 Usage

    my $untainted = &untaint($tainted);

=head4 Arguments

=item * C<$tainted> Tainted value to untaint

=head4 Returns

Returns the untained string

=cut

sub untaint {
	my $input = shift;
	$input =~ m/^(.*)$/;
	my $output = $1;
	return $output;
}

=head2 fsfiles

List all scan files on the filesystem

=head4 Usage

    my @scansondisk = &fsfiles;

=head4 Arguments

None

=head4 Returns

Array of file paths of scans found on the filesystem

=cut

sub fsfiles {
	# Search filesystem basepath to enumerate all *.jpg
	my $basepath = &basepath;
	my $rule = Path::Iterator::Rule->new;
	$rule->iname( '*.jpg' );
	my @fsfiles = $rule->all($basepath);

	# Filter out empty elements
	@fsfiles = grep {$_} @fsfiles;

	return @fsfiles;
}


=head2 dbfiles

List all scan files in the database

=head4 Usage

    my @scansindb = &dbfiles;

=head4 Arguments

=item * C<$db> database handle

=head4 Returns
Array of file paths of scans recorded in the database

=cut

sub dbfiles {
	my $href = shift;
	my $db = $href->{db};
	my $basepath = &basepath;
	# Query DB to find all known scans
	my $dbfilesref = &lookuplist({db=>$db, col=>"concat('$basepath', '/', directory, '/', filename)", table=>'scans_negs'});
	my @dbfiles = @$dbfilesref;

	# Filter out empty elements
	@dbfiles = grep {$_} @dbfiles;

	return @dbfiles;
}


=head2 unsci

DBD returns integer zero in scientific format as 0E0. This rewrites it.

=head4 Usage

    $int = &unsci($int);

=head4 Arguments

=item * C<$int> an integer returned by DBD

=head4 Returns

The same integer as passed in, except with string 0E0 rewritten as integer 0

=cut

sub unsci {
	my $int = shift;
	$int = 0 if ($int eq '0E0');
	return $int;
}



=head2 search

Search for objects in the database

=head4 Usage

    my $id = &search({
        db         => $db,
        table      => 'choose_camera',
        searchterm => $searchterm,
        choices    => [
            { desc => 'Do nothing' },
            { desc => 'Get camera info', handler => \&camera_info, id=>'camera_id', },
            { desc => 'Load a film', handler => \&film_load, id=>'camera_id', },
            { desc => 'Sell this camera', handler => \&camera_sell, id=>'camera_id', }
        ],
    });

=head4 Arguments

=item * C<$db> database handle

=item * C<$table> name of table or view to search in

=item * C<$keyword> keyword to describe the thing being chosen, e.g. C<camera>. Defaults to attempting to figure it out with C<&keyword>

=item * C<$searchterm> string to search for in the database

=item * C<$cols> = pair of columns where the first will be returned as the matched ID and the second is the column to be searched in. Defaults to ['id', 'opt']

=item * C<$where> where clause for the search. Defaults to C<"opt like '%$searchterm%' collate utf8mb4_general_ci">

=item * C<$choices> arrayref to an array of hashes which represent actions to be taken on a located item. You must provide C<desc>, a description of the action, C<handler>, a function reference to a suitable handler, and C<id>, the name of the parameter to use to pass in the ID located object.

=head4 Returns

ID of located object

=cut

# Search for objects in the database
sub search {
	my $href = shift;
	my $db = $href->{db};
	my $table = $href->{table};
	my $keyword = $href->{keyword} // &keyword($table);
	my $searchterm = $href->{searchterm} // &prompt({prompt=>"Enter $keyword search term"});
	my $cols = $href->{cols} // ['id', 'opt'];
	my $where = $href->{where} // "opt like '%$searchterm%' collate utf8mb4_general_ci";
	my $choices = $href->{choices};

	print "Searching for $keyword objects that match '$searchterm'\n";

	# Perform search
	my $id = &listchoices({
		db     => $db,
		cols   => $cols,
		table  => $table,
		where  => $where,
		skipok => 1,
	});

	# Bail out if no results found
	if (!$id) {
		print "No $keyword objects matching '$searchterm' were found\n";
		return 0;
	}

	if ($choices && @$choices >0) {
		# Ask user to choose a followup action
		my $action = &multiplechoice({choices => $choices});

		# Execute chosen handler with ID passed into named arg
		if ($action && $choices->[$action]{handler}) {
			$choices->[$action]{handler}->({db=>$db, $choices->[$action]{id}=>$id});
		}
	} else {
		print "Selected $id\n";
	}
	return;
}

=head2 tabulate

Display multi-column SQL views as tabulated data.

=head4 Usage

    &tabulate({db=>$db, view=>$view});

=head4 Arguments

=item * C<$db> database handle

=item * C<$view> name of SQL view to print

=item * C<$cols> columns of view to return. Defaults to C<*>

=item * C<$where> optional WHERE clause

=head4 Returns

Number of rows displayed

=cut

sub tabulate {
	my $href = shift;
	my $db = $href->{db};
	my $view = $href->{view};
	my $cols = $href->{cols} // '*';
	my $where = $href->{where} // {};

	# Use SQL::Abstract
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->select($view, $cols, $where);

	my $sth = $db->prepare($stmt);
	my $rows = $sth->execute(@bind);
	my $returnedcols = $sth->{'NAME'};
	my @array;
	my $table = Text::TabularDisplay->new(@$returnedcols);
	while (my @row = $sth->fetchrow) {
		$table->add(@row);
	}

	#	print "$choices[$action]{'desc'}\n";
	print $table->render;
	print "\n";
	return $rows;
}


=head2 canondatecode

Decode Canon datecodes to discover the year of manufacture. Datecodes are sometimes ambiguous so by passing in the dates that the model was
introduced and discontinued, the year of manufacture can be pinned down.

=head4 Usage

    my $manufactured = &canondatecode({datecode=>$datecode, introduced=>$introduced, discontinued=>$discontinued});

=head4 Arguments

=item * C<$datecode> the datecode to decode

=item * C<$introduced> year that the model was introduced. Assumes 1800 if not defined.

=item * C<$discontinued> year that the model was discontinued. Assumes 2100 if not defined.

=head4 Returns

Year of manufacture if the decoding was successful, otherwise undef

=cut

sub canondatecode {
	my $href = shift;
	my $datecode = $href->{datecode};
	my $introduced = $href->{introduced} // 1800;
	my $discontinued = $href->{discontinued} // 2100;

	# Reformat datecode for reliable matching
	$datecode = uc($datecode);
	$datecode =~ s/[^A-Z0-9]//g;

	# Map alphabet to numbers
	my %h;
	@h{'A' .. 'Z'} = (0 .. 25);

	my @guesses;

	# AB1234, B1234A, B123A
	# From 1960-2012, the date code is in the form of "AB1234". "A" indicates the factory. Prior to 1986, "A" is moved to the end.
	# "B" is a year code that indicates the year of manufacture. Canon increments this letter each year starting with A in 1960
	# Of the 4 digits, the first two are the month of manufacture. Sometimes the leading 0 is omitted.
	if ($datecode =~ /^[A-Z]?([A-Z])[0-9]{3,4}[A-Z]?$/ ) {
		my $dateletter = $1;
		my $epochstart = 1960;
		my $epochend = 2012;
		my $datenumber = $h{$dateletter};

		for (my $i=0; ; $i++) {
			my $guess = $epochstart + $datenumber + $i*26;

			# Stop if we go above the end date of the datecode epoch
			last if ($guess > $epochend);

			push(@guesses, $guess);
		}

	# From 2008, the date code is 10 digits. The first two correspond to the year & month of manufacture.
	# From 2008-2012 the month code runs from 38-97. In 2013, it is reset to 01. These are treated as different epochs.
	} elsif ($datecode =~ /^(\d{2})\d{8}$/ ) {
		my $datenumber = $1;

		# First epoch
		if ($datenumber >= 38 and $datenumber <= 97) {
			my $epochstart = 2008;
			my $epochend = 2012;
			my $start = 38;

			my $guess = $epochstart + int(($datenumber - $start) / 12);
			push(@guesses, $guess);
		}

		# Second epoch
		{
			my $epochstart = 2013;
			my $epochend = 2100;
			my $start = 1;

			for (my $i=0; ; $i++) {
				my $guess = $epochstart + int((($datenumber + $i*100) - $start) / 12);
				last if ($guess > $epochend);
				push(@guesses, $guess);
			}
		}
	}

	# Now examine our guesses for plausibility based on when the lens was released & discontinued
	my @plausible;
	foreach my $guess (@guesses) {
		# Skip if our guess is before the lens was introduced
		next if ($guess < $introduced);

		# Stop if our guess is after the lens was discontinued
		next if ($guess > $discontinued);

		push(@plausible, $guess);
	}

	# If we narrowed it down to one year, return that. Otherwise, return nothing.
	if (scalar(@plausible) == 1) {
		return $plausible[0];
	}
	return;
}

=head2 choose_shutterspeed

While entering a negative into a film, prompt the user to select an available shutter speed for the camera in use. If they choose C<B> or C<T>, prompt them for
the duration in seconds, and return that instead. Also add it to the C<SHUTTER_SPEED_AVAILABLE> table, marked as a "bulb" speed if necessary.

=head4 Usage

    my $shutter_speed = &choose_shutterspeed({db=>$db, film_id=>$film_id});

=head4 Arguments

=item * C<$db> DB handle

=item * C<$film_id> Film ID that we are inserting into, so the camera can be found

=head4 Returns

String representation of a shutter speed, which is both a valid EXIF representation, and also a valid data object.

=cut

sub choose_shutterspeed {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id};

	# Prompt user to choose available shutter speed for their camera
	my $shutter_speed = &listchoices({db=>$db, keyword=>'shutter speed', table=>'choose_shutter_speed_by_film', where=>{film_id=>$film_id}, type=>'text', required=>1});

	# If they chose B or T
	if ($shutter_speed eq 'B' or $shutter_speed eq 'T') {
		my $shutter_speed = &prompt({prompt=>'What duration was the exposure? (s)', type=>'integer', required=>1});

		# If this is not already a valid shutter speed, insert it as a bulb-only speed
		my $cameramodel_id = &lookupval({db=>$db, col=>'cameramodel_id', table=>'FILM join CAMERA on FILM.camera_id=CAMERA.camera_id', where=>{film_id=>$film_id}});
		if (!&lookupval({db=>$db, col=>'count(*)', table=>'SHUTTER_SPEED_AVAILABLE', where=>{cameramodel_id=>$cameramodel_id, shutter_speed=>$shutter_speed}})) {
			# insert new bulb shutter speed
			my %data;
			$data{cameramodel_id} = $cameramodel_id;
			$data{shutter_speed} = $shutter_speed;
			$data{bulb} = 1;
			&newrecord({db=>$db, data=>\%data, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});
		}
	}
	return $shutter_speed;
}

# This ensures the lib loads smoothly
1;
