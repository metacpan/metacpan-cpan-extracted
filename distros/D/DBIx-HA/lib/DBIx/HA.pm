# High Availability package for DBI
#
# Copyright (c) 2003-2006 Henri Asseily <henri@asseily.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

{
package DBIx::HA;

use 5.006000;

use constant DBIx_HA_DEBUG => $ENV{DBIX_HA_DEBUG} || 0;
use Data::Dumper;
use DBI 1.49 ();
use Sys::SigAction qw( set_sig_handler );
use Exporter ();
use strict;
use vars qw ( @ISA $prefix );
@ISA = qw ( DBI );

our $loaded_Apache = 0;
our $loaded_Apache_DBI = 0;
our $logdir;

BEGIN {
	$DBIx::HA::VERSION = 1.10;

	# Sample Fail Test Functions for different Database Servers
	# They are used in the configuration 
	# Input is ($ErrorID, $ErrorString)
	# Output is boolean: If true, then we'll consider the error a critical condition, ok to failover
	# If false, then DBIx::HA will not act on it and pass it straight through to the client
	sub FTF_SybaseASE { $_[0] > 10 ? 0 : 1 }; # Fail Test Function for Sybase ASE
}

our $prefix = "[$$] DBIx::HA:           "; 

sub initialize {
	if ($Apache::VERSION) {
		$loaded_Apache = 1;
	}
	if ($Apache::DBI::VERSION) {
		$loaded_Apache_DBI = 1;
	}
	if ($loaded_Apache_DBI) {
		$Apache::DBI::DEBUG = DBIx_HA_DEBUG;	# If we're debugging here, we should also debug Apache::DBI
	}
	if (DBIx_HA_DEBUG > 1) {
		warn "$prefix in initialize:\n";
		warn Dumper %DATABASE::conf;
	}
	my $dbname;
	foreach $dbname (keys %DATABASE::conf) {
		# set default failover to process (i.e. each process is independent from others
		# choices are : process, application
		if (! $DATABASE::conf{$dbname}->{'failoverlevel'}) {
			$DATABASE::conf{$dbname}->{'failoverlevel'} = 'process';
		}
		# add default timeouts for connection and execution
		if (! $DATABASE::conf{$dbname}->{'connecttimeout'}) {
			$DATABASE::conf{$dbname}->{'connecttimeout'} = 30;
		}
		if (! $DATABASE::conf{$dbname}->{'executetimeout'}) {
			$DATABASE::conf{$dbname}->{'executetimeout'} = 30;
		}
		# add default failover rule based on DBI error
		# default is to not request failover, whatever the error
		# do not ever set the default to always request failover, as any SQL error would trigger failover!
		if (! $DATABASE::conf{$dbname}->{'failtest_function'}) {
			$DATABASE::conf{$dbname}->{'failtest_function'} = sub { 0 };
		}
		$DATABASE::conf{$dbname}->{'end_of_stack'} = 0;	# error condition reaching end of stack
		for my $conn_aref (@{$DATABASE::conf{$dbname}->{'db_stack'}}) {
            my $dsn = $conn_aref->[0];
			# create an easy reverse-lookup table for finding the db server name from the dsn
			$DBIx::HA::finddbserver{$dsn}  = $dbname;
			# add timeout when within Apache::DBI
			# default to no ping (-1)
			if ($loaded_Apache_DBI) {
				if ($Apache::DBI::VERSION < 0.89) {
					die "$prefix Requirement unmet. Apache::DBI must be at version 0.89 or above";
				}
				# create a cached lookup table for finding the Apache::DBI cache key index from the dsn
				$DBIx::HA::ApacheDBIidx{$dsn}  = _getApacheDBIidx(@$conn_aref);
				Apache::DBI->setPingTimeOut($dsn, $DATABASE::conf{$dbname}->{'pingtimeout'} || -1);
			}
		};
		# set the active database to be the first in the stack
		_writesharedfile($dbname, 0) unless ($DATABASE::conf{$dbname}->{'active_db'});

		# hook up the child initialization routine
		if(Apache->can('push_handlers') && ($Apache::ServerStarting == 1)) {
			Apache->push_handlers(PerlChildInitHandler => \&_init_child);
		}
		# do not force a connection here
		# as we may be in the parent process. Connect in _init_child instead.
	};
}

sub _init_child {
	# Set up debugging PID for children
	$DBIx::HA::prefix = "[$$] DBIx::HA:           "; 
	$DBIx::HA::st::prefix = "[$$] DBIx::HA:st:        "; 
	$DBIx::HA::db::prefix = "[$$] DBIx::HA:db:        "; 
	if (DBIx_HA_DEBUG > 1) {
		warn "$prefix in init_child:\n";
	}
	my $dbname;
	foreach $dbname (keys %DATABASE::conf) {
		# under application failover, maybe we already have an active db.
		# set the active database to be the first in the stack unless we got it earlier.
		_readsharedfile($dbname);
		_writesharedfile($dbname, 0) unless ($DATABASE::conf{$dbname}->{'active_db'});

		# allow for connect on initialization
		if ($DATABASE::conf{$dbname}->{'connectoninit'} && $loaded_Apache_DBI) {
			warn "$prefix Connecting to $dbname on init_child\n" if (DBIx_HA_DEBUG);
			DBIx::HA->connect($dbname);
		}
	};
}


sub _readsharedfile {
	# reads from file-based shared memory to get active database under Apache
	my $dbname = shift;
	if ($DATABASE::conf{$dbname}->{'failoverlevel'} eq 'application') {
		# do this only if we're doing application failover and not process failover
		if ($loaded_Apache && (-f "$logdir/DBIxHA_activedb_$dbname")) {
			open IN, "$logdir/DBIxHA_activedb_$dbname";
			my $dbidx = <IN>;
			chomp $dbidx;
			close IN;
			if ($dbidx == -1) {	# we're told that we're at the end of the stack. No db server is available.
				$DATABASE::conf{$dbname}->{'end_of_stack'} = 1;
				return 0;
			}
			$DATABASE::conf{$dbname}->{'end_of_stack'} = 0;
			if (($dbidx =~ /^\d+$/o) && $DATABASE::conf{$dbname}->{'db_stack'}->[$dbidx]) {
				$DATABASE::conf{$dbname}->{'active_db'} = $DATABASE::conf{$dbname}->{'db_stack'}->[$dbidx];
				$DBIx::HA::activeserver{$dbname}  = $dbidx;
				unless ($Apache::ServerStarting == 1) {
					my $r = Apache->request;
					$r->notes("activedb_$dbname", $dbidx) if (ref $r);
				}
			} else {
				warn "$prefix in _readsharedfile: $dbname shared file has erroneous content, overwriting.\n";
				_writesharedfile($dbname, $DBIx::HA::activeserver{$dbname});
				return 0;
			}
		}
	}
	return 1;
}

sub _writesharedfile {
	my $dbname = shift;
	my $dbidx = shift;
	# updates the active handle
	# and writes to file-based shared memory for active database under Apache
	warn "$prefix in _writesharedfile: activating index $dbidx for database $dbname\n" if (DBIx_HA_DEBUG);
	$DATABASE::conf{$dbname}->{'active_db'} = $DATABASE::conf{$dbname}->{'db_stack'}->[$dbidx];
	$DBIx::HA::activeserver{$dbname}  = $dbidx;

	if ($DATABASE::conf{$dbname}->{'failoverlevel'} eq 'application') {
	# do this only if we're doing application failover and not process failover
		if ($loaded_Apache) {
			unless ($Apache::ServerStarting == 1) {
				my $r = Apache->request;
				$r->notes("activedb_$dbname", $dbidx) if (ref $r);
			}
			$logdir = Apache::server_root_relative(undef,'logs');
			open IN, ">/$logdir/DBIxHA_activedb_$dbname" || return 0;
			print IN $DBIx::HA::activeserver{$dbname};
			close IN;
			if ($Apache::ServerStarting == 1) {
				chmod 0666, "$logdir/DBIxHA_activedb_$dbname";
			}
		}
	}
	return 1;
}

sub _getdbname {
	# returns the db server name when given the dsn string
	my $dsn = shift;
	warn "$prefix in _getdbname: $DBIx::HA::finddbserver{$dsn} \n" if (DBIx_HA_DEBUG > 2);
	return $DBIx::HA::finddbserver{$dsn};
}

sub _isactivedb {
	# returns true if the db server in use is the one that should be active
	my $dsn = shift;
	my $dbname = _getdbname ($dsn);
	_readsharedfile($dbname);
	if ($DATABASE::conf{$dbname}->{'end_of_stack'}) {
		# we're not in the active db, because there is no active database, the end of stack is reached.
		return 0;
	}
	if ($dsn eq $DATABASE::conf{$dbname}->{'active_db'}->[0]) {
		warn "$prefix in _isactivedb: ".$dsn." is the active one \n" if (DBIx_HA_DEBUG > 2);
		return 1;
	}
	warn "$prefix in _isactivedb: ".$dsn." is NOT active \n" if (DBIx_HA_DEBUG > 2);
	$DATABASE::retries{$DATABASE::conf{$dbname}->{'active_db'}->[0]} = 0;	# reset the active db's retries for this process
	return 0;
}

sub _getnextdb {
	# returns the proper db server arrayref to use if the current one is dead
	my $dsn = shift;
	my $dbname = _getdbname ($dsn);
	if (_isactivedb ($dsn)) {
		# do this only if we are the first to look for a good db server
		# otherwise just return the active db server
		my $foundmatch = 0;
		my $idxnextdb = 0;
		my $stackcount = scalar(@{$DATABASE::conf{$dbname}->{'db_stack'}});
		foreach (@{$DATABASE::conf{$dbname}->{'db_stack'}}) {
			$idxnextdb++;
			if ($dsn eq $_->[0]) {
				# we got to the current db server in the stack
				# next db server in the stack is the correct one
				$foundmatch = 1;
				last;
			}
		}
		if (! $foundmatch) {	# didn't find a match, current dsn is invalid
			warn "$prefix in _getnextdb: current dsn is invalid for $dbname: $dsn \n" if (DBIx_HA_DEBUG);
			$idxnextdb = 0;
		} elsif ($idxnextdb > ($stackcount - 1)) {
			warn "$prefix in _getnextdb: Reached end of db server stack for $dbname. Staying there.\n" if (DBIx_HA_DEBUG);
			$DATABASE::conf{$dbname}->{'end_of_stack'} = 1;
			_writesharedfile($dbname, -1);
			return undef;
		}
		_writesharedfile($dbname, $idxnextdb);
		warn "$prefix in _getnextdb: activated ".$DATABASE::conf{$dbname}->{'active_db'}->[0]." \n" if (DBIx_HA_DEBUG);
	} elsif ($DATABASE::conf{$dbname}->{'end_of_stack'}) {
		return undef;
	} else {
		warn "$prefix in _getnextdb: found different active db server, switching to ".$DATABASE::conf{$dbname}->{'active_db'}->[0]."\n" if (DBIx_HA_DEBUG);
	}
	return $DATABASE::conf{$dbname}->{'active_db'}->[0];
}

sub _getApacheDBIidx {
	# generates the ApacheDBI cache idx key from the passed dsn info
	if (! $loaded_Apache_DBI) {
		# Apache::DBI isn't loaded, exit.
		return undef;
	}
	# first generate the same $idx key entry as ApacheDBI does
	my @args   = map { defined $_ ? $_ : "" } @_;
	if ($args[0] =~ /^dbi:/i) { $args[0] =~ s/^dbi:[^:]+://io; };	# remove the dbi:driver: piece
	my $idx = join $;, $args[0], $args[1], $args[2];

	if (3 == $#args and ref $args[3] eq "HASH") {
		map { $idx .= "$;$_=$args[3]->{$_}" } sort keys %{$args[3]};
	}
	warn "$prefix in getApacheDBIidx: generated idx: $idx , from dsn $args[0]\n" if (DBIx_HA_DEBUG > 1);
	return $idx;
}

sub _reconnect {
	my $currdsn = shift;
	my $dbh = shift || undef;
	my $olddsn = $currdsn;	# old dsn to delete from Apache::DBI
	my $conn_str;
	my $selrow;
	my $dbname = _getdbname ($currdsn);
	my $newdbh;
	my $i;

	if (! _isactivedb ($currdsn)) {	# wrong database server, use the active one
		$currdsn = _getnextdb ($currdsn);
	}
	if (! $currdsn) {
		warn "$prefix in _reconnect: No data source available, end of stack is reached. dbh is undefined. \n";
		eval { $dbh->disconnect if ((defined $dbh) && (ref $dbh)); undef $dbh; };
		return ($currdsn, undef);	# bad dbh and dsn
	}

	FINDDB: {
	my $dbstackindex = 0;	# pointer to position in the stack
	foreach $selrow (@{$DATABASE::conf{$dbname}->{'db_stack'}}) {	# loop through the stack
		if ($currdsn eq $selrow->[0]) {	# found the proper db server in the stack
			if ($loaded_Apache_DBI) { # delete the cached ApacheDBI entry
				my $ApacheDBIConnections = Apache::DBI::all_handlers();
				delete $$ApacheDBIConnections{$DBIx::HA::ApacheDBIidx{$olddsn}} if ($DBIx::HA::ApacheDBIidx{$olddsn});
				warn "$prefix in _reconnect: deleted cached ApacheDBI entry ".$DBIx::HA::ApacheDBIidx{$olddsn}."\n" if (DBIx_HA_DEBUG);
			}
			warn "$prefix in _reconnect: retrying ".$selrow->[0]."\n" if (DBIx_HA_DEBUG);
			$i=0;
			$DATABASE::retries{$currdsn} = 0 if (! $DATABASE::retries{$currdsn});
			for ($i=$DATABASE::retries{$currdsn}; $i < $DATABASE::conf{$dbname}->{'max_retries'}; $i++) {	# retry max_retries
				$DATABASE::retries{$currdsn}++;
				# now we're going to create a new good database handle and swap it with the old bad one
				$newdbh = _connect_with_timeout (@$selrow);
				if (defined $newdbh) {
					# we managed to create a new database handle
					if ((defined $dbh) && (ref $dbh)) {
						# the old one still exists, so we're going to swap it and then destroy it
						warn "$prefix in _reconnect: Pointing dbh to newdbh\n" if (DBIx_HA_DEBUG);
						$dbh->swap_inner_handle($newdbh);
						# wipe the old database handle (which in turn finishes all its children sth's)
						# If we're using DBD::Sybase, make sure syb_flush_finish is off so we don't get remaining results
                                                $newdbh->{syb_flush_finish} = 0 if $newdbh->{syb_flush_finish}
                                                    and $newdbh->{Driver}{Name} ne 'Gofer';
						eval { undef $newdbh; };
					} else {
						# there was no previous active database handle, so that's easy
						$dbh = $newdbh;
					}
					warn "$prefix Successfully reconnected to $currdsn\n";
					$DATABASE::retries{$currdsn} = 0; # reset the retries counter
					_writesharedfile($dbname, $dbstackindex);
					# Do callback if it exists
					if ( ref $DATABASE::conf{$dbname}->{'callback_function'}) {
						&{$DATABASE::conf{$dbname}->{'callback_function'}}($dbh, $dbname);
					}
					return ($currdsn, $dbh); 
				} #if
				warn "$prefix in _reconnect: failed ".($i+1)." times to connect to $currdsn\n" if (DBIx_HA_DEBUG > 1);
				select undef, undef, undef, 0.2; # wait a fraction of a second
			} #for
			# we found our db server in the stack, but couldn't connect to it
			# Get another one, and try again, assuming we've not exhausted the stack!
			$olddsn = $currdsn;			# remember the old one to delete it from Apache::DBI
			$currdsn = _getnextdb ($currdsn);	# go to next dsn
			if (! $currdsn) {			# we reached the end of the stack!
				warn "$prefix *** ERROR: Exhausted DBI failover stack. Last DSN is: $olddsn \n";
				return ($olddsn, undef);
			}
			warn "$prefix in _reconnect: dbstackindex: $dbstackindex; Trying another db server: $currdsn \n";
			goto FINDDB;
		} #if
		$dbstackindex++;
	} #foreach
	} # FINDDB
	warn "$prefix in _reconnect: Couldn't find a good data source, dbh is undefined. Pointing to $currdsn\n";
	return ($currdsn, undef);	# bad dbh! (multiple tries failed)
}

sub connect {
	warn "$prefix Apache::DBI handlers are: \n" if (DBIx_HA_DEBUG > 1);
	warn Dumper Apache::DBI::all_handlers() if (DBIx_HA_DEBUG > 1 && $loaded_Apache_DBI);
	my $class = shift;
	my $dbname = shift;
	my $conf = $DATABASE::conf{$dbname}
            or Carp::croak("No entry for '$dbname' in %DATABASE::conf");
	my $active_db = $conf->{'active_db'}
            or Carp::croak("No active_db for '$dbname' (did you call initialize?)");
	my ($dsn, $username, $auth, $attrs) = @$active_db;

	# Update the active db. If it's been updated, switch to it
	if (! _isactivedb($dsn)) {
		($dsn, $username, $auth, $attrs) = @{$DATABASE::conf{$dbname}->{'active_db'}};
		warn "$prefix in connect: switching to active db $dsn" if (DBIx_HA_DEBUG);
	}

	# now we've got the right data source. Go ahead.
	$DATABASE::retries{$dsn} = 0;	# initialize # of retries for the dsn
	my $dbh = _connect_with_timeout($dsn, $username, $auth, $attrs);
	if (defined $dbh) {
		warn "$prefix in connect: first try worked for $dsn\n" if (DBIx_HA_DEBUG);
	} else {
		warn "$prefix in connect: retrying connect of $dsn\n" if (DBIx_HA_DEBUG);
		($dsn, $dbh) = _reconnect ($dsn, $dbh);
	}
	return $dbh;
}

sub _connect_with_timeout {
	my ($dsn, $username, $auth, $attrs) = @_;
	warn "$prefix in _connect_with_timeout: dsn: $dsn \n" if (DBIx_HA_DEBUG > 1);
	my $res;
	my $dbh;
	my $timeout = 0;
	eval {
		no strict;
		my $h = set_sig_handler(
			'ALRM', 
			sub { $timeout = 1; die 'TIMEOUT'; },
			{ mask=>['ALRM'], safe=>1 }
		);
		alarm($DATABASE::conf{_getdbname($dsn)}->{'connecttimeout'});
		$dbh = DBI->connect($dsn, $username, $auth, $attrs);
		alarm(0);
	};
	alarm(0);
	if ($@ or $timeout) {	# there's a problem above
		if ($timeout) {	# it's a timeout
			warn "$prefix *** CONNECT TIMED OUT in $dsn";
			eval { $dbh->disconnect };
			$dbh = undef;
		} else {	# problem in the connection
			warn "$prefix Error in DBI::connect: $@\n" if $@;
		}
	}
        $dbh->{private_dbixha_dsn} = $dsn if $dbh;
	return $dbh;
}
} # end package DBIx::HA

{
package DBIx::HA::db;
use strict;
use constant DBIx_HA_DEBUG => DBIx::HA::DBIx_HA_DEBUG;
use vars qw ( @ISA );
@ISA = qw(DBI::db DBIx::HA);
our $prefix = "[$$] DBIx::HA:db:        "; 

# note that the DBI::db methods do not fail if the database connection is dead
sub prepare {
	my $dbh = shift;
	my $sql = shift;
	my $sth;
	my $dsn = $dbh->{private_dbixha_dsn} || die "panic: no private_dbixha_dsn";
	warn "$prefix in prepare: dsn: $dsn ; sql: $sql \n" if (DBIx_HA_DEBUG > 1);
	if (DBIx::HA::_isactivedb ($dsn)) {
		warn join "\n", "$prefix Statement handle being prepared while existing statement handle still open!",
                        "\tdbh:\t\t$dsn",
                        "\tprevious statement:\t".$dbh->{Statement},
                        "\tcurrent statement:\t$sql",
                        "\tACTIVE KIDS: ".$dbh->{ActiveKids}."\n"
                    if $dbh->{ActiveKids};
	} else {
		my $dbname = DBIx::HA::_getdbname($dsn);
		($dsn, $dbh) = DBIx::HA::_reconnect ($dsn, $dbh);
		if (! defined $dbh) { # we couldn't connect at all
			warn "$prefix in prepare: couldn't prepare sql: $sql\n";
			return undef;
		}
	}
	$sth = $dbh->SUPER::prepare($sql,@_);
	return $sth;
}
	
} # end package DBIx::HA::db

{
package DBIx::HA::st;
use strict;
use constant DBIx_HA_DEBUG => DBIx::HA::DBIx_HA_DEBUG;
use Sys::SigAction qw( set_sig_handler );
use vars qw ( @ISA $prefix );
@ISA = qw(DBI::st DBIx::HA);
our $prefix = "[$$] DBIx::HA:st:        "; 

sub execute {
	my $sth = shift;
	my $dbh = $sth->{Database};
	my $sql = $dbh->{Statement};
	my $dsn = $dbh->{private_dbixha_dsn} || die "panic: no private_dbixha_dsn";
	my $dbname = DBIx::HA::_getdbname($dsn);
	my $res;
	my $to;	# did we trip a timeout on the execution?
	my $orig_error_code;
	my $orig_error_string;
	my $max_executions = $DATABASE::conf{$dbname}->{'max_retries'} * scalar(@{$DATABASE::conf{$dbname}->{'db_stack'}});

	warn "=================\n" if (DBIx_HA_DEBUG > 1);
	warn "$prefix in execute: dsn: $dsn ; sql: $sql \n" if (DBIx_HA_DEBUG > 1);
	if (DBIx::HA::_isactivedb ($dsn)) {
		($res, $to) = &_execute_with_timeout ($dsn, $sth);
		$orig_error_code = $DBI::err;
		$orig_error_string = $DBI::errstr;
		if ($to || ((! defined $res) && &{$DATABASE::conf{$dbname}->{'failtest_function'}}($orig_error_code, $orig_error_string))) {
			# It was a timeout error or a critical network library error (connection in a bad state)
			warn "$prefix in execute: timeout error or network lib error, reexecuting: $sql ; dsn: $dsn \n" if (DBIx_HA_DEBUG);
			for (my $count_execs = 0; $count_execs < $max_executions; $count_execs++) {
				($dsn, $sth, $res) = _reexecute ($dsn, $sql, $sth);
				last if (defined $res); # reexecution worked (or failed hard with -666)
			} 
		} elsif (! defined $res) {
			# We got an error code from the server upon statement execution.
			# We will let the client decide what to do and let it be.
			warn "$prefix *** ERROR: $orig_error_code; $orig_error_string \n" if (DBIx_HA_DEBUG);
			warn "$prefix in execute: bad sql: $sql ; dsn: $dsn \n" if (DBIx_HA_DEBUG);
		}
	} else { # current db is not active
		for (my $count_execs = 0; $count_execs < $max_executions; $count_execs++) {
			($dsn, $sth, $res) = _reexecute ($dsn, $sql, $sth);
			last if (defined $res); # reexecution worked (or failed hard with -666)
		}
	}
	if (! defined $res) { # Execution failed
		warn "$prefix in execute: result is undefined, statement execution failed! statement: $sql ; dsn: $dsn \n" if (DBIx_HA_DEBUG);
		warn "+++++++++++++++++\n" if (DBIx_HA_DEBUG > 1);
		return undef;
	}
	if ($res == -666) { # the devil killed you! We couldn't connect to the db!
		warn "$prefix in execute: statement couldn't be executed because connect failed abnormally. statement: $sql ; dsn: $dsn \n";
		warn "+++++++++++++++++\n" if (DBIx_HA_DEBUG > 1);
		return undef;
	}
	warn "$prefix in execute: statement executed successfully! statement: $sql ; dsn: $dsn \n" if (DBIx_HA_DEBUG);
	warn "$prefix in execute: res: $res ; errstr: $DBI::errstr \n" if (DBIx_HA_DEBUG);
	$DATABASE::retries{$dsn} = 0;	# flush the retries to this dsn, since executing worked
	undef $@; # don't make an upstream eval die because of what happened here, since we're fine now
	warn "+++++++++++++++++\n" if (DBIx_HA_DEBUG > 1);
	return $res;
}

=begin private

=head2

 ($execute_result,$timeout_triggered) = _execute_with_timeout($dsn,$sth);

Calls "execute" on a DBI statement handle, and handles a possible timeout of the query.

Args:
 $dsn: a key in our internal lookup table of connection details
 $sth: DBI statement handle

Returns:
  - result of execute() call 
  - boolean, true if timeout was triggered. 
    

=end private

=cut


sub _execute_with_timeout {
	my $dsn = shift;
	my $sth = shift;
	my $sql = $sth->{Statement};
	warn "$prefix in _execute_with_timeout: dsn: $dsn ; sql : $sql \n" if (DBIx_HA_DEBUG > 1);
	my $res;
	my $timeout = 0;
	eval {
		my $h = set_sig_handler(
			'ALRM',
			sub { $timeout = 1; die 'TIMEOUT'; },
			{ mask=>['ALRM'],
			safe=>1 }
		);
		alarm($DATABASE::conf{DBIx::HA::_getdbname($dsn)}->{'executetimeout'});
		$res = $sth->SUPER::execute;
		alarm(0);
	};
	alarm(0);
	if ($@ or $timeout) {	# there's a problem above
		if ($timeout) {	# it's a timeout
			warn "$prefix *** EXECUTION TIMED OUT in $dsn ; SQL: $sql";
		} else {	# problem in the execution
			warn "$prefix Error in DBI::execute: $@\n" if $@;
		}
		eval { $sth->finish; };
		$sth = undef;
		$res = undef;
	}
	return ($res, $timeout);
}

sub _reexecute {
	# reexecute the statement in the following way:
	# reconnect with a new dbh
	# redo prepare and execute until it works
	my $dsn = shift;
	my $sql = shift;
	my $sth = shift || undef;
	my $dbh = undef;
	my $newsth;
	my $res;
	my $to;

	warn "$prefix in _reexecute: dsn: $dsn \n" if (DBIx_HA_DEBUG > 1);
	warn "$prefix Reexecuting statement: $sql" if (DBIx_HA_DEBUG > 1);
	if (defined $sth) {
		$dbh = $sth->{Database};
	}
	($dsn, $dbh) = DBIx::HA::_reconnect ($dsn, $dbh);
	if (! defined $dbh) { return ($dsn, $sth, -666); } # we couldn't connect at all
	$newsth = $dbh->prepare($sql);
	($res, $to) = &_execute_with_timeout ($dsn, $newsth);
	if (! $res) {	# execute_with_timeout failed
		warn "$prefix in _reexecute: reexecuting failed. dsn: $dsn  ; statement: $sql\n" if (DBIx_HA_DEBUG);
		eval { $sth->finish; };
		return ($dsn, $sth, undef);
	}
	if (defined $sth) {
		$sth->swap_inner_handle($newsth, 1);	# allow reparenting of the statement handle
		eval { $newsth->finish; };
		undef $newsth;
	} else {
		$sth = $newsth;
	}
	return ($dsn, $sth, $res);
}

} # end package DBIx::HA::st

1;

__END__

=head1 NAME

DBIx::HA - High Availability package for DBI

=head1 SYNOPSIS

 use DBIx::HA;

 $connect_attributes = {
         syb_flush_finish => 1,
         AutoCommit => 1,
         ChopBlanks => 1,
         PrintError => 0,
         RaiseError => 0,
         RootClass  => 'DBIx::HA'
         };

 $DATABASE::conf{'test'} = {
    max_retries => 2,
    db_stack => [
        [ 'dbi:Sybase:server=prod1;database=test', 'user1', 'password1', $connect_attributes ],
        [ 'dbi:Sybase:server=prod2;database=test', 'user2', 'password2', $connect_attributes ],
        [ 'dbi:Sybase:server=prod3;database=test', 'user3', 'password3', $connect_attributes ],
        ],
    connectoninit   => 0,
    pingtimeout     => -1,
    failoverlevel   => 'application',
    connecttimeout  => 1,
    executetimeout  => 8,
    callback_function => \&MyCallbackFunction,
	failtest_function   => \&DBIx::HA::FTF_SybaseASE,
    };

 DBIx::HA->initialize();
 $dbh = DBIx::HA->connect('test');
    
 $sth = $dbh->prepare($statement);
 $rv = $sth->execute;

=head1 DESCRIPTION

C<DBIx::HA> is a High Availability module for C<DBI>. It is implemented by
overloading the DBI C<connect>, C<prepare> and C<execute> methods and can
be seamlessly used without code modification except for initialization.

C<DBIx::HA> also works seamlessly with C<Apache::DBI> when available, and
ensures that cached database handles in the Apache::DBI module are properly
updated when failing over.

Features of C<DBIx::HA> are:

=over 4

=item multiple failovers

Should a datasource become unavailable, queries are automatically sent to
the next available datasource in a user-configured datasource stack.
All subsequent queries continue to hit the failover server until
reinitialized. This ensures that a failed datasource can be properly brought
back online before it is put back in service.

=item timeouts

Database calls are wrapped in user-configurable timeouts. Connect and execute
timeouts are handled independently. As of version 0.62, timeouts are 
handled through Sys::SigAction for consistent signal handling behavior across
Perl versions.

=item configurable retries

Queries can be retried n times before a datasource is considered failed.
Starting with version 0.95, the retry counter is reset whenever a reconnect
works.

=item callback function

A user-defined callback function can be called upon abnormal failure and
disconnection from a datasource in order to clean locally cached handles and
perform other housekeeping tasks.

=item inter-process automatic failover under mod_perl

Failover can be triggered for a single process or a set of processes at the
application level. Specifically designed for Apache's multi-process model,
if one mod_perl process triggers a failover, it is propagated to all other
mod_perl processes using the same database handle.

=back

C<DBIx::HA> was designed primarily for reliability and speed. Functionality
that would compromise speed was not considered. This module has been tested
extensively at very high loads in the Apache/mod_perl/Sybase environment.

=head1 CONFIGURATION

The hash I<%DATABASE::conf> is currently the configuration repository for
C<DBIx::HA>. It must be manually and directly populated by the user prior
to initialization and usage of C<DBIx::HA>.

Each key of I<%DATABASE::conf> is the name of a virtual database handle.
The corresponding value is a hashref with the following keys:

=over 4

=item db_stack REQUIRED

db_stack is an arrayref of arrayrefs. Each entry is of the format:

[ $dsn, $username, $password, \%connection_attributes ]

See the C<DBI> documentation for more information.
The order of the db_stack entries is very important. It determines the
order by which each dsn will be tried upon triggering a failover. The
first entry is the main dsn that will be used at start.

=item max_retries REQUIRED

max_retries takes an integer > 0 as value. It determines the number of times
a datasource will be consecutively retried upon failure. It B<is reset> upon
success of a retry. This is a change in behavior starting in version 0.95.
For example, if max_retries is 3, if datasource #1 can't be reached three
times in a row then I<_reconnect()> will reset the number of tries and go to
datasource #2 if available.

=item connectoninit ( DEFAULT: 0 )

If set to 1 and L<Apache::DBI> has already been loaded, then during the
I<initialize()> phase database connections will be opened with the
currently active db_stack entry.  This is very useful under mod_perl and
replaces the purpose of the C<Apache::DBI> I<connect_on_init()> method. 

=item pingtimeout ( DEFAULT: -1 )

This configures the usage of the ping method, to validate a connection.  The
option is only checked if L<Apache::DBI> has already been loaded. The default
of -1 disables pinging the datasource. It is recommended not to modify it. See
C<Apache::DBI> for more information on ping timeouts. Timeout is in seconds.

=item failoverlevel ( DEFAULT: process )

I<failoverlevel> determines whether a process will notify its sisters when fails
over to another datasource. 

=over 4

=item process

no notification is made, and each process independently manages its datasource
availability. Within a mod_perl environment, this means that each Apache process
could be potentially hitting a different physical database server.

=item application

A file-based interprocess communication is used to notify Apache/mod_perl
processes of the currently active datasource. This allows all processes to fail
over near-simultaneously. A process in the middle of an I<execute> will do it
on the next call to I<prepare> or I<execute>. This is only available under
mod_perl. It only has an effect if we detect that mod_perl is in effect, by
checking that C<$Apache::VERSION> has a value.

=back

=item connecttimeout ( DEFAULT: 30 )

Timeout for connecting to a datasource, in seconds. A value of 0 disables this timeout.

=item executetimeout ( DEFAULT: 30 )

Timeout for execution of a statement, in seconds. If the timeout is triggered,
the database handle is deleted and a new connect is tried. If the connect
succeeds, we assume that the problem is with a runaway SQL statement or bad
indexing. If the connect fails, then we fail over. A value of 0 disables this timeout.

=item callback_function ( DEFAULT: I<none> )

reference to a function to call whenever the datasource is changed due to a
failover. See the TIPS sections for a usage example.

=item failtest_function ( DEFAULT: sub{0} )

Reference to a function to call to test if a DBI error is a candidate for
failover or not. This is only triggered when a call to C<execute()> returns
an undefined value.

Input is ($DBI::err, $DBI::errstr). These correspond to the native driver error
code and string values. See the docs for your database driver and L<DBI> for
details.

Output is boolean: If true, then we'll consider the error a critical
condition, ok to failover. If false, then DBIx::HA will not act on it
and pass it straight through to the client.

This Fail Test Function (FTF) function is extremely important for the proper
functioning of DBIx::HA. You must be careful  in defining it
precisely, based on the database engine that you are using. A sample
function for Sybase is included:

  failtest_function   => \&DBIx::HA::FTF_SybaseASE,

To consider any error a reason to failover, you could use the following:

  failtest_function   => sub {1},

=back

=head1 USER METHODS

These methods provide a user interface to C<DBIx::HA>.

=over 4

=item initialize ()

This method is called as a static method after database configuration is
done.
At this point, database configuration resides in the I<%DATABASE::conf> hash
that needs to be properly populated. Later revisions of C<DBIx::HA> will
allow the passing of a reference to any configuration hash to I<initialize>.

See a sample %DATABASE::conf in the SYNOPSIS section. That section creates
an entry for the 'test' HA database handle, which is comprised of 3 physical
database handles (prod1, prod2, prod3). 'prod1' is the main handle, while the
other 2 are backup handles.

Add other HA database handles by creating more entries in I<%DATABASE::conf>. 

=item connect ( $dbname )

Static method to connect to the HA handle 'dbname'. There must be a valid
entry for $DATABASE::conf{'dbname'}.
Returns a standard DBI database handle.

=item prepare ( $dbh, $sql )

Overload of I<DBI::prepare()>, with the same inputs and outputs.

=item execute ()

Overload of I<DBI::execute()>, with the same inputs and outputs.

=back

=head1 CLASS METHODS

These private methods are not intended to be called by the user, but are
listed here for reference.

=over 4

=item _init_child ()

=item _readsharedfile ( $dbname )

=item _writesharedfile ( $dbname, $dbstackindex )

=item _getdbname ( $dsn )

=item _isactivedb ( $dsn )

=item _getnextdb ( $dsn )

=item _getApacheDBIidx ()

=item _reconnect ( $dsn, [ $dbh ] )

=item _connect_with_timeout ( $dsn, $username, $auth, \%attrs )

=item _reprepare ( $dsn, $sql )

=item _prepare_with_timeout ( $dsn, $dbh, $sql )

=item _reexecute ( $dsn, $sql, [ $sth ] )

=item _execute_with_timeout ( $dsn, $sth )

=back

=head1 TIPS AND TECHNIQUES

=over 4

=item load-balancing across read-only servers

It is very simple to load-balance across read-only database servers.
Simply randomize or reorder the 'db_stack' entry in your database
configuration on a per-process basis. This will make each process have
its own set of primary and backup servers.
Obviously you should never do that on a read-write environment with hot
spares as you will be writing to the hot spares without writing to the
primary server. Consider C<DBD::Multiplex> for such an application.

=item manually setting the active datasource without downtime

Under mod_perl you can flip all Apache processes to a specific datasource
by simply modifying the file B<DBIxHA_activedb_$dbname> located in the /log
directory in your Apache installation. Assuming that you are using
B<failoverlevel 'application'>, all processes will switch to the datasource you
define in that file as soon as they are ready to prepare or execute a statement.

Another trick is to set the value in the shared file to -1. This will tell the
module that we've reached the end of the stack and no connection should be
attempted, effectively blocking all database calls.

Conversely, if the shared file does contain -1 because all DSNs in the stack
have failed, you can reset it to whatever DSN entry you want without having to
bounce Apache.

=back

=head1 DEPENDENCIES

This modules requires Perl >= 5.6.0, DBI >= 1.49  and Sys::SigAction.

Apache::DBI is recommended when using mod_perl.  If using Apache::DBI, version 0.89 or above is required.
Always load Apache::DBI and Apache before DBIx::HA if you want DBIx::HA to know of them.

If using PostgreSQL, use DBD::Pg 2.0 or newer. Older versions of DBD::Pg contain a bug
which make it incompatible with this module. 

=head1 BUGS

Currently I<%DATABASE::conf> needs to be manually and directly populated.
A proper interface needs to be built for it.

=head1 URLS

The DBIx::HA project is hosted in Google Code:
  http://code.google.com/p/perl-dbix-ha/

Please submit bug reports or feature improvements requests to the site above.

The svn repository is also at:
  https://perl-dbix-ha.googlecode.com/svn/

=head1 SEE ALSO

C<DBD::Multiplex> for simultaneous writes to multiple data sources.

C<Apache::DBI> for ping timeouts and caching of database handles.

C<Sys::SigAction> for safe signal handling, particularly with DBI.

=head1 AUTHOR

Henri Asseily <henri@asseily.com>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Henri Asseily <henri@asseily.com>.
All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=for html <hr>


=cut


