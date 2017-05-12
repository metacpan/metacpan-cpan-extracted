package Argv;

$VERSION = '1.28';
@ISA = qw(Exporter);

use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;
use constant CYGWIN	=> $^O =~ /cygwin/i ? 1 : 0;

# To support the "FUNCTIONAL INTERFACE"
@EXPORT_OK = qw(system exec qv pipe MSWIN CYGWIN);

use strict;
use Carp;
require Exporter;

my $class = __PACKAGE__;

my $NUL = MSWIN ? 'NUL' : '/dev/null';

# Adapted from perltootc (see): an "eponymous meta-object" implementing
# "translucent attributes".
# For each key in the hash below, a method is automatically generated.
# Each method sets the object attr if called as an instance method or
# the class attr if called as a class method. They return the instance
# attr if it's defined, the class attr otherwise. The method name is
# lower-case; e.g. 'qxargs'. The default value of each attribute comes
# from the hash value set here, which may be overridden in the environment.
use vars qw(%Argv);
%Argv = (
    AUTOCHOMP	=> $ENV{ARGV_AUTOCHOMP} || 0,
    AUTOFAIL	=> $ENV{ARGV_AUTOFAIL} || 0,
    AUTOGLOB	=> $ENV{ARGV_AUTOGLOB} || 0,
    AUTOQUOTE	=> defined($ENV{ARGV_AUTOQUOTE}) ? $ENV{ARGV_AUTOQUOTE} : 1,
    DBGLEVEL	=> $ENV{ARGV_DBGLEVEL} || 0,
    DFLTSETS	=> {'' => 1},
    ENVP	=> undef,
    EXECWAIT	=> defined($ENV{ARGV_EXECWAIT}) ?
					    $ENV{ARGV_EXECWAIT} : scalar(MSWIN),
    INPATHNORM	=> $ENV{ARGV_INPATHNORM} || 0,
    MUSTEXEC	=> $ENV{ARGV_MUSTEXEC} || 0,
    NOEXEC	=> $ENV{ARGV_NOEXEC} || 0,
    OUTPATHNORM	=> $ENV{ARGV_OUTPATHNORM} || 0,
    QXARGS	=> $ENV{ARGV_QXARGS} || -1,
    QXFAIL	=> $ENV{ARGV_QXFAIL} || 0,
    QUIET	=> defined($ENV{ARGV_QUIET})  ? $ENV{ARGV_QUIET}  : 0,
    STDIN	=> defined($ENV{ARGV_STDIN})  ? $ENV{ARGV_STDIN}  : 0,
    STDOUT	=> defined($ENV{ARGV_STDOUT}) ? $ENV{ARGV_STDOUT} : 1,
    STDERR	=> defined($ENV{ARGV_STDERR}) ? $ENV{ARGV_STDERR} : 2,
    SYFAIL	=> $ENV{ARGV_SYFAIL} || 0,
    SYXARGS	=> $ENV{ARGV_SYXARGS} || 0,
    PIPECB	=> sub { print shift; return 1 },
);

# Generates execution-attribute methods from the table above. Provided
# as a class method itself to potentially allow a derived class to
# generate more of these. Semantics of these methods are quite
# context-driven and are explained in the PODs.
sub gen_exec_method {
    my $meta = shift;
    no strict 'refs'; # must evaluate $meta as a symbolic ref
    my @data = @_ ? map {uc} @_ : keys %{$meta};
    for my $attr (@data) {
	$$meta{$attr} ||= 0;
	my $method = lc $attr;
	*$method = sub {
	    my $self = shift;
	    # In null context with no args, set boolean value 'on'.
	    @_ = (1) if !@_ && !defined(wantarray);
	    my $ret = 0;
	    if (ref $self) {
		if (@_) {
		    if (defined(wantarray)) {
			if (ref $self->{$attr}) {
			    unshift(@{$self->{$attr}}, shift);
			} elsif (defined $self->{$attr}) {
			    $self->{$attr} = [shift, $self->{$attr}];
			} else {
			    $self->{$attr} = [shift];
			}
			return $self;
		    } else {
			$self->{$attr} = shift;
			return undef;
		    }
		} else {
		    $ret = defined($self->{$attr}) ?
					    $self->{$attr} : $class->{$attr};
		}
	    } else {
		if (@_) {
		    if (defined(wantarray)) {
			if (ref $class->{$attr}) {
			    unshift(@{$class->{$attr}}, shift);
			} else {
			    $class->{$attr} = [shift, $class->{$attr}];
			}
		    } else {
			$class->{$attr} = shift;
		    }
		    # If setting a class attribute, export it to the
		    # env in case we fork a child also using Argv.
		    my $ev = uc join('_', $class, $attr);
		    $ENV{$ev} = $class->{$attr};
		    return $self;
		} else {
		    $ret = $class->{$attr};
		}
	    }
	    if (ref($ret) eq 'ARRAY' && ref($ret->[0]) ne 'CODE') {
		my $stack = $ret;
		$ret = shift @$stack;
		if (ref $self) {
		    if (@$stack) {
			$self->{$attr} = shift @$stack;
		    } else {
			delete $self->{$attr};
		    }
		} else {
		    $self->{$attr} = shift @$stack;
		}
	    }
	    return $ret;
	}
    }
}

# Generate all the attribute methods declared in %Argv above.
$class->gen_exec_method;

# Generate methods for diverting stdin, stdout, and stderr in ->qx.
{
    my %streams = (stdin => 1, stdout => 1, stderr => 2);
    for my $name (keys %streams) {
	my $method = "_qx_$name";
	no strict 'refs';
	*$method = sub {
	    my $self = shift;
	    my $r_cmd = shift;
	    my $nfd = shift;
	    my $fd = $streams{$name};
	    if ($nfd !~ m%^[\d-]*$%) {
		push(@$r_cmd, "$fd$nfd");
	    } elsif ($fd == 0) {
		warn "Error: illegal value '$nfd' for $name" if $nfd > 0;
		push(@$r_cmd, "<$NUL") if $nfd < 0;
	    } elsif ($nfd == 0) {
		push(@$r_cmd, "$fd>$NUL");
	    } elsif ($nfd == (3-$fd)) {
		push(@$r_cmd, sprintf "%d>&%d", $fd, 3-$fd);
	    } elsif ($nfd != $fd) {
		warn "Error: illegal value '$nfd' for $name";
	    }
	};
    }
}

# Getopt::Long::GetOptions() respects '--' but strips it, while
# we want to respect '--' and leave it in. Thus this override.
sub GetOptions {
    @ARGV = map {/^--$/ ? qw(=--= --) : $_} @ARGV;
    my $ret = Getopt::Long::GetOptions(@_);
    @ARGV = map {/^=--=$/ ? qw(--) : $_} @ARGV;
    return $ret;
}

# This method is much like the generated exec methods but has some
# special-case logic: If called with a param which is true, it starts up
# a coprocess. If called with false (aka 0) it shuts down the coprocess
# and destroys the IPC::ChildSafe object. If called with no params at
# all it returns the existing IPC::ChildSafe object.
sub ipc_childsafe {
    my $self = shift;
    my $ipc_state = $_[0];
    my $ipc_obj;
    if ($ipc_state) {
	eval { require IPC::ChildSafe };
	return undef if $@;
	IPC::ChildSafe->VERSION(3.10);
	$ipc_obj = IPC::ChildSafe->new(@_);
    }
    no strict 'refs';
    if (ref $self) {
	if (defined $ipc_state) {
	    $self->{_IPC_CHILDSAFE} = $ipc_obj;
	    return $self;
	} else {
	    return exists($self->{_IPC_CHILDSAFE}) ?
			$self->{_IPC_CHILDSAFE} : $class->{_IPC_CHILDSAFE};
	}
    } else {
	if (defined $ipc_state) {
	    $class->{_IPC_CHILDSAFE} = $ipc_obj;
	    return $self;
	} else {
	    return $class->{_IPC_CHILDSAFE};
	}
    }
}

# Class/instance method. Parses command line for e.g. -/dbg=1. See PODs.
sub attropts {
    my $self = shift;
    my $r_argv = undef;
    my $prefix = '-/';
    if (ref $_[0] eq 'HASH') {
	my $cfg = shift;
	$r_argv = $cfg->{ARGV};
	$prefix = $cfg->{PREFIX};
    }
    require Getopt::Long;
    local $Getopt::Long::passthrough = 1;
    local $Getopt::Long::genprefix = "($prefix)";
    my @flags = map {"$_=i"} ((map lc, keys %Argv::Argv), @_);
    my %opt;
    if (ref $self) {
	if ($r_argv) {
	    local @ARGV = @$r_argv;
	    GetOptions(\%opt, @flags);
	    @$r_argv = @ARGV;
	} else {
	    local @ARGV = $self->args;
	    if (@ARGV) {
		GetOptions(\%opt, @flags);
		$self->args(@ARGV);
	    }
	}
    } elsif ($r_argv) {
	local @ARGV = @$r_argv;
	GetOptions(\%opt, @flags);
	@$r_argv = @ARGV;
    } elsif (@ARGV) {
	GetOptions(\%opt, @flags);
    }
    for my $method (keys %opt) {
	$self->$method($opt{$method});
    }
    return $self;
}
*stdopts = \&attropts;	# backward compatibility

# A class method which returns a summary of operations performed in
# printable format. Called with a void context to start data-
# collection, with a scalar context to end it and get the report.
sub summary {
    my $cls = shift;
    my($cmds, $operands);
    if (!defined wantarray) {
	$Argv::Summary = {};
	return;
    }
    return unless $Argv::Summary;
    my $fmt = "%30s:  %4s\t%s\n";
    my $str = sprintf $fmt, "$cls Summary", 'Cmds', 'Operands';
    for (sort keys %{$Argv::Summary}) {
	my @stats = @{$Argv::Summary->{$_}};
	$cmds += $stats[0];
	$operands += $stats[1];
	$str .= sprintf $fmt, $_, $stats[0], $stats[1];
    }
    $str .= sprintf $fmt, 'TOTAL', $cmds, $operands if defined $cmds;
    $Argv::Summary = 0;
    return $str;
}

# Constructor.
sub new {
    my $proto = shift;
    my $attrs = shift if ref($_[0]) eq 'HASH';
    my $self;
    if (ref($proto)) {
	# As an instance method, make a deep clone of the invoking object.
	# Some cloners are fast but not commonly installed, others the
	# reverse. We try them in order of speed and fall back to
	# Data::Dumper which is slow but core Perl as of 5.6.0. I could
	# just inherit from Clone or Storable but want to not force
	# users who don't need cloning to install them.
	eval {
	    require Clone;
	    Clone->VERSION(0.12);       # 0.11 has a bug that breaks Argv
	    $self = Clone::clone($proto);
	};
	if ($@) {
	    eval {
		require Storable;
		$self = Storable::dclone($proto);
	    };
	}
	if ($@) {
	    require Data::Dumper;
	    # Older Perl versions may not have the XS interface installed,
	    # so try it and fall back to the pure-perl version on failure.
	    my $copy = eval {
		Data::Dumper->Deepcopy(1)->new([$proto], ['self'])->Dumpxs;
	    };
	    $copy = Data::Dumper->Deepcopy(1)->new([$proto], ['self'])->Dump
									if $@;
	    eval $copy;
	}
	die $@ if $@ || !$self;
	# At least some cloners can't clone a code ref...
	$self->{PIPECB} = $proto->{PIPECB};
    } else {
	$self = {};
	if ($proto ne __PACKAGE__) {
	    # Inherit class attributes from subclass class attributes.
	    no strict 'refs';
	    for (keys %$proto) {
		$self->{$_} = $proto->{$_};
	    }
	}
	$self->{AV_PROG} = [];
	$self->{AV_ARGS} = [];
	$self->{PIPECB} = $Argv{PIPECB};
	bless $self, $proto;
	$self->optset('');
    }
    $self->attrs($attrs) if $attrs;
    $self->argv(@_) if @_;
    return $self;
}
*clone = \&new;

# Nothing to do here, just avoiding interaction with AUTOLOAD.
sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    (my $cmd = $Argv::AUTOLOAD) =~ s/.*:://;
    return if $cmd eq 'DESTROY';
    no strict 'refs';
    # install a new method '$cmd' to avoid autoload next time ...
    *$cmd = sub {
	my $self = shift;
	if (ref $self) {
	    $self->argv($cmd, @_);
	} else {
	    $self->new($cmd, @_);
	}
    };
    # ... then service this request
    return $self->$cmd(@_);
}

# Instance methods; most class methods are auto-generated above.

# A shorthand way to set a bunch of attributes by passing a hashref
# of their names=>values.
sub attrs {
    my $self = shift;
    my $attrs = shift;
    if ($attrs) {
	for my $key (keys %$attrs) {
	    (my $method = $key) =~ s/^-//;
	    $self->$method($attrs->{$key});
	}
    }
    return $self;
}

# Replace the instance's prog(), opt(), and args() vectors all together.
# Without arguments, return the command as it currently looks either as
# a list or a string depending on context.
sub argv {
    my $self = shift;
    if (@_) {
	$self->attrs(shift) if ref($_[0]) eq 'HASH';
	$self->{AV_PROG} = [];
	$self->{AV_OPTS}{''} = [];
	$self->{AV_ARGS} = [];
	$self->prog(shift) if @_;
	$self->attrs(shift) if ref($_[0]) eq 'HASH';
	$self->opts(@{shift @_}) if ref $_[0] eq 'ARRAY';
	$self->args(@_) if @_;
	return $self;
    } else {
	my @cmd = ($self->prog, $self->opts, $self->args);
	if (wantarray) {
	    return @cmd;
	} else {
	    return "@cmd";
	}
    }
}
*cmd = \&argv;	# backward compatibility

# Set or get the 'prog' part of the command line.
sub prog {
    my $self = shift;
    if (@_) {
	my @prg = ref $_[0] ? @{$_[0]} : @_;
	@{$self->{AV_PROG}} = @prg;
    } elsif (!defined(wantarray)) {
	@{$self->{AV_PROG}} = ();
    }
    if (@_) {
	return $self;
    } else {
	return wantarray ? @{$self->{AV_PROG}} : ${$self->{AV_PROG}}[0];
    }
}

# Set or get the 'args' part of the command line.
sub args {
    my $self = shift;
    if (@_) {
	my @args = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
	@{$self->{AV_ARGS}} = @args;
    } elsif (!defined(wantarray)) {
	@{$self->{AV_ARGS}} = ();
    }
    if (@_) {
	return $self;
    } else {
	return @{$self->{AV_ARGS}};
    }
}

# Generates the parse(), opts(), and flag() method families. During
# construction this is used to generate the methods for the anonymous
# option set; it can be used explicitly to generate parseXX(), optsXX(),
# and argsXX() for optset 'XX'.
sub optset {
    my $self = shift;
    for (@_) {
	my $set = uc $_;
	next if defined $self->{AV_OPTS}{$set};
	$self->{AV_OPTS}{$set} = [];
	$self->{AV_LKG}{$set} = {};
	my($p_meth, $o_meth, $f_meth) = map { $_ . $set } qw(parse opts flag);
	$self->{AV_DESC}{$set} = [];
	no strict 'refs'; # needed to muck with symbol table
	*$p_meth = sub {
	    my $self = shift;
	    $self->{AV_DESC}{$set} ||= [];
	    if (@_) {
		if (ref($_[0]) eq 'ARRAY') {
		    $self->{CFG}{$set} = shift;
		} elsif (ref($_[0]) eq 'HASH') {
		    $self->warning("do not provide a linkage specifier");
		    shift;
		}
		@{$self->{AV_DESC}{$set}} = @_;
		$self->factor($set,
				$self->{AV_DESC}{$set}, $self->{AV_OPTS}{$set},
				$self->{AV_ARGS}, $self->{CFG}{$set});
		if (defined $self->{AV_OPTS}{$set}) {
		    my @parsedout = @{$self->{AV_OPTS}{$set}};
		}
	    }
	    return @{$self->{AV_OPTS}{$set}};
	} unless $Argv::{$p_meth};
	*$o_meth = sub {
	    my $self = shift;
	    $self->{AV_OPTS}{$set} ||= [];
	    if (@_ || !defined(wantarray)) {
		@{$self->{AV_OPTS}{$set}} = @_;
	    }
	    return @_ ? $self : @{$self->{AV_OPTS}{$set}};
	} unless $Argv::{$o_meth};
	*$f_meth = sub {
	    my $self = shift;
	    if (@_ > 1) {
		while(my($key, $val) = splice(@_, 0, 2)) {
		    $self->{AV_LKG}{$set}{$key} = $val;
		}
	    } else {
		my $key = shift;
		return $self->{AV_LKG}{$set}{$key};
	    }
	} unless $Argv::{$f_meth};
    }
    return keys %{$self->{AV_DESC}}; # this is the set of known optsets.
}

# Not generally used except internally; not documented. First arg
# is an option set name followed by bunch of array-refs: a pointer
# to a list of Getopt::Long-style option descs, a ref to be filled
# in with a list of found options, another containing the input
# args and to be filled in with the leftovers, and an optional
# one containing Getopt::Long-style config options.
sub factor {
    my $self = shift;
    my($pset, $r_desc, $r_opts, $r_args, $r_cfg) = @_;
    my @vgra;
    {
        local @ARGV = @$r_args;
        if ($r_desc && @$r_desc) {
            require Getopt::Long;
            # Need this version so Configure() returns prev state.
            Getopt::Long->VERSION(2.23);
            if ($r_cfg && @$r_cfg) {
                my $prev = Getopt::Long::Configure(@$r_cfg);
                GetOptions($self->{AV_LKG}{$pset}, @$r_desc);
                Getopt::Long::Configure($prev);
            } else {
                local $Getopt::Long::passthrough = 1;
                local $Getopt::Long::autoabbrev = 1;
                local $Getopt::Long::debug = 1 if $self->dbglevel == 5;
                GetOptions($self->{AV_LKG}{$pset}, @$r_desc);
            }
        }
        @vgra = @ARGV;
    }
    my(@opts, @args);
    for (reverse @$r_args) {
        if (@vgra && $vgra[$#vgra] eq $_) {
            unshift(@args, pop (@vgra));
        } else {
            unshift(@opts, $_);
        }
    }
    @$r_opts = @opts if $r_opts;
    @$r_args = @args;
    return @opts;
}

# Extract and return any of the specified options from object.
sub extract {
    my $self = shift;
    my $set = shift;
    $self->optset($set) unless defined $self->{AV_LKG}{$set};
    my $p_meth = 'parse' . $set;
    my $o_meth = 'opts' . $set;
    $self->$p_meth(@_);
    my @extracts = $self->$o_meth();
    return @extracts;
}

sub argpathnorm {
    my $self = shift;
    my $norm = $self->inpathnorm;
    return unless $norm && !ref($norm);
    if (CYGWIN) { #for the cygwin shell
        s%\\%\\\\%g for @_;
    }
    return unless MSWIN;
    for my $word (@_) {
	# If requested, change / for \ in Windows file paths.
	# This is necessarily an inexact science.
	my @fragments = split ' ', $word;
	for (@fragments) {
	    if (m%^"?/%) {
		if (m%(.*/\w+):(.+)%) {
		    # If it looks like an option specifying a path (/opt:path),
		    # normalize only the path part.
		    my($opt, $path) = ($1, $2);
		    $path =~ s%/%\\%g;
		    $_ = "$opt:$path";
		} else {
		    # If it contains a slash (any kind) after the initial one
		    # treat it as a full path. This is where you get into
		    # ambiguity with combined options (e.g. /E/I/Q/S) which
		    # could technically be a path. So that's just not allowed
		    # when path-norming.
		    my $slashes = tr/\/\\//;
		    s%/%\\%g if $slashes > 1;
		}
	    } else {
		s%/%\\%g;
	    }
	}
	$word = "@fragments";
    }
}

# Quotes @_ in place against shell expansion. Usually called via autoquote attr
sub quote {
    my $self = shift;
    for (grep {defined} @_) {
	# Hack - allow user to exempt any arg from quoting by prefixing '^'.
	next if s%^\^%%;
	# Special case - turn internal newlines back to literal \n on Win32
	s%\n%\\n%gs if MSWIN;
	# If arg is already quoted with '': on Unix it's safe, leave alone.
	# On Windows, replace the single quotes with escaped double quotes.
	if (m%^'(.*)'$%s) {
	    $_ = qq(\\"$1\\") if MSWIN;
	    next;
	} elsif (m%^".*"$%s) {
	    $_ = qq(\\"$_\\") if MSWIN || CYGWIN;
	    next;
	}
	# Skip if contains no special chars.
	if (MSWIN) {
	    # On windows globbing is not handled by the shell so we
	    # let '*' go by.
	    next unless m%[^-=:_."\w\\/*]% || tr%\n%%;
	} else {
	    next unless m%[^-=:_."\w\\/]% || m%\\n% || tr%\n%%;
	}
	# Special case - leave things that look like redirections alone.
	next if /^\d?(?:<{1,2})|(?:>{1,2})/;
	# This is a hack to support MKS-built perl 5.004. Don't know
	# if the problem is with MKS builds or 5.004 per se.
	next if MSWIN && $] < 5.005;
	# Now quote embedded quotes ...
	$_ =~ s%(\\*)"%$1$1\\"%g;
	# quote a trailing \ so it won't quote the quote (!) ...
	s%\\{1}$%\\\\%;
	# and last the entire string.
	$_ = qq("$_");
    }
    return $self;
}

# Submits @_ to Perl's glob() function. Usually invoked via autoglob attr.
sub glob {
    my $self = shift;
    my @orig = @_ ? @_ : $self->args;
    if (! @orig) {
	$self->warning("no arguments to glob");
	return 0;
    }
    my @globbed;
    for (@orig) {
	if (/^'(.*)'$/) {		# allow '' to escape globbing
	    push(@globbed, $1);
	} elsif (/[*?]/) {
	    push(@globbed, glob)
	} else {
	    push(@globbed, $_)
	}
    }
    if (defined wantarray) {
	return @globbed;
    } else {
	$self->args(@globbed);
    }
}

# Internal. Takes a list of optset names, returns a list of options.
sub _sets2opts {
    my $self = shift;
    my(@sets, @opts);
    if (! @_) {
	@sets = keys %{$self->dfltsets};
    } elsif ($_[0] eq '-') {
	@sets = ();
    } elsif ($_[0] eq '+') {
	@sets = $self->optset;
    } else {
	my %known = map {$_ => 1} $self->optset;
	for (@_) { $self->warning("Unknown optset '$_'\n") if !$known{$_} }
	@sets = @_;
    }
    for my $set (@sets) {
	next unless $self->{AV_OPTS}{$set} && @{$self->{AV_OPTS}{$set}};
	push(@opts, @{$self->{AV_OPTS}{$set}});
    }
    return @opts;
}

# Internal, collects data for use by 'summary' method.
sub _addstats {
    my $self = shift;
    my($prg, $argcnt) = @_;
    my $stats = $Argv::Summary->{$prg} || [0, 0];
    $$stats[0]++;
    $$stats[1] += $argcnt;
    $Argv::Summary->{$prg} = $stats;
}

# Handles ->autofail operations. If given a scalar, exit with the value
# of that scalar on failure unless the scalar == 0, in which case
# don't exit. If given a ref to a scalar, increment the scalar for
# each failure. If given a code ref, call that subroutine. An array ref
# is assumed to contain a code ref followed by parameters for the sub.
sub fail {
    my($self, $specific) = @_;
    my $general = $self->autofail;
    if (my $val = $specific || $general) {
	if (ref($val) eq 'CODE') {
	    &$val($self);
	} elsif (ref($val) eq 'ARRAY') {
	    my @arr = @$val;
	    my $func = shift(@arr);
	    &$func(@arr);
	} elsif (ref($val) eq 'SCALAR') {
	    $$val++;
	} elsif ($val !~ /^\d*$/) {
	    die $val;
	} elsif ($val) {
	    exit $val;
	}
    }
    return $self;
}

# Convert lines to UNIX (/) format iff they represent file pathnames.
sub unixpath {
    my $self = shift;
    for (@_) {
	chomp(my $chomped = $_);
	s%\\%/%g if -e $chomped;
    }
}

# A no-op except it prints the current state of the object to stderr.
sub objdump {
    my $self = shift;
    (my $obj = shift || 'argv') =~ s%^\$%%;
    require Data::Dumper;
    print STDERR Data::Dumper->new([$self], [$obj])->Dumpxs;
    return $self;
}

sub readonly {
    my $self = shift;
    no strict 'refs';
    if (@_) {
	$self->{AV_READONLY} = shift;
	return $self;
    } else {
	if (exists($self->{AV_READONLY})) {
	    return $self->{AV_READONLY};		# instance
	} else {
	    my $class = ref $self;
	    if ($class && exists($class->{AV_READONLY})) {
		return $class->{AV_READONLY};	# class
	    } else {
		return 'no';
	    }
	}
    }
}

sub _read_only {
    my $self = shift;
    return $self->readonly =~ /^y/i;
}

# Hidden method for printing debug output.
sub _dbg {
    my $self = shift;
    my($level, $prefix, $fh, @txt) = @_;
    my @tmp = @txt;
    for (@tmp) { $_ = qq("$_") if /\s/ && !/^"/ }

    # Print all EV's that were added to or modified from the real env.
    my $envp = $self->envp;
    if ($envp) {
	for (sort keys %$envp) {
	    next if $ENV{$_} && $ENV{$_} eq $envp->{$_};
	    print $fh "+ [\$$_=", $envp->{$_}, "]\n";
	}
    }

    $self->objdump if $level >= 3;
    my($ifd, $ofd, $efd) = ($self->stdin, $self->stdout, $self->stderr);
    if ($ifd !~ m%^[\d-]*$%) {
	$ifd =~ s%/%\\%g if MSWIN;
	push(@tmp, $ifd);
    } elsif ($ifd < 0) {
	push(@tmp, "<$NUL");
    }
    if ($ofd !~ m%^[\d-]*$%) {
	$ofd =~ s%/%\\%g if MSWIN;
	push(@tmp, $ofd);
    } elsif ($ofd <= 0) {
	push(@tmp, "1>$NUL");
    } elsif ($ofd != 1) {
	push(@tmp, "1>&$ofd");
    }
    if ($efd !~ m%^[\d-]*$%) {
	$efd =~ s%/%\\%g if MSWIN;
	push(@tmp, "2$efd");
    } elsif ($efd <= 0) {
	push(@tmp, "2>$NUL");
    } elsif ($efd != 2) {
	push(@tmp, "2>&$efd");
    }
    print $fh "$prefix @tmp\n";
}

# Attempt to derive the value of ARG_MAX (the maximum command-line
# length) for the current platform. Windows isn't really POSIX and
# in my tests POSIX::ARG_MAX() usually throws an exception.
# Therefore, on Windows we catch the exception and set the value
# to 32767. I don't know what the actual limit is but 32K seems to
# work whereas 64K fails and I haven't tried to narrow that range
# (actually a bit of subsequent testing showed 48000 to work and
# 50000 to fail, but I still prefer to depend on a round number).
# On other platforms, if ARG_MAX is missing we use _POSIX_ARG_MAX
# (4096) # as the default (that being the smallest value of ARG_MAX
# allowed by the POSIX standard).
{
    my($_argmax, $_pathmax);
    sub _arg_max {
	require Config;
	if (!defined($_argmax)) {
	    $_argmax = MSWIN ? 32767 : 4096;
	    eval { require POSIX; $_argmax = POSIX::ARG_MAX(); };
	    # The terminating NULL of argv.
	    $_argmax -= $Config::Config{ptrsize};
	}
	return $_argmax;
    }
    sub _path_max {
	if (!defined($_pathmax)) {
	    $_pathmax = MSWIN ? 260 : 1024;
	    eval { require POSIX; $_pathmax = POSIX::PATH_MAX(); };
	}
	return $_pathmax;
    }
}

# Determine the size of the environment block for subtraction
# from the calculated value of ARG_MAX. We allow for an equals
# sign and terminating null in each EV, plus the pointer
# within the environ array that references it.
# Note: Windows limits do not appear to include the environment block.
sub _env_size {
    require Config;
    my $envlen = 0;
    my $ptrsize = $Config::Config{ptrsize};
    for my $ev (keys %ENV) {
	$envlen += length($ev);
	$envlen += length($ENV{$ev}) if $ENV{$ev};
	$envlen += 2 + $ptrsize;
    }
    # Need one more pointer's worth for the terminating NULL in 'environ'.
    return $envlen + $ptrsize;
}

# In the case where the user wants to do qxargs-style chunking by
# buffer length rather than argument count, we need to keep pushing
# args onto said buffer till we run out of room.
sub _chunk_by_length {
    require Config;
    my ($args, $max) = @_;
    my @chunk = ();
    my $chunklen = 0;
    my $extra = $Config::Config{ptrsize} + 1;
    while (grep {defined} @{$args}) {
	# Reached max length?
	if (($chunklen + length(${$args}[0]) + $extra) >= $max) {
	    # Always send at least one chunk no matter what.
	    push(@chunk, shift(@{$args})) unless @chunk;
	    last;
	} else {
	    $chunklen += length(${$args}[0]) + $extra;
	    push(@chunk, shift(@{$args}));
	}
    }
    #printf STDERR "CHUNK: $chunklen (MAX=$max, LEFT=%d)\n", scalar(@{$args});
    return @chunk;
}

# Wrapper around Perl's exec(). Strawberry Perl 5.12 warns...
{ no warnings 'redefine';
sub exec {
    $class->new(@_)->exec if !ref($_[0]) || ref($_[0]) eq 'HASH';
    my $self = shift;
    if ((ref($self) ne $class) && $self->ipc_childsafe) {
	exit($self->system(@_) || $self->ipc_childsafe->finish);
    } elsif (MSWIN && $self->execwait) {
	exit($self->system(@_) >> 8);
    } else {
	my $envp = $self->envp;
	my $dbg = $self->dbglevel;
	my @cmd = (@{$self->{AV_PROG}},
			    $self->_sets2opts(@_), @{$self->{AV_ARGS}});
	if ($self->noexec && !$self->_read_only) {
	    $self->_dbg($dbg, '-', \*STDERR, @cmd);
	} else {
	    my($ifd, $ofd, $efd) = ($self->stdin, $self->stdout, $self->stderr);
	    $self->_dbg($dbg, '+', \*STDERR, @cmd) if $dbg;
	    open(_I, '<&STDIN');
	    open(_O, '>&STDOUT');
	    open(_E, '>&STDERR');
	    if ($ifd !~ m%^[\d-]*$%) {
		open(STDIN, $ifd) || warn "$ifd: $!";
	    } elsif ($ifd < 0) {
		open(STDIN, "<$NUL") || warn "STDIN: $!";
	    } else {
		warn "Warning: illegal value '$ifd' for stdin" if $ifd > 0;
	    }
	    if ($ofd !~ m%^[\d-]*$% && !$self->quiet) {
		open(STDOUT, $ofd) || warn "$ofd: $!";
	    } elsif ($ofd <= 0 || $self->quiet) {
		open(STDOUT, ">$NUL") || warn "STDOUT: $!";
	    } elsif ($ofd == 2) {
		open(STDOUT, '>&STDERR') || warn "Can't dup stdout";
	    } elsif ($ofd != 1) {
		warn "Warning: illegal value '$ofd' for stdout";
	    }
	    if ($efd !~ m%^[\d-]*$%) {
		open(STDERR, $efd) || warn "$efd: $!";
	    } elsif ($efd <= 0) {
		open(STDERR, ">$NUL") || warn "STDERR: $!";
	    } elsif ($efd == 1) {
		open(STDERR, '>&STDOUT') || warn "Can't dup stderr";
	    } elsif ($efd > 2) {
		warn "Warning: illegal value '$efd' for stderr";
	    }
	    my $rc;
	    if ($envp) {
		local %ENV = %$envp;
		$rc = exec(@cmd);
	    } else {
		$rc = exec(@cmd);
	    }
	    # Shouldn't get here but defensive programming and all that ...
	    if ($rc) {
		my $error = "$!";
		open(STDIN, '<&_I'); close(_I);
		open(STDOUT, '>&_O'); close(_O);
		open(STDERR, '>&_E'); close(_E);
		die "$0: $cmd[0]: $error\n";
	    }
	}
    }
}}

sub lastresults {
    my $self = shift;
    if (defined(wantarray)) {
	my @qxarr = @{$self->{AV_LASTRESULTS}};
	my $rc = shift @qxarr;
	if (wantarray) {
	    return @qxarr;
	} else {
	    return $rc;
	}
    } else {
	$self->{AV_LASTRESULTS} = \@_;
    }
}

# Internal - service method for system/exec to call into IPC::ChildSafe.
sub _ipccmd {
    my $self = shift;
    my $cmd = shift;
    # Throw out the prog name since it's already running
    if (@_) {
	$cmd = "@_";
    } else {
	$cmd =~ s/^\w+\s*//;
    }
    # Hack - there's an "impedance mismatch" between instance
    # methods in this class and the class methods in
    # IPC::ChildSafe, so we toggle the attrs for every cmd.
    my $csobj = $self->ipc_childsafe;
    $csobj->dbglevel($self->dbglevel);
    $csobj->noexec($self->noexec) if $self->noexec && !$self->_read_only;
    my %results = $csobj->cmd($cmd);
    return %results;
}

# Wrapper around Perl's system().
sub system {
    return $class->new(@_)->system if !ref($_[0]) || ref($_[0]) eq 'HASH';
    my $self = shift;
    my $envp = $self->envp;
    my $rc = 0;
    my($ifd, $ofd, $efd) = ($self->stdin, $self->stdout, $self->stderr);
    $self->args($self->glob) if $self->autoglob;
    my @prog = @{$self->{AV_PROG}};
    my @opts = $self->_sets2opts(@_);
    my @args = @{$self->{AV_ARGS}};
    my $childsafe = ((ref($self) ne $class) &&
			    $self->ipc_childsafe && !$self->mustexec) ? 1 : 0;

    # These potentially modify their arguments in place.
    $self->argpathnorm(@prog, @args);
    $self->quote(@prog, @opts, @args)
	if (((MSWIN && (@prog + @opts + @args) > 1) || $childsafe) &&
						       $self->autoquote);
    my @cmd = (@prog, @opts, @args);
    my $dbg = $self->dbglevel;
    if ($childsafe) {
	$self->_addstats("@prog", scalar @args) if $Argv::Summary;
	$self->warning("cannot change \%ENV of child process") if $envp;
	$self->warning("cannot close stdin of child process") if $ifd;
	my %results = $self->_ipccmd(@cmd);
	$? = $rc = ($results{status} << 8);
	if ($self->quiet) {
	    # say nothing
	} elsif ($ofd !~ m%^[\d-]*$%) {
	    if (open(OFD, $ofd)) {
		print OFD @{$results{stdout}} if @{$results{stdout}};
		close OFD;
	    } else {
		warn "$ofd: $!";
	    }
	} elsif ($ofd == 2) {
	    print STDERR @{$results{stdout}} if @{$results{stdout}};
	} else {
	    warn "Warning: illegal value '$ofd' for stdout" if $ofd > 2;
	    print STDOUT @{$results{stdout}} if @{$results{stdout}};
	}
	if ($efd == 1) {
	    print STDOUT @{$results{stderr}} if @{$results{stderr}};
	} elsif ($efd !~ m%^[\d-]*$%) {
	    if (open(EFD, $efd)) {
		print EFD @{$results{stderr}} if @{$results{stderr}};
		close EFD;
	    } else {
		warn "$efd: $!";
	    }
	} else {
	    warn "Warning: illegal value '$efd' for stderr" if $efd > 2;
	    print STDERR @{$results{stderr}} if @{$results{stderr}};
	}
    } else {
	# Reset to defaults in dbg mode (what's this for?)
	($ofd, $efd) = (1, 2) if defined($dbg) && $dbg > 2;
	if ($self->noexec && !$self->_read_only) {
	    $self->_dbg($dbg, '-', \*STDERR, @cmd);
	    return 0;
	}
	open(_I, '<&STDIN');
	open(_O, '>&STDOUT');
	open(_E, '>&STDERR');

	if ($ifd !~ m%^[\d-]*$%) {
	    open(STDIN, $ifd) || warn "$ifd: $!";
	} elsif ($ifd < 0) {
	    open(STDIN, "<$NUL") || warn "STDIN: $!";
	} else {
	    warn "Warning: illegal value '$ifd' for stdin" if $ifd > 0;
	}

	if ($ofd !~ m%^[\d-]*$% && !$self->quiet) {
	    open(STDOUT, $ofd) || warn "$ofd: $!";
	} elsif ($ofd <= 0 || $self->quiet) {
	    open(STDOUT, ">$NUL") || warn "STDOUT: $!";
	} elsif ($ofd == 2) {
	    open(STDOUT, '>&STDERR') || warn "Can't dup stdout";
	} elsif ($ofd != 1) {
	    warn "Warning: illegal value '$ofd' for stdout";
	}

	if ($efd !~ m%^[\d-]*$%) {
	    open(STDERR, $efd) || warn "$efd: $!";
	} elsif ($efd <= 0) {
	    open(STDERR, ">$NUL") || warn "STDERR: $!";
	} elsif ($efd == 1) {
	    open(STDERR, '>&STDOUT') || warn "Can't dup stderr";
	} elsif ($efd > 2) {
	    warn "Warning: illegal value '$efd' for stderr";
	}

	my $limit = $self->syxargs;
	if ($limit && @args) {
	    if ($limit == -1) {
		$limit = -_arg_max();
		$limit += _env_size() if !MSWIN;
		# There's no shell used in list-form system() ...
		$limit += _path_max();		# for @prog
		$limit += length("@opts");
	    }
	    while (my @chunk = $limit > 0 ?
		    splice(@args, 0, $limit) :
		    _chunk_by_length(\@args, abs($limit))) {
		$self->_addstats("@prog", scalar @chunk) if $Argv::Summary;
		@cmd = (@prog, @opts, @chunk);
		$self->_dbg($dbg, '+', \*_E, @cmd) if $dbg;
		if ($envp) {
		    local %ENV = %$envp;
		    $rc |= system @cmd;
		} else {
		    $rc |= system @cmd;
		}
	    }
	} else {
	    $self->_addstats("@prog", scalar @args) if $Argv::Summary;
	    $self->_dbg($dbg, '+', \*_E, @cmd) if $dbg;
	    if ($envp) {
		local %ENV = %$envp;
		$rc = system @cmd;
	    } else {
		$rc = system @cmd;
	    }
	}
	open(STDIN, '<&_I'); close(_I);
	open(STDOUT, '>&_O'); close(_O);
	open(STDERR, '>&_E'); close(_E);
    }
    print STDERR "+ (\$? == $?)\n" if $dbg > 1;
    if ($?) {
	$self->lastresults($?>>8, ());
	$self->fail($self->syfail);
    }
    return $rc;
}

# Wrapper around Perl's qx(), aka backquotes.
sub qx {
    return $class->new(@_)->qx if !ref($_[0]) || ref($_[0]) eq 'HASH';
    my $self = shift;
    my $envp = $self->envp;
    my @prog = @{$self->{AV_PROG}};
    my @opts = $self->_sets2opts(@_);
    my @args = @{$self->{AV_ARGS}};
    my $childsafe = ((ref($self) ne $class) &&
			    $self->ipc_childsafe && !$self->mustexec) ? 1 : 0;

    # These potentially modify their arguments in place.
    @args = $self->glob(@args)
		if MSWIN && $self->autoglob && $childsafe;
    $self->argpathnorm(@prog, @args);
    $self->quote(@prog, @opts, @args)
	if (((@prog + @opts + @args) > 1 || $childsafe) && $self->autoquote);

    my @cmd = (@prog, @opts, @args);
    my @data;
    my $dbg = 0;
    my $rc = 0;
    my($ifd, $ofd, $efd) = ($self->stdin, $self->stdout, $self->stderr);
    my $noexec = $self->noexec && !$self->_read_only;
    if ($childsafe) {
	$self->_addstats("@prog", scalar @args) if $Argv::Summary;
	$self->warning("cannot change \%ENV of child process") if $envp;
	$self->warning("cannot close stdin of child process") if $ifd;
	if ($noexec) {
	    $self->_dbg($dbg, '-', \*STDERR, @cmd);
	} else {
	    my %results = $self->_ipccmd(@cmd);
	    if ($ofd <= 0) {
		# ignore the results
	    } elsif ($ofd == 1) {
		push(@data, @{$results{stdout}});
	    } elsif ($ofd == 2) {
		print STDERR @{$results{stdout}};
	    } else {
		warn "Warning: illegal value '$ofd' for stdout";
	    }
	    if ($efd == 1) {
		push(@data, @{$results{stderr}});
	    } else {
		print STDERR @{$results{stderr}} if $efd;
		warn "Warning: illegal value '$efd' for stderr" if $efd > 2;
	    }
	    $? = $rc = $results{status} << 8;
	}
    } else {
	$dbg = $self->dbglevel;
	# Reset to defaults in dbg mode (what's this for?)
	($ofd, $efd) = (1, 2) if defined($dbg) && $dbg > 2;
	my $limit = $self->qxargs;
	if ($limit && @args) {
	    if ($limit == -1) {
		$limit = -_arg_max();
		$limit += _env_size() if !MSWIN;
		$limit += _path_max();		# for the shell
		$limit += length('-c');
		$limit += _path_max();		# for @prog
		$limit += length("@opts");
	    }
	    while (my @chunk = $limit > 0 ?
		    splice(@args, 0, $limit) :
		    _chunk_by_length(\@args, abs($limit))) {
		$self->_addstats("@prog", scalar @chunk) if $Argv::Summary;
		@cmd = (@prog, @opts, @chunk);
		if ($noexec) {
		    $self->_dbg($dbg, '-', \*STDERR, @cmd);
		} else {
		    $self->_dbg($dbg, '+', \*STDERR, @cmd) if $dbg;
		    $self->_qx_stderr(\@cmd, $efd);
		    $self->_qx_stdout(\@cmd, $ofd);
		    if ($envp) {
			local %ENV = %$envp;
			push(@data, qx(@cmd));
		    } else {
			push(@data, qx(@cmd));
		    }
		    $rc ||= $?;
		}
	    }
	} else {
	    $self->_addstats("@prog", scalar @args) if $Argv::Summary;
	    if ($noexec) {
		$self->_dbg($dbg, '-', \*STDERR, @cmd);
	    } else {
		$self->_dbg($dbg, '+', \*STDERR, @cmd) if $dbg;
		$self->_qx_stderr(\@cmd, $efd);
		$self->_qx_stdout(\@cmd, $ofd);
		if ($envp) {
		    local %ENV = %$envp;
		    @data = qx(@cmd);
		} else {
		    @data = qx(@cmd);
		}
		$rc ||= $?;
	    }
	}
	$? = $rc if $rc && ! $?;
    }
    print STDERR "+ (\$? == $?)\n" if $dbg > 1;
    if ($?) {
	$self->lastresults($?>>8, @data);
	$self->fail($self->qxfail);
    }
    $self->unixpath(@data) if MSWIN && $self->outpathnorm;
    if (wantarray) {
	print STDERR map {"+ <- $_"} @data if @data && $dbg >= 2;
	chomp(@data) if $self->autochomp;
	return @data;
    } else {
	my $data = join('', @data);
	print STDERR "+ <- $data" if @data && $dbg >= 2;
	chomp($data) if $self->autochomp;
	return $data;
    }
}
# Can't override qx() in main package so we export an alias instead.
*qv = \&qx;

sub pipe {
    return $class->new(@_)->pipe if !ref($_[0]) || ref($_[0]) eq 'HASH';

    my $self = shift;

    my $cb = $self->pipecb;
    $self->error("No callback supplied") unless ref($cb) eq 'CODE';

    my ($pipe, $pid) = $self->readpipe(@_);
    my $line;
    my $abort = 0;
    while($line = <$pipe>) {
	chomp($line) if $self->autochomp;
	my $keepGoing = &$cb($line);
	if (!$keepGoing) {
	    if ($self->_read_only) {
		$abort = 1;
		last;
	    }
	    $self->warning("Not abortable unless readonly - continuing!");  
	}
    }
    if (MSWIN && $abort)    {
	# This is somewhat ugly, but due to perl impl details as well as
	# the fact that Windows does not have the proper counterpart to
	# SIGPIPE, we'll have to 'help' things along...
	#
	Argv::Win32Utils::killProcessTree($self, $pid);
    }
    my $rc = close($pipe);
    $self->fail($self->qxfail) if !$rc;
    return $rc;
}

# Wrapper around Perl's "open(FOO, '<cmd> |')" operator.
sub readpipe {
    return $class->new(@_)->readpipe if !ref($_[0]) || ref($_[0]) eq 'HASH';
    my $self = shift;
    my $envp = $self->envp;
    my @prog = @{$self->{AV_PROG}};
    my @opts = $self->_sets2opts(@_);
    my @args = @{$self->{AV_ARGS}};

    # These potentially modify their arguments in place.
    $self->argpathnorm(@prog, @args);
    $self->quote(@prog, @opts, @args)
	if (((@prog + @opts + @args) > 1) && $self->autoquote);

    my @cmd = (@prog, @opts, @args);
    my $dbg = 0;
    my($ifd, $ofd, $efd) = ($self->stdin, $self->stdout, $self->stderr);
    my $noexec = $self->noexec && !$self->_read_only;
    $dbg = $self->dbglevel;
    $self->_addstats("@prog", scalar @args) if $Argv::Summary;
    if ($noexec) {
	$self->_dbg($dbg, '-', \*STDERR, @cmd, '|');
    } else {
	my $handle;
	$self->_dbg($dbg, '+', \*STDERR, @cmd, '|') if $dbg;
	$self->_qx_stderr(\@cmd, $efd);
	$self->_qx_stdout(\@cmd, $ofd);
	my $rc;
	if ($envp) {
	    local %ENV = %$envp;
	    $rc = open($handle, "@cmd |");
	} else {
	    $rc = open($handle, "@cmd |");
	}
	$self->fail($self->qxfail) if !$rc || !defined($handle);
	my $oldfh = select($handle); $| = 1; select($oldfh);
	return wantarray ? ($handle, $rc) : $handle;
    }
}

# Internal - provide a warning with std format and caller's context.
sub warning {
    my $self = shift;
    (my $prog = $0) =~ s%.*[/\\]%%;
    no strict 'refs';
    carp('Warning: ', ${$self->{AV_PROG}}[-1] || $prog, ': ', @_);
}

# Internal - provide a fatal error with std format and caller's context.
sub error {
    my $self = shift;
    (my $prog = $0) =~ s%.*[/\\]%%;
    no strict 'refs';
    croak('Error: ', ${$self->{AV_PROG}}[-1] || $prog, ': ', @_);
}

# Hack this thing in here to help with *&#$ Windows. We want to hide it
# as much as possible in the hope that a better way may be found
# someday. Thus it's implemented as an "inner class" rather than
# a separate file.
{
    package Argv::Win32Utils;

    # Preload this to avoid INIT block failure in Win32::API::Type
    # (but it may not be installed at all, which is ok).
    eval "require Win32::API";

    # For internal use only - attempt to kill the process tree stemming from
    # the given pid.
    # Attempts several ways using various packages that may or may not be
    # present.
    sub killProcessTree {
	my $argv = shift;
	my $pid = shift;

	# Undocumented way to turn this off in case it causes big problems...
	return 0 if $ENV{ARGV_WIN32UTILS_SKIP_KILLPROCESSTREE};

	require Win32::Process;
	
	my ($implDesc, $impl) = __findImpl($argv);	
	print STDERR "Using $implDesc...\n" if $argv->dbglevel > 1;
	&$impl($argv, $pid);
	
	return 0;
    }

    # For internal use only - attempt to kill a single process
    sub killProcess {
	my $argv = shift;
	my $pid = shift;

	print STDERR "Killing $pid...\n" if $argv->dbglevel > 1;
	return Win32::Process::KillProcess($pid, 0);
    }

    # Implementation using Win32::Process::Info
    # This pkg can give us a (pruned) pid tree with the expected
    # layout right away.
    sub __win32_process_info {
	my $argv = shift;
	my $pid = shift;

	my %pidTree = new Win32::Process::Info->Subprocesses($pid);
	__deepKill($argv, $pid, \%pidTree);
	
	return 0;	
    }

    # Implementation using Win32::ToolHelp
    # this pkg gives a different view - rework into a pid tree
    # by 1) enter all pids as keys, and then 2) add their children.
    sub __win32_toolhelp {
	my $argv = shift;
	my $pid = shift;

	my %pidTree;
	my @allProcesses = Win32::ToolHelp::GetProcesses();
	$pidTree{$_->[1]} = [] foreach (@allProcesses);
	push(@{$pidTree{$_->[5]}}, $_->[1]) foreach (@allProcesses);
	__deepKill($argv, $pid, \%pidTree);

	return 0;
    }

    # Kill processes depth first by following the tree.
    sub __deepKill {
	my $argv = shift;
	my $pid = shift;
	my $pidTree = shift;
	
	# give a parent an opportunity to terminate by itself
	# which is likely when their child died
	#
	foreach my $childPid (@{$pidTree->{$pid}}) {
	    __deepKill($argv, $childPid, $pidTree);
	}
	killProcess($argv, $pid);
    }

    # Dynamically find an implementation that can figure out
    # the process tree and kill it.
    # Fall back to just kill the root pid (which may just be enough).
    sub __findImpl {
	my $argv = shift;
	
	# begin with a list to ensure a preferred search order
	# but put the list in a hash for easy lookup
	#
	my @implList = (
	    "Win32::ToolHelp", \&__win32_toolhelp,
	    "Win32::Process::Info", \&__win32_process_info,
	);
	my %implHash = @implList;
	foreach my $implName (@implList) {
	    eval "use $implName";
	    return ("$implName (tree capable)", $implHash{$implName}) unless $@;
	}
	
	# no luck, use fallback
	my @helpers = keys(%implHash);
	$argv->warning("No process tree helper found - install any of these packages: [@helpers]");
	return ("Win32::Process (not tree capable)", \&killProcess);
    }

    1;
}

1;

__END__

=head1 NAME

Argv - Provide an OO interface to an arg vector

=head1 SYNOPSIS

    use Argv;

    # A roundabout way of getting perl's version.
    my $pl = Argv->new(qw(perl -v));
    $pl->exec;

    # Run /bin/cat, showing how to provide "predigested" options.
    Argv->new('/bin/cat', [qw(-u -n)], @ARGV)->system;

    # A roundabout way of globbing.
    my $echo = Argv->new(qw(echo M*));
    $echo->glob;
    my $globbed = $echo->qx;
    print "'echo M*' globs to: $globbed";

    # A demonstration of head-like behavior (aborting early).
    my $maxLinesToPrint = 5;
    my $callback = sub {
	print shift;
	return --$maxLinesToPrint;
    };
    my $head = Argv->new('ls', [qw(-l -a)]);
    $head->readonly("yes"); 
    $head->pipecb($callback); 
    $head->pipe;

    # A demonstration of the builtin xargs-like behavior.
    my @files = split(/\s+/, $globbed);
    my $ls = Argv->new(qw(ls -d -l), @files);
    $ls->parse(qw(d l));
    $ls->dbglevel(1);
    $ls->qxargs(1);
    my @long = $ls->qx;
    $ls->dbglevel(0);
    print @long;

    # A demonstration of how to use option sets in a wrapper program.
    @ARGV = qw(Who -a -y foo -r);	# hack up an @ARGV
    my $who = Argv->new(@ARGV);		# instantiate
    $who->dbglevel(1);			# set verbosity
    $who->optset(qw(UNAME FOO WHO));	# define 3 option sets
    $who->parseUNAME(qw(a m n p));	# parse these to set UNAME
    $who->parseFOO(qw(y=s z));		# parse -y and -z to FOO
    $who->parseWHO('r');		# for the 'who' cmd
    warn "got -y flag in option set FOO\n" if $who->flagFOO('y');
    print Argv->new('uname', $who->optsUNAME)->qx;
    $who->prog(lc $who->prog);		# force $0 to lower case
    $who->exec(qw(WHO));		# exec the who cmd

More advanced examples can be lifted from the test script or the
./examples subdirectory.

=head1 RAISON D'ETRE

Argv presents an OO approach to command lines, allowing you to
instantiate an 'argv object', manipulate it, and eventually execute it,
e.g.:

    my $ls = Argv->new('ls', ['-l']));
    my $rc = $ls->system;	# or $ls->exec or $ls->qx

Which raises the immediate question - what value does this mumbo-jumbo
add over Perl's native way of doing the same thing:

    my $rc = system(qw(ls -l));

The answer comes in a few parts:

=over

=item * STRUCTURE

First, Argv recognizes the underlying property of an arg vector, which
is that it begins with a B<program name> potentially followed by
B<options> and then B<operands>. An Argv object factors a raw argv into
these three groups, provides accessor methods to allow operations on
each group independently, and can then paste them back together for
execution.


=item * OPTION SETS

Second, Argv encapsulates and extends C<Getopt::Long> to allow parsing
of the argv's options into different I<option sets>. This is useful in
the case of wrapper programs which may, for instance, need to parse out
one set of flags which direct the behavior of the wrapper itself, extract
a different set and pass them to program X, another for program Y, then
exec program Z with the remainder.  Doing this kind of thing on a basic
@ARGV using indexing and splicing is do-able but leads to spaghetti-ish
code.

=item * EXTRA FEATURES

The I<execution methods> C<system, exec, qx, and pipe> extend their
Perl builtin analogues in a few ways, for example:

=over

=item 1. An xargs-like capability without shell intervention.

=item 2. UNIX-like C<exec()> behavior on Windows.

=item 3. Automatic quoting of C<system()> on Win32 and C<qx()>/C<pipe()>
everywhere.

=item 4. Automatic globbing (primarily for Windows).

=item 5. Automatic chomping.

=item 6. Pathname normalization (primarily for Windows).

=back

=back

All of these behaviors are optional and may be toggled either as class
or instance attributes. See EXECUTION ATTRIBUTES below.

=head1 DESCRIPTION

An Argv object treats a command line as 3 separate entities: the
I<program>, the I<options>, and the I<args>. The I<options> may be
further subdivided into user-defined I<option sets> by use of the
C<optset> method. When one of the I<execution methods> is called, the
parts are reassembled into a single list and passed to the underlying
Perl execution function.

Compare this with the way Perl works natively, keeping the 0th element
of the argv in C<$0> and the rest in C<@ARGV>.

By default there's one option set, known as the I<anonymous option
set>, whose name is the null string. All parsed options go there.  The
advanced user can define more option sets, parse options into them
according to Getopt::Long-style descriptions, query or set the parsed
values, and then reassemble them in any way desired at exec time.
Declaring an option set automatically generates a set of methods for
manipulating it (see below).

All argument-parsing within Argv is done via Getopt::Long.

=head1 AUTOLOADING

Argv employs the same technique made famous by the Shell module
to allow any command name to be used as a method. E.g.

	$obj->date->exec;

will run the 'date' command. Internally this is translated into

	$obj->argv('date')->exec;

See the C<argv> method below.

=head1 FUNCTIONAL INTERFACE

Because the extensions to C<system/exec/qx> described above may be
helpful in writing portable programs, the methods are also made
available for export as traditional functions. Thus:

    use Argv qw(system exec qv pipe);

will override the Perl builtins. There's no way (that I know of) to
override the operator C<qx()> so an alias C<qv()> is provided.

=head1 CONSTRUCTOR

    my $obj = Argv->new(@list)

The C<@list> is what will be parsed/executed/etc by subsequent method
calls. During initial construction, the first element of the list is
separated off as the I<program>; the rest is lumped together as part of
the I<args> until and unless option parsing is done, in which case
matched options are shifted into collectors for their various I<option
sets>. You can also create a "predigested" instance by passing any or
all of the prog, opt, or arg parts as array refs. E.g.

    Argv->new([qw(cvs ci)], [qw(-l -n)], qw(file1 file2 file3));

Predigested options are placed in the default (anonymous) option set.

The constructor can be used as a class or instance method. In the
latter case the new object is a deep (full) clone of its progenitor.
In fact there's a C<clone> method which is an alias to C<new>, allowing
clones to be created via:

	my $copy = $orig->clone;

The first argument to C<new()> or C<clone()> may be a hash-ref, which
will be used to set I<execution attributes> at construction time. I.e.:

    my $obj = Argv->new({autochomp => 1, stderr => 0}, @ARGV);

You may choose to create an object and add the command line later:

    my $obj = Argv->new;
    $obj->prog('cat');
    $obj->args('/etc/motd');

Or

    my $obj = Argv->new({autochomp=>1});
    my $motd = $obj->argv(qw(cat /etc/motd))->qx;

Or (using the autoloading interface)

    my $motd = $obj->cat('/etc/motd')->qx;

=head1 METHODS

=head2 INSTANCE METHODS

=over

=item * prog()

Returns or sets the name of the program (the C<"argv[0]">). The
argument may be a list, e.g. C<qw(rcs co)> or an array reference.

=item * opts()

Returns or sets the list of operands (aka arguments). As above, it may
be passed a list or an array reference. This is simply the member of
the class of optsI<NAME>() methods (see below) whose <NAME> is null;
it's part of the predefined I<anonymous option set>.

=item * args()

Returns or sets the list of operands (aka arguments).  If called in a
void context and without args, the effect is to set the list of
operands to C<()>.

=item * argv()

Allows you to set the prog, opts, and args in one method call. It takes
the same arguments as the constructor (above); the only difference is
it operates on a pre-existing object to replace its attributes. I.e.

    my $obj = Argv->new;
    $obj->argv('cmd', [qw(-opt1 -opt2)], qw(arg1 arg2));

is equivalent to

    my $obj = Argv->new('cmd', [qw(-opt1 -opt2)], qw(arg1 arg2));

Without arguments, returns the current arg vector as it would be
executed:

    my @cmd = $ct->argv;

=item * optset(<list-of-set-names>);

For each name I<NAME> in the parameter list, an I<option set> of that
name is declared and 3 new methods are registered dynamically:
C<parseI<NAME>(), optsI<NAME>(), and flagI<NAME>()>. These methods are
described below: note that the I<anonymous option set> (see I<OPTION
SETS>) is predefined, so the methods C<parse(), opts(), and flag()> are
always available.  Most users won't need to define any other sets.
Note that option-set names are forced to upper case. E.g.:

    $obj->optset('FOO');

=item * parseI<NAME>(...option-descriptions...)

Takes a list of option descriptions and uses Getopt::Long::GetOptions()
to parse them out of the current argv B<and into option set I<NAME>>.
The opt-descs are exactly as supported by parseI<FOO>() are exactly the
same as those described for Getopt::Long, except that no linkage
argument is allowed. E.g.:

    $obj->parseFOO(qw(file=s list=s@ verbose));

=item * optsI<NAME>()

Returns or sets the list of options in the B<option set I<NAME>>.

=item * flagI<NAME>()

Sets or gets the value of a flag in the appropriate optset, e.g.:

    print "blah blah blah\n" if $obj->flagFOO('verbose');
    $obj->flagFOO('verbose' => 1);

=item * extract

Takes an I<optset> name and a list of option descs; creates the named
optset, extracts any of the named options, places them in the specified
optset, and returns them.

=item * quote(@list)

Protects the argument list against exposure to a shell by quoting each
element. This method is invoked automatically by the I<system> method
on Windows platforms, where the underlying I<system> primitive always
uses a shell, and by the I<qx> method on all platforms since it invokes
a shell on all platforms.

The automatic use of I<quote> can be turned off via the I<autoquote>
method (see).

IMPORTANT: this method quotes its argument list B<in place>. In other
words, it may modify the arguments.

=item * glob

Expands the argument list using the Perl I<glob> builtin. Primarily
useful on Windows where the invoking shell does not do this for you.

Automatic use of I<glob> on Windows can be enabled via the I<autoglob>
method (vide infra).

=item * objdump

A no-op except for printing the state of the invoking instance to
stderr. Potentially useful for debugging in situations where access to
I<perl -d> is limited, e.g. across a socket connection or in a
crontab. Invoked automatically at I<dbglevel=3>.

=item * readonly

Sets/gets the "readonly" attribute, which is a string indicating
whether the instance is to be used for read operations only. If the
attribute's value starts with C<y>, execution methods will be allowed
to proceed even if the C<$obj-E<gt>noexec> attribute is set.

The value of this is that it enables your script to have a C<-n> flag,
a la C<make -n>, pretty easily by careful management of
C<-E<gt>readonly> and C<-E<gt>noexec>.  Consider a script which runs
C<ls> to determine whether a file exists and then, conditionally, uses
C<rm -f> to remove it.  Causing a C<-n> flag from the user to set
C<-E<gt>noexec> alone would break the program logic since the C<ls>
would be skipped too. But, if you take care to use objects with the
I<readonly> attribute set for all read-only operations, perhaps by
defining a special read-only object:

	my $ro = Argv->new;
	$ro->readonly('yes');
	$ro->ls('/tmp')->system;

then the C<-n> flag will cause only write operations to be skipped.

Note that, if you choose to use this feature at all, determining which
operations are readonly is entirely the programmer's responsibility.
There's no way for Argv to determine whether a child process will
modify state.

=back

=head2 EXECUTION METHODS

The three methods below are direct analogues of the Perl builtins.
They simply reassemble a command line from the I<prog>, I<opts>, and
I<args> parts according to the option-set rules described below and
invoke their builtin equivalent on it.

=over

=item * system([<optset-list>])

Reassembles the argv and invokes system(). Return value and value of
$?, $!, etc. are just as described in I<perlfunc/"system">

Arguments to this method determine which of the parsed option-sets will
be used in the executed argv. If passed no arguments, C<$obj-E<gt>system>
uses the value of the 'dfltsets' attribute as the list of desired sets.
The default value of 'dfltsets' is the anonymous option set.

An option set may be requested by passing its name (with an optional
leading '+') or explicitly rejected by using its name with a leading
'-'. Thus, given the existence of option sets I<ONE, TWO, and THREE>,
the following are legal:

    $obj->system;			# use the anonymous set only
    $obj->system('+');			# use all option sets
    $obj->system(qw(ONE THREE);		# use sets ONE and THREE

The following sequence would also use sets ONE and THREE.

    $obj->dfltsets({ONE => 1, THREE => 1});
    $obj->system;

while this would use all parsed options:

    $obj->dfltsets({'+' => 1});
    $obj->system;

and this would set the default to none class-wide, and then use it:

    $obj->dfltsets({'-' => 1});
    $obj->system;

By default the C<$obj-E<gt>system> method autoquotes its arguments I<iff>
the platform is Windows and the arguments are a list, because in this
case a shell is always used. This behavior can be toggled with
C<$obj-E<gt>autoquote>.

=item * exec([<optset-list>])

Similar to I<system> above, but never returns. On Windows, it blocks
until the new process finishes for a more UNIX-like behavior than the
I<exec> implemented by the MSVCRT, if the B<execwait> attribute is set.
This is actually implemented as

    exit($obj->system(LIST));

on Windows, and thus all C<system> shell-quoting issues apply

Option sets are handled as described in I<system> above.

=item * qx([<optset-list>])

Same semantics as described in I<perlfunc/"qx"> but has the capability
to process only a set command line length at a time to avoid exceeding
OS line-length limits. This value is settable with the I<qxargs>
method.

One difference from the builtin I<perlfunc/"qx"> is that the builtin
allows you to leave off the double quotes around the command string
(though they are always there implicitly), whereas the I<qv()>
functional interface I<must use literal quotes>. For instance, using
I<qx()> you can use either of:

    my @results = qx(command string here);
    my @results = qx("command string here");

which are semantically identical, but with I<qv()> you must use the
latter form.

Also, if I<autoquote> is set the arguments are escaped to protect them
against the platform-standard shell I<on all platforms>. 

Option sets are handled as described in I<system> above.

=item * pipe([<optset-list>])

Provides functionality to use the 'open' process pipe mechanism in
order to read output line by line and optionally stop reading early.
This is useful if the process you are reading can be lengthy but where
you can quickly determine whether you need to let the process finish or
if you need to save all output.  This can save a lot of time and/or
memory in many scenarios.

You must pass in a callback code reference using C<-E<gt>pipecb>. This
callback will receive one line at a time (autochomp is active). The
callback can do whatever it likes with this line. The callback should
return a false value to abort early, but for this to be honored, the
Argv instance should be marked 'readonly' using the C<-E<gt>readonly>
method. A default callback is in effect at start that merely prints the
output.

C<-E<gt>pipe> is otherwise similar to, and reuses settings for I<qx>
(except for the ability to limit command line lengths).

Without exhaustive testing, this is believed to work in a well-behaved
manner on Unix.

However, on Windows a few caveats apply. These appear to be limitations
in the underlying implementation of both Perl and Windows.

=over

=item 1. Windows has no concept of SIGPIPE. Thus, just closing the pipe handle
will not necessarily cause the child process to quit. Bummer :-(.

=item 2. Sometimes an extra process is inserted. For example, if stderr
has been redirected using $obj->stderr(1) (send stderr to stdout), this
causes Perl to utilize the shell as an intermediary process, meaning
that even if the shell process quits, its child will continue.

=back

For the above reasons, in case of an abort request, on Windows we take it
further and forcibly kill the process tree stemming from the pipe. However,
to make this kill the full tree, some nonstandard packages are required.
Currently any of these will work:

=back

=over

=item * Win32::Process::Info

=item * Win32::ToolHelp

Both are available as PPM packages for ActiveState perls, or on CPAN.

=back

=head2 EXECUTION ATTRIBUTES

The behavior of the I<execution methods> C<system, exec, and qx> is
governed by a set of I<execution attributes>, which are in turn
manipulated via a set of eponymous methods. These methods are
auto-generated and thus share certain common characteristics:

=over

=item * Translucency

They can all be invoked as class or instance methods.  If used as an
instance method the attribute is set only on that object; if used on
the class it sets or gets the default for all instances which haven't
overridden it.  This is inspired by the section on I<translucent
attributes> in Tom Christiansen's I<perltootc> tutorial.

=item * Class Defaults

Each attribute has a class default which may be overridden with an
environment variable by prepending the class name, e.g. ARGV_QXARGS=256
or ARGV_STDERR=0;

=item * Context Sensitivity

The attribute value is always a scalar. If a value is passed it
becomes the new value of the attribute and the object or class is
returned. If no value is passed I<and there is a valid return
context>, the current value is returned. In a void context with no
parameter, the attribute value is set to 1.

=item * Stickiness (deprecated)

A subtlety: if an I<execution attribute> is set in a void context, that
attribute is I<"sticky">, i.e. it retains its state until explicitly
changed. But I<if a new value is provided and the context is not void>,
the new value is B<temporary>. It lasts until the next I<execution
method> (C<system, exec, or qx>) invocation, after which the previous
value is restored. This feature allows locutions like this:

	$obj->cmd('date')->stderr(1)->system;

Assuming that the C<$obj> object already exists and has a set of
attributes; we can override one of them at execution time. The next
time C<$obj> is used, stderr will go back to wherever it was directed
before. More examples:

	$obj->stdout(1);          # set attribute, sticky
	$obj->stdout;             # same as above
	$foo = $obj->stdout;      # get attribute value
	$obj2 = $obj->stdout(1);  # set to 1 (temporary), return $obj

WARNING: this attribute-stacking has turned out to be a bad idea. Its
use is now deprecated. There are other ways to get to the same place:
you can maintain multiple objects, each of which has different but
permanent attributes. Or you can make a temporary copy of the object
and modify that, e.g.:

    $obj->clone->stderr(1)->system;
    $obj->clone({stderr=>1})->system;

each of which will leave C<$obj> unaffected.

=back

=over

=item * autochomp

All data returned by the C<qx> or C<pipe> methods is chomped first.
Unset by default.

=item * autofail

When set, the program will exit immediately if the C<system>, C<qx>, or
C<pipe> methods detect a nonzero status. Unset by default.

Autofail may also be given a code-ref, in which case that function will
be called upon error. This provides a basic exception-handling system:

    $obj->autofail(sub { print STDERR "caught an exception\n"; exit 17 });

Any failed executions by C<$obj> will result in the above message and
an immediate exit with return code == 17. Alternatively, if the
reference provided is an array-ref, the first element of that array is
assumed to be a code-ref as above and the rest of the array is passed
as args to the function on failure. Thus:

    $obj->autofail([&handler, $arg1, $arg2]);

Will call C<handler($arg1, $arg2)> on error. It's even possible to
turn the handler into a C<fake method> by passing the object ref:

    $obj->autofail([&handler, $obj, $arg1, $arg2]);

If the reference is to a scalar, the scalar is incremented for each
error and execution continues. Switching to a class method example:

    my $rc = 0;
    Argv->autofail(\$rc);
    [do stuff involving Argv objects]
    print "There were $rc failures counted by Argv\n";
    exit($rc);

=item * syfail,qxfail

Similar to C<autofail> but apply only to C<system()> or
C<qx()>/C<pipe()> respectively. Unset by default.

=item * lastresults

Within an C<autofail> handler this may be used to get access to the
results of the failed execution.  The return code and stdout of the
last command will be stored and can be retrieved as follows:

    # set up handler as a fake method (see above)
    $obj->autofail([&handler, $obj, $arg1, $arg2]);

    # then later, in the handler
    my $self = shift;			# get the obj ref
    my @output = $self->lastresults;	# gives stdout in list context
    my $rc = $self->lastresults;	# and retcode in scalar

Note that stdout is only available for -E<gt>qx, not for -E<gt>system.
And stderr is never available unless you've explicitly redirected it to
stdout. This is just the way Perl I/O works.

=item * envp

Allows a different environment to be provided during execution of the
object. This setting is in scope only for the child process and will
not affect the environment of the current process.  Takes a hashref:

    my %newenv = %ENV;
    $newenv{PATH} .= ':/usr/ucb';
    delete @newenv{qw(TERM LANG LD_LIBRARY_PATH)};
    $obj->envp(\%newenv);

Subsequent invocations of I<$obj> will add I</usr/ucb> to PATH and
subtract TERM, LANG, and LD_LIBRARY_PATH.

=item * autoglob

If set, the C<glob()> function is applied to the operands
(C<$obj-E<gt>args>) on Windows only. Unset by default.

=item * autoquote

If set, the operands are automatically quoted against shell expansion
before C<system()> on Windows and C<qx()> on all platforms (since
C<qx()> I<always> invokes a shell and C<system()> always does so on
Windows).  Set by default.

An individual word of an argv can opt out of autoquoting by using a
leading '^'. For instance:

    ('aa', 'bb', "^I'll do this one myself, thanks!", 'cc')

The '^' is stripped off and the rest of the string left alone.

=item * dbglevel

Sets the debug level. Level 0 (the default) means no debugging, level 1
prints each command before executing it, and higher levels offer
progressively more output. All debug output goes to stderr.

=item * dfltsets

Sets and/or returns the default set of I<option sets> to be used in
building up the command line at execution time.  The default-default is
the I<anonymous option set>. I<Note: this method takes a B<hash
reference> as its optional argument and returns a hash ref as well>.
The selected sets are represented by the hash keys; the values are
meaningless.

=item * execwait

If set, C<$obj-E<gt>exec> on Windows blocks until the new process is
finished for a more consistent UNIX-like behavior than the traditional
Win32 Perl port. Perl just uses the Windows exec() routine, which runs
the new process in the background. Set by default.

=item * inpathnorm

If set, normalizes pathnames to their native format just before
executing. This is NOT set by default, and even when set it's a no-op
except on Windows where it converts /x/y/z to \x\y\z. Only the I<prog>
and I<args> lists are normalized; options placed in the I<opts> list
are left alone.

However, for better or worse it's common to lump opts and args together
so some attempt is made to separate them heuristically.  The algorithm
is that if the word begins with C</> we consider that it might be an
option and look more carefully: otherwise we switch all slashes to
backslashes.  If a word is in the form C</opt:stuff> we assume I<stuff>
is meant as a path and convert it. Otherwise words which look like
options (start with a slash and contain no other slashes) are left
alone.

This is necessarily an inexact science. In particular there is an
ambiguity with combined options, e.g. /E/I/Q.  This is a legal pathname
and is treated as such. Therefore, do not set combined options as part
of the I<args> list when making use of argument path norming. Some
Windows commands accept Unix-style options (-x -y) as well which can be
useful for disambiguation.

=item * outpathnorm

If set, normalizes pathnames returned by the C<qx> method from
\-delimited to /-delimited. This is NOT set by default; even when set
it's a no-op except on Windows.

=item * noexec

Analogous to the C<-n> flag to I<make>; prints what would be executed
without executing anything.

=item * qxargs

Sets a maximum command line length for each execution, allowing you to
blithely invoke C<$obj-E<gt>qx> on a list of any size without fear of
exceeding OS or shell limits. I<The attribute is set to a per-platform
default>; this method allows it to be changed as described below.

A value of 0 turns off the feature; all arguments will be thrown onto
one command line and if that's too big it will fail. A positive value
specifies the maximum number of B<arguments> to place on each command
line.  As the number of args has only a tenuous relationship with the
length of the command line, this usage is deprecated and retained only
for historical reasons (but see below). A negative value sets the
overall command line length in B<bytes>, which is a more sensible way
to handle it.  As a special case, a value of C<-1> sets the limit to
that reported by the system (C<getconf ARG_MAX> on POSIX platforms,
32767 on Windows).  The default is C<-1>.  Examples:

    $obj->qxargs(0);		# no cmdline length limit
    $obj->qxargs(-2048);	# limit cmdlines to 2048 bytes
    $obj->qxargs(-1);		# limit cmdlines to ARG_MAX bytes
    $obj->qxargs(256);		# limit cmdlines to 256 arguments

Notes: The actual cmdline length limit is somewhat less than ARG_MAX on
POSIX systems for reasons too complex to explain here.

=item * syxargs

Analogous to I<qxargs> but applies to C<system()>. Unlike I<qxargs>,
this is turned off by default. The reason is that C<qx()> is typically
used to I<read> data whereas C<system()> is more often used to make
stateful changes.  Consider that "ls foo bar" produces the same result
if broken up into "ls foo" and "ls bar" but the same cannot be said for
"mv foo bar".

=item * stdout

Setting this attribute to 0, e.g:

    $obj->stdout(0);

causes STDOUT to be connected to the C<1E<gt>/dev/null> (Unix) or NUL
(Windows) device during invocation of the I<execution methods>
C<system>, C<qx>, and C<exec> and restored when they finish. Relieves
the programmer of the burden and noise of opening, dup-ing, and
restoring temporary handles.

A value of 2 is the equivalent of using C<1E<gt>&2> to the shell,
meaning that it would send stdout to the stderr device.

It's also possible to pass any non-numeric EXPR; these will be passed
to open().  For instance, to accumulate output from the current object
in C</tmp/foo> use:

    $obj->stdout(">>/tmp/foo");

Note that in this usage, responsibility for portable constructs such as
the existence of I</tmp> belongs to the programmer.

=item * stderr

As above, for STDERR. A value of 1 is the equivalent of C<2E<gt>&1>,
meaning that it sends stderr to the stdout device. E.g.:

    @alloutput = $obj->stderr(1)->qx;

=item * stdin

As above, for STDIN, but note that setting -E<gt>stdin to 0 is a no-op.
To turn off standard input it's necessary to use a negative value:

    $obj->stdin(-1);

=item * quiet

This attribute causes STDOUT to be closed during invocation of the
C<system> and C< exec> (but not C<qx>) I<execution methods>. It will
cause the application to run more quietly. This takes precedence over
a redirection of STDOUT using the <$obj-E<gt>stdout> method above.

=back

=over

=item * attropts

The above attributes can be set via method calls (e.g.
C<$obj-E<gt>dbglevel(1)>) or environment variables (ARGV_DBGLEVEL=1). Use
of the <$obj-E<gt>attropts> method allows them to be parsed from the command
line as well, e.g. I<myscript -/dbglevel 1>. If invoked as a class
method it causes options of the same names as the methods above to be
parsed (and removed) from the current C<@ARGV> and set as class
attributes.  As an instance method it parses and potentially depletes
the current argument vector of that object, and sets instance attributes
only. E.g.:

    Argv->attropts;

would cause the script to parse the following command line:

    script -/noexec 1 -/dbglevel=2 -flag1 -flag2 arg1 arg2 arg3 ...

so as to remove the C<-/noexec 1 -/dbglevel 2> and set the two class
attrs.  The C<-/> prefix is chosen to prevent conflicts with "real"
flags. Abbreviations are allowed as long as they're unique within the
set of -/ flags. As an instance method:

    $obj->attropts;

it will parse the current value of C<$obj-E<gt>args> and run

    $obj->foo(1);

for every instance of C<-/foo=1> found there.

=back

=head1 PORTABILITY

ClearCase::Argv should work on all ClearCase platforms. It's primarily
maintained on Solaris 9 and Windows XP with CC 7.0, using Perl5.8.x.

=head1 PORTABILITY

This module is primarily maintained on Solaris 9 and Windows XP using
Perl 5.8.x or newer.  There is no known reason it should fail to work
on any POSIX or Windows (NT4.0 and above) platform with a sufficiently
modern Perl.

=head1 PERFORMANCE

If you make frequent use of the C<clone> method, you might consider
installing the I<Clone> module by Ray Finch. This tends to speed up
instance cloning a good bit.

=head1 BUGS

It's not exactly a bug but ... this module served as my laboratory for
learning about Perl OO, autoloading, and various other advanced Perl
topics. Therefore it was not written in a disciplined manner; rather, I
stuck in every neat idea I was playing with at the time. As a result,
though it works well as far as I know, there's a hopeless array of ways
to do everything. I know the motto of Perl is TMTOWTDI but Argv goes
one further: TWTMWTDE (There's Way Too Many Ways To Do Everything).

For instance, to run commands with different values for execution
attributes such as C<autoquote> or C<stderr>, you can keep multiple
instances around with different attribute sets, or you can keep one
I<template> instance which you clone-and-modify before each execution,
letting the clone go out of scope immediately:

    $obj->clone->stderr(0)->system;

Or you can keep one instance around and modify its state before each
use. Or toggle the class attributes while leaving the instance
attributes untouched. Which is better?  I don't know the answer, but
choosing a consistent style is a good idea.

=head1 AUTHOR

David Boyce <dsbperl AT boyski.com>

=head1 COPYRIGHT

Copyright (c) 1999-2006 David Boyce. All rights reserved.  This Perl
program is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=head1 GUARANTEE

Double your money back!

=head1 SEE ALSO

perl(1), Getopt::Long(3), IPC::ChildSafe(3)

For Windows quoting background: http://blogs.msdn.com/b/oldnewthing/archive/2010/09/17/10063629.aspx

=cut
