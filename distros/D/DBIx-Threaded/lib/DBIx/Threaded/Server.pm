#
# Copyright (c) 2005, Presicient Corp., USA
#	Portions derived from DBI 1.48, Copyright (c) 1994-2004 Tim Bunce, Ireland
#	Inspired by the Pots::* set of modules by Remy...
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

require 5.008_003;

our $VERSION = 0.10;

package DBIx::Threaded::Server;

use Carp;
use DBI;
use DBIx::Threaded;
use threads;
use threads::shared;
use Storable qw(freeze thaw);

use strict;
use warnings;
#
#	when set, use storable to marshal
#
our $_marshalled;

our @_trace : shared = (0, '');

my %simple_rpc = qw(
func 1
parse_trace_flag 1
parse_trace_flags 1
private_data 1
trace 1
get_info 1

db_do 1
db_ping 1
db_begin_work 1
db_commit 1
db_rollback 1
db_rows 1
db_quote 1
db_quote_identifier 1
db_last_insert_id 1
db_selectrow_array 1
db_selectrow_arrayref 1
db_selectrow_hashref 1
db_selectall_arrayref 1
db_selectall_hashref 1
db_selectcol_arrayref 1

db_st_selectrow_array 3
db_st_selectrow_arrayref 3
db_st_selectrow_hashref 3
db_st_selectall_arrayref 3
db_st_selectall_hashref 3
db_st_selectcol_arrayref 3

db_primary_key 1
db_type_info_all 1
db_type_info 1
db_data_sources 1

st_fetchrow 2
st_fetchrow_arrayref 2
st_fetchrow_hashref 2
st_fetchall_arrayref 2
st_fetchall_hashref 2

st_rows 1
st_blob_read 1
st_blob_copy_to_file 1

db_start_do 1
db_start_selectrow_array 1
db_start_selectrow_arrayref 1
db_start_selectrow_hashref 1
db_start_selectall_arrayref 1
db_start_selectall_hashref 1
db_start_selectcol_arrayref 1

db_start_st_selectrow_array 3
db_start_st_selectrow_arrayref 3
db_start_st_selectrow_hashref 3
db_start_st_selectall_arrayref 3
db_start_st_selectall_hashref 3
db_start_st_selectcol_arrayref 3

db_start_primary_key 1

st_start_blob_read 1
st_start_blob_copy_to_file 1
);

sub new {
	my $class = shift;
	my $cmdq = shift;
#
#	create a thread; this is called on context of the
#	client thread
#
	my $obj = { _cmdq => $cmdq };
	bless $obj, $class;
	my $thread = threads->create(\&run, $obj);
	$obj->{_thread} = $thread->tid();
#	$thread->detach;	# we don't care anymore...
#print "started a thread\n";
	return $cmdq->wait_for_listener() ? $obj : undef;
}
#
#	curse (unbless) us into a shared structure
#	for storing in shared objects,
#	or passing between threads
#
sub curse {
	my $obj = shift;
	my %cursed : shared = (
		_cmdq => $obj->{_cmdq}->curse,
		_thread => $obj->{_thread} 
	);
	return \%cursed;
}
#
#	redeem (rebless) to recover us after
#	we've been stored in a shared object or passed
#	between threads
#
sub redeem {
	my ($class, $obj) = @_;
	return bless {
		_thread => $obj->{_thread},
		_cmdq => Thread::Queue::Duplex->redeem($obj->{_cmdq})
	}, $class;
}

sub get_queue { return shift->{_cmdq}; }

sub tid { return shift->{_thread}; }

sub trace {
	@_trace = @_;
	return 1;
}

#
#	start is equivalent to connect()
#	NOTE: do we need connect_cached ???
#
sub start {
	my ($obj, $marshal, $dsn, $user, $pass, $attrs) = @_;
#
#	input param list is
#	- marshal type (scalar string)
#	- DSN (scalar string)
#	- userid (scalar)
#	- password (scalar)
#	- attributes hashref, including any chained subclass
#
#	need to copy attributes to a shared hash
#
	if ($attrs) {
		my %attrs : shared = ( %{$attrs} );
		$attrs = \%attrs;
	}
	my @params : shared = ($marshal, $dsn, $user, $pass, $attrs, undef, 'connect');
	my $id = $obj->{_cmdq}->enqueue(\@params);
	return undef unless $id;
	my $results = $obj->{_cmdq}->wait($id);
#
#	unmarshal
#
	$results = (ref $results->[0]) ? $results->[0] :
		thaw $results->[0];
#
#	return error info if we failed
#
	return $results
		if $results->[1];
#
#	else just return our object
#
	return $obj;
}

sub stop {
	my $obj = shift;
#
#	may need a more forceful method here to kill
#	a runaway thread...
#
#print "stopping a thread\n";
	$obj->{_cmdq}->enqueue_simplex('STOP');
	threads->object($obj->{_thread})->join();
	delete $obj->{_cmdq};
	delete $obj->{_thread};
	return $obj;
}

sub run {
	my $obj = shift;

	my $cmdq = $obj->{_cmdq};
	$cmdq->listen();
	my $dbh;
	my $dbhrefcnt = 0;	# track ref count
	my %sths = ();		# track each sth
	my %sthrefs = ();	# track ref count of each sth
	my $helper;			# helper module object
	my $helperclass;	# and its class
	my @params = ();
	my @results = ();
#
#	freshen our object (for freeing purposes
#
	$obj->{_thread} = threads->self->tid();

	while (1) {
#
#	wait for connect request before general processing
#
		my $cmd = $cmdq->dequeue();
		my $id = shift @$cmd;
#
#	always check for trace event
#
		DBI->trace(@_trace)
			if $_trace[0];

		my $op = pop @$cmd;
#
#	unmarshall the params
#
		if (ref $op) {
			$cmd = $op;
			$op = pop @$cmd;
		}
		elsif ($op ne 'STOP') {
#print STDERR "run: $op\n";
#
#	must be frozen, thaw it
#
			$cmd = thaw $op;
			$op = pop @$cmd;
#print STDERR "run: thawed $op\n";
		}
#
#	on stop, we'll drop everything (stmts and connection)
#	whoevers on the other end of our cmdq better know
#	not to queue anything else up
#	and we should probably cancel everything already in the
#	queue ?
#	maybe TQD needs a close() method ?
#
#		$obj->_respond($id, undef, undef, undef, undef, 1),
		return 1
			if ($op eq 'STOP');

		my $stmtid = pop @$cmd;
#
#	destroys may occur after we've already cleaned up
#
		$obj->_respond($id, $op, undef, undef, undef, 1),
		next
			if ($id &&
				(substr($op, 3) eq 'DESTROY') &&
				(! $dbh));

		$obj->_respond($id, $op, -1, 
			"Unexpected $op request: must be connected to do that.", 'S1000'),
		next
			unless ($dbh || ($op eq 'connect'));
#
#	if a start op and we don't have helper, or
#	helper doesn't implement the op, adjust
#
		$op=~s/^(db|st)_start(_.+)$/$1$2/
			unless $helper &&
				$helper->can(substr($op, 3));

		if ($op eq 'connect') {
#
#	if we get a connection request when still connected,
#	something is horribly wrong...
#
			$obj->_respond($id, $op, -1, 
				'Unexpected connection request: already connected.', 'S1000'),
			next
				if $dbh;
#
#	get our marshalling discipline
#
			$obj->{_marshal} = shift @$cmd;
#
#	rest of @cmd is connect() params, including any chained subclass
#
			$obj->{_nextStmtId} = 1;
			@$cmd = @$cmd[0..3];
			$dbh = DBI->connect(@$cmd);
#
#	if helper defined, create it
#
			$helperclass = $cmd->[3]->{dbix_threaded_helper}
				if ($cmd->[3] && (ref $cmd->[3] eq 'HASH'));
			$helper = ${helperclass}->new($dbh)
				if ($helperclass && $dbh);
#
#	make sure to capture warnings...
#
			$obj->_respond($id, $op, $DBI::err, $DBI::errstr, $DBI::state, ($dbh ? 1 : undef));
			next;
		}	# end if connect

		@params = @$cmd;
		
		my $method = substr($op, 3);
 		my $sth;
		if (substr($op, 0, 3) eq 'st_') {
	 		$sth = $sths{$stmtid};
	 		$obj->_respond($id, $op, -1, 'Unknown statement.', 'S1000'),
	 		next
	 			unless $sth;
	 	}
		my $h = (substr($op, 0, 3) eq 'db_') ? $dbh :
			(substr($op, 0, 3) eq 'st_') ? $sth : $dbh->{Driver};
		my $bindings;
#
#	common methods
#
		$h->{$params[0]} = $params[1],
 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, 1),
 		next
		 	if ($method eq 'STORE');
#
#	may need to marshal here...
#
 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, 
 			$h->{$params[0]}),
 		next
	 		if ($method eq 'FETCH');

	 	if ($simple_rpc{$op} || $simple_rpc{$method}) {
#
#	bind type info if needed
#
 			my $cols = ($simple_rpc{$op} && ($simple_rpc{$op} == 2)) ? 
 				pop @params : undef;
	 		_bind_cols($h, $cols)
	 			if $cols;
#
#	check for those magic dbh->select()'s
#
			if ($simple_rpc{$op} && ($simple_rpc{$op} == 3)) {
				$sth = $sths{shift @params};
				$obj->_respond($id, $op, -1, 'Unknown statement handle', 'S1000', undef),
				next
					unless $sth;
				unshift @params, $sth;
				$method = substr($method, 3);
			}
#
#	check for asyncs
#
 			@results = ($op=~/^(db|st)_start_/) ?
 				$obj->_cancelable($helper, $id, $op, $h, \@params) :
 				$h->$method(@params);
 			$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, @results);
	 	}
	 	elsif ($op eq 'force_disconnect') {
#
#	force everything out, this may cause
#	other referencing threads to fail on their 
#	next/pending requests
#	NOTE: this is simplex
#
			$dbh = undef;
	 		%sths = ();
	 		%sthrefs = ();
	 		$helperclass = $helper = undef;
	 		DBIx::Threaded->dbix_threaded_free_thread($obj);
	 	}
############################################################
#
#	CONNECTION LEVEL METHODS
#
############################################################
	 	elsif (($op eq 'db_disconnect') ||
	 		($op eq 'db_DESTROY')) {
#
#	we don't destroy/disconnect until *all*
#	refs, including any subordinate sths,
#	are destroyed
#
			$dbhrefcnt--;
#	print "Decr'd db refcount to $dbhrefcnt\n";
			$h = undef,		# so ref count goes to zero
			$dbh = undef,
	 		%sths = (),
	 		%sthrefs = (),
#	 		Carp::carp("$op destroyed a connection"),
	 		$helperclass = $helper = undef,
	 		DBIx::Threaded->dbix_threaded_free_thread($obj)
	 			unless $dbhrefcnt;
	 		$obj->_respond($id, $op, undef, undef, undef, 1)
	 			if $id;
	 	}
	 	elsif (
	 		($op eq 'db_prepare') ||
			($op eq 'db_prepare_cached') ||
	 		($op eq 'db_tables') ||
	 		($op eq 'db_table_info') ||
	 		($op eq 'db_column_info') ||
	 		($op eq 'db_primary_key_info') ||
	 		($op eq 'db_foreign_key_info')) {
#
#	these all generate sth's...
#
			my $sth = $h->$method(@params);
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state),
	 		next
	 			unless $sth;
#
#	keep refcount for the stmt, and update
#	connection refcount to reflect add'l use
#
			my $stmtid = $obj->{_nextStmtId}++;
			$sths{$stmtid} = $sth;
			$sthrefs{$stmtid} = 1;
			$dbhrefcnt++;
#	print "Incr'd db refcount to $dbhrefcnt\n";

	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, $stmtid);
	 	}
	 	elsif (
	 		($op eq 'db_start_prepare') ||
			($op eq 'db_start_prepare_cached') ||
	 		($op eq 'db_start_tables') ||
	 		($op eq 'db_start_table_info') ||
	 		($op eq 'db_start_column_info') ||
	 		($op eq 'db_start_primary_key_info') ||
	 		($op eq 'db_start_foreign_key_info')) {
#
#	these all generate sth's...
#
			my $sth = $obj->_cancelable($helper, $id, $op, $h, \@params);
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state),
	 		next
	 			unless $sth;
#
#	keep refcount for the stmt, and update
#	connection refcount to reflect add'l use
#
			my $stmtid = $obj->{_nextStmtId}++;
			$sths{$stmtid} = $sth;
			$sthrefs{$stmtid} = 1;
			$dbhrefcnt++;
#	print "Incr'd db refcount to $dbhrefcnt\n";
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, $stmtid);
	 	}
		elsif ($op eq 'db__add_ref') {
#
#	somebody passed a ref to our proxy to another thread
#
			$dbhrefcnt++;
#	print "Incr'd db refcount to $dbhrefcnt\n";
	 		$obj->_respond($id, $op, undef, undef, undef, 1)
	 			if $id;
	 	}

########################################################
#
#	BEGIN statement methods
#
########################################################
	 	elsif ($op eq 'st_DESTROY') {
#
#	decrement refcount, if zero, destroy it
#	NOTE we also increment connection refcount
#
			$sthrefs{$stmtid}--;
	 		$dbhrefcnt--;
#print "Server: decr'd stmt $stmtid to $sthrefs{$stmtid}\n";
	 		$sth = $h = undef,	# so refcount drops to zero
	 		delete $sths{$stmtid},
	 		delete $sthrefs{$stmtid}
#	 		print "destroyed stmt $stmtid\n"
				if ($sthrefs{$stmtid} <= 0);
			$dbh = undef,
#	 		Carp::carp("$op destroyed a connection"),
	 		$helperclass = $helper = undef,
	 		DBIx::Threaded->dbix_threaded_free_thread($obj)
				if ($dbhrefcnt <= 0);
	 		$obj->_respond($id, $op, undef, undef, undef, 1)
	 			if $id;
	 	}
	 	elsif ($op eq 'st_execute') {
#
#	coalesce the bound params with the execute()
#	params
#
			$bindings = pop @params;
			my %inouts = ();
			if ($bindings) {
				foreach (keys %{$$bindings[0]}) {
					$h->bind_param_inout($_, $$bindings[0]{$_}, $$bindings[1]{$_}),
					$inouts{$_} = 1,
					next
						if ref $$bindings[0]{$_};
					$h->bind_param($_, $$bindings[0]{$_}, $$bindings[1]{$_});
				}
			}

			my $rc = $h->execute(@params);
			my $ios;
			$ios = {},
			map { $ios->{$_} = ${$$bindings[0]{$_}} } keys %inouts
				if ($bindings && scalar keys %inouts && defined($rc));
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, $rc, $ios);
	 	}
	 	elsif ($op eq 'st_execute_array') {
#
#	coalesce the bound params with the execute()
#	params
#	NOTE: need to send arraytuplestatus back!!
#
			$bindings = pop @params;
			map { 
				$h->bind_param_array($_, $$bindings[0]{$_}, $$bindings[1]{$_});
			} keys %{$$bindings[0]}
				if $bindings;

			my @status = ();
	 		my $rc = $h->execute_array(
	 			{ ArrayTupleStatus => \@status }, @params);
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, $rc, \@status);
	 	}
	 	elsif ($op eq 'st_start_execute') {
#
#	coalesce the bound params with the execute()
#	params
#
			$bindings = pop @params;
			my %inouts = ();
			if ($bindings) {
				foreach (keys %{$$bindings[0]}) {
					$h->bind_param_inout($_, $$bindings[0]{$_}, $$bindings[1]{$_}),
					$inouts{$_} = 1,
					next
						if ref $$bindings[0]{$_};
					$h->bind_param($_, $$bindings[0]{$_}, $$bindings[1]{$_});
				}
			}

			my $rc = $obj->_cancelable($helper, $id, $op, $h, \@params);
			my $ios;
			$ios = {},
			map { $ios->{$_} = ${$$bindings[0]{$_}} } keys %inouts
				if ($bindings && scalar keys %inouts && defined($rc));
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, $rc, $ios);
	 	}
	 	elsif ($op eq 'st_start_execute_array') {
#
#	coalesce the bound params with the execute()
#	params
#	NOTE: need to send arraytuplestatus back!!
#
			$bindings = pop @params;
			map { 
				$h->bind_param_array($_, $$bindings[0]{$_}, $$bindings[1]{$_});
			} keys %{$$bindings[0]}
				if $bindings;

			my @status = ();
			unshift @params, { ArrayTupleStatus => \@status };
	 		my $rc = $obj->_cancelable($helper, $id, $op, $h, \@params);
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, $rc, \@status);
	 	}
#	 	elsif ($op eq 'st_execute_for_fetch') {
#
#	not really supported yet
#
#	 		$obj->_respond($id, $op, $sth->execute_for_fetch(@params));
#	 	}
	 	elsif ($op eq 'st_finish') {
			$h->finish;
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, 1);
	 	}
	 	elsif ($op eq 'st_cancel') {
	 		$h->cancel;
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, 1);
	 	}
	 	elsif ($op eq 'st_dump_results') {
	 		my $fd = pop @params;
	 		my $fh;
	 		$obj->_respond($id, $op, -1, "Unable to dup filehandle: $!", 'S1000'),
	 		next
	 			unless open($fh, ">>&=$fd");
	 		$h->dump_results(@params, $fh);
	 		$obj->_respond($id, $op, $h->err, $h->errstr, $h->state, 1);
		}
	 	elsif ($op eq 'st_more_results') {
#
#	need a shared scalar for our resultset counter
#
			($helper && $helper->can('more_results')) ?
		 		$obj->_respond($id, $op, undef, undef, undef, $sth->more_results(@params)) :
		 		$obj->_respond($id, $op, -1, 'more_results() not supported by this driver.', 'S1000');
		}
#
#	register a ref to the handle
#
		elsif ($op eq 'st__add_ref') {
#
#	somebody passed a ref to our proxy to another thread
#	Note that we update connection's refcount as well,
#	since the stmt's proxy instance DESTROY will also
#	decrement the connection refcount
#
			$sthrefs{$stmtid}++;
#	print "Server: incr'd stmt $stmtid to $sthrefs{$stmtid}\n";
#	print "Incr'd db refcount to $dbhrefcnt\n";
			$dbhrefcnt++;
	 		$obj->_respond($id, $op, undef, undef, undef, 1)
	 			if $id;
	 	}

	}	# end while forever

	$cmdq->ignore();
	return 1;
}
#
#	respond to request, using baseline marshalling methods
#	NOTE: these are identical to the client side
#	(maybe we should create a module/package for them ?)
#
sub _respond {
	my $obj = shift;
	my $id = shift;

	my $frozen;
	if ($obj->{_marshal} eq 'freeze') {
		eval {
			$frozen = freeze([@_]);
		};
		return $obj->{_cmdq}->respond($id, $frozen)
			unless $@;

		warn "can't freeze: $@\n";
		my @result : shared = (-1, "Can't freeze: $@", 'S1000');
		return $obj->{_cmdq}->respond($id, \@result)
	}
#
#	only freeze if we have any complex objects
#
	my @results : shared = ();

	foreach (@_) {
#
#	eval it so we catch any instance of trying to share
#	something not shareable
#
		push(@results, $_), next
			unless defined($_) && (ref $_);

		eval {
			if (ref $_ eq 'ARRAY') {
				my @tmp : shared = @$_;
				push @results, \@tmp;
			}
			elsif (ref $_ eq 'ARRAY') {
				my %tmp : shared = %$_;
				push @results, \%tmp;
			}
			elsif (ref $_ eq 'SCALAR') {
				my $tmp : shared = $$_;
				push @results, \$tmp;
			}
			else {	# probably throws an error
				push @results, $_;
			}
		};
		next unless $@;

#		warn "can't share $_: $@\n";
		eval {
			$frozen = freeze([@_]);
		};
#		print "freeze returns a ", (ref $frozen || 'scalar'), "\n" and
		return $obj->{_cmdq}->respond($id, $frozen)
			unless $@;

		warn "can't freeze: $@\n";
		@results = (-1, "Can't freeze: $@", 'S1000');
		return $obj->{_cmdq}->respond($id, \@results);
	}	#end foreach result

	return $obj->{_cmdq}->respond($id, \@results);
}
#
#	common method for applying bind_col
#	ONLY USED TO SUPPLY TYPE INFO!!
#
sub _bind_cols {
	my ($sth, $bindings) = @_;
	foreach (1..$#$bindings) {
		$sth->bind_col($_, undef, $bindings->[$_])
			if $bindings->[$_];
	}
}
#
#	support true async operations
#	(for cancel/abort purposes only)
#	INCOMPLETE!!! REQUIRES A HELPER!!
#
sub _cancelable {
	my ($obj, $helper, $id, $op, $h, $params) = @_;

	my $method = ($op=~/^db_st_/) ? substr($op, 6) : substr($op, 3);
	my @results = ();
	@results = $helper->$method($obj->{_cmdq}, $id, $h, @$params);
	return wantarray ? @results : $results[0];
}

1;
__END__

=head1 NAME

DBIx::Threaded::Server - Server container class to provide thread-safe
	proxy for DBI objects

=head1 SYNOPSIS

	#
	#	NOTE: DBIx::Threaded::Server derived objects are
	#	not intended for direct use by an application.
	#	See DBIx::Threaded for the proxy client i/f
	#
	my $cmdq = Thread::Queue::Duplex->new();
	my $proxy = DBIx::Threaded::Server->new($cmdq);
	
	my $rc = $proxy->start('freeze', @connect_params);
	
	my $id = $cmdq->enqueue('do', @params);
	my $rc = $cmdq->wait($id);

=head1 DESCRIPTION

DBIx::Threaded::Server provides a container class to create and access
a DBI connection within its own thread, in order to
permit it to be used by multiple threads.
As of version 1.48, DBI does not permit DBI-generated objects
(namely, connection and statement handles) to be used outside
of the thread in which they are created.

A pleasant side effect of DBIx::Threaded's architecture
is that it permits thread-safe use of DBD's which are not
currently thread-safe or thread-friendly.

B<NOTE:> DBIx::Threaded::Server is not intended to be used directly
by applications. See L<DBIx::Threaded> for the DBI subclass which
provides the client side stubs intended for application use.

DBIx::Threaded provides a L<Thread::Queue::Duplex> object to
DBIx::Threaded::Server objects when a connection is created (or when
a pooled Server instance is created), in order to provide a lightweight 
communications channel between the client stubs and
the server container objects, using either L<threads::shared> variables,
or L<Storable> freeze/thaw to pass parameters and 
results between the client and server.

DBIx::Threaded is inspired by, but does not directly use, the 
L<Pots::*|Pots::MethodServer> set of modules to implement threadsafe
objects.

Also note that, due to the way in which Perl threads are spawned
(i.e., cloning the entire interpretter context of the spawning thread),
a create_pool() class level method is provided to permit creation
of minimal context threads during application initialization, in order
to conserve memory resources.

DBI method calls are initiated over the queue using 
L<threads::shared> copies of the parameter list elements; however,
alternate encodings are possible by implementing the 
L<Thread::Queue::Queueable> interface on any objects in the
parameter list to, e.g., use L<Storable> freeze/thaw.

DBIx::Threaded::Server implements the following methods:

=over 4

=item new

Constructor, creates a thread.

=item start

Starts the thread with connection parameters; the thread
will immediately accept the connection parameters and attempt
to connect.

=item stop

Stops the currently running thread.

=item run

Runs the thread routine as an infinite loop, dequeueing
requests as they arrive on the queue, processing them
by calling the appropriate DBI functions, and then
collecting the results and posting the response
to the queue via L<Thread::Queue::Duplex>::respond().

=back

=head1 AUTHOR, COPYRIGHT, & LICENSE

Dean Arnold, Presicient Corp. L<darnold@presicient.com>

Copyright(C) 2005, Presicient Corp., USA

Permission is granted to use this software under the same terms
as Perl itself. Refer to the Perl Artistic License for details.

=cut
