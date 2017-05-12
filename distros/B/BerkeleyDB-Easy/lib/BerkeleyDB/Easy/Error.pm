package BerkeleyDB::Easy::Error;

use strict;
use warnings;

use BerkeleyDB::Easy::Common;

our (@ISA, @EXPORT, %EXPORT_TAGS, %Errors);

BEGIN {
	constant->import({ CODE => 0, DESC => 1, SKIP => 3 });
}

BEGIN {
	@ISA         = qw(Exporter);
	@EXPORT      = ();
	%EXPORT_TAGS = (
		subs => [qw(_exception _throw _assign _const _lookup _caller _carp)],
	);
	
	# All our constants get BDB_ prefix. And they're dualvars, with neg
	# values to avoid stepping on toes.
	%Errors = (
		BDB_DEFAULT => [-900, q(Default error)                      ],
		BDB_UNKNOWN => [-404, q(Unknown error)                      ],
		BDB_PLACE   => [-666, q(Placeholder error)                  ],
		BDB_HANDLE  => [-902, q(Failed to create BerkeleyDB handle) ],
		BDB_TYPE    => [-901, q(Invalid BerkeleyDB database type)   ],
		BDB_FLAG    => [-903, q(Invalid options flag)               ],
		BDB_PARAM   => [-904, q(Invalid options parameter)          ],
		BDB_CONST   => [-905, q(Invalid constant function)          ],
	);
	
	# Create constants and make them available for export under the
	# 'errors' tag.
	for my $name (keys %Errors) {
		my $code = $Errors{$name}->[CODE];
		constant->import($name, Scalar::Util::dualvar($code, $name));
		push @{$EXPORT_TAGS{errors}}, $name;
	}
	
	# Export everything.
	push @EXPORT, map @{$EXPORT_TAGS{$_}}, keys %EXPORT_TAGS;
}

#
# Define the attributes for exception objects. _install called with a 
# single argument as done here creates a simple named accessor
#
for (qw(code name time level desc detail package file line sub trace)) {
	__PACKAGE__->_install($_);
}

#
# Stringify an exception object. Create default message if none is set.
#
sub stringify {
	my $self = shift;

	$self->{message} ||= join q(. ), grep $_, 
		$self->{desc},
		$self->{detail};

	$self->{string}  ||= sprintf q([%s] %s (%d): %s %s),
		$self->{sub},
		$self->{name},
		$self->{code},
		$self->{message},
		$self->{trace};
}

sub numberify { shift->{code} }

use overload fallback => 1,
	q("") => q(stringify),
	q(0+) => q(numberify);

#
# Throw an exception. First, get it's severity level and ignore it if
# appropriate. Otherwise call _exception to build the error object and
# _log to log it and warn/die as necessary.
#
sub _throw {
	my ($self, $error, $extra, $flag) = @_;

	DEBUG and do {
		my $code = int($error) || q(?);
		$self->_debug(qq(Throwing "$error" ($code)));
	};
	
	my $level = $self->_assign($error);
	if ($level == BDB_IGNORE) {
		TRACE and $self->_trace(qq(Ignoring exception: $error));
		return;
	}

	my $exc = $self->_exception($error, $extra, $flag);
	$exc->{level} = $level;
	$self->_log($level, $exc);

	$exc;
}

#
# Build an exception.
# (Internal method, used by _throw)
#
sub _exception {
	my ($self, $error, $extra, $flag) = @_;
	
	our $HiRes ||= !!$self->_try(sub { require Time::HiRes });
	my %exc = (
		time => ($HiRes ? Time::HiRes::time() : time),
		code => (int $error || int BDB_UNKNOWN),
	);
	
	# Populate package, file, line and sub attributes.
	# If VERBOSE, get a full stack trace.
	my $caller  = $self->_caller(SKIP);
	$exc{$_}    = $caller->{$_} for qw(package file line sub);
	$exc{trace} = BDB_VERBOSE
		? $self->_carp
		: qq(at $exc{file} line $exc{line}.);

	my @detail = $extra;

	# TODO: a lot of this needs to be reworked. Misbehaving parts
	#       commented out.
	
	# Gnarly logic here to determine where the error came from
	# and consolidate diagnostic messages that were squirreled away
	# into a nice object. From perlvar:
	#
	#  $!  = $OS_ERROR = $ERRNO : current value of the C errno integer.
	#  $^E = $EXTENDED_OS_ERROR : Error information specific to the current
	#    operating system. At the moment, this differs from $! under only
	#    VMS, OS/2, and Win32 (and for MacPerl). On all other platforms, 
	#    $^E is always just the same as $! .

	# DB_ prefix means error is from BerkeleyDB (the C library).
	# Parse the exception into name and desc.
	# If $! or $^E are also set, put them in the 'detail' field.
	if ($error =~ /^DB_/) {
		@exc{qw(name desc)} = $error =~ /^(DB_\w+):\s*(.+?)\.?$/;
		push @detail, $!, ($^E ne $! and $^E) unless $flag;
	}

	# Perl/OS error. Look up name from errno. Put $^E into 'detail'.
	# If $flag is set, we never localized $! (due to optimization setting)
	# so its value could be stale. In that case, skip this check.
	# elsif ($! and not $flag) {
	# 	@exc{qw(name desc)} = ($self->_lookup($!), $!);
	# 	push @detail, ($^E ne $! and $^E);
	# }

	# Extended OS error. Usually won't appear without $!, but handle the
	# possibility just in case. If $flag is set, we never localized $^E.
	# elsif ($^E and not $flag) {
	# 	@exc{qw(name desc)} = ($self->_lookup($^E), $^E);
	# }

	# BDB_ prefix means error was generated internally.
	elsif ($error =~ /^BDB_/) {
		@exc{qw(name desc)} = ($error, $Errors{$error}->[DESC]);
	}

	# Fallback. Not sure where error originated.
	else {
		@exc{qw(name desc)} = ($self->_lookup($error), $error);
	}
	
	# BerkeleyDB.pm error. Should only happen when there's a BerkeleyDB
	# (C library) error during initialization. In that case, the BDB.pm
	# error global will usually contain additional info.
	if ($BerkeleyDB::Error) {
		my $match  = qr/(?::\s*)?([^:]+?)\.?$/;
		my ($err ) = $BerkeleyDB::Error =~ $match;
		my ($desc) = $exc{desc}         =~ $match;
		push @detail, $err if $err ne $desc;
	}

	# @detail may have accumulated multiple messages. Join them into one str.
	$exc{detail} = join q(. ), map ucfirst, grep $_, @detail;
	
	bless \%exc, $self->_Error;
}

#
# Look up or set the severity level of an error. Sets the level when the
# second argument ($level) is provided. This is done in the constructor
# if the user opts to assign non-default severity levels to one or more
# errors when a handle is created.
#
sub _assign {
	my ($self, $error, $level) = @_;
	return BDB_ERROR unless ref $self;

	# Look up error code from string
	$error = $self->_const($error) if not int $error;
	my $code = int $error;

	# The BerkeleyDB.pm handle object is inside-out since it's an XS library.
	# Our handle is the same object reblessed into our class, so we can't
	# store any attributes on it. Instead, look up the address and use it as
	# the key for a class-global %Config hash, where we store instance
	# settings.

	my $handle = $self->_handle->[0];
	our $Config ||= {};
	
	# Set severity level if we got $level
	if ($level) {
		no strict 'refs';
		defined ${_Common . q(::Levels)}{$level}
			or $self->_throw(BDB_FLAG, qq(Invalid error level "$level"));
		$Config->{$handle}{$code} = $level;
	}

	# Return user-supplied severity level or the default.
	$Config->{$handle}{$code}
		or $Config->{$handle}{int BDB_DEFAULT}
		or BDB_ERROR;
}

#
# Resolve a system error name to its errno integer code.
# (Complement to _lookup. Internal method, used by _assign)
# 
# Convenience function for option parsing, for when the user
# gives us a string erorr name instead of an int or dualvar.
#
sub _const {
	my ($self, $name) = @_;

	DEBUG and $self->_debug(qq(Resolving constant: $name));

	my $caller   = $self->_caller(SKIP)->{package};
	my $fullname = qq(&$caller\::$name);

	# Resolve the name to a coderef. Look in our caller, this module,
	# BerkeleyDB, and Errno, in that order.
	my $func = $caller->can($name)
		|| $self->can($name)
		|| do { BerkeleyDB->can($name) }
		|| do { require Errno; Errno->can($name) }
		or $self->_throw(BDB_CONST, qq(Sub $fullname is undefined));

	# Now that we have a coderef, try calling it to get the error code.
	# Catch any exceptions and repackage them into an error object.
	my $return = $self->_try(sub { $self->_wrap($func) }, sub {
		my ($error) = $_ =~ /^(.*?)(?: at .+ line \d+)?\.?$/m;
		$self->_throw(BDB_CONST, qq(Sub $fullname died "$error"));
	});

	# Make sure what we got is an integer. (Well, this doesn't actually go
	# that far, but it's in the ballpark.)
	int $return or $self->_throw(
		BDB_CONST, qq(Sub $fullname returned non-integer "$return"),
	);

	$return;
}

#
# Lookup a system error name from its integer errno code.
# (Complement to _const. Internal method, used by _exception)
#
# Used by _exception to show a user-friendly/googleable error name
# instead of an integer errno. Creates a hash mapping all the exportable
# POSIX constants from Errno. There are a lot, so we delay doing this until
# needed, then cache it.
# 
sub _lookup {
	my ($self, $error) = @_;
	my $code = int $error;
	
	if ($code) {
		require Errno;
		
		my $posix = (our $Posix ||= { 
			map { Errno->$_ => $_ } @{$Errno::EXPORT_TAGS{POSIX}}
		})->{$code};
		return $posix if $posix;
		
		local $! = $code;
		my @name = grep $!{$_}, keys %!;
		return $name[0] if @name == 1;

		# Otherwise, if @name > 1, the errno is ambigious because multiple
		# errors share the same code. Many do, so not a frivolous check.
	}
	
	$self->_warn(qq(Can't resolve error code "$code"));
	BDB_UNKNOWN;
}

#
# Walk down the callstack until we get the first package that isn't us.
# (Internal method, used by _const and _exception)
#
sub _caller {
	my ($self, $frame) = @_;
	my $base = $self->_Base;
	
	my ($pkg, $file, $line, $sub);
	while (($pkg, $file, $line, $sub) = (caller $frame++)[0..3]) {
		last if $pkg !~ /$base/;
	}
	
	# Something went wrong.
	# Don't $self->_warn again or we'll end up back here.
	warn qq(Can't figure out who called into $base) unless $pkg;
	{ package => $pkg, file => $file, line => $line, sub => $sub };
}

#
# Get a stack trace, excluding packages that belong to this distribution.
# (Internal method, used by _exception)
#
sub _carp {
	my $self = shift;

	our $Classes ||= do { 
		no strict 'refs';
		[ map { $self->$_ } @{${_Common . q(::EXPORT_TAGS)}{class}} ];
	};
	
	require Carp;
	local %Carp::Internal;
	$Carp::Internal{$_}++ for @$Classes;
	(my $trace = Carp::longmess()) =~ s/^\s+//;
	$trace;
}

INFO and __PACKAGE__->_info(q(Error.pm finished loading));

1;
