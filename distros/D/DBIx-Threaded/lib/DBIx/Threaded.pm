#
# Copyright (c) 2005, Presicient Corp., USA
#	Portions derived from DBI 1.48, Copyright (c) 1994-2004 Tim Bunce, Ireland
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

require 5.008_003;

our $VERSION = 0.10;

our %dbix_thrd_lcl_attrs = qw(
Database 1
PrintError 1
PrintWarn 1
RaiseError 1
HandleError 2
HandleSetErr 2
ErrCount 2
);

{
package		# hide from PAUSE
DBIx::Threaded::common; # ====== Common base class methods ======

use Storable qw(freeze thaw);
use threads;
use threads::shared;
use DBI;

our %stmt_gen = qw(
db_prepare 1
db_prepare_cached 1
db_tables 1
db_table_info 1
db_column_info 1
db_primary_key_info 1
db_foreign_key_info 1
);

use strict;
use warnings;
#
#	some baseline marshalling methods
#	_marshal is identical to server version
#
sub _marshal {
	my $obj = shift;

	return freeze([@_])
		if ($obj->{_marshal} eq 'freeze');
#
#	only freeze if we have any complex objects
#
	my @params : shared = ();

	foreach (@_) {
#
#	eval it so we catch any instance of trying to share
#	something not shareable
#
		eval {
			push @params, 
				(defined($_) && (ref $_)) ?
				((ref $_ eq 'ARRAY') ? &share( @$_ ) : 
					(ref $_ eq 'HASH') ? &share( %$_ ) : 
						&share( $$_ )
				) : $_;
		};
		return freeze([@_]) 
			if $@;
	}

	return \@params;
}
#
#	generic unmarshal autodetects which
#	we need to do
#
sub _unmarshal {
	my $obj = shift;
	my $resp;
	unless (ref $_[0]->[0]) {
		eval {
			$resp = thaw $_[0]->[0];
		};
		Carp::carp("Can't thaw response: $@"),
		return undef
			if $@;
	}
	else {
		$resp = $_[0]->[0];
	}
#
#	collect any error info; note that this may trigger
#	RaiseError/PrintError/PrintWarn
#
	my ($method, $err, $errstr, $state) = 
		(shift @$resp, shift @$resp, shift @$resp, shift @$resp);

	$obj->set_err($err, $errstr, $state, $method)
		if defined($err);
#
#	some methods return stuff we need to instantiate
#
	if (($method eq 'st_execute') || ($method eq 'st_start_execute')) {
		if (ref $resp->[-1]) {
#
#	if inout params bound, then recover their values
#
			my $inouts = pop @$resp;
			map {
				${$obj->{_bound_params}[$_]} = $inouts->[$_]
					if $obj->{_bound_params}[$_] && 
						ref $obj->{_bound_params}[$_] &&
						$inouts->[$_];
			} 1..$#$inouts;
		}
	}
#
#	remaining response element (if any) is either a scalar, or
#	a shared arrayref of marshalled values
#
	return $resp
		unless (!$err && $stmt_gen{$method});
#
#	if its a stmt generator we have to construct the stmt here
#
	my $stmtid = shift @$resp;
	return $stmtid ?
		DBIx::Threaded::st->new($stmtid, $obj) :
		undef;
}

# methods common to all handle types:
#
#	all these just use a common communication method
#
sub _send_request {
	my $obj = shift;

	($obj->{_err}, $DBIx::Threaded::err,
		$obj->{_errstr}, $DBIx::Threaded::errstr,
		$obj->{_state}, $DBIx::Threaded::state) =
		(undef, undef, undef, undef, '', '')
			if ref $obj;

	my $class = ref $obj;
	$class = ($class && ($class=~/^.+?::(dr|db|st)/)) ?
		$1 . '_' . pop @_ : pop @_;
#
#	add object ID (if any) and qualify the operation
#	with its classtype
#
#print STDERR "_send_request: calling $class\n";

Carp::carp('sending db_DESTROY') if ($class eq 'db_DESTROY');

	push (@_, $obj->{_id}, $class),
	($obj->{_err}, $obj->{_errstr}, $obj->{_state}) = (undef, undef, undef)
		if ref $obj;

	my $id = $obj->{_cmdq}->enqueue($obj->_marshal(@_));
	return undef unless $id;
	my $resp = $obj->{_cmdq}->wait($id);
#
#	unpack/unmarshall response and return
#	results
#
	$resp = $obj->_unmarshal($resp);

#print STDERR "_send_request: returning from $class\n";
	return (ref $resp eq 'ARRAY') ? 
		(wantarray ? @$resp : shift @$resp) : $resp;
}

sub _send_simplex {
	my $obj = shift;
	my $class = ref $obj;
	($class) = ($class=~/^.+?::(dr|db|st)/);
	$class .= '_' . pop @_;
#
#	add object ID (if any) and qualify the operation
#	with its classtype
#
#print STDERR "_send_simplex: calling $class\n";

#Carp::carp('sending st_DESTROY') if ($class eq 'st_DESTROY');

	push @_, $obj->{_id}, $class;

	return $obj->{_cmdq} ?
		$obj->{_cmdq}->enqueue_simplex($obj->_marshal(@_)) : 1;
}

sub _start_request {
	my $obj = shift;

	($obj->{_err}, $DBIx::Threaded::err,
		$obj->{_errstr}, $DBIx::Threaded::errstr,
		$obj->{_state}, $DBIx::Threaded::state) =
		(undef, undef, undef, undef, '', '')
			if ref $obj;

	my $class = ref $obj;
	($class) = ($class=~/^.+?::(dr|db|st)/);
	$class .= '_start_' . pop @_;
	push @_, $obj->{_id}, $class;
	return $obj->{_cmdq}->enqueue( $obj->_marshal(@_) );
}
#
#	needed for multiTQD users to wait_any/all()
#
sub dbix_threaded_get_queue {
	return shift->{_cmdq};
}

sub dbix_threaded_tid {
	return shift->{_thread};
}

sub dbix_threaded_ready {
	my ($obj, $id) = @_;
	return $obj->{_cmdq}->ready($id) ? $obj : undef;
}

sub dbix_threaded_wait {
	my ($obj, $id) = @_;
	my $resp = $obj->{_cmdq}->wait($id);
#
#	unpack/unmarshall response and return
#	results
#
	$resp = $obj->_unmarshal($resp);
#
#	check for a stmt generator
#
	return (ref $resp eq 'ARRAY') ? 
		(wantarray ? @$resp : shift @$resp) : $resp;
}

sub dbix_threaded_wait_until {
	my ($obj, $timeout, $id) = @_;
	my $resp = $obj->{_cmdq}->wait_until($timeout, $id);
	return undef unless $resp;
#
#	unpack/unmarshall response and return
#	results
#
	$resp = $obj->_unmarshal($resp);
#
#	check for a stmt generator
#
	return (ref $resp eq 'ARRAY') ? 
		(wantarray ? @$resp : shift @$resp) : $resp;
}
#
#	cancel a pending/inprogress request by
#	marking it canceled; note that, to be effective,
#	a helper class must exist and support cancellation
#	Also note that this is different than $sth->cancel()
#
sub dbix_threaded_cancel {
	my ($obj, $id) = @_;
	$obj->{_cmdq}->mark($id, 'CANCEL');
	return $obj;
}
#
#	not supported for now
#
sub clone {
	return DBI->set_err(-1, 'clone() not supported.', 'S1000');
}
#
#	error accessors can fallback to the base
#
sub func {
	return _send_request(@_, 'func');
}

sub can {
	return shift->_send_request(@_, 'can');
}

sub parse_trace_flag {
	return _send_request(@_, 'parse_trace_flag');
}

sub parse_trace_flags {
	return _send_request(@_, 'parse_trace_flags');
}

sub private_data {	
	return _send_request(@_, 'private_data');
}

sub trace {	
	return _send_request(@_, 'trace');
}

sub get_info {
	return _send_request(@_, 'get_info');
}

sub swap_inner_handle {
	return shift->set_err(-1, 'swap_inner_handle() not supported.', 'S1000');
}
#
#	need local version of these; kiped from DBI::PP
#
sub err    { return shift->{_err};    }
sub errstr { return shift->{_errstr}; }
sub state  { return shift->{_state};  }
sub set_err {
    my ($h, $err, $errstr, $state, $method, $rv) = @_;

	($DBIx::Threaded::err, $DBIx::Threaded::errstr, $DBIx::Threaded::state) =
		defined($err) ? ($err, $errstr, $state) : (undef, undef, ''),
	return
	    unless ref $h;

	return 
		if $h->{HandleSetErr} && 
			$h->{HandleSetErr}->($h, $err, $errstr, $state, $method);

	($h->{_err}, $DBIx::Threaded::err,
		$h->{_errstr}, $DBIx::Threaded::errstr,
		$h->{_state}, $DBIx::Threaded::state) =
		(undef, undef, undef, undef, '', ''),
	return
	    unless defined($err);

    if ($h->{_errstr}) {
		$h->{_errstr} .= sprintf " [err was %s now %s]", $h->{_err}, $err
			if $h->{_err} && $err;
		$h->{_errstr} .= sprintf " [state was %s now %s]", $h->{_state}, $state
			if $h->{_state} and $h->{_state} ne 'S1000' && $state;
		$h->{_errstr} .= "\n$errstr";
		$DBIx::Threaded::errstr = $h->{_errstr};
    }
    else {
		$h->{_errstr} = $DBIx::Threaded::errstr = $errstr;
    }

    # assign if higher priority: err > "0" > "" > undef
    my $err_changed;
    if ($err			# new error: so assign
		or !defined $h->{_err}	# no existing warn/info: so assign
           # new warn ("0" len 1) > info ("" len 0): so assign
		or defined $err && length($err) > length($h->{_err}))
	{
        $h->{_err} = $DBIx::Threaded::err = $err;
		++$h->{ErrCount} if $err;
		++$err_changed;
    }

    if ($err_changed) {
		$state ||= 'S1000' if $DBIx::Threaded::err;
		$h->{_state} = $DBIx::Threaded::state = ($state eq '00000') ? '' : $state
			if $state;
    }

	$h->{Database}{_err}    = $DBIx::Threaded::err,
	$h->{Database}{_errstr} = $DBIx::Threaded::errstr,
	$h->{Database}{_state}  = $DBIx::Threaded::state
    	if $h->isa('DBIx::Threaded::st');

    $h->{_last_method} = $method;
#
#	if any error/warning switches enabled, continue processing
#
	my ($pe,$pw,$re,$he) = @{$h}{qw(PrintError PrintWarn RaiseError HandleError)};

	return $rv
		unless ($err && ($pe || $re || $he))
			or (!$err && length($err) && $pw);

	my $msg = sprintf "%s %s %s: %s", ref $h, $method,
		($err eq "0") ? "warning" : "failed", $errstr;

	if ($h->{ShowErrorStatement} and 
		my $Statement = $h->{Statement}) {
		$msg .= ' for [``' . $Statement . "''";
		if (my $ParamValues = $h->FETCH('ParamValues')) {
			my $pv_idx = 0;
			my ($k,$v);
			$msg .= " with params: ";
			$msg .= sprintf "%s%s=%s", ($pv_idx++==0) ? "" : ", ", $k, DBI::neat($v)
				while ( ($k,$v) = each %$ParamValues );
	    }
	    $msg .= "]";
	}
    carp $msg and return $rv
    	if (($err eq '0') && $pw);

	my $do_croak = 1;
	if (my $subsub = $h->{HandleError}) {
		return $rv
			if &$subsub($msg, $h);	# note we do not pass the returned value
	}

	DBI->trace_msg(4, 
		"    $method has failed ($h->{PrintError}, $h->{RaiseError})\n");
	carp $msg if $pe;
	die $msg if $re;

    return $rv; # usually undef
}

sub _not_impl {
	my ($h, $method) = @_;
	$h->trace_msg("Driver does not implement the $method method.\n");
	return;	# empty list / undef
}
#
#	we'll override this so we can grab copies of the methods
#	before DBI does...note that this is a dummy operation
#
sub install_method {
# special class method called directly by apps and/or drivers
# to install new methods into the DBI dispatcher
# DBD::Foo::db->install_method("foo_mumble", { usage => [...], options => '...' });
#	my ($class, $method, $attr) = @_;
#	Carp::croak("Class '$class' must begin with DBD:: and end with ::db or ::st")
#		unless $class =~ /^DBD::(\w+)::(dr|db|st)$/;

#	my ($driver, $subtype) = ($1, $2);
#	Carp::croak("invalid method name '$method'")
#		unless $method =~ m/^([a-z]+_)\w+$/;

#	my $prefix = $1;
#	my $reg_info = $dbd_prefix_registry->{$prefix};
#	Carp::croak("method name prefix '$prefix' is not registered") 
#		unless $reg_info;

#	my %attr = %{$attr||{}}; # copy so we can edit
	# XXX reformat $attr as needed for _install_method
#	my ($caller_pkg, $filename, $line) = caller;
#	DBI->_install_method("DBI::${subtype}::$method", "$filename at line $line", \%attr);
}

}	# end common

{
package DBIx::Threaded;

use Config;
use Carp();
use DBI;
use Time::HiRes;

BEGIN {
	if ($Config{useithreads}) {
		use threads;
		use threads::shared;
		use Thread::Queue::Duplex;
		use DBIx::Threaded::Server;
	}
}
#
#	lets not really subclass, in case we accidently
#	forget to proxy a method
#
use base qw(DBIx::Threaded::common DBI);

use vars qw($SUBCLASS);

our @dbix_thrd_pool : shared = ();
our %dbix_thrd_map : shared = ();
our ($err, $errstr, $state);

use strict;
use warnings;

END {
#
#	stop all the threads in pool ?
#	will we know when they've freed themselves up ?
#	for now, just kill off free threads
#
	if ($Config{useithreads}) {
		lock(@dbix_thrd_pool);
		DBIx::Threaded::Server->redeem($_)->stop
			foreach (@dbix_thrd_pool);
		@dbix_thrd_pool = ();
	}
}

#
#	keep refs to each thread instance here so we can
#	propogate driver level changes to all threads
#
our %installed_drh = ();  # maps driver names to installed driver handles
#
#	a pool of threads for quick connection
#
our %connections = ();
#
#	permit subclass chaining...assuming the subclasses
#	support chaining
#
sub import {
	my $pkg = shift;

	return 1 unless scalar @_;

	die 'Invalid subclass import.'
		unless (scalar @_ == 2) && 
			(lc $_[0] eq 'subclass');
	$SUBCLASS = $_[1];
	1;
}

#
#	create a thread pool for faster startup
#	NOTE: class-level method
#
sub dbix_threaded_create_pool {
	my ($class, $count) = @_;
	return undef 
		unless ($count && ($count > 0));

	return $count
		unless $Config{useithreads};

	my ($thread, $cmdq);
	lock(@dbix_thrd_pool);
	my $started;
#	$started = time(),
	$thread = DBIx::Threaded::Server->new(
		Thread::Queue::Duplex->new( ListenerRequired => 1 )),
	$dbix_thrd_map{$thread->tid()} = 1,
	push(@dbix_thrd_pool, $thread->curse)
#	print "Pool thread $_: ", time() - $started, "\n"
		foreach (1..$count);

	return $count;
}

sub connect {
    my ($class, $dsn, $user, $pass, $attrs) = @_;
#
#	if not configured for threads, return regular DBI
#	connection (or our subclass)
#
	unless ($Config{useithreads}) {
		my $class;
		if ($SUBCLASS) {
			$attrs = { } unless $attrs;
			$attrs->{RootClass} = $SUBCLASS;
		}
		return DBI->connect($dsn, $user, $pass, $attrs);
	}
#
#	allocate or create a thread
#	create command queue for it
#	marshall the arguments
#	send to thread
#	wait for reply
#		- reply will include the driver name
#		- if driver name not installed, install it,
#			and query server for installed method names
#			*then* we have to figger out how to install them...
#	return results
#
	return $class->set_err(-1, 'Invalid connect() attributes.', 'S1000')
		if ($attrs && 
			(
				(! ref $attrs) ||
				(ref $attrs ne 'HASH') ||
				(defined($attrs->{dbix_threaded_marshal}) &&
					($attrs->{dbix_threaded_marshal} ne 'freeze') &&
					($attrs->{dbix_threaded_marshal} ne 'share')) ||
				(defined($attrs->{dbix_threaded_max_pending}) &&
					(($attrs->{dbix_threaded_max_pending}!~/^\d+$/) ||
					($attrs->{dbix_threaded_max_pending} <= 0)))
			)
		);

	return $class->set_err(-1, 'RootClass attribute conflicts with imported subclass.', 'S1000')
		if ($attrs && $attrs->{RootClass} && $SUBCLASS && 
			($attrs->{RootClass} ne $SUBCLASS));

	$attrs->{RootClass} = $SUBCLASS
		if $SUBCLASS;

	$attrs->{dbix_threaded_marshal} = 'share'
		unless ($attrs && $attrs->{dbix_threaded_marshal});

	my $thread;
	{
		lock(@dbix_thrd_pool);

		$thread = (scalar @dbix_thrd_pool) ? 
			DBIx::Threaded::Server->redeem(shift @dbix_thrd_pool) :
			DBIx::Threaded::Server->new(
				Thread::Queue::Duplex->new(ListenerRequired => 1));
		delete $dbix_thrd_map{$thread->tid()};
	}
#
#	normalize connection params, so we can add subclass list
#
	push @_, undef
		while (scalar @_ < 4);
	my $results = $thread->start($attrs->{dbix_threaded_marshal}, 
		$dsn, $user, $pass, $attrs);
	Carp::croak("Cannot start() a server instance.")
		unless $results;
#
#	if failed, return thread to pool
#
	unless (ref $results eq 'DBIx::Threaded::Server') {
		lock(@dbix_thrd_pool);
		$dbix_thrd_map{$thread->tid()} = 1;
		push @dbix_thrd_pool, $thread->curse;
		return DBIx::Threaded::common->set_err(@$results);
	}
#
#	wouldn't you really rather new() ?
#	what happens when we exit wo/ saving a ref
#	to $thread ?
#
	$thread->get_queue()->set_max_pending($attrs->{dbix_threaded_max_pending});
	my $obj = DBIx::Threaded::db->new(
		$thread->get_queue(),
		$thread,
		$attrs);

	$DBIx::Threaded::connections{$obj} = $obj;
	return $obj;
}
*connect_cached = \&connect;

#sub connect_cached {
#
#	for now just use regular connect;
#	eventually we'll need to figger out
#	what to do with this
#
#	return shift->connect(@_);
#}

#
#	since this would cause a driver load, we can't support it
#	until a thread is started, so we just run an async closure
#
sub _data_sources {
	my $dsrcs = shift;
	@$dsrcs = DBI->data_sources(@_);
	return 1;
}

sub data_sources {
	my $class = shift;
	my @dsrcs : shared = ();
	my $thread = threads->create(\&_data_sources, \@dsrcs, @_);
	$thread->join;
	return @dsrcs;
}

sub _installed_versions {
	my $target = shift;
	DBI->installed_versions,
	return 1
		unless $target;
		
    if (ref $target eq 'ARRAY') {
       @$target = DBI->installed_versions;
    }
    else {
    	my $versions = DBI->installed_versions;
    	%$target = %$versions;
    }
	return 1;
}
#
#	ditto for versions
#
sub installed_versions {
	my @dsrcs : shared = ();
	my %version : shared = ();
	my $wantary = wantarray;
	my $thread = threads->create(\&_installed_versions, 
		wantarray ? \@dsrcs : defined(wantarray) ? \%version : undef);
	$thread->join;
	return wantarray ? @dsrcs : (defined wantarray ? \%version : 1);
}
#
#	async isn't working!
#
sub _avail_drivers {
	my ($dsrcs, $quiet) = @_;
#	print "available_drivers() thread\n";
	@$dsrcs = DBI->available_drivers($quiet);
	return 1;	
}
#
#	ditto for available drivers
#
sub available_drivers {
	my ($class, $quiet) = @_;
	my @dsrcs : shared = ();
	my $thread = threads->create(\&_avail_drivers, \@dsrcs, $quiet);
	$thread->join;
	return @dsrcs;
}

sub default_user {
	return shift->_send_request(@_, 'default_user');
}
#
#	class method to permit the server thread to put
#	itself back into the pool when it has fully disconnected
#
sub dbix_threaded_free_thread {
	my ($class, $thread) = @_;
	lock(@dbix_thrd_pool);
	$dbix_thrd_map{$thread->tid()} = 1,
	push(@dbix_thrd_pool, $thread->curse)
		unless $dbix_thrd_map{$thread->tid()};
	return 1;
}
#
#	this should be installed in all servers
#
sub trace {
	my $class = shift;
	return DBIx::Threaded::Server->trace(@_);
}
#
#	install a proxy version of an installed method
#
sub  _install_method {
    my ( $caller, $method ) = @_;

	my $method_code = q[
		sub {
			return shift->_send_request($method);
		}];
    no strict qw(refs);
    my $code_ref = eval qq{#line 1 "$method"\n$method_code};
    *$method = $code_ref;
}

sub _force {
	my $obj = shift;
	lock(@dbix_thrd_pool);
	return 1 if $dbix_thrd_map{$obj->{_thread}->tid()};
	$obj->_send_simplex('force_disconnect');
	return 1;
}
#
#	general async completion waits
#
sub _validate_handle_list {
	my $class = shift;
	my %qs = ();
	map { 
		return $class->set_err(-1, 'Invalid handle in list.', 'S1000')
			unless ($_ && ref $_ && 
				($_->isa('DBIx::Threaded::db') || $_->isa('DBIx::Threaded::st'))); 
		$qs{$_->{_cmdq}} = $_;
	} @_;
	return \%qs;
}

sub _q2h {
	my $qs = shift;
	my @hs = ();
	map { push @hs, $qs->{$_}; } @_;
	return @hs;
}

sub dbix_threaded_wait_any {
	my $class = shift;
#
#	validate the handle list; must be either DBIx::Threaded::db or 
#	DBIx::Threaded::st
#
	my $qs = $class->_validate_handle_list(@_);
	return undef
		unless $qs;
	return _q2h($qs, Thread::Queue::Duplex->wait_any(keys %$qs));
}

sub dbix_threaded_wait_any_until {
	my $class = shift;
	my $timeout = shift;

	my $qs = $class->_validate_handle_list(@_);
	return undef
		unless $qs;
	return _q2h($qs, Thread::Queue::Duplex->wait_any_until($timeout, keys %$qs));
}

sub dbix_threaded_wait_all {
	my $class = shift;
#
#	validate the handle list; must be either DBIx::Threaded::db or 
#	DBIx::Threaded::st
#
	my $qs = $class->_validate_handle_list(@_);
	return undef
		unless $qs;
	return _q2h($qs, Thread::Queue::Duplex->wait_all(keys %$qs));
}

sub dbix_threaded_wait_all_until {
	my $class = shift;
	my $timeout = shift;

	my $qs = $class->_validate_handle_list(@_);
	return undef
		unless $qs;
	return _q2h($qs, Thread::Queue::Duplex->wait_all_until(keys %$qs));
}

1;
}

{
package		# hide from PAUSE
DBIx::Threaded::dr;	# ====== DRIVER ======

use DBI;
use Config;

use base qw(DBIx::Threaded::common );

use strict;
use warnings;

sub new {
	my ($class, $cmdq) = @_;
	
    my (%hash, $i, $h);
    $i = tie    %hash, $class, { _cmdq => $cmdq };  # ref to inner hash (for driver)
    $h = bless \%hash, $class;         # ref to outer hash (for application)
	return $h;
}

sub TIEHASH { bless $_[1] => $_[0]; }

sub disconnect_all {
#
#	iterate over the connections, sending disconnect
#	on them all ? Not certain what to do with this...
#
	return shift->_send_request(@_, 'disconnect_all');
}

sub data_sources {
	return shift->_send_request(@_, 'data_sources');
}

sub default_user {
	return shift->_send_request(@_, 'default_user');
}

sub STORE {
	my ($obj, $attr, $value) = @_;
#
#	remap handlers to a local instance
#	can we just throw this up to the DBI base class ?
#	Since any error we get we'll be storing locally
#	via set_err()
#
	$obj->{$attr} = $value,
	return 1
		if $dbix_thrd_lcl_attrs{$attr} ||
			(substr($attr, 0, 1) eq '_');

	return $obj->_send_request($attr, $value, 'STORE');
}

sub FETCH {
	my ($obj, $attr) = @_;
#
#	remap the attribute's coderef to a local instance
#
	return ($dbix_thrd_lcl_attrs{$attr} || substr($attr, 0, 1) eq '_') ? 
		$obj->{$attr} :
		$obj->_send_request($attr, 'FETCH');
}

sub DESTROY {
#
#	not certain what to do here, other than destroy in the
#	server...guess we'll let it decide on ref counts...
#
}

}


{
package		# hide from PAUSE
DBIx::Threaded::db;	# ====== DATABASE ======
use Thread::Queue::Queueable;

use base qw(DBIx::Threaded::common Thread::Queue::Queueable);
use strict;
use warnings;

sub new {
	my ($class, $cmdq, $thread, $attrs) = @_;
    my (%hash, $i, $h);
    $i = tie    %hash, $class, { 
   		_cmdq => $cmdq,
		_thread => $thread,
		_marshal => $attrs->{dbix_threaded_marshal},
		_inner => 2,
		};  # ref to inner hash (for driver)
	$hash{$_} = $attrs->{$_}
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
    $h = bless \%hash, $class;         # ref to outer hash (for application)
	return $h;
}
#
#	construct transient db object
#
sub _renew {
	my ($class, $sth) = @_;
    my (%hash, $i, $h);
    $i = tie    %hash, $class, { 
   		_cmdq => $sth->{_cmdq},
		_thread => $sth->{_thread},
		_marshal => $sth->{_marshal},
		_transient => 1		# mark as transient so it doesn't DESTROY in server
		};  # ref to inner hash (for driver)
	$hash{$_} = $sth->{$_}
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
    $h = bless \%hash, $class;         # ref to outer hash (for application)
	return $h;
}

sub TIEHASH { bless $_[1] => $_[0]; }

######################################################
#
#	TQQ METHOD OVERRIDES
#	default onEnqueue, onDequeue, and onCancel are OK
#
######################################################
#
#	methods to curse/redeem us for passing between threads
#
sub curse {
	my $obj = shift;

	my %cursed : shared = (
		_cmdq => $obj->{_cmdq}->curse,
		_thread => $obj->{_thread}->curse,
		_marshal => $obj->{_marshal}
	);
#
#	we can't pass HandleError or HandleSetErr, since they're
#	CODErefs, and we don't pass ErrCount since that should be
#	reset in the new thread...unless we made it shared ?
#
	$cursed{$_} = ($DBIx::Threaded::dbix_thrd_lcl_attrs{$_} == 1) ? $obj->{$_} : undef
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
	return \%cursed;
}

sub redeem {
	my ($class, $obj) = @_;

    my (%hash, $i, $h);
    $i = tie    %hash, $class, { 
		_cmdq => Thread::Queue::Duplex->redeem($obj->{_cmdq}),
		_thread => DBIx::Threaded::Server->redeem($obj->{_thread}),
		_marshal => $obj->{_marshal},
		_inner => 2,
		};  # ref to inner hash (for driver)
	$hash{$_} = $obj->{$_}
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
    $h = bless \%hash, $class;         # ref to outer hash (for application)
	return $h;
}

sub onEnqueue {
	my $obj = shift;
#
#	we have to create a new ref in the server
#	when we enqueue
#
	$obj->_send_simplex('_add_ref');
	return $obj->SUPER::onEnqueue();
}

sub onCancel {
#
#	we added a ref when we queued up, so now we
#	need to remove the ref
#
	shift->_send_simplex('DESTROY');
	return 1;
}

sub data_sources {
	return shift->_send_request(@_, 'data_sources');
}

sub connected {
	return shift->_send_request(@_, 'connected');
}

sub begin_work {
	return shift->_send_request(@_, 'begin_work');
}

sub commit {
	return shift->_send_request(@_, 'commit');
}

sub rollback {
	return shift->_send_request(@_, 'rollback');
}

sub do {
	my $rc = shift->_send_request(@_, 'do');
	return $rc;
}

sub last_insert_id {
	return shift->_send_request(@_, 'last_insert_id');
}

sub selectrow_array {
	my $obj = shift;
	my $sth = shift;
	
	my @resp = (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_send_request($sth->_get_stmt_id, @_, 'st_selectrow_array') :
		$obj->_send_request($sth, @_, 'selectrow_array');
	return scalar @resp ? @resp : undef;
}

sub selectrow_arrayref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_send_request($sth->_get_stmt_id, @_, 'st_selectrow_arrayref') :
		$obj->_send_request($sth, @_, 'selectrow_arrayref');
}

sub selectrow_hashref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_send_request($sth->_get_stmt_id, @_, 'st_selectrow_hashref') :
		$obj->_send_request($sth, @_, 'selectrow_hashref');
}

sub selectall_arrayref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_send_request($sth->_get_stmt_id, @_, 'st_selectall_arrayref') :
		$obj->_send_request($sth, @_, 'selectall_arrayref');
}

sub selectall_hashref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_send_request($sth->_get_stmt_id, @_, 'st_selectall_hashref') :
		$obj->_send_request($sth, @_, 'selectall_hashref');
}

sub selectcol_arrayref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_send_request($sth->_get_stmt_id, @_, 'st_selectcol_arrayref') :
		$obj->_send_request($sth, @_, 'selectcol_arrayref');
}

sub prepare {
	return shift->_send_request(@_, 'prepare');
}

sub prepare_cached {
	return shift->_send_request(@_, 'prepare_cached');
}

sub tables {
	return shift->_send_request(@_, 'tables');
}

sub table_info {
	return shift->_send_request(@_, 'table_info');
}

sub column_info {
	return shift->_send_request(@_, 'column_info');
}

sub primary_key_info {
	return shift->_send_request(@_, 'primary_key_info');
}

sub foreign_key_info {
	return shift->_send_request(@_, 'foreign_key_info');
}

sub ping {
	return shift->_send_request(@_, 'ping');
}

sub disconnect {
	return shift->_send_request(@_, 'disconnect');
}

sub quote {
	return shift->_send_request(@_, 'quote');
}

sub quote_identifier {
	return shift->_send_request(@_, 'quote_identifier');
}

sub rows {
	return shift->_send_request(@_, 'rows');
}

sub type_info_all {
	return shift->_start_request(@_, 'type_info_all');
}

sub type_info {
	return shift->_start_request(@_, 'type_info');
}

#
#	async version of some
#
sub dbix_threaded_start {
	return shift->_start_request(@_, 'do');
}

sub dbix_threaded_start_prepare {
	return shift->_start_request(@_, 'prepare');
}

sub dbix_threaded_start_selectrow_array {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_start_request($sth->_get_stmt_id, @_, 'st_selectrow_array') :
		$obj->_start_request($sth, @_, 'selectrow_array');
}

sub dbix_threaded_start_selectrow_arrayref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_start_request($sth->_get_stmt_id, @_, 'st_selectrow_arrayref') :
		$obj->_start_request($sth, @_, 'selectrow_arrayref');
}

sub dbix_threaded_start_selectrow_hashref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_start_request($sth->_get_stmt_id, @_, 'st_selectrow_hashref') :
		$obj->_start_request($sth, @_, 'selectrow_hashref');
}

sub dbix_threaded_start_selectall_arrayref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_start_request($sth->_get_stmt_id, @_, 'st_selectall_arrayref') :
		$obj->_start_request($sth, @_, 'selectall_arrayref');
}

sub dbix_threaded_start_selectall_hashref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_start_request($sth->_get_stmt_id, @_, 'st_selectall_hashref') :
		$obj->_start_request($sth, @_, 'selectall_hashref');
}

sub dbix_threaded_start_selectcol_arrayref {
	my $obj = shift;
	my $sth = shift;
	
	return (ref $sth && (ref $sth eq 'DBIx::Threaded::st')) ?
		$obj->_start_request($sth->_get_stmt_id, @_, 'st_selectcol_arrayref') :
		$obj->_start_request($sth, @_, 'selectcol_arrayref');
}

sub dbix_threaded_start_primary_key {
	return shift->_start_request(@_, 'primary_key');
}

sub dbix_threaded_start_prepare_cached {
	return shift->_start_request(@_, 'prepare_cached');
}

sub dbix_threaded_start_tables {
	return shift->_start_request(@_, 'tables');
}

sub dbix_threaded_start_table_info {
	return shift->_start_request(@_, 'table_info');
}

sub dbix_threaded_start_column_info {
	return shift->_start_request(@_, 'column_info');
}

sub dbix_threaded_start_primary_key_info {
	return shift->_start_request(@_, 'primary_key_info');
}

sub dbix_threaded_start_foreign_key_info {
	return shift->_start_request(@_, 'foreign_key_info');
}

sub take_imp_data {
	return shift->set_err(-1, 'take_imp_data() not supported.', 'S1000');
}

sub STORE {
	my ($obj, $attr, $value) = @_;
#
#	eventually support RowsCacheSize for client/server
#	traffic optimization
#
#	remap handlers to a local instance
#	can we just throw this up to the DBI base class ?
#	Since any error we get we'll be storing locally
#	via set_err()
#
	$obj->{$attr} = $value,
	return 1
		if $dbix_thrd_lcl_attrs{$attr} || (substr($attr, 0, 1) eq '_');
	return $obj->_send_request($attr, $value, 'STORE');
}

sub FETCH {
	my ($obj, $attr) = @_;

#
#	create local driver object
#	note that we don't create any reference counts
#	this is a very transient object
#
	return ($dbix_thrd_lcl_attrs{$attr} || substr($attr, 0, 1) eq '_') ? 
		$obj->{$attr} :
		($attr eq 'Driver') ? DBIx::Threaded::dr->new($obj->{_cmdq}) :
			$obj->_send_request($attr, 'FETCH');
}

sub DESTROY {
#
#	not certain what to do here, other than destroy in the
#	server...guess we'll let it decide on ref counts...
#
	my $obj = shift;
#
#	getting some odd inner/outer undef'd errors here,
#	so just eval this to suppress them
#
	eval {
	$obj->{_inner}--;
	$obj->_send_simplex('DESTROY')
		unless ($obj->{_inner} || $obj->{_transient});
	};
}
#
#	provide a safety outlet in case things go awry
#	NOTE that the server will free itself to the pool
#
sub dbix_threaded_force_disconnect {
	my $obj = shift;
	return DBIx::Threaded->_force($obj);
}

}


{   
package		# hide from PAUSE
DBIx::Threaded::st;	# ====== STATEMENT ======
use Thread::Queue::Queueable;

use base qw(DBIx::Threaded::common Thread::Queue::Queueable );

use strict;
use warnings;

sub new {
	my ($class, $id, $dbh) = @_;
    my (%hash, $i, $h);
    $i = tie    %hash, $class, {  # ref to inner hash (for driver)
		_id => $id, 
		_cmdq => $dbh->{_cmdq},
		_marshal => $dbh->{_marshal},
		_thread => $dbh->{_thread},
		_inner => 2,
		_bound_cols => [],
		_bound_coltypes => [],
		_bound_colcnt => 0,

		_bound_params => {},
		_bound_paramtypes => {},
		_bound_paramcnt => 0,
		
		_server_rs => undef,	# ref to server's shared resultset counter
		_curr_rs => 0,			# our private resultset counter
		Database => $dbh
	};
	$hash{$_} = $dbh->{$_}
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
    $h = bless \%hash, $class;         # ref to outer hash (for application)
	return $h;
}

sub TIEHASH { bless $_[1] => $_[0]; }

sub _get_stmt_id { return shift->{_id}; }

######################################################
#
#	TQQ METHOD OVERRIDES
#	default onDequeue OK
#	don't know about onCancel yet...
#
######################################################
#
#	methods to curse/redeem us for passing between threads
#	NOTE: we do not preserve column/param binding between
#	threads!
#
sub curse {
	my $obj = shift;

	my %cursed : shared = (
		_id => $obj->{_id},
		_cmdq => $obj->{_cmdq}->curse,
		_thread => $obj->{_thread}->curse,
		_marshal => $obj->{_marshal},
		_server_rs => $obj->{_server_rs},
		_curr_rs => $obj->{_curr_rs}
	);
	$cursed{$_} = ($DBIx::Threaded::dbix_thrd_lcl_attrs{$_} == 1) ? $obj->{$_} : undef
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
	return \%cursed;
}

sub redeem {
	my ($class, $obj) = @_;

    my (%hash, $i, $h);
    $i = tie    %hash, $class, {  # ref to inner hash (for driver)
		_id => $obj->{_id},
		_cmdq => Thread::Queue::Duplex->redeem($obj->{_cmdq}),
		_thread => DBIx::Threaded::Server->redeem($obj->{_thread}),
		_marshal => $obj->{_marshal},
		_inner => 2,

		_server_rs => $obj->{_server_rs},
		_curr_rs => $obj->{_curr_rs},

		_bound_cols => [],
		_bound_coltypes => [],
		_bound_colcnt => 0,

		_bound_params => {},
		_bound_paramtypes => {},
		_bound_paramcnt => 0,
	};
	$hash{$_} = $obj->{$_}
		foreach (keys %DBIx::Threaded::dbix_thrd_lcl_attrs);
#
#	construct a transient Database reference
#
    $h = bless \%hash, $class;         # ref to outer hash (for application)
	$h->{Database} = DBIx::Threaded::db->_renew($h);
	return $h;
}

sub onEnqueue {
	my $obj = shift;
#
#	we have to create a new ref in the server
#	when we enqueue
#
	$obj->_send_simplex('_add_ref');
	return $obj->SUPER::onEnqueue();
}

sub onCancel {
	my $obj = shift;
#
#	we added a ref when we queued up, so now we
#	need to remove the ref
#
	$obj->_send_simplex('DESTROY');
	return 1;
}

#
#	got some binders we need to figger how to handle
#
sub bind_col {
#
#	keep bound ref locally, and populate on fetch()
#
	my ($obj, $colnum, $ref, $type) = @_;

	unless (defined($ref)) {

		$obj->{_bound_colcnt}--
			if $obj->{_bound_cols}[$colnum] &&
				$obj->{_bound_colcnt};

		$obj->{_bound_cols}[$colnum] = undef;


		$obj->{_bound_coltypes}[$colnum] = $type
			if defined($type);

		return 1;
	}

    return $obj->set_err(-1, "bind_col($colnum,$ref) needs a reference to a scalar")
		unless (ref $ref eq 'SCALAR');

	$obj->{_bound_coltypes}[$colnum] = $type
		if defined($type);

	$obj->{_bound_colcnt}++
		unless $obj->{_bound_cols}[$colnum];

	$obj->{_bound_cols}[$colnum] = $ref;
	return 1;
}

sub bind_columns {
	my $obj = shift;
	my $i = 1;
	map { return undef unless $obj->bind_col($i++, $_); } @_;
	return 1;
}

sub bind_param_inout {
	my ($obj, $pnum, $ref, $type) = @_;

	unless (defined($ref)) {

		$obj->{_bound_paramcnt}--
			if $obj->{_bound_params}{$pnum} &&
				$obj->{_bound_paramcnt};

		$obj->{_bound_params}{$pnum} = undef;


		$obj->{_bound_paramtypes}{$pnum} = $type
			if defined($type);

		return 1;
	}

    return $obj->set_err(-1, "bind_param_inout($pnum,$ref) needs a reference to a scalar")
		unless (ref $ref eq 'SCALAR');

	$obj->{_bound_paramtypes}{$pnum} = $type
		if defined($type);

	$obj->{_bound_paramcnt}++
		unless $obj->{_bound_params}{$pnum};

	$obj->{_bound_params}{$pnum} = $ref;
	return 1;
}

sub bind_param {
	my ($obj, $pnum, $ref, $type) = @_;

	$obj->{_bound_paramtypes}{$pnum} = $type
		if defined($type);

	$obj->{_bound_paramcnt}++
		unless $obj->{_bound_params}{$pnum};

	$obj->{_bound_params}{$pnum} = $ref;
	return 1;
}

sub bind_param_array {
	my ($obj, $pnum, $ref, $type) = @_;

    return $obj->set_err(-1, "bind_param_array($pnum,$ref) needs an arrayref")
		unless (defined($ref) && (ref $ref eq 'SCALAR'));

	$obj->{_bound_paramtypes}{$pnum} = $type
		if defined($type);

	$obj->{_bound_paramcnt}++
		unless $obj->{_bound_params}{$pnum};

	$obj->{_bound_params}{$pnum} = $ref;
	return 1;
}
#
#	everything else should be easy
#
#	get async out of the way
#
sub dbix_threaded_start {
#
#	include any bound parameters
#	NOTE that the app may have provided params
#	in this call
#
	my $obj = shift;
	my $params = scalar keys %{$obj->{_bound_params}} ?
		[ $obj->{_bound_params}, $obj->{_bound_paramtypes} ] : undef;
	return $obj->_start_request(@_, $params, 'execute');
}

sub dbix_threaded_start_array {
	my $obj = shift;
	my $params = scalar keys %{$obj->{_bound_params}} ?
		[ $obj->{_bound_params}, $obj->{_bound_paramtypes} ] : undef;
	return $obj->_start_request(@_, $params, 'execute_array');
}

sub execute {
	my $obj = shift;
	my $params = scalar keys %{$obj->{_bound_params}} ?
		[ $obj->{_bound_params}, $obj->{_bound_paramtypes} ] : undef;
	my @resp = $obj->_send_request(@_, $params, 'execute');
	return undef unless scalar @resp;

	return shift @resp;
}

sub execute_array {
	my $obj = shift;
	my $attrs = shift;
	return $obj->set_err(-1, 'ArrayTupleFetch not supported.', 'S1000')
		if $attrs->{ArrayTupleFetch};
	my $params = scalar keys %{$obj->{_bound_params}} ?
		[ $obj->{_bound_params}, $obj->{_bound_paramtypes} ] : undef;
	my @resp = $obj->_send_request(@_, $params, 'execute_array');
	@{$attrs->{ArrayTupleStatus}} = @{$resp[-1]};
	return $resp[0];
}
#
#	ooops we can't support this yet
#
sub execute_for_fetch {
#	return shift->_send_request(@_, 'execute_for_fetch');
	return shift->set_err(-1, 'execute_for_fetch() not supported.', 'S1000');
}
#########################################################
#
#	in future, we'll need to test the server vs. current
#	resultset count and make sure they're the same, and
#	provide the current rscount to the server for the fetch
#	operation, in case another thread sneaks in ahead of
#	us and grabs the last row of the current RS.
#
#########################################################
sub fetch {
	my $obj = shift;

	my $cols = $obj->{_bound_colcnt} ?
		$obj->{_bound_coltypes} : undef;
	my @resp = $obj->_send_request(@_, $cols, 'fetchrow_arrayref');
	return undef unless scalar @resp;
#
#	if bound columns, populate now
#
	my $row = shift @resp;
	if ($cols) {
		map {
			${$obj->{_bound_cols}[$_]} = $row->[$_-1]
				if $obj->{_bound_cols}[$_];
		} 1..scalar @$row;
	}
	return $row;
}
*fetchrow_arrayref = \&fetch;

sub fetchrow {
	my $obj = shift;
	
	my $cols = $obj->{_bound_colcnt} ?
		$obj->{_bound_coltypes} : undef;
	my @resp = $obj->_send_request(@_, $cols, 'fetchrow');
	return undef unless scalar @resp;

	if ($cols) {
		map {
			$obj->{_bound_cols}[$_] = $resp[$_-1]
				if $obj->{_bound_cols}[$_];
		} 1..scalar @resp;
	}
	return @resp;
}
*fetchrow_array = \&fetchrow;

sub fetchrow_hashref {
	my $obj = shift;
	my $name = $_[0] || 'NAME';

	my $cols = $obj->{_bound_colcnt} ?
		$obj->{_bound_coltypes} : undef;
	my @resp = $obj->_send_request(@_, $cols, 'fetchrow_hashref');
	return undef unless scalar @resp;
	my $row = shift @resp;
#
#	must get the NAME (or selected stmt key), and then correlate
#	column numbers to the returned results...this is *very*
#	heavyweight, and highly discouraged!!!
#
	if ($cols) {
		my $names = $obj->FETCH($name);
		return undef unless $names;
		map {
			$obj->{_bound_cols}[$_] = $row->{$names->[$_]}
				if $obj->{_bound_cols}[$_];
		} 1..scalar @$cols;
	}
	return $row;
}
#
#	only support bind_col for typing !!!
#
sub fetchall_arrayref {
	my $obj = shift;
	
	my $cols = $obj->{_bound_colcnt} ?
		$obj->{_bound_coltypes} : undef;
	my @resp = $obj->_send_request(@_, $cols, 'fetchall_arrayref');
	return scalar @resp ? shift @resp : undef;
}
#
#	only support bind_col for typing !!!
#
sub fetchall_hashref {
	my $obj = shift;
	
	my $cols = $obj->{_bound_colcnt} ?
		$obj->{_bound_coltypes} : undef;
	my @resp = $obj->_send_request(@_, $cols, 'fetchall_hashref');
	return scalar @resp ? shift @resp : undef;
}

#
#	need to create a string-file for this
#	since we can't pass the fh (but we may be able to pass the fd ?)
#
sub dump_results {
	my $obj = shift;
	$_[3] = defined($_[3]) ? fileno($_[3]) : fileno(STDOUT);

	return shift->_send_request(@_, 'dump_results');
}

sub finish {
	return shift->_send_request(@_, 'finish');
}

sub rows {
	return shift->_send_request(@_, 'rows');
}
#
#	need to handle async operations here; we'll
#	need a way to check if the operation is still
#	in progress, and redirect to dbix_threaded_cancel
#
sub cancel {
	my $obj = shift;

	return $obj->_send_request(@_, 'cancel');
}

sub STORE {
#
#	eventually support RowsInCache locally for optimized
#	client/server thread traffic
#
	my ($obj, $attr, $value) = @_;
	$obj->{$attr} = $value,
	return 1
		if $dbix_thrd_lcl_attrs{$attr} || (substr($attr, 0, 1) eq '_');
	return $obj->_send_request($attr, $value, 'STORE');
}

sub FETCH {
	my ($obj, $attr) = @_;
#
#	trap ParamValues and ParamTypes here; we don't
#	let threads see each others parameter bindings
#
	return ($dbix_thrd_lcl_attrs{$attr} || (substr($attr, 0, 1) eq '_')) ? $obj->{$attr} :
		($attr eq 'ParamValues') ? $obj->{_bound_params} :
		($attr eq 'ParamTypes') ? $obj->{_bound_paramtypes} :
			$obj->_send_request($attr, 'FETCH');
}

sub DESTROY {
	my $obj = shift;
#
#	not certain what to do here, other than destroy in the
#	server...guess we'll let it decide on ref counts...
#
	$obj->{_inner}--;
	$obj->_send_simplex('DESTROY')
		unless $obj->{_inner};
}

#
#	these should be stubbed until officially published
#
sub blob_read {
	return shift->_send_request(@_, 'blob_read');
}

sub blob_copy_to_file {
	return shift->_send_request(@_, 'blob_copy_to_file');
}

sub more_results {
#
#	this method gets a bit complicated
#	the server maintains a shared resultset counter,
#	to which each copy of the client stmt handle
#	has a ref. Each stmt handle maintains a private
#	"current resultset" counter
#	if current < server
#		return true
#	else 
#		call server(passing our current in case someone
#			else gets there first)
#
#	also, in fetch operations, stmt object should
#	check the resultset counts
#
	my $obj = shift;
	return 1
		if (${$obj->{_server_rs}} > $obj->{_curr_rs});
	
	return $obj->_send_request($obj->{_curr_rs}, 'more_results');
}

}

1;
__END__

=head1 NAME

DBIx::Threaded - Proxy class to permit DBI objects to be
	shared by multiple threads

=head1 SYNOPSIS

	use DBIx::Threaded
		subclass => DBIx::Chart;	# add any subclass to chain here
	#
	#	see DBI 1.48 docs for all the DBI methods and attributes
	#	In addition, the following methods are provided:
	#
	my $dbh = DBIx::Threaded->connect('dbi:SomeDSN', $user, $pass,
		{ 
			RaiseError => 0, 
			PrintError => 1,
			dbix_threaded_Helper => 'SomeDSNHelper',
			dbix_threaded_marshal => 'freeze',
			dbix_threaded_max_pending => 20
		});

	$id = $dbh->dbix_threaded_start($sql, \%attr);
	$id = $sth->dbix_threaded_start($sql, \%attr);
                                        # start execution of SQL, ala do()

	$rc = $h->dbix_threaded_wait($id);
                                        # wait for prior start() to complete

	$rc = $h->dbix_threaded_wait_until($timeout, $id); 
                                        # wait up to $timeout secs for 
                                        # prior start() to complete

	$rc = $h->dbix_threaded_cancel($id); 
                                        # cancel the specified operation
                                        # may also be initiated by $sth->cancel()
	
	@handles = DBIx::Threaded->dbix_threaded_wait_any(@handles);
                                        # wait for async completion on
                                        # any of @handles; returns the handles
                                        # that have completions
	
	@handles = DBIx::Threaded->dbix_threaded_wait_any_until($timeout, @handles);
                                        # wait up to $timeout secs for
                                        # for async completion on
                                        # any of @handles; returns the handles
                                        # that have completed
	
	@handles = DBIx::Threaded->dbix_threaded_wait_all(@handles);
                                        # wait for async completion on
                                        # all of @handles
	
	@handles = DBIx::Threaded->dbix_threaded_wait_all_until($timeout, @handles);
                                        # wait up to $timeout secs for
                                        # async completion on
                                        # all of @handles

	$h->dbix_threaded_ready($id);
                                        # indicates if the specified operation
                                        # has completed yet

	$tid = $dbh->dbix_threaded_tid();   # returns TID of underlying DBI thread

	DBIx::Threaded->dbix_threaded_create_pool($num_of_threads);
                                        # create pool of threads to use for
                                        # DBI connections; intended for use
                                        # before full app init in order to
                                        # reduce memory size of thread
                                        # interpretter instances

	$dbh->dbix_threaded_force_disconnect();
                                        # forces disconnect, regardless of
                                        # outstanding refs
	
	$h->dbix_threaded_get_queue();      # returns the underlying TQD used
                                        # by the proxy stubs

=head1 DESCRIPTION

DBIx::Threaded provides a subclass of L<DBI> that provides wrappers for
standard DBI objects to permit them to be used by multiple threads.
Due to the limitations of threading and tied objects in Perl 5, DBI
(as of version 1.48), does not permit DBI-generated objects
(namely, connection and statement handles) to be used outside
of the thread in which they are created.

Due to its architecture, DBIx::Threaded also has the pleasant 
side-effect of providing thread-safe access to DBD's which are not 
otherwise thread-friendly or thread-safe (assuming any underlying
client libraries and/or XS code are thread-safe, e.g., do not
rely on unrestricted access to process-global variables).

DBIx::Threaded accomplishes this by spawning a separate server
(or I<apartment>) thread to encapsulate a DBI container class 
L<DBIx::Threaded::Server>, for each connection 
created by the connect() method. All the DBI connection and statement 
interfaces for a single connection are then executed within that thread
(note that this is, in some respects, similar to the way Perl manages
threads::shared variables).

Separate client DBI connection and statement subclasses are also defined
to provide stub method implementations for the various DBI API
interfaces, DBI attributes, and any DBD-specific installed methods or 
attributes.

A L<Thread::Queue::Duplex> I<aka TQD)> object is created for each connection
to provide a lightweight communication channel between the client stubs and
the server container objects, passing parameters and results between
the client and server using either L<threads::shared> variables
for simple scalars and structures, or marshalling via L<Storable> for more
complex structures.

Note that, due to the way in which Perl threads are spawned
(i.e., cloning the entire interpretter context of the spawning thread),
a C<dbix_threaded_create_pool()> class level method is provided to permit creation
of minimal context threads during application initialization, in order
to conserve memory resources.

Also note that DBIx::Threaded supports DBI subclass chaining so that,
e.g., it is possible to use L<DBIx::Chart> with DBIx::Threaded. The subclass
may be specified either as an imported hash value in the form

	use DBIx::Threaded subclass => SubClass;

or in the C<connect()> call via the C<RootClass> attribute, as
supported by L<DBI>.

Finally, in the event DBIx::Threaded is used in a Perl environment
that does B<not> support threads (i.e., C<$Config{useithreads}> is false),
it will fallback to the basic DBI behaviors, i.e., C<connect()> will
simply call C<DBI-E<gt>connect()>, and thus the caller will get a regular
DBI connection handle (or, if subclasses were declared when 
DBIx::Threaded was C<use>'d, a subclassed connection handle).

DBIx::Threaded provides the following classes:

=over 4

=item DBIx::Threaded

main client side subclass of DBI

=item DBIx::Threaded::dr

client side subclass of DBI::dr

B<NOTE>: since each connection is isolated in its own thread
(and hence, perl interpretter) context, use of the driver handle
is of marginal value, as any operations applied to a driver handle
derived from a DBIx::Threaded connection can only effect the driver running
in the container thread, and will have B<no> effect on any of the other
connection instances.

=item DBIx::Threaded::db

client side subclass of DBI::db

=item DBIx::Threaded::st

client side subclass of DBI::st

=item DBIx::Threaded::Server

implements the server side, as a container class for DBI

=back

DBIx::Threaded provides all the same methods, attributes, and behaviors
as DBI, plus some additional methods relevant to asynchronous execution
and general threading housekeeping.

=head2 Notation and Conventions

The following conventions are used in this document:

  $dbh    Database handle object
  $sth    Statement handle object
  $drh    Driver handle object (rarely seen or used in applications)
  $h      Any of the handle types above ($dbh, $sth, or $drh)
  $rc     General Return Code  (boolean: true=ok, false=error)
  $rv     General Return Value (typically an integer)
  @ary    List of values returned from the database, typically a row of data
  $rows   Number of rows processed (if available, else -1)
  $fh     A filehandle
  undef   NULL values are represented by undefined values in Perl
  \%attr  Reference to a hash of attribute values passed to methods

Note that Perl will automatically destroy database and statement handle objects
if all references to them are deleted. B<However>, since DBIx::Threaded
derived objects may be in use by multiple concurrent threads, 
DBIx::Threaded::Server maintains a separate reference count, and will
only destroy an object when all outstanding references have been
destroyed.

=head2 Outline Usage

To use DBIx::Threaded,
first you need to load the DBIx::Threaded module:

  use DBIx::Threaded;
  use strict;
  use warnings;

(C<use strict;> and  C<use warnings;> aren't required, but if you want my support,
you'd better use them!)

Then you need to L</connect> to your data source and get a I<handle> for that
connection:

	$dbh = DBIx::Threaded->connect($dsn, $user, $password,
		{ 
			RaiseError => 1, 
			AutoCommit => 0,
			dbix_threaded_helper => 'SomeDSNHelper',
			dbix_threaded_marshal => 'freeze',
			dbix_threaded_max_pending => 20
		});

Refer to L<DBI> for all the DBI standard methods, attributes, and behaviors.

The following additional connection attributes are defined:

=over 4

=item B<dbix_threaded_helper> I<(not yet fully supported)>

Provides the name of a "helper" class to be used by
the apartment thread to implement useful, but non-standard
methods. Currently, only the following methods are defined:

	# Constructor; takes the associated connection handle
	$helper = $helperclass->new($dbh);

	# Wrapper around the underlying DBD's more_results()
	# implementation (if any). Should return 1 if there are more
	# results, undef otherwise.
	$helper->more_results($sth);

	#
	# Wrappers for various cancelable async "start execution"
	# methods; the following special parameters are provided:
	#
	#	$cmdq - the TQD for this connection
	#	$id   - the unique ID of the initated request
	#
	# These parameters are provided to permit $helper to poll 
	# the connection's TQD via the cancelled($id) method to determine
	# if the application has cancelled the operation.
	#
	# Also note that the helper may only implement a few of these;
	# DBIx::Threaded::Server will test $helper->can($method) to
	# determine if the method has been implemented.
	#
	# The helper should return the usual results for the
	# implemented operation. If the operation is cancelled,
	# the helper should returned either the usual results
	# (if they were received before the cancel), or
	# an appropriate error message indicating the cancel
	# was applied.
	#
	# Note that the various fetch() methods are not cancelable,
	# though they may incur long latencies in some instances.
	#
	$helper->start_do($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_prepare($cmdq, $id, $dbh, $sql, $attrs);
	$helper->start_prepare_cached($cmdq, $id, $dbh, $sql, $attrs);
	$helper->start_tables($cmdq, $id, $dbh, $sql, $attrs);
	$helper->start_table_info($cmdq, $id, $dbh, $sql, $attrs);
	$helper->start_column_info($cmdq, $id, $dbh, $sql, $attrs);
	$helper->start_primary_key($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_primary_key_info($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_foreign_key_info($cmdq, $id, $dbh, $sql, @params, $attrs);

	$helper->start_selectrow_array($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_selectrow_arrayref($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_selectrow_hashref($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_selectall_arrayref($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_selectall_hashref($cmdq, $id, $dbh, $sql, @params, $attrs);
	$helper->start_selectcol_arrayref($cmdq, $id, $dbh, $sql, @params, $attrs);

	$helper->start_execute($cmdq, $id, $sth, @params);
	$helper->start_execute_array($cmdq, $id, $sth, \%attrs, @params);

See the L<Cancelable Async Operations> below for more details.

=item B<dbix_threaded_marshal>

Specifies the type of marhsalling to use when transfering
data between the client stub and the apartment thread.
Valid values are 'freeze' and 'share'. 'freeze' uses the
L<Storable> module's C<freeze()> and C<thaw()> methods
to convert complex structures into scalar values, while 'share'
converts structures into L<threads::shared> variables, which may
be faster, but does not currently support deepcopy operations.
Default is 'share'.

=item B<dbix_threaded_max_pending>

Specifies the maximum number of pending requests to be queued
to the apartment thread. This value is applied to the underlying
L<Thread::Queue::Duplex> MaxPending attribute; when more than the
specified number of requests are pending in the associated
TQD, the TQD C<enqueue()> operation will block until the
number of pending requests has dropped below the specified
threshold. Default is zero, i.e., no limit.

=back

In addition, the following methods are defined:

=over 4

=item C<DBIx::Threaded-E<gt>dbix_threaded_create_pool($num_of_threads)>

Class level method to create pool of threads to use for
DBIx::Threaded::Server objects; intended for use before 
full application initialization in order to reduce memory 
size of thread interpretter instances. 
Perl threads are implemented by cloning the entire interpretter
context of the spawning thread, which can result in 
significant replication of unused resources. By pre-allocating
threads early during application initialization, the resources
consumed by the container threads can be reduced.

=item C<$id = $dbh-E<gt>dbix_threaded_start()> I<async> C<$dbh-E<gt>do()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_prepare()> I<async> C<$dbh-E<gt>prepare()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_prepare_cached()> I<async> C<$dbh-E<gt>prepare_cached()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_tables()> I<async> C<$dbh-E<gt>tables()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_table_info()> I<async> C<$dbh-E<gt>table_info()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_column_info()> I<async> C<$dbh-E<gt>column_info()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_primary_key()> I<async> C<$dbh-E<gt>primary_key()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_primary_key_info()> I<async> C<$dbh-E<gt>primary_key_info()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_foreign_key_info()> I<async> C<$dbh-E<gt>foreign_key_info()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_selectrow_array()> I<async> C<$dbh-E<gt>selectrow_array()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_selectrow_arrayref()> I<async> C<$dbh-E<gt>selectrow_arrayref()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_selectrow_hashref()> I<async> C<$dbh-E<gt>selectrow_hashref()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_selectall_arrayref()> I<async> C<$dbh-E<gt>selectall_arrayref()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_selectall_hashref()> I<async> C<$dbh-E<gt>selectall_hashref()>

=item C<$id = $dbh-E<gt>dbix_threaded_start_selectcol_arrayref()> I<async> C<$dbh-E<gt>selectcol_arrayref()>

=item C<$id = $sth-E<gt>dbix_threaded_start()> I<async> C<$sth-E<gt>execute()>

=item C<$id = $sth-E<gt>dbix_threaded_start_array()> I<async> C<$sth-E<gt>execute_array()>

Starts the specified DBI operation in async mode. Once the request
has been queued to the apartment thread via the associated connection's
TQD, the methods return immediately. Applications can use this 
method to spawn multiple non-blocking database operations, then 
perform other concurrent processing, and finally L<wait()> for the 
database operations to complete. 

Note that, since DBI does not yet define a standard external 
cancel/abort mechanism, a helper class implementation is
required to safely cancel these operations once they have been 
initiated (see L<dbix_threaded_helper> attribute). However, 
as DBIx::Threaded implements the L<Thread::Queue::Duplex> 
class, C<cancel()> and C<cancel_all()> methods are available to partially
support cancellation of operations before the apartment thread
has begun servicing the request; refer to
the L<Thread::Queue::Duplex> docs for details.

=item C<$rc = $h-E<gt>dbix_threaded_wait($id)>

Wait indefinitely for completion of the specified async operation.
B<Note> that the return values for some C<start()>'d operations
(e.g., C<$sth-E<gt>execute_array()>) will 
return an array of items (e.g., for C<$sth-E<gt>execute_array()>, 
the return count, and an arrayref of ArrayTupleStatus) unless 
explicitly called in scalar context, 
due to the transfer of additional information from the apartment 
thread to the client.

=item C<$rc = $h-E<gt>dbix_threaded_wait_until($timeout, $id)>

Wait up to $timeout secs for for completion of the specified async operation.
	
=item C<$rc = $h-E<gt>dbix_threaded_cancel($id)>

Requests cancellation of the specified C<$dbh-E<gt>dbix_threaded_startXXX()>'ed 
operation. Note that actual cancellation will only occur if a
helper class has been supplied that implements the associated C<start()> 
method, B<and> the specific operation has not already completed.

=item C<@handles = DBIx::Threaded-E<gt>dbix_threaded_wait_any(@handles)>

Wait indefinitely for completion of B<any> start()'ed operation
on any of @handles (which may be initiated on either connection or 
statement handles). Returns an array of handles.
	
=item C<@handles = DBIx::Threaded-E<gt>dbix_threaded_wait_any_until($timeout, @handles)>

Wait up to $timeout secs for completion of B<any> start()'ed operation
on any of @handles (which may be either connection or statement handles)
	
=item C<@handles = DBIx::Threaded-E<gt>dbix_threaded_wait_all(@handles)>

Wait indefinitely for completion of start()'ed operations
on B<all> of @handless
	
=item C<@handles = DBIx::Threaded-E<gt>dbix_threaded_wait_all_until($timeout, @handles)>

Wait up to $timeout secs for completion of start()'ed operations
on B<all> of @handles

=item C<$rc = $h-E<gt>dbix_threaded_ready($id)>

Test if the specified operation is complete.

=item C<$tid = $h-E<gt>dbix_threaded_tid()>

Returns TID of handle's underlying Perl thread

=item C<$dbh-E<gt>dbix_threaded_force_disconnect()>

Forces disconnection of the underlying connection, regardless
if there are any outstanding references (either to the 
connection or to any of its statement handles)

B<NOTE:> Since a connection, and any of its subordinate
statement handles, may be passed to, and in use by, any thread
at any time, the DBIx::Threaded::Server object maintains a reference
count on the connection and statement objects. On C<DESTROY()>, or
C<disconnect()>, the appropriate reference counts are decremented;
the C<DESTROY()> or C<disconnect()> operation will only
be applied in the server if the object's reference count 
drops to zero. Further note that incrementing or decrementing the
reference count on a statement object results in the same operation
on the associated connection's reference count.

C<dbix_threaded_force_disconnect()> has been provide as a safety outlet if needed.

=item C<$h-E<gt>dbix_threaded_get_queue()>

Returns the TQD object used as a communication channel between the 
client proxy and the container thread. Useful, e.g.,  for class-level TQD 
wait_any/all() when a thread needs to monitor multiple TQD's.

=back

=head2 Unsupported Methods/Attributes

The following methods and attributes are currently unsupported,
but may be implemented in future releases:

=over 4

=item C<$sth-E<gt>execute_array()> with C<ArrayTupleFetch> attribute

Since it requires a CODE ref or direct access to another
statement handle, it can't be directly passed
to the container thread. An implementation may be
provided in a future release.

=item C<$dbh-E<gt>clone()>

I<An implementation should be provided in a future release.>

=item C<connect_cached()>

I<Currently implemented as alias to regular connect().>

=item C<$drh-E<gt>disconnect_all()>

Due to the threaded operation, and the fact that connections
may be created in any thread at any time, disconnect_all()
executed in one thread may not have meaning for other threads,
as there's no real way for a driver handle to be aware
of all the connections which may have been generated from it.

=item C<$sth-E<gt>execute_for_fetch()>

Since it requires a CODE ref, it can't be directly passed
to the container thread. I<An implementation should be
provided in a future release, using some form of proxy>.

=item B<installed methods>

While DBD's can install methods in the container thread, they
are not currently available in the client proxy; use the C<func()>
method instead. I<An implementation should be
provided in a future release, once I figure out how to 
proxy these>.

=item C<bind_col(), bind_columns()> with C<fetchall_arrayref(), fetchall_hashref()>

Due to the issues described below, DBIx::Threaded does not populate
bound variables on a fetchall_arrayref() or fetchall_hashref()
operation.

=item C<swap_inner_handle()>

Methinks this would cause serious headaches for apartment threading,
(its certainly giving me headaches thinking about it) and I'm not 
certain anyone has any use for it anyway.

=item C<$dbh-E<gt>take_imp_data()>

This method is intended for the DBI::Pool method of "loaning"
a connection to another thread; it has the side effect of
making the connection in the loaning thread non-functional. 
As DBIx::Threaded provides a more flexible solution for sharing 
B<both> connections B<and> statement objects between threads 
B<without> leaving the object in a non-functioning state,
it serves no purpose in the DBIx::Threaded environment. Consider it
unimplemented.

=back

=head2 Application Notes

=over 4

=item B<DBix::Threaded is not a true DBI subclass>

True DBI subclasses derive their object hierarchy through
the DBI via the (possibly overridden) DBI::dr class C<connect()>
method, allowing DBI to add "magic" to the created objects,
which is later used in various methods (e.g., C<set_err(), errstr()>, etc.).

In order to be able to C<curse()> and C<redeem()> DBIx::Threaded
objects for passing between threads via TQD's, DBIx::Threaded
must use regular objects without the added DBI "magic". As a result,
some original DBI behaviors may not be fully compatible or implemented.
I<Note:> Most DBI behaviors lost due to this situation have
been implemented by borrowing code from L<DBI::PurePerl>, esp.
for the error handling methods and attributes; hopefully, the
impact is minimal.

One known impact is that the 

	$dbh = DBI->connect($dsn, $user, $password, {
		...
		RootClass => 'DBIx::Threaded',
		});

form of connection B<is not supported>. C<connect()> must be called
directly on the DBIx::Threaded class.

=item B<Avoid> C<bind_col(), bind_columns(), bind_param_inout(), bind_param_inout_array()>

Output binding in a threaded environment adds significant complexity,
thereby reducing any percieved performance gains to be achieved
by the usual C<bind()> methods. While DBIx::Threaded does support
these methods with all fetches, excluding fetchall_arrayref() and
fetchall_hashref(), they pose several issues:

=back

=over 8

=item C<threads::shared> I<variables cannot be bound>

bind_col() et al. does not support binding tied variables; L<threads::shared>
is implemented as a tie. Hence, the binding operation is not a
real bind into the container thread environment.

=item I<Multiple threads may bind simultaneously>

If concurrent threads apply bind operations on the same
statement handle, DBIx::Threaded isolates each set of bind()'s
to the individual thread, i.e., the first thread will only see the
result of fetch() operations which are initiated in its thread, and
its bound variables will B<not> be modified by a fetch() in 
another thread on the same statement handle.

In addition, when a statement handle is passed to another thread, 
all output bindings are removed in the receiving thread (though
they continue to exist in the original thread).

Finally, the DBI (1.48) states that multiple variables can be bound
to the same column on the same statement. DBIx::Threaded only
supports a single bind variable; any subsequent bind() operation
on a column that already has a bound variable will replace the
old binding with the new one.

=item I<Performance Impact>

Due to the prior bind isolation issue, DBIx::Thread must explicitly
load the bind variables for each C<fetch()> operation.

=back

Note that the C<bind_col()> and C<bind_column()> methods are supported
with C<fetchall_arrayref> and C<fetchall_hashref>, but only for the purposes
of specifying returned column type information.

=over 4

=item B<Statements Returning Multiple Result Sets>

I<As of release 1.48, DBI does not publish a standard interface
for handling multiple result sets from a single statement. However,
a more_results() stub method has been defined, and several DBD's
do support the capability via driver specific methods or attributes.
This section attempts to detail the issues
involved in safely supporting the capability in DBIx::Threaded; note that
this solution has not yet been fully implemented.>

Some special considerations must be applied to support multiple
resultsets from a single statement. Most notably, in the event
multiple threads are consuming results from the same statement,
some coordination between the threads is required to notify
all threads that the current resultset is exhausted, and a
subsequent resultset is now available.

Each statement object in the server thread will be assigned
a shared scalar resultset count, that is incremented each time
the server detects that a resultset has been exhausted (i.e.,
a fetch operation returns C<undef>). This shared scalar will
also be referenced by each client stub statement object created
for the statement. In addition, each client stub statement
keeps its own private resultset counter. On each fetch()
operation, the client will compare its private counter to the
shared counter and, if the private count is less than the
shared count, it will return C<undef>, indicating the current
resultset is exhausted. When an application calls the more_results()
method, the client stub increments its private resultset count,
and returns true, until its private count is equal to or greater than
the shared count.

The client also passes its private count to the server on each fetch
operation, in order for the server to verify the client is
fetching on the current resultset (as it is possible for another
thread to have exhausted the resultset while the current thread's
request was waiting in the TQD).

Since each DBD has its own C<more_results()> implementation (for those
supporting it), DBIx::Threaded relies on the "helper" module interface
(described under the L<dbix_threaded_helper> attribute definition
above) to provide a single consistent more_results() implementation.

=item B<Scrollable Cursor Support>

Like multiple resultsets, as of release 1.48, DBI does not 
provide a standard interface for scrollable cursors. However,
some DBD's support the capability via either SQL syntax, or
driver-specific methods or attributes.
This section attempts to detail the issues
involved in supporting scrollable cursors for statements
that may be shared across multiple threads.

In practical terms, sharing of scrollable cursors
between threads is probably a B<very bad idea>. Even if 
DBIx::Threaded could detect a position operation, and
your application was notified of the positioning, it is unlikely
it will be able to do anything about it, other than abort
the thread.

=item B<Cancelable Async Operations>

Some drivers provide fully async capabilities
for at least a subset of the supported interface
(e.g., C<$sth-E<gt>execute()>). Access to such capability
from within DBIx::Threaded::Server could be very valuable,
esp. for drivers permitting external cancel/abort of
in-progress C<execute()> operations. While the DBI does
not currently define a standard interface, DBIx::Threaded
provides a "helper" module interface (described in the
L<dbix_threaded_helper> attribute definition) with
which individual drivers can provide cancelable async 
versions of the usual DBI API interfaces.

The helper interfaces provide the connection's TQD and the 
specific call's unique identifier as parameters to permit 
polling of the TQD C<cancelled($id)> method. If C<cancelled()>
returns true, the implementation can initiate a cancel/abort
operation on the pending operation.

The helper may only support a subset of the cancelable methods.
DBIx::Threaded::Server will test $helper->can($method) to
determine if the method has been implemented.

The helper should return the usual results for the
implemented operation. If the operation is cancelled,
the helper should returned either the usual results
(if they were received before the cancel), or
an appropriate error message indicating the cancel
was applied.

The helper checks for async versions of the following DBI API 
methods:

	$dbh->do();
	$dbh->prepare();
	$dbh->prepare_cached();
	$dbh->tables();
	$dbh->table_info();
	$dbh->column_info();
	$dbh->primary_key();
	$dbh->primary_key_info();
	$dbh->foreign_key_info();
	$dbh->selectrow_array();
	$dbh->selectrow_arrayref();
	$dbh->selectrow_hashref();
	$dbh->selectall_arrayref();
	$dbh->selectall_hashref();
	$dbh->selectcol_arrayref();

	$sth->execute();
	$sth->execute_array();

Note that the various fetch() methods are not cancelable,
though they may incur long latencies in some instances. A
future release may provide support for cancelable fetches.

=item B<Behavior of Errors and Warnings>

Errors and warnings are reported and handled as usual,
except that C<PrintError>, C<PrintWarn>, C<RaiseError>,
C<HandleError>, and C<HandleSetErr>
are all disabled in the apartment thread. Instead, any error
or warning result will be passed back to the client stub,
where the setting of the various error/warning attributes
will be applied.

B<Also note> that the C<HandleError>, and C<HandleSetErr>
attributes B<cannot> be passed between threads, since
their values are coderefs. To use those attributes,
they must be explicitly re-instantiated in the receiving thread
whenever a handle is passed between threads.

C<$DBIx::Threaded::err, $DBIx::Threaded::errstr,> and C<$DBIx::Threaded::state>
class variables (analogous to the DBI equivalents) are provided to report 
class level errors, e.g., for failed connect() calls.

Finally, note that a handle's C<ErrCount> attribute is reset to zero
in the receiving thread when a handle is passed between threads.

=item B<Class methods> C<installed_versions()>, C<data_sources()>

As both these class-level methods cause DBI drivers to be loaded,
DBIx::Threaded must execute them in an C<async> BLOCK, in order
to isolate the impact of the driver loading. Needless to say,
this creates some extra overhead; my advice is I<just don't do it>.

=item B<Attribute Handling>

For most attributes, the client stub C<STORE> and C<FETCH> methods
are simply redirected to the associated apartment thread. As a result,
setting and retrieving handle attributes may be a long latency operation,
depending on how many and for what purpose other threads are 
concurrently using the underlying object.

Some attributes are B<not> passed through to the apartment thread,
including C<PrintError>, C<PrintWarn>, C<RaiseError>, C<HandleError>, 
C<HandleSetErr>, C<$dbh-E<gt>{Driver}>, and C<$sth-E<gt>{Database}>.

Most of these locally handled attributes are related to error
processing, as described above.
C<Driver> and C<Database>, however, are special cases. A fetch on 
C<Driver> causes the connection object to construct a new "transient" 
client stub driver. The C<$sth->{Database}> attribute is populated
with the original connection object B<only> if the statement is
created and used in the same thread that the connection object 
was created in>. If a statement handle is passed to another thread,
C<$sth->{Database}> is populated with a transient connection object
when it is C<redeem()>'d in the receiving thread.

When using a transient driver object, be aware
that, due to possible threading segregation, the information it returns 
may not reflect a true global driver state, and modifications applied
to it may not effect all connection or statement instances. For transient
connection objects, the object will behave identically to the original,
but performing a comparison operation between 2 transient objects,
or a transient and original object, for the same connection, will
not be equal. I<Note:> Transient objects are returned due to the
possibility that the current thread may not have a reference to the
original parent driver or connection object.

Finally, modifying some attributes may be problematic when sharing
a handle between multiple threads. If one thread modifies behavioral
or presentation attributes on a shared object (e.g., C<ChopBlanks>, 
C<FetchHashKeyName>, etc.), all threads referencing the modified object
will observe the changed behavior or presentation.

=item C<$dbh-E<gt>last_insert_id()>

Since multiple threads may be applying insert operations to the same
connection, the value returned by C<$dbh-E<gt>last_insert_id()>
may not be the value relevant to the current thread's last insert.

=item C<trace()>

When turning on tracing, be aware that not all connections may be
effected, due to possible thread segregation. In addition, since
multiple concurrent trace operations are possible, the output trace
file may be a bit scrambled or out of sequence.

=item C<ParamValues> and C<ParamTypes> B<attributes>

The values returned for these will always be B<only> the values
and/or types supplied B<within the calling thread>. In other words,
the values supplied in a C<bind_param()> in one thread
are not visible to another thread. B<Note>, however, that
a parameter value bound by one thread I<may> impact another
thread executing the same statement handle if the 2nd thread
does not bind a new value to the parameter, i.e., the
container thread will retain and reuse the bound parameters values
from the most recent binding.

=item B<Application Private Attributes>

DBIx::Threaded objects prefix all private members with
an underscore ('_'). When such attributes are encountered
by the C<STORE()> or C<FETCH()> methods, the attribute
is applied to the local client stub object, rather than
being passed to the apartment thread. An application may 
apply thread-private application-specific attributes to
DBIx::Threaded objects; note that these attributes will
B<not> be transfered to the receiving thread when an object
is passed on a TQD.

Also note that, if the DBD in use permits caching of
application-specific attributes on its objects, applications
can use that feature to communicate attributes between
threads (assuming the attributes do not begin with
'_').

=item B<Using Signals and Threads>

B<JUST DON'T DO IT!!!>

See the "Process-scope Changes" section of the
L<Perl Threads Tutorial|perlthrtut> as to why
it probably won't work. It certainly won't be portable,
and, as has ever been the case with signals, at least 25%
of the time, it won't do what you expect.

=back

=head1 TESTING

In order to provide a useful test environment, DBIx::Threaded's test script
relies on "real" DBDs to execute the tests. The current test script (in t/test.t)
recognizes the following DBDs:

	DBD::Teradata (Ver 2.0+)
	DBD::ODBC (ODBC driver for Teradata)
	DBD::CSV
	DBD::Amazon
	DBD::SQLite

Additional DBDs can be configured by updating the C<%query_map> variable
at the beginning of the test script. Each driver has a specific entry
in the C<%query_map>, keyed by the driver name, which is derived
from the DSN supplied from the B<DBIX_THRD_DSN> environment variable.
Note that ODBC drivers are a special case, in that, in addition to a generic
ODBC driver entry, driver specific entries can be added using the
prefix "ODBC_" concatenated to the upper-cased version of the string
returned by C<$dbh->get_info(17)>, e.g., "ODBC_TERADATA" for ODBC using
a Teradata driver.

Each C<%query_map> entry is a hashref containing hte following keys:

=over 4

=item CanPing

If true, C<$dbh-E<gt>ping> will be tested

=item CanGetInfo

If true, C<$dbh-E<gt>get_info> will be tested
to retrieve the DBMS version info.

=item CanDataSources

If true, C<$dbh-E<gt>data_sources> will be tested

=item CanTableInfo

If true, C<$dbh-E<gt>table_info> will be tested against
the table created by the L<CreateTable> SQL entry

=item CanColumnInfo

If true, C<$dbh-E<gt>column_info> will be tested against
the table created by the L<CreateTable> SQL entry

=item CanPKInfo

If true, C<$dbh-E<gt>primary_key_info> will be tested against
the table created by the L<CreateTable> SQL entry

=item CanPK

If true, C<$dbh-E<gt>primary_key> will be tested against
the table created by the L<CreateTable> SQL entry

=item CanFKInfo

If true, C<$dbh-E<gt>foreign_key_info> will be tested against
the table created by the L<CreateTable> SQL entry

=item CanCommit

If true, C<$dbh-E<gt>commit>, C<$dbh-E<gt>rollback>, and C<$dbh-E<gt>begin_work>
will be tested

=item ConnSetup

Specifies a query to be executed immediately after connection in order
to setup any environment or connection properties in the DBMS.

=item UserDateTime

Specifies a simple query to return a single row with 3 columns.
Usually something like "SELECT CURRENT_USER, CURRENT_DATE, CURRENT_TIME".

=item CreateTable

Specifies a simple query to create a (possibly temporary) table, e.g.,

	create volatile table thrdtest (
		col1 int, 
		col2 varchar(100),
		col3 decimal(10,3)
	) unique primary index(col1)
	on commit preserve rows

=item InsertRow

Specifies an INSERT statement with placeholders to insert values into
the table created by CreateTable, e.g.,

	insert into thrdtest values(?, ?, ?)

Note that the values to be inserted are of INTEGER, VARCHAR, and DECIMAL
types.

=item SelectRows

Specifies the query to use to select all the columns out of the
table created by CreateTable, e.g.,

	select * from thrdtest order by col1

=item HashCol

Specifies the name of the column to be used as the hash key for
testing C<selectall_hashref()>

=back

=head2 Running the Tests

The test script uses 4 environment variables to establish the test
connection:

	DBIX_THRD_DSN - the usual 'dbi:Driver:dsn' string
	DBIX_THRD_USER - a username for the connection
	DBIX_THRD_PASS - a password for the connection
	DBIX_THRD_SUBCLASS - the name of a DBI subclass to be chained
		for testing, e.g. "DBIx::Chart"

Only DBIX_THRD_DSN is required; if either DBIX_THRD_USER or 
DBIX_THRD_PASS is undefined, they will simply
omit the undefined arguments from the C<connect()> call. Likewise, omitting
DBIX_THRD_SUBCLASS will simply omit the C<RootClass> attribute.

=head2 Testing Notes

=over 4

=item Microsoft Windows Issues

Testing with ActiveState Perl 5.8.3 on Windows XP has exposed a bug
in Perl threads causing the test to crash on exit. Using Perl 5.8.6
or higher (not just for testing, but in general) is highly recommended.

=item Currently Tested Platforms

The following platform/Perl/DBD's have been tested thus far
(reports for additional drivers, and associated patches for
the test script, are very welcome):

	OS                     Perl Version  DBD
	-----------------      ------------  ------------------------
	Windows XP             AS 5.8.3      DBD::Teradata 8.002
	Windows XP             AS 5.8.3      DBD::CSV
	Windows XP             AS 5.8.3      DBD::SQLite
	Windows XP             AS 5.8.3      DBD::ODBC (Teradata)
	Windows XP             AS 5.8.3      DBD::CSV w/ DBIx::Chart

	Windows 2000           AS 5.8.7      DBD::Teradata 8.002
	Windows 2000           AS 5.8.7      DBD::CSV
	Windows 2000           AS 5.8.7      DBD::ODBC (Teradata)

	Linux Fedora Core 4    5.8.7         DBD::CSV
	Linux Fedora Core 4    5.8.7         DBD::SQLite

	Mac OS X 10.3.9(PPC)   AS 5.8.7      DBD::Teradata 8.002
	Mac OS X 10.3.9(PPC)   AS 5.8.7      DBD::CSV
	Mac OS X 10.3.9(PPC)   AS 5.8.7      DBD::SQLite

=back

=head1 SEE ALSO

L<DBI>, L<Thread::Queue::Duplex>, L<threads>, L<threads::shared>, L<Storable>

=head1 AUTHOR, COPYRIGHT, & LICENSE

Dean Arnold, Presicient Corp. L<darnold@presicient.com>

Copyright(C) 2005, Presicient Corp., USA

Permission is granted to use this software under the same terms
as Perl itself. Refer to the L<Perl Artistic License|perlartistic> for details.

=cut
