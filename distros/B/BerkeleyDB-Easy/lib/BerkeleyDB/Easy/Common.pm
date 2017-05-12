package BerkeleyDB::Easy::Common;

use strict;
use warnings;
no warnings 'uninitialized';

use Exporter     ();
use Scalar::Util ();

# The following are "switchboard" methods for class dispatching.
# The idea is that sometimes classes need to call each other laterally
# and not through the inheritance chain. For example, Handle::cursor()
# creates a new cursor, so it finds the right class via $self->_Cursor.
# That way, if you wanted to extend that class with your own, you
# could just override Common::_Cursor here instead of tracking down
# and overriding all the various call sites.

use constant {
	_Base   => 'BerkeleyDB::Easy',
	_Handle => 'BerkeleyDB::Easy::Handle',
	_Cursor => 'BerkeleyDB::Easy::Cursor',
	_Error  => 'BerkeleyDB::Easy::Error',
	_Common => 'BerkeleyDB::Easy::Common',
};

sub _unstrict { no strict 'refs'; no warnings 'once'; ${+shift} }

our (@ISA, @EXPORT, %EXPORT_TAGS, %Levels);

#
# Set up constant functions and exports used by the other packages
# TODO: Process compile/construction-time options;
#       integrate with handle constructor
#
BEGIN {
	@ISA         = qw(Exporter);
	@EXPORT      = ();
	%EXPORT_TAGS = (
		subs  => [qw(_generate _accessor _compile _install _wrap _try 
					 _lines _log)],
		class => [],  # Class dispatching        ex: _Base, _Btree
		flag  => [],  # Error level flags, etc.  ex: BDB_TRACE, BDB_IGNORE
		spec  => [],  # Specification constants  ex: FUNC, RECV, K, V, F
		bool  => [],  # Compilation guard bools  ex: TRACE, INFO, NOTICE
	);
	
	# Class dispatching (export under :class) ---------------------------
	
	my @classes = qw(
		Handle  Cursor  Error  Common
		Btree   Hash    Queue  Recno   Heap  Unknown
	);
	
	my $base = q(BerkeleyDB::Easy);
	constant->import(_Base => $base);
	push @{$EXPORT_TAGS{class}}, q(_Base);
	
	for my $name (@classes) {
		my $const = qq(_$name);
		my $class = qq($base\::$name);
		constant->import($const => $class);
		push @{$EXPORT_TAGS{class}}, $const;
	}
	
	# Error severity / log levels ---------------------------------------
	
	my @levels = (
		'IGNORE',   # 0
		'FATAL',    # 1
		'ERROR',    # 2
		'WARN',     # 3
		'NOTICE',   # 4
		'INFO',     # 5
		'DEBUG',    # 6
		'TRACE',    # 7
	);
	
	my $log_level = 0;
	for my $level (reverse 0 .. $#levels) {
		my $level_name = $levels[$level];
		
		# User flags, ie: BDB_DEBUG (export under :flag)
		my $flag_name = qq(BDB_$level_name);
		my $flag_dual = Scalar::Util::dualvar($level, $flag_name);
		constant->import($flag_name, $flag_dual);
		$Levels{$flag_dual} = $flag_dual;
		push @{$EXPORT_TAGS{flag}}, $flag_name;
		
		# We don't need guards or handlers for IGNORE
		next if $level == 0;
		
		# Guard booleans, ie: DEBUG (export under :bool)
		$log_level ||= $flag_dual if $ENV{$flag_name}
			or _unstrict(_Base . q(::) . ucfirst lc $level_name);
		constant->import($level_name, $level <= $log_level);
		push @{$EXPORT_TAGS{bool}}, $level_name;
		
		# Handler aliases, ie: _debug (export under :sub)
		my $handler_name = q(_) . lc $level_name;
		my $handler_sub  = sub {
			my $self = shift;
			unshift @_, $flag_dual;
			$self->_log(@_);
		};
		no strict 'refs';
		*$handler_name = $handler_sub;
		push @{$EXPORT_TAGS{sub}}, $handler_name;
	}
	
	# BDB_LEVEL (export under :flag)
	constant->import(BDB_LEVEL => $log_level || BDB_IGNORE());
	push @{$EXPORT_TAGS{flag}}, q(BDB_LEVEL);
	
	# BDB_VERBOSE (export under :flag)
	my $verbose = $ENV{BDB_VERBOSE} || _unstrict(_Base . q(::Verbose));
	$verbose    = $log_level >= BDB_DEBUG() if not defined $verbose;
	constant->import(BDB_VERBOSE => !!$verbose);
	push @{$EXPORT_TAGS{flag}}, q(BDB_VERBOSE);

	# Subroutine generator specification (export under :spec) -----------
	
	my %spec = (
		K => q($key),     FUNC => 0,
		V => q($value),   RECV => 1,
		F => q($flags),   SEND => 2,
		S => q($status),  SUCC => 3,
		R => q($return),  FAIL => 4,
		A => q(@_),       OPTI => 5,
		X => q($x),       FLAG => 6,
		Y => q($y),
		Z => q($z),
		T => q(1),
		N => q(''),
		U => q(undef),
	);
	while (my ($key, $val) = each %spec) {
		constant->import($key, $val);
		push @{$EXPORT_TAGS{spec}}, $key;
	}

	# Export all tag groups by default
	push @EXPORT, map @{$EXPORT_TAGS{$_}}, keys %EXPORT_TAGS;
}

#
# Install a stub closure into the calling package. When called for the 
# first time, it will compile and magic goto itself. If we get passed a
# specification, generate a BerkeleyDB.pm wrapper function. Otherwise, make
# a simple object accessor.
#
sub _install {
	my ($self, $name, $spec) = @_;
	my ($pack, $file, $line) = (caller)[0..2];

	DEBUG and $self->_debug(qq(Installing method stub: $name));

	my $stub = sub {
		my $code = $spec
			? $self->_generate($spec, $name, $pack)
			: $self->_accessor($name);

		TRACE and $self->_trace(qq(Generated code: $code));
		$self->_compile($code, $name, $pack);

		goto &{"$pack\::$name"};
	};

	no strict 'refs';
	*{"$pack\::$name"} = $stub;
}

#
# Expand function specification into code via a dynamic template.
# (Internal method, used by _install)
# 
sub _generate {
	my ($self, $spec, $name, $pack) = @_;
	
	# Optimization level. The higher this is, the less we do.
	my $opt = $spec->[OPTI] || 0;

	# The parameters to our function and the vars we will unroll @_ into.
	# Generally some combination of K ($key), V ($value), and F ($flags).
	my $recv = join q(, ), q($self), @{$spec->[RECV]};
	
	# Need to declare any other variables we're going to need that didn't
	# get declared when we unrolled @_.
	my $decl = do {
		my %r =     map  { $_ => 1             } @{$spec->[RECV]};
		join q(, ), grep { $_ ne A and !$r{$_} } @{$spec->[SEND]};
	};

	# What BerkeleyDB.pm class are we wrapping?
	# Either ::Common (for all handle types) or ::Cursor.
	my $isa = do { no strict 'refs'; ${qq($pack\::ISA)}[0] };

	# Does the function return something we need to keep? (db_cursor)
	#   Yes (R): keep it and get $status from SUPER::status.
	#    No (S): return value is $status.
	my $keep = ( grep { $_ eq R } @{$spec->[SUCC]} ) ? R : S;
	
	# What function are we wrapping?
	my $func = $spec->[FUNC];

	# Does it require a default flag?
	my $flag = $spec->[FLAG];

	# Arguments that we send to the function. If the function has a default
	# flag, we need to OR it together with any flags provided by the user.
	my $send = join q(, ), $flag
		? map { $_ eq F ? qq($flag | ${\F}) : $_ } @{$spec->[SEND]}
		: @{$spec->[SEND]};

	# What to return on failure ($status is set) or success.
	my $fail = join q(, ), @{$spec->[FAIL]};
	my $succ = join q(, ), @{$spec->[SUCC]};
	
	# Use specification to generate code from the following template.
	# Right now, the only use of $opt is to determine if we localize
	# error variables and signal handlers, which is expensive.
	# Various other logic is done is to create the trimmest possible
	# wrapper depending on the needs of the function.
	
	# $opt = 1;
	my ($D, $W) = (BDB_FATAL, BDB_WARN);

	$self->_lines(
		(                  qq|sub $name {                                 |),
		(!$opt          && qq|    my \@err;                               |),
		(!$opt          && qq|    local (\$!, \$^E);                      |),
		(!$opt          && qq|    local \$SIG{__DIE__} =                  |),
		(!$opt          && qq|        sub { \@err = ($D, \$_) };          |),
		(!$opt          && qq|    local \$SIG{__WARN__} =                 |),
		(!$opt          && qq|        sub { \@err = ($W, \$_) };          |),
		( $opt <= 1     && qq|    undef \$BerkeleyDB::Error;              |),
		(                  qq|    my ($recv) = \@_;                       |),
		($decl          && qq|    my ($decl);                             |),
		(TRACE          && qq|    \$self->_trace('$name', \@_);           |),
		($send ne A     && qq|    my $keep = $isa\::$func(\$self, $send); |),
		($send eq A     && qq|    my $keep = &$isa\::$func;               |),
		($keep eq R     && qq|    my ${\S} = $isa\::status(\$self);       |),
		(!$opt          && qq|    \$self->_log(\@err) if \@err;           |),
		(                  qq|    if (${\S}) {                            |),
		(!$opt          && qq|        \$self->_throw(${\S});              |),
		( $opt          && qq|        \$self->_throw(${\S}, undef, $opt); |),
		($fail ne $succ && qq|        return($fail);                      |),
		(                  qq|    }                                       |),
		(                  qq|    return($succ);                          |),
		(                  qq|}                                           |),
	);
}

#
# Make a getter-setter for managing our own state.
# (Internal method, used by _install)
#
sub _accessor {
	my ($self, $name) = @_;

	$self->_lines(
		(qq|sub $name {                      |),
		(qq|    my \$self = shift;           |),
		(qq|    if (\@_) {                   |),
		(qq|        \$self->{$name} = shift; |),
		(qq|        return(\$self);          |),
		(qq|    }                            |),
		(qq|    return(\$self->{$name});     |),
		(qq|}                                |),
	);
}

#
# Prior to compilation, interleave code with line directives so that 
# stack traces will be still be somewhat useful. They'll point to the
# file and line number of our caller, the site of the template definition.
# (Internal method, used by _generate and _accessor)
#
sub _lines {
	my $self = shift;
	my ($file, $line) = (caller)[1..2];

	join qq(# line $line $file(EVAL)\n), 
		map { (my $ln = $_) =~ s/\s*$/\n/; $ln }
		grep $_, @_;
}

#
# Compile some code into the requested package (or caller).
# (Internal method, used by _install)
#
sub _compile {
	my ($self, $code, $name, $pack) = @_;
	$name ||= q(__ANON__);
	$pack ||= caller;

	INFO and $self->_info(qq(Compiling method: $name));

	my ($sub, $err);
	{
		local $@;
		no warnings 'redefine';
		$sub = eval(qq(package $pack; $code));
		($err = $@) =~ s/, at EOF\n$//;
	};

	$self->_fatal(qq(Error compiling method "$name": $err)) if $err;
	
	$sub;
}

#
# BerkeleyDB.pm doesn't throw many exceptions -- only during initialization,
# really -- but whenever it might, we wrap it and localize its global error
# variable as well as the operating system's, so we can return everything
# back to the user in a pristine state.
#
sub _wrap {
	my ($self, $func) = (shift, shift);
	local ($BerkeleyDB::Error, $!, $^E);
	$func->(@_);
}

#
# An even tinier Try::Tiny because lol no dependencies.
#
sub _try {
	my ($self, $try, $catch) = @_;
	my ($ok, $ret, $err);

	my $prev = $@;
	{
		local $@;
		$ok = eval {
			local $@ = $prev;
			$ret = $try->();
			1;
		};
		$err = $@;
	};

	if ($catch and not $ok) {
		local $_ = $err;
		$catch->();
	}

	$ret;
}

#
# Log a message and then warn or die depending on the severity level.
# Just prints to STDOUT for now.
# Used by _throw, and thinly wrapped by:
#   _trace _debug _info _notice _warn _error _fatal
#
sub _log {
	my ($self, $level, @args) = @_;

	if (my $exc = ref $args[0] && $args[0]) {
		# TODO: Unpack error object.
	}

	my $msg = @args ? join q(, ), @args : '';
	print STDERR qq(<< $level : $msg >>\n);
	
	if ($level <= BDB_ERROR) {
		die @args;
	}
	elsif ($level == BDB_WARN) {
		warn @args;
	}
}

INFO and __PACKAGE__->_info(q(Common.pm finished loading));

1;
