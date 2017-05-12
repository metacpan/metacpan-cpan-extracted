# Easy.pm - Easy to Use DBI interface

# Copyright (C) 1999-2002 Stefan Hornburg, Dennis Schön
# Copyright (C) 2003-2013 Stefan Hornburg (Racke) <racke@linuxia.de>

# Authors: Stefan Hornburg (Racke) <racke@linuxia.de>
#          Dennis Schön <ds@1d10t.de>
# Maintainer: Stefan Hornburg (Racke) <racke@linuxia.de>
# Version: 0.21

# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any
# later version.

# This file is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this file; see the file COPYING.  If not, write to the Free
# Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

package DBIx::Easy;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);

# Public variables
use vars qw($cache_structs);
$VERSION = '0.21';
$cache_structs = 1;

use DBI;

=head1 NAME

DBIx::Easy - Easy to Use DBI interface

=head1 SYNOPSIS

  use DBIx::Easy;
  my $dbi_interface = new DBIx::Easy qw(Pg template1);

  $dbi_interface -> insert ('transaction',
                   id => serial ('transaction', 'transactionid'),
                   time => \$dbi_interface -> now);

  $dbi_interface -> update ('components', "table='ram'", price => 100);
  $rows_deleted = $dbi_interface -> delete ('components', 'stock = 0');
  $dbi_interface -> makemap ('components', 'id', 'price', 'price > 10');
  $components = $dbi_interface -> rows ('components');
  $components_needed = $dbi_interface -> rows ('components', 'stock = 0');

=head1 DESCRIPTION

DBIx::Easy is an easy to use DBI interface.
Currently the Pg, mSQL, mysql, Sybase, ODBC and XBase drivers are supported.

=head1 CREATING A NEW DBI INTERFACE OBJECT

  $dbi_interface = new DBIx::Easy qw(Pg template1);
  $dbi_interface = new DBIx::Easy qw(Pg template1 racke);
  $dbi_interface = new DBIx::Easy qw(Pg template1 racke aF3xD4_i);
  $dbi_interface = new DBIx::Easy qw(Pg template1 racke@linuxia.de aF3xD4_i);
  $dbi_interface = new DBIx::Easy qw(Pg template1 racke@linuxia.de:3306 aF3xD4_i);

The required parameters are the database driver
and the database name. Additional parameters are the database user
and the password to access the database. To specify the database host
use the USER@HOST notation for the user parameter. If you want to specify the
port to connect to use USER@HOST:PORT.

=head1 DESTROYING A DBI INTERFACE OBJECT

It is important that you commit all changes at the end of the interaction
with the DBMS. You can either explicitly commit 

  $dbi_interface -> commit ();

or do it implicitly:

  undef $dbi_interface;

=head1 ERROR HANDLING

  sub fatal {
    my ($statement, $err, $msg) = @_;
    die ("$0: Statement \"$statement\" failed (ERRNO: $err, ERRMSG: $msg)\n");
  }
  $dbi_interface -> install_handler (\&fatal);

If any of the DBI methods fails, either I<die> will be invoked
or an error handler installed with I<install_handler> will be
called.

=head1 CACHING ISSUES

By default, this module caches table structures. This can be
disabled by setting I<$DBIx::Easy::cache_structs> to 0.

=head1 XBASE DRIVER

The DBIx::Easy method rows fails to work with the DBD::XBase driver.

=cut

# Private Variables
# =================

my $maintainer_adr = 'racke@linuxia.de';

# Keywords for connect()
my %kwmap = (mSQL => 'database', mysql => 'database', Pg => 'dbname',
			Sybase => 'database', ODBC => '', XBase => '');
my %kwhostmap = (mSQL => 'host', mysql => 'host', Pg => 'host',
				 Sybase => 'server', ODBC => '', XBase => '');
my %kwportmap = (mysql => 'port', Pg => 'port');

my %kwutf8map = (mysql => 'mysql_enable_utf8', 
		 Pg => 'pg_enable_utf8',
		 SQLite => 'sqlite_unicode', 
		 Sybase => 'syb_enable_utf8');

# Whether the DBMS supports transactions
my %transactmap = (mSQL => 0, mysql => 0, Pg => 1, Sybase => 'server',
				  ODBC => 0, XBase => 0);
  
# Statement generators for serial()
my %serialstatmap = (mSQL => sub {"SELECT _seq FROM $_[0]";},
					 Pg => sub {"SELECT NEXTVAL ('$_[1]')";});

# Statement for obtaining the table structure
my %obtstatmap = (mSQL => sub {my $table = shift;
							   "SELECT " . join (', ', @_)
                                 . " FROM $table WHERE 0 = 1";},
				  mysql => sub {my $table = shift;
							   "SELECT " . join (', ', @_)
                                 . " FROM $table WHERE 0 = 1";},
				  Pg => sub {my $table = shift;
							 "SELECT " . join (', ', @_)
							   . " FROM $table WHERE FALSE";},
				  Sybase => sub {my $table = shift;
							   "SELECT " . join (', ', @_)
                                 . " FROM $table WHERE 0 = 1";},
				  ODBC => sub {my $table = shift;
							   "SELECT " . join (', ', @_)
                                 . " FROM $table WHERE 0 = 1";},
				  XBase => sub {my $table = shift;
							   "SELECT " . join (', ', @_)
                                 . " FROM $table WHERE 0 = 1";});
  
# Supported functions
my %funcmap = (mSQL => {COUNT => 0},
			   mysql => {COUNT => 1},
			   Pg => {COUNT => 1},
			   Sybase => {COUNT => 1},
			   ODBC => {COUNT => 0});

# Cache
my %structs;
  
# Preloaded methods go here.

sub new
  {
	my $proto = shift;
	my $class = ref ($proto) || $proto;
	my $self = {};

	$self ->{DRIVER} = shift;
	$self ->{DATABASE} = shift;
	$self ->{USER} = shift;
	# check for a host part
	if (defined $self->{USER} && $self->{USER} =~ /@/) {
		$self->{HOST} = $';
		$self->{USER} = $`;
		
	}
    if (defined $self->{HOST} && $self->{HOST} =~ /:/) {
		$self->{PORT} = $';
		$self->{HOST} = $`;
	}
	$self ->{PASS} = shift;
	$self ->{CONN} = undef;
	$self ->{HANDLER} = undef;		# error handler

	bless ($self, $class);
	
    # sanity check: driver
    unless (defined ($self -> {DRIVER}) && $self->{DRIVER} =~ /\S/) {
		$self -> fatal ("No driver selected for $class.");
    }
	unless (exists $kwmap{$self -> {DRIVER}}) {
		$self -> fatal ("Sorry, $class doesn't support the \""
						. $self -> {DRIVER} . "\" driver.\n" 
						. "Please send mail to $maintainer_adr for more information.\n");
    }

	# sanity check: database name
    unless (defined ($self -> {DATABASE}) && $self->{DATABASE} =~ /\S/) {
		# ok for sybase with host
		unless ($self->{DRIVER} eq 'Sybase' && $self->{HOST}) {
			$self -> fatal ("No database selected for $class.");
		}
    }

	return $self if $^O eq 'MSWin32';

    # we may try to get password from DBMS specific
    # configuration file

    unless (defined $self->{PASS}) {
        unless (defined $self->{'USER'}
            && $self->{'USER'} ne getpwuid($<)) {   
            $self->passwd();
        }
    }

	return ($self);
}

# ------------------------------------------------------
# DESTRUCTOR
#
# If called for an object with established connection we
# commit any changes.
# ------------------------------------------------------

sub DESTROY {
	my $self = shift;

	if (defined ($self -> {CONN})) {
        unless ($self -> {CONN} -> {AutoCommit}) {
            $self -> {CONN} -> commit;
        }
	    $self -> {CONN} -> disconnect;
    }
}

# ------------------------------
# METHOD: fatal
#
# Error handler for this module.
# ------------------------------

sub fatal {
	my ($self, $info, $err) = @_;
	my $errstr = '';

	if (defined $self -> {CONN}) {
		$err = $DBI::err;
		$errstr = $DBI::errstr;

		unless ($self -> {CONN} -> {AutoCommit}) {
            # something has gone wrong, rollback anything
            $self -> {CONN} -> rollback ();
        }
    }
    
	if (defined $self -> {'HANDLER'}) {
		&{$self -> {'HANDLER'}} ($info, $err, $errstr);
    } elsif (defined $self -> {CONN}) {
		die "$info (DBERR: $err, DBMSG: $errstr)\n";
    } elsif ($err) {
		die "$info ($err)\n";
    } else {
		die "$info\n";
	}
}

# ---------------------------------------------------------------
# METHOD: connect
#
# Establishes the connection to the database if not already done.
# Returns database handle if successful, dies otherwise.
# ---------------------------------------------------------------

sub connect ()
  {
	my $self = shift;
	my ($dsn, $oldwarn, %dbi_params);
	my $msg = '';
    
	unless (defined $self -> {CONN})
	  {
		# build the data source string for DBI
		# ... the driver name
		$dsn .= 'dbi:' . $self -> {DRIVER} . ':';
		# ... optionally the var part (ODBC has no vars)
		if ($kwmap{$self -> {DRIVER}}) {
			$dsn .= $kwmap{$self -> {DRIVER}} . "=";
		}
		# ... database name
		$dsn .= $self -> {DATABASE};
		# ... optionally the host part
		if ($self -> {HOST}) {
			$dsn .= ';' . $kwhostmap{$self->{DRIVER}}
				. '=' . $self -> {HOST};
		}
		# ... optionally the host part
		if ($self -> {PORT}) {
		    if ($self->{PORT} =~ m%/%
			&& $self->{DRIVER} eq 'mysql') {
			# got socket passed as port
			$dsn .= ';' . 'mysql_socket'
				. '=' . $self -> {PORT};
		    }
		    else {
			$dsn .= ';' . $kwportmap{$self->{DRIVER}}
				. '=' . $self -> {PORT};
		    }
		}
        # install warn() handler to catch DBI error messages
        $oldwarn = $SIG{__WARN__};
        $SIG{__WARN__} = sub {$msg = "@_";};

		$dbi_params{AutoCommit} = !$transactmap{$self->{DRIVER}};

		if (exists $kwutf8map{$self->{DRIVER}}) {
		    $dbi_params{$kwutf8map{$self->{DRIVER}}} = 1;
                }

		$self->{CONN} = DBI->connect ($dsn, 
					      $self -> {USER}, 
					      $self -> {PASS},
					      \%dbi_params,
		    );

        # deinstall warn() handler
        $SIG{__WARN__} = $oldwarn;
        
		unless (defined $self -> {CONN})
		  {
            # remove file/line information from error message
            $msg =~ s/\s+at .*?line \d+\s*$//;
            
			# print error message in any case
			$self -> fatal ("Connection to database \"" . $self -> {DATABASE}
			  . "\" couldn't be established", $msg);
            return;
		  }
	  }
    
	# no need to see SQL errors twice
	$self -> {CONN} -> {'PrintError'} = 0;
	$self -> {CONN};
  }

# -------------------------
# METHOD: process STATEMENT
# -------------------------

=head1 METHODS

=head2 DATABASE ACCESS

=over 4

=item process I<statement>

  $sth = $dbi_interface -> process ("SELECT * FROM foo");
  print "Table foo contains ", $sth -> rows, " rows.\n";

Processes I<statement> by just combining the I<prepare> and I<execute>
steps of the DBI. Returns statement handle in case of success.

=back

=cut

sub process
  {
  my ($self, $statement) = @_;
  my ($sth, $rv);
  
  return unless $self -> connect ();

  # prepare and execute it
  $sth = $self -> {CONN} -> prepare ($statement)
	|| $self -> fatal ("Couldn't prepare statement \"$statement\"");
  $rv = $sth -> execute ()
	|| $self -> fatal ("Couldn't execute statement \"$statement\"");

  $sth;
  }

# ------------------------------------------------------
# METHOD: insert TABLE COLUMN VALUE [COLUMN VALUE] ...
#
# Inserts the given COLUMN/VALUE pairs into TABLE.
# ------------------------------------------------------

=over 4

=item insert I<table> I<column> I<value> [I<column> I<value>] ...

  $sth = $dbi_interface -> insert ('bar', drink => 'Caipirinha');

Inserts the given I<column>/I<value> pairs into I<table>. Determines from the
SQL data type which values has to been quoted. Just pass a reference to
the value to protect values with SQL functions from quoting.

=back

=cut

sub insert ($$$;@)
  {
	my $self = shift;
	my $table = shift;
	my (@columns, @values);
	my ($statement, $sthtest, $flags);
	my ($column, $value);

	return unless $self -> connect ();

	while ($#_ >= 0)
	  {
		$column = shift; $value = shift;
		push (@columns, $column);
		push (@values, $value);
	  }

    $flags = $self->typemap($table);
    
	for (my $i = 0; $i <= $#values; $i++) {
        if (ref ($values[$i]) eq 'SCALAR') {
			$values[$i] = ${$values[$i]};
        } elsif ($flags->{$columns[$i]} == DBI::SQL_INTEGER
				 || $flags->{$columns[$i]} == DBI::SQL_SMALLINT
				 || $flags->{$columns[$i]} == DBI::SQL_DECIMAL
				 || $flags->{$columns[$i]} == DBI::SQL_FLOAT
				 || $flags->{$columns[$i]} == DBI::SQL_REAL
				 || $flags->{$columns[$i]} == DBI::SQL_DOUBLE
				 || $flags->{$columns[$i]} == DBI::SQL_NUMERIC) {
			# we don't need to quote numeric values, but
			# we have to check for empty input
			unless (defined $values[$i] && $values[$i] =~ /\S/) {
				$values[$i] = 'NULL';
			}
		} elsif (defined $values[$i]) {
			$values[$i] = $self -> quote ($values[$i]);
        } else {
            $values[$i] = 'NULL';
        }
    }
	
	# now the statement
	$statement = "INSERT INTO $table ("
	  . join (', ', @columns) . ") VALUES ("
		. join (', ', @values) . ")";

	# process it
	$self -> {CONN} -> do ($statement)
	  || $self -> fatal ("Couldn't execute statement \"$statement\"");
  }

# ---------------------------------------------------------------
# METHOD: update TABLE CONDITIONS COLUMN VALUE [COLUMN VALUE] ...
#
# Updates the rows matching CONDITIONS with the given
# COLUMN/VALUE pairs and returns the number of the
# modified rows.    
# ---------------------------------------------------------------

=over 4

=item update I<table> I<conditions> I<column> I<value> [I<column> I<value>] ...

  $dbi_interface -> update ('components', "table='ram'", price => 100);
  $dbi_interface -> update ('components', "table='ram'", price => \"price + 20");

Updates any row of I<table> which fulfill the I<conditions> by inserting the given I<column>/I<value> pairs. Scalar references can be used to embed strings without further quoting into the resulting SQL statement. Returns the number of rows modified.

=back

=cut

sub update
  {
	my $self = shift;
	my $table = shift;
	my $conditions = shift;
	my (@columns);
	my ($statement, $rv);
	my ($column, $value);

	# ensure that connection is established
	return unless $self -> connect ();
	
	while ($#_ >= 0) {
		$column = shift; $value = shift;
        # avoid Perl warning
        if (defined $value) {
		    if (ref($value) eq 'SCALAR') {
				$value = $$value;
			} else {
				$value = $self -> {CONN} -> quote ($value);
			}
        } else {
            $value = 'NULL';
        }
		push (@columns, $column . ' = ' . $value);
	}

	# now the statement
	$statement = "UPDATE $table SET "
	  . join (', ', @columns) . " WHERE $conditions";

	# process it
	$rv = $self -> {CONN} -> do ($statement);
    if (defined $rv) {
        # return the number of rows changed
        $rv;
    } else {
        $self -> fatal ("Couldn't execute statement \"$statement\"");
    }
}

# ---------------------------------------------------------------
# METHOD: put TABLE CONDITIONS COLUMN VALUE [COLUMN VALUE] ...
#
# Either updates the rows matching CONDITIONS with the given
# COLUMN/VALUE pairs or puts (inserts) them into TABLE.
# Returns the number of modified rows (1 in case of an insert).
# ---------------------------------------------------------------

=over 4

=item put I<table> I<conditions> I<column> I<value> [I<column> I<value>] ...

=back

=cut

sub put
  {
	my $self = shift;
	my $table  = shift;
	my $conditions = shift;

	# ensure that connection is established
	return unless $self -> connect ();

	# check for existing rows
	if ($self->rows($table, $conditions)) {
		$self->update($table, $conditions, @_);
	} else {
		$self->insert($table, @_);
		1;
	}
}

# ---------------------------------
# METHOD: delete TABLE [CONDITIONS]
# ---------------------------------

=over 4

=item delete I<table> I<conditions>

  $dbi_interface -> delete ('components', "stock=0");

Deletes any row of I<table> which fulfill the I<conditions>. Without conditions
all rows are deleted. Returns the number of rows deleted.

=back

=cut

sub delete {
	my ($self, $table, $conditions) = @_;
	my $sth;

    if ($conditions) {
		$sth = $self -> process ("delete from $table where $conditions");
	} else {
		$sth = $self -> process ("delete from $table");
	}

	$sth -> rows();
}

# ----------------------------------------
# METHOD: do_without_transaction STATEMENT
# ----------------------------------------

=over 4

=item do_without_transaction I<statement>

  $sth = $dbi_interface -> do_without_transaction ("CREATE DATABASE foo");

  Issues a DBI do statement while forcing autocommit. This is used for
  statements that can't be run in transaction mode (like CREATE DATABASE
  in PostgreSQL).

=back

=cut

sub do_without_transaction {
	my ($self, $statement) = @_;
	my ($rv, $autocommit);

	return unless $self -> connect ();

	$autocommit = $self -> {CONN} -> {AutoCommit};

    # Force autocommit
    $self -> {CONN} -> {AutoCommit} = 1;

    $rv = $self -> {CONN} -> do ($statement);
	
    # Restore autocommit setting
    $self -> {CONN} -> {AutoCommit} = $autocommit;

    unless (defined $rv) {
		$self -> fatal ("Couldn't do statement \"$statement\"");
	}

	return $rv;
}

# -------------------------------
# METHOD: rows TABLE [CONDITIONS]
# -------------------------------

=over 4

=item rows I<table> [I<conditions>]

  $components = $dbi_interface -> rows ('components');
  $components_needed = $dbi_interface -> rows ('components', 'stock = 0');

Returns the number of rows within I<table> satisfying I<conditions> if any.

=back

=cut

sub rows
  {
	my $self = shift;
	my ($table, $conditions) = @_;
	my ($sth, $aref, $rows);
	my $where = '';
	
	if (defined ($conditions))
	  {
		$where = " WHERE $conditions";
	  }
	
	# use COUNT(*) if available
	if ($funcmap{$self -> {DRIVER}}->{COUNT})
	  {
		$sth = $self -> process ("SELECT COUNT(*) FROM $table$where");
		$aref = $sth->fetch;
		$rows = $$aref[0];
	  }
	else
	  {
		$sth = $self -> process ("SELECT * FROM $table$where");
		$rows = $sth -> rows;
	  }

	$rows;
  }

# -----------------------------------------------
# METHOD: makemap TABLE KEYCOL VALCOL [CONDITION]
# -----------------------------------------------

=over 4

=item makemap I<table> I<keycol> I<valcol> [I<condition>]

    $dbi_interface -> makemap ('components', 'idf', 'price');
    $dbi_interface -> makemap ('components', 'idf', 'price', 'price > 10');
    $dbi_interface -> makemap ('components', 'idf', '*');
    $dbi_interface -> makemap ('components', 'idf', '*', 'price > 10');

Produces a mapping between the values within column
I<keycol> and column I<valcol> from I<table>. If an
I<condition> is given, only rows matching this
I<condition> are used for the mapping.    

In order to get the hash reference to the record as value of the
mapping, use the asterisk as the I<valcol> parameter.

=back

=cut

sub makemap {
    my ($self, $table, $keycol, $valcol, $condition) = @_;
    my ($sth, $row, %map, $sel);
	my $condstring = '';

	# check for condition
	if ($condition) {
		$condstring = " WHERE $condition";
	}
	
	if ($valcol eq '*') {
		# need hash reference as value
		$sth = $self->process("SELECT * FROM $table$condstring");
		while ($row = $sth -> fetchrow_hashref) {
			$map{$row->{$keycol}} = $row;
		}
	} else {
        # need particular field as value
		$sth = $self -> process ("SELECT $keycol, $valcol FROM $table$condstring");
		while ($row = $sth -> fetch) {
			$map{$$row[0]} = $$row[1];
		}
	}
	
    \%map;
}

# -----------------------------------------
# METHOD: random_row TABLE CONDITIONS [MAP]
# -----------------------------------------

=over 4

=item random_row I<table> I<conditions> [I<map>]

Returns random row of the specified I<table>. If I<map> is set,
the result is a hash reference of the selected row, otherwise
an array reference. If the table doesn't contains rows, undefined
is returned.

=back

=cut
#'

sub random_row {
	my ($self, $table, $conditions, $map) = @_;
	my ($sth, $aref, $row);

	if ($conditions) {
		$sth = $self -> process ("select * from $table where $conditions");
	} else {
		$sth = $self -> process ("select * from $table");
	}
	
	cache ($table, 'NAME', $sth);
	
	$aref = $sth -> fetchall_arrayref ();
	if (@$aref) {
		$row = $aref->[int(rand(@$aref))];

		if ($map) {
			# pass back hash reference
			fold ([$self->columns($table)], $row);
		} else {
			# pass back array reference
			$row;
		}				   
	}
}

# -------------------------------  
# METHOD: serial TABLE SEQUENCE
# -------------------------------

=over 4

=item serial I<table> I<sequence>

Returns a serial number for I<table> by querying the next value from
I<sequence>. Depending on the DBMS one of the parameters is ignored.
This is I<sequence> for mSQL resp. I<table> for PostgreSQL. mysql
doesn't support sequences, but the AUTO_INCREMENT keyword for fields.
In this case this method returns 0 and mysql generates a serial
number for this field.

=back

=cut
#'

sub serial 
  {
	my $self = shift;
	my ($table, $sequence) = @_;
	my ($statement, $sth, $rv, $resref);
	
	return unless $self -> connect ();
    return ('0') if $self->{DRIVER} eq 'mysql';

	# get the appropriate statement
	$statement = &{$serialstatmap{$self->{DRIVER}}};

	# prepare and execute it
	$sth = $self -> process ($statement);

	unless (defined ($resref = $sth -> fetch))
	  {
		$self -> fatal ("Unexpected result for statement \"$statement\"");
	  }

	$$resref[0];
  }

# ---------------------------------------------------------
# METHOD: fill STH HASHREF [FLAG COLUMN ...]
#
# Fetches the next table row from the result stored in STH.
# ---------------------------------------------------------

=over 4

=item fill I<sth> I<hashref> [I<flag> I<column> ...]

Fetches the next table row from the result stored into I<sth>
and records the value of each field in I<hashref>. If I<flag>
is set, only the fields specified by the I<column> arguments are
considered, otherwise the fields specified by the I<column> arguments
are omitted.

=back

=cut

sub fill
  {
	my ($dbi_interface, $sth, $hashref, $flag, @columns) = @_;
	my ($fetchref);

	$fetchref = $sth -> fetchrow_hashref;
	if ($flag)
	  {
		foreach my $col (@columns)
		  {
			$$hashref{$col} = $$fetchref{$col};
		  }
	  }
	else
	  {
		foreach my $col (@columns)
		  {
			delete $$fetchref{$col};
		  }
		foreach my $col (keys %$fetchref)
		  {
			$$hashref{$col} = $$fetchref{$col};
		  }
	  }
  }

# ------------------------------------------------------
# METHOD: view TABLE
#
# Produces text representation for database table TABLE.
# ------------------------------------------------------

=over 4

=item view I<table> [I<name> I<value> ...]

  foreach my $table (sort $dbi_interface -> tables)
    {
    print $cgi -> h2 ('Contents of ', $cgi -> code ($table));
    print $dbi_interface -> view ($table);
    }

Produces plain text representation of the database table
I<table>. This method accepts the following options as I<name>/I<value>
pairs:

B<columns>: Which columns to display.

B<order>: Which column to sort the row after.

B<limit>: Maximum number of rows to display.

B<separator>: Separator inserted between the columns.

B<where>: Display only rows matching this condition.

  print $dbi_interface -> view ($table,
                                order => $cgi -> param ('order') || '',
                                where => "price > 0");

=back

=cut

sub view
  {
    my ($self, $table, %options) = @_;
    my ($view, $sth);
    my ($orderstr, $condstr) = ('', '');
	my (@fields);

    unless (exists $options{'limit'}) {$options{'limit'} = 0}
    unless (exists $options{'separator'}) {$options{'separator'} = "\t"}

    # anonymous function for cells in top row
    # get contents of the table
    if ((exists ($options{'order'}) && $options{'order'})) {
      $orderstr = " ORDER BY $options{'order'}";
    }
    if ((exists ($options{'where'}) && $options{'where'})) {
      $condstr = " WHERE $options{'where'}";
    }
	if ((exists ($options{'columns'}) && $options{'columns'})) {
	  $sth = $self -> process ('SELECT ' . $options{'columns'}
							   . " FROM $table$condstr$orderstr");
	} else {
      $sth = $self -> process ("SELECT * FROM $table$condstr$orderstr");
	}
    my $names = $sth -> {NAME};
    $view = join($options{'separator'}, map {$_} @$names) . "\n";
    my ($count, $ref);
    while($ref = $sth->fetch) {
      $count++;
	  undef @fields;
	  for (@$ref) {
		  if (defined $_) {
			  s/\n/\\n/sg;
              s/\t/\\t/g;
			  push (@fields, $_);
		  } else {
			  push (@fields, '');
		  }
	  }
      $view .= join($options{'separator'}, @fields) . "\n";
      last if $count == $options{'limit'};
    }
#    my $rows = $sth -> rows;
#    $view .="($rows rows)";
    $view;
  }

=head2 DATABASE INFORMATION

=over 4

=item is_table I<NAME>

Returns truth value if there exists a table I<NAME> in
this database.

=back

=cut

sub is_table {
    my ($self, $name) = @_;
    
    grep {$_ eq $name} ($self->tables);
}

=over 4

=item tables

Returns list of all tables in this database.

=back

=cut

sub tables {
	my $self = shift;
	my @t;
	
	if ($self->{DRIVER} eq 'mysql') {
        my $dbname = $self->{DATABASE};
        @t = map {s/^(`\Q$dbname\E`\.)?`(.*)`$/$2/; $_}
          ($self -> connect () -> tables ());
	} else {
		@t = $self -> connect () -> tables ();
	}
    return @t;
}

=over 4

=item sequences

Returns list of all sequences in this database (Postgres only).

=back

=cut

sub sequences {
    my $self = shift;
    my (@sequences, $sth, $row);

    if ($self->{DRIVER} eq 'Pg') {
        $sth = $self -> process ("SELECT relname FROM pg_class WHERE relkind = 'S'");
        while ($row = $sth -> fetch ()) {
            push (@sequences, $$row[0]);
        }
    }
    return @sequences;
}

# ------------------------------------------
# METHOD: columns TABLE
#
# Returns list of the column names of TABLE.
# ------------------------------------------

=over 4

=item columns I<TABLE>

Returns list of the column names of I<TABLE>.

=back

=cut

sub columns {
    my ($self, $table) = @_;
    my ($sth);
    my (@cols);

	if (@cols = cache($table, 'NAME')) {
		return @cols;
	}
    
    $sth = $self -> process ("SELECT * FROM $table WHERE 0 = 1");
	
	cache($table, 'NAME', $sth);
	
    @{$sth->{NAME}};
}

# -------------------
# METHOD: types TABLE
# -------------------

=over 4

=item types I<TABLE>

Returns list of the column types of I<TABLE>.

=back

=cut

sub types {
    my ($self, $table) = @_;

    $self->info_proc($table, 'TYPE');
}

# -------------------
# METHOD: sizes TABLE
# -------------------

=over 4

=item sizes I<TABLE>

Returns list of the column sizes of I<TABLE>.

=back

=cut

sub sizes {
    my ($self, $table) = @_;

    $self->info_proc ($table, 'PRECISION');
}

# ---------------------
# METHOD: typemap TABLE
# ---------------------

=over 4

=item typemap I<TABLE>

Returns mapping between column names and column types
for table I<TABLE>.

=back

=cut

sub typemap {
    my ($self, $table) = @_;

    $self->info_proc ($table, 'TYPE', 1);
}

# ---------------------
# METHOD: sizemap TABLE
# ---------------------

=over 4

=item sizemap I<TABLE>

Returns mapping between column names and column sizes
for table I<TABLE>.

=back

=cut    

sub sizemap {
    my ($self, $table) = @_;

    $self->info_proc ($table, 'PRECISION', 1);
}

# ---------------------------------------------------------------
# METHOD: add_columns
#
# Creates columns from a representation supplied by describe_table.
# ---------------------------------------------------------------

sub add_columns {
	my ($self, $table, $repref, @columns) = @_;
	my (%colref, $col, $cref, $null, $line, @stmts, $cmd);
	
	for $col (@columns) {
		$colref{$col} = 1;
	}

	for $cref (@{$repref->{columns}}) {
		next unless exists $colref{$cref->{Field}};
		$colref{$cref->{Field}} = $cref;
	}

	for $col (@columns) {
		$cref = $colref{$col};
		if ($cref->{Null} ne 'YES') {
			$null = ' NOT NULL ';
		} else {
			$null = '';
		}
		$line = qq{alter table $table add $cref->{Field} $cref->{Type}$null $cref->{Extra} default '$cref->{Default}'};
		push (@stmts, $line);
	}

	for $cmd (@stmts) {
		$self->process($cmd);
	}
}


# ---------------------------------------------------------------
# METHOD: create_table
#
# Creates table from a representation supplied by describe_table.
# ---------------------------------------------------------------

sub create_table {
	my ($self, $table, $repref) = @_;
	my $crtstr = '';
	my (@stmts, $line, $null, %icols, $colstr);
	
	for my $cref (@{$repref->{columns}}) {
		if ($cref->{Null} ne 'YES') {
			$null = ' NOT NULL ';
		} else {
			$null = '';
		}
		$line = qq{$cref->{Field} $cref->{Type}$null $cref->{Extra} default '$cref->{Default}'};
		push (@stmts, $line);
	}

	for my $cref (@{$repref->{indices}}) {
		push (@{$icols{$cref->{Key_name}}}, $cref->{Column_name});
	}

	for my $cref (@{$repref->{indices}}) {
		next unless exists $icols{$cref->{Key_name}};
		$colstr = join(', ', @{$icols{$cref->{Key_name}}});
		if ($cref->{Key_name} eq 'PRIMARY') {
			$line = qq{PRIMARY KEY ($colstr)};
		} else {
			$line = qq{KEY $cref->{Key_name} ($colstr)};
		}
		push (@stmts, $line);
		delete $icols{$cref->{Key_name}};
	}
	$crtstr = "create table $table (\n" . join(",\n", @stmts) . ")";
	$self->process($crtstr);
}

# ------------------------------------------
# METHOD: describe_table
#
# Returns representation of the given table.
# ------------------------------------------

sub describe_table {
	my ($self, $table) = @_;
	my ($sth, $href);
	my %rep = (columns => [], indices => []);
	
	$sth = $self->process("show columns from $table");
	while (my $href = $sth->fetchrow_hashref()) {
		push (@{$rep{columns}}, $href);
	}
	$sth->finish();
	
	$sth = $self->process("show index from $table");
	while (my $href = $sth->fetchrow_hashref()) {
		push (@{$rep{indices}}, $href);
	}
	$sth->finish();
	\%rep;
}

# --------------------------------------------
# METHOD: now
#
# Returns representation for the current time.
# --------------------------------------------

=head2 TIME VALUES

=over 4

=item now

  $dbi_interface -> insert ('transaction',
                   id => serial ('transaction', 'transactionid'),
                   time => \$dbi_interface -> now);

Returns representation for the current time. Uses special values of
the DBMS if possible.

=back

=cut

sub now
  {
	my $self = shift;

    # Postgres and mysql have an special value for the current time
	if ($self->{DRIVER} eq 'Pg'
		|| $self->{DRIVER} eq 'mysql') {
		return 'now()';
	}
	
    # determine current time by yourself
	scalar (gmtime ());
  }

# --------------------------------------------------
# METHOD: money2num MONEY
#
# Converts the monetary value MONEY (e.g. $10.00) to
# a numeric one.
# --------------------------------------------------

=head2 MONETARY VALUES

=over 4

=item money2num I<money>

Converts the monetary value I<money> to a numeric one.

=back

=cut

sub money2num
  {
	my ($self, $money) = @_;

	# strip leading dollar sign
	$money =~ s/\$//;
	# remove commas
	$money =~ s/,//g;
	# ignore empty pennies
	$money =~ s/\.00$//;
	
	$money;
  }

# METHOD: filter HANDLE FUNC [TABLE] OPT

my %filter_default_opts = (col_delim => "\t",
                           col_delim_rep => '\t',
                           prepend_key => undef,
                           row_delim => "\n",
                           row_delim_rep => '\n',
                           return => '',
                           prepend_row => undef);

sub filter {
	my ($self, $sth, $opt) = @_;
	my (@keys, $row, @ret);

    for (keys %filter_default_opts) {
        $opt->{$_} = $filter_default_opts{$_}
            unless defined $opt->{$_};
    }

    if ($opt->{prepend_key}) {
        @keys = @{$sth->{NAME}};
    }

	while ($row = $sth->fetch()) {
        if ($opt->{return} eq 'keys') {
            push(@ret, $row->[0]);
        }
        my @f;
        my $i = 0;
        for my $f (@$row) {
            $f = '' unless defined $f;
            $f =~ s/$opt->{row_delim}/$opt->{row_delim_rep}/g;
            $f =~ s/$opt->{col_delim}/$opt->{col_delim_rep}/g;
            if (defined $opt->{prepend_key}) {
                $f = $keys[$i++] . $opt->{prepend_key} . $f;
            }
            push(@f, $f);
        }
        if (defined $opt->{prepend_row}) {
            print $opt->{prepend_row};
        }
        print join($opt->{col_delim}, @f), $opt->{row_delim};
	}

	@ret;
}

# -----------------------------------------------------
# METHOD: is_auth_error MSG
# -----------------------------------------------------

=head2 MISCELLANEOUS

=over 4

=item is_auth_error I<msg>

This method decides if the error message I<msg>
is caused by an authentification error or not.

=back

=cut

sub is_auth_error {
	my ($self, $msg) = @_;

	if ($self->{DRIVER} eq 'mysql') {
		if ($msg =~ /^DBI\sconnect(\('database=.*?(;host=.*?)?',.*?\))? failed: Access denied for user\s/) {
			return 1;
		}
		if ($msg =~ /^DBI->connect(\(database=.*?(;host=.*?)?\))? failed: Access denied for user:/) {
			return 1;
		}
	} elsif ($self->{DRIVER} eq 'Pg') {
		if ($msg =~ /^DBI\sconnect(\('dbname=.*?(;host=.*?)?',.*?\))? failed:.+no password supplied/) {
			return 1;
		}
    
		if ($msg =~ /^DBI->connect failed.+no password supplied/) {
			return 1;
		}
	}
}

# ------------------------------------------
# METHOD: passwd
#
# Determines password for current user.
# This method is implemented only for Mysql,
# where we can look it up in ~/my.cnf.
# ------------------------------------------

sub passwd {
    my ($self) = shift;
    my $clientsec = 0;
    my ($mycnf, $option, $value);
    
    # implemented only for mysql
    return unless $self->{'DRIVER'} eq 'mysql';

	# makes sense only for the localhost
	return if $self->{'HOST'};
	
    # determine home directory
    if (exists $ENV{'HOME'} && $ENV{'HOME'} =~ /\S/ && -d $ENV{'HOME'}) {
        $mycnf = $ENV{'HOME'};
    } else {
        $mycnf = (getpwuid($>)) [7];
    }
    $mycnf .= '/.my.cnf';

    # just give up if file is not accessible
    open (CNF, $mycnf) || return;
    while (<CNF>) {
        # ignore comments and blank lines
        next if /^\#/ or /^;/;
        next unless /\S/;
        # section ?
        if (/\[(.*?)\]/) {
            if (lc($1) eq 'client') {
                $clientsec = 1;
            } else {
                $clientsec = 0;
            }
        } elsif ($clientsec) {
            # in the [client] section check for password option
            ($option, $value) = split (/=/, $_, 2);
            if ($option =~ /\s*password\s*/) {
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
                $self->{'PASS'} = $value;
                last;
            }
        }
    }
        
    close (CNF);
}

# install error handler
sub install_handler {$_[0] -> {'HANDLER'} = $_[1];}

# direct interface to DBI
sub prepare {my $self = shift; $self -> connect () -> prepare (@_);}
sub commit {my $self = shift; $self->connect (); return if $self->{CONN}->{AutoCommit}; $self->{CONN}->commit();}
sub rollback {$_[0] -> connect () -> rollback ();}
sub quote {$_[0] -> connect () -> quote ($_[1]);}

# auxiliary functions

# ----------------------------------------------------------------
# FUNCTION: cache TABLE TYPE [HANDLE]
#
# This function handles the internal caching of table informations
# like column names and types.
#
# If HANDLE is provided, the information will be fetched from
# HANDLE and stored cache, otherwise the information from the
# cache will be returned.
# ----------------------------------------------------------------

sub cache {
	my ($table, $type, $handle) = @_;
	my (@types);
	
    if ($cache_structs) {
		if ($handle) {
			$structs{$table}->{$type} = $handle->{$type};
		} else {
			if (exists $structs{$table} && exists $structs{$table}->{$type}) {
				return @{$structs{$table}->{$type}};
			}
		}
	}

	return;
}

# ----------------------------------------------
# FUNCTION: fold ARRAY1 ARRAY2
#
# Returns mapping between the elements of ARRAY1
# and the elements fo ARRAY2.
# ----------------------------------------------

sub fold {
    my ($array1, $array2) = @_;
    my (%hash);

    for (my $i = 0; $i < @$array1; $i++) {
        $hash{$$array1[$i]} = $$array2[$i];
    }
    \%hash;
}

# -----------------------------------------------
# METHOD: info_proc TABLE TOKEN [WANTHASH]
#
# Returns information about the columns of TABLE.
# TOKEN should be either NAME or PRECISION.
# -----------------------------------------------

sub info_proc {
    my ($self, $table, $token, $wanthash) = @_;
    my $sth;
    
    if ($cache_structs) {
        unless (exists $structs{$table}) {
            $sth = $self -> process ("SELECT * FROM $table WHERE 0 = 1");
            for ('NAME', 'PRECISION', 'TYPE') {
                $structs{$table}->{$_} = $sth->{$_};
            }
        }

        if ($wanthash) {
            fold ($structs{$table}->{NAME},
                  $structs{$table}->{$token});
        } else {
            @{$structs{$table}->{$token}};
        }
    } else {
        $sth = $self -> process ("SELECT * FROM $table WHERE 0 = 1");

        if ($wanthash) {
            fold ($sth->{NAME}, $sth->{PRECISION});
        } else {
            @{$sth->{$token}};
        }
    }
}

1;
__END__

=head1 AUTHORS

Stefan Hornburg (Racke), racke@linuxia.de
Dennis Sch\[:o]n, ds@1d10t.de

Support for Sybase and ODBC provided by
David B. Bitton <david@codenoevil.com>.

=head1 VERSION

0.20

=head1 SEE ALSO

perl(1), DBI(3), DBD::Pg(3), DBD::mysql(3), DBD::msql(3), DBD::Sybase(3), DBD::ODBC(3).

=cut
