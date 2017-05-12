# -*- Mode: perl -*-
#
# $Id: Datum.pm,v 0.1.1.2 2001/07/13 17:04:58 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Datum.pm,v $
# Revision 0.1.1.2  2001/07/13 17:04:58  ram
# patch2: integrated mods made by CDE:
# patch2:  added DEBUG CONFIGURATION section
# patch2:  added HISTORY AND CREDITS section
# patch2:  fixed demo script to include leading DFEATURE call
#
# Revision 0.1.1.1  2001/05/30 21:09:36  ram
# patch1: added LIMITATIONS section to warn about stringify overloading
#
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Carp::Datum;

use vars qw($VERSION);
$VERSION = '0.101';

use Log::Agent;
use Log::Agent qw(logwrite);

use Getargs::Long qw(ignorecase);

use Carp::Datum::Flags;
require Carp::Datum::Parser;

require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK @EXPORT_FAIL %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = (qw(DLOAD_CONFIG
              DFEATURE 
              DTRACE
              DASSERT
              VERIFY
              DREQUIRE
              DENSURE
              DVAL
              DARY
              DVOID
              implies
              equiv
             ), 
           @Carp::Datum::Flags::EXPORT);
@EXPORT_FAIL = qw(on off);
@EXPORT_OK = qw(on off);
%EXPORT_TAGS = (all => \@EXPORT);

use vars qw(
            $DBG
            $DEBUG_TABLE
            $CFG
           );

$DBG = DBG_OFF;

require Carp::Datum::Cfg;
$CFG = Carp::Datum::Cfg->make();


$DEBUG_TABLE = {default => { debug => [DBG_ALL, 0],
                             trace => [TRC_ALL, 0],
                             args => -1
                           },
                alias => []
               };


#
# ->export_fail
#
# Called by Exporter when one of the symbols listed in @EXPORT_FAIL is
# indeed exported.
#
sub export_fail {
	my ($self, @syms) = @_;
	my @failed;
	foreach my $sym (@syms) {
		if    ($sym eq 'on')		{ $DBG = DBG_ON }
		elsif ($sym eq 'off')		{ $DBG = DBG_OFF }
		else						{ push(@failed, $sym) }
	}

	Log::Agent::DATUM_is_here() if $DBG;	# Intercept Log::Agent traces

	return @failed;					# Empty list if OK
}

#
# DLOAD_CONFIG
#
# read the debug input to get the debug instructions. Filename
# content and raw string configuration are concatened to be parsed.
#
# Arguments:
#   -file     => $filename: file to load [optionnal]
#   -config   => $string: string which contains config set up [optionnal]
#   -trace    => boolean: print the parsing result when true [optionnal]
#
sub DLOAD_CONFIG {
    return unless $DBG;

    my ($dump_parser, @remaining) = cgetargs(@_, {-strict => 0, -extra => 1},
                                             [qw(trace)]);

    require Carp::Datum::Cfg;
    $CFG = Carp::Datum::Cfg->make(@remaining);
    
	Log::Agent::DATUM_is_here();		# Intercept Log::Agent traces

    return unless $dump_parser == 1;

    require Data::Dumper;
    DTRACE(TRC_DEBUG, Data::Dumper::Dumper($CFG->cfg_table));

    return;
}


#
# DFEATURE
#
#
sub DFEATURE {
    return unless $DBG && $CFG->check_debug(DBG_FLOW);

	#
	# This routine is usually called as:
	#
	#  DFEATURE(my $f, "any", "other", $param);
	#
	# so the first argument is a lexical lvalue.
	#
	# To ensure the tracing capabilities, we rely on the immediate collecting
	# of the "$f" lexical as soon as the scope of the routine is left: the
	# DESTROY hook will be called on the Carp::Datum object, so we'll know.
	#
	# One day, Perl's garbage collecting scheme may loose this systematic
	# destroying of lexicals by differing object reclaiming if reference
	# counting is abandonned and GC algorithms requiring object traversal
	# are implemented.
	#
	# When that day comes, the alternative will be to systematically use
	# the DVOID, DVAL and DARY on returning, and to maintain a parallel
	# stack here.  Exceptions will be detected by tagging the depth level
	# and checking it at DVOID, DVAL or DARY time.  This will probably require
	# probing the subroutine name of our caller, and computing the depth
	# of the perl stack if the caller does not match.  And to handle recursion,
	# and exceptions happening in there, to flag places where eval() is used
	# so that we know where to look if the stack depth is not as deep as
	# expected.
	#
	# A huge work anyway, so despite reference counting not being the best
	# GC algorithm, it has the nice property of being somewhat predictible.
	# It's usually bad to depend on such knowledge, but here that's very,
	# and I mean VERY, convenient.
	#
	# 	-- RAM, 01/10/2000
	#

    $_[0] = new Carp::Datum(@_[1 .. $#_]);
    return;

	# XXX use weakrefs in 5.6 and above to keep track of those objects in
	# XXX a parallel stack, and to fix display ordering in DESTROY, where
	# XXX the caller is sometimes destroyed before the callee.
}

#
# DVOID
# DVAL
# DARY
#
# Print the return code and effectively return it.
#
# When the given parameter is an array and the return context is also
# an array, there is no trouble to determine what is returned: it is the
# array.
#
# But when the context is a scalar, it is more difficult since the
# parameter might be either a regular array, or a list of
# statement. For the fist case, the function must return the number of
# elements , and the latter form must return the last statements
# value.
#
# Use DVOID when you would otherwise say "return;".
# Use DVAL to return a scalar, or the last element of a list when called in
# scalar context, the list when called in array context (wantarray).
# Use DARY when you return a list, and it will be taken as the amount of items
# when you're called in scalar context, and as the list otherwise.
#
# To be properly stripped when assertions are to be removed from the code,
# one should say:
#
#	return DVAL 1;		# will become "return 1;"
#
#  and NOT:
#
#	return DVAL(1);		# will really become "return (1);"
#
# unless you really mean:
#
#	return DVAL (1);
#
# i.e. the DVOID, DVAL and DARY words are to be thought as "tags" that will be
# removed, without otherwise touching anything else.
#

sub DVOID {
    return unless $DBG && $CFG->check_debug(DBG_RETURN);

    trace("Returning" . where(1));
    return;
}

sub DVAL {
    return wantarray ? @_: $_[$#_]
      unless $DBG && $CFG->check_debug(DBG_RETURN);

    # fix the arg list when the value to return is undef
    @_ = (undef) if $#_ == -1;

    trace("Returning: " . 
          (wantarray ? 
           "(" . (join ', ', (map {data_format($_)} @_)) . ")": 
           data_format($_[$#_])) .where(1));
    return (wantarray ? @_ : $_[$#_]);
}

sub DARY {
    return @_ unless $DBG && $CFG->check_debug(DBG_RETURN);

    # fix the arg list when the value to return is undef
    #    @_ = () if $#_ == -1;

    # get the scalar of the array
    my $a = @_;

    trace("Returning: " . 
          (wantarray ? 
           "(" . (join ', ', (map {data_format($_)} @_)) . ")": 
           data_format(scalar @_)) .where(1));

    return @_;
}

#
# DTRACE
#
# Arguments Form 1:
#   {-level => level, -marker => marker},  message
#
# Arguments Form 2:
#   level, message
#
# Arguments Form 3:
#   message
#
sub DTRACE {
    return if $DBG && !$CFG->check_debug(DBG_TRACE);

    # parse arguments
    my $level = TRC_DEBUG;
    my $marker = '';
    if (ref $_[0] eq 'HASH') {
        my $hashref = shift;
        if (defined $hashref->{-level}) {
            $level = $hashref->{-level};
        }
        if (defined $hashref->{-marker}) {
            $marker = $hashref->{-marker};
        }
    }
    else {
        if ($_[0] =~ /^\d+$/) {
            # take the first argument as level if it is not alone
            if ($#_ > 0) {
                $level = shift;
            }
        }
    }

	if ($DBG) {
		# check whether tracing level is permitted
		return unless $CFG->check_trace($level);
    
		trace(join('', @_) . where(1), $marker);
		return;
	}

	#
	# No debugging activated, call must be remapped to Log::Agent.
	#

	%Carp::Datum::logmap = (
		TRC_EMERGENCY()	=> [\&logdie, undef],		# panic
		TRC_ALERT()		=> [\&logerr, undef],
		TRC_CRITICAL()	=> [\&logerr, undef],
		TRC_ERROR()		=> [\&logerr, undef],
		TRC_WARNING()	=> [\&logwarn, undef],
		TRC_NOTICE()	=> [\&logsay, undef],
		TRC_INFO()		=> [\&logtrc, 'info'],
		TRC_DEBUG()		=> [\&logtrc, 'debug'],
	) unless defined %Carp::Datum::logmap;

	my $entry = $Carp::Datum::logmap{$level};

	#
	# Use magic "goto &" to forget about the DTRACE call.
	#
	# That's important if they use the caller indication feature
	# in Log::Agent.  Otherwise, all calls would be traced from here.
	#

	if (defined $entry) {
		my ($fn, $loglvl) = @$entry;
		@_ = defined $loglvl ? ($loglvl, join('', @_)) : (join '', @_);
		goto &$fn;
	} else {
		@_ = (join '', @_);
		goto &logerr;
	}

    return;
}

#
# DASSERT
#
sub DASSERT {
    return assert(DBG_PANIC|DBG_STACK, 'assertion', @_) unless $DBG;

    my $dbg_flag = $CFG->flag('debug');
    return unless $dbg_flag & DBG_ASSERT;

    assert($dbg_flag, 'assertion', @_);
}

#
# DREQUIRE
#
sub DREQUIRE {
    return assert(DBG_PANIC|DBG_STACK, 'pre-condition', @_) unless $DBG;

    my $dbg_flag = $CFG->flag('debug');    
    return unless $dbg_flag & DBG_REQUIRE;

    assert($dbg_flag, 'pre-condition', @_);
}

#
# VERIFY
#
# same behavior as a DREQUIRE, but it cannot be disabled with the
# Datum debug flag. It is useful to protect the edge of a module from
# the external invocation.
sub VERIFY {
    my ($test, $string) = @_;

    assert(DBG_PANIC|DBG_STACK, 'verify', @_);
}


#
# DENSURE
#
sub DENSURE {
    return assert(DBG_PANIC|DBG_STACK, 'post-condition', @_) unless $DBG;

    my $dbg_flag = $CFG->flag('debug');    
    return unless $dbg_flag & DBG_ENSURE;

    assert($dbg_flag, 'post-condition', @_);
}


#
# implies
#
# Implement the logical operation (migth be useful for assertion)
#
sub implies {
    return (!$_[0]) || $_[1];
}

#
# equiv
#
# Implement the logical operation (migth be useful for assertion)
#
sub equiv {
    return !$_[0] == !$_[1];
}

#
# assert
#
# perhaps modify the signature when caching features is implemented for
# CFG
#
sub assert {
    my $debug_flag = shift;
    my $assert_type = shift;
    my $test = shift;

    return if $test;

	#
	# Carp::Datum is potentially used by many modules.  Its core code
	# must be as small as possible to compile quickly.
	#
	# Here, we get an assertion failure, an exceptional event.  It's ok
	# to impose a further delay.
	# 

	require Carp::Datum::Assert;
	Carp::Datum::Assert->import(qw(assert_expr stack_dump));

    my $expr = assert_expr(2);
	my $msg;
    $msg = ": " . join('', @_) if @_;
	$msg .= " ($expr)" if $expr ne '';
    $msg = $msg . where(2);
	my $stack = stack_dump(2);

	#
	# When debugging, log to the debug file.
	#
    
	if ($DBG) {
		trace("$assert_type FAILED". $msg, "!!");
		if ($debug_flag & DBG_STACK) {
			foreach my $item (@$stack) {
				trace($item, "!!");
			}
		}
	}

	#
	# Always log something to the error channel anyway
	#
	# If they configured Log::Agent with -confess, they'll get a
	# stack dump as well on panic.
	#

	if ($debug_flag & DBG_PANIC) {
		logdie "PANIC: $assert_type FAILED" . $msg;
	} else {
		logwarn "$assert_type FAILED" . $msg;
	}
}

#
# alias
#
# Alias filename, to strip long filenames.
#
sub alias {
	my ($name) = @_;

    for my $alias (@{$CFG->cfg_alias}) {
        my ($x, $y) = @{$alias};
		if (substr($name, 0, length $x) eq $x) {
			substr($name, 0, length $x) = $y;
            last;
        }
    }

	return $name;
}

#
# where
#
sub where {
    my ($level) = @_;
    my ($package, $filename, $line) = caller($level);
	$filename = alias($filename);

    return " [$filename:$line]";
}

my $DEPTH           = 0;
my $max_trace_depth = -1;
my $space           = "|  ";

#
# ->new
#
# Create a new object, meant to be destroyed at function exit
#
sub new {
    my $this  = shift @_;
    my $class = ref($this) || $this;
    my $self  = {};
    
    # get the max argument setting (by specifying 'args(yes|no|num);'
    # in config file.
    # NOTE: that is done before the arg query since the call is
    # modifying the DB::args value with different values.
    my $max_arg =  $CFG->flag('args', 1);

	my $offset = 2;
    my ($package, $filename, $line) = caller($offset);
    my $sub = (caller($offset + 1))[3];
	$sub = $sub ? "$sub()" : "global";
	my $from = '';
	$from = " from $sub at " . alias($filename) . ":$line" if defined $line;

    package DB;
    # ignore warning
    use vars qw(@args);
    my @caller = caller(2);
    package Carp::Datum;
    
    # grab info from leftover parameters
    my $info = @_ ? ": '@_'": "";
    
    if (@caller) {
        # shrink the list of argument if too long
        my $shrinked = 0;
        if ($max_arg >= 0 && $#DB::args >= $max_arg ) {
            $#DB::args = $max_arg - 1;
            $shrinked = 1;
        }

        my @args_list = map { data_format($_) } @DB::args;
        push @args_list, "..." if $shrinked;

        $self->{'call'} = "$caller[3](" . join(", ", @args_list) . ")$info";
    } else {
        $self->{'call'} = "global$info"
    }
	$self->{'call'} .= $from;
        
    trace("+-> " . $self->{'call'} . where($offset));
    $self->{'depth'} = $DEPTH++;
    
    bless $self, $class;
}

#
# ->DESTROY
#
sub DESTROY {
    my $self = shift;

    my $prev_depth = $DEPTH;
    $DEPTH = $self->{'depth'};
    trace("+-< " . $self->{'call'});
    $DEPTH = $prev_depth - 1;
}

#
# trace
#
sub trace {
    my ($message, $header) = @_;

    $header .= "   ";
    $header = substr($header, 0, 3);

    logwrite('debug', 'debug', $header . $space x $DEPTH . $message); 
}

#
# data_format
#
# return the given value to a printable form.
#
sub data_format {
    return "undef" unless defined $_[0];

    return $_[0] if (ref $_[0]) || ($_[0]=~ /^-?[1-9]\d{0,8}$/) ||
      (($_[0] + 0) eq $_[0]) ;

    require Data::Dumper;
    return Data::Dumper::qquote($_[0] );
}

1;

=head1 NAME

Carp::Datum - Debugging And Tracing Ultimate Module

=head1 SYNOPSIS

 # In modules
 use Carp::Datum;
 
 # Programming by contract
 sub routine {
     DFEATURE my $f_, "optional message";    # $f_ is a lexical lvalue here
     my ($a, $b) = @_;
     DREQUIRE $a > $b, "a > b";
     $a += 1; $b += 1;
     DASSERT $a > $b, "ordering a > b preserved";
     my $result = $b - $a;
     DENSURE $result < 0;
     return DVAL $result;
 }
 
 # Tracing
 DTRACE "this is a debug message";
 DTRACE TRC_NOTICE, "note: a = ", $a, " is positive";
 DTRACE {-level => TRC_NOTICE, -marker => "!!"}, "note with marker";
 
 # Returning
 return DVAL $scalar;     # single value
 return DARY @list;       # list of values

 # In application's main
 use Carp::Datum qw(:all on);      # turns Datum "on" or "off"

 DLOAD_CONFIG(-file => "debug.cf", -config => "config string");

=head1 DESCRIPTION

The C<Carp::Datum> module brings powerful debugging and tracing features
to development code: automatic flow tracing, returned value tracing,
assertions, and debugging traces.  Its various functions may be customized
dynamically (i.e. at run time) via a configuration language allowing
selective activation on a routine, file, or object type basis.  See
L<Carp::Datum::Cfg> for configuration defails.

C<Carp::Datum> traces are implemented on top of C<Log::Agent> and go to its
debugging channel.  This lets the application have full control of the
final destination of the debugging information (logfile, syslog, etc...).

C<Carp::Datum> can be globally turned on or off by the application.  It is
off by default, which means no control flow tracing (routine entry and exit),
and no returned value tracing.  However, assertions are still fully monitored,
and the C<DTRACE> calls are redirected to C<Log::Agent>.

The C version of C<Carp::Datum> is implemented with macros, which may
be redefined to nothing to remove all assertions in the released
code.  The Perl version cannot be handled that way, but comes with
a C<Carp::Datum::Strip> module that will B<lexically> remove all the
assertions, leaving only C<DTRACE> calls.  Modules using C<Carp::Datum>
can make use of C<Carp::Datum::MakeMaker> in their Makefile.PL to
request stripping at build time.  See L<Carp::Datum::MakeMaker> for
instructions.

Here is a small example showing what traces look like, and what happens by
default on assertion failure.  Since C<Log::Agent> is not being customized, the
debugging channel is STDERR.  In real life, one would probably
customize Log::Agent with a file driver, and redirect the debug channel
to a file separate from both STDOUT and STDERR.

First, the script, with line number:

  1 #!/usr/bin/perl
  2
  3 use Carp::Datum qw(:all on);
  4
  5 DFEATURE my $f_;
  6
  7 show_inv(2, 0.5, 0);
  8
  9 sub show_inv {
 10      DFEATURE my $f_;
 11      foreach (@_) {
 12          print "Inverse of $_ is ", inv($_), "\n";
 13      }
 14      return DVOID;
 15 }
 16
 17  sub inv {
 18      DFEATURE my $f_;
 19      my ($x) = @_;
 20      DREQUIRE $x != 0, "x=$x not null";
 21      return DVAL 1 / $x;
 22  }
 23

What goes to STDOUT:

 Inverse of 2 is 0.5
 Inverse of 0.5 is 2
 FATAL: PANIC: pre-condition FAILED: x=0 not null ($x != 0) [./demo:20]

The debugging output on STDERR:

    +-> global [./demo:5]
    |  +-> main::show_inv(2, 0.5, 0) from global at ./demo:7 [./demo:10]
    |  |  +-> main::inv(2) from main::show_inv() at ./demo:12 [./demo:18]
    |  |  |  Returning: (0.5) [./demo:21]
    |  |  +-< main::inv(2) from main::show_inv() at ./demo:12
    |  |  +-> main::inv(0.5) from main::show_inv() at ./demo:12 [./demo:18]
    |  |  |  Returning: (2) [./demo:21]
    |  |  +-< main::inv(0.5) from main::show_inv() at ./demo:12
    |  |  +-> main::inv(0) from main::show_inv() at ./demo:12 [./demo:18]
 !! |  |  |  pre-condition FAILED: x=0 not null ($x != 0) [./demo:20]
 !! |  |  |  main::inv(0) called at ./demo line 12
 !! |  |  |  main::show_inv(2, 0.5, 0) called at ./demo line 7
 ** |  |  |  FATAL: PANIC: pre-condition FAILED: x=0 not null ($x != 0) [./demo:20]
    |  |  +-< main::inv(0) from main::show_inv() at ./demo:12
    |  +-< main::show_inv(2, 0.5, 0) from global at ./demo:7
    +-< global

The last three lines were manually re-ordered for this manpage: because of the
pre-condition failure, Perl enters its global object destruction routine,
and the destruction order of the lexicals is not right.  The $f_ in show_inv()
is destroyed before the one in inv(), resulting in the inversion.  To better
please the eye, it has been fixed.  And the PANIC is emitted when the pre-condition
failure is detected, but it would have messed up the trace example.

Note that the stack dump is prefixed with the "!!" token, and the fatal
error is tagged with "**".  This is a visual aid only, to quickly locate
troubles in logfiles by catching the eye.

Routine entry and exit are tagged, returned values and parameters are
shown, and the immediate caller of each routine is also traced.  The
final tags C<from global at ./demo:7 [./demo:10]> refer to the file
name (here the script used was called "demo") and the line number
where the call to the C<Carp::Datum> routine is made: here the
C<DFEATURE> at line 10. It also indicates the caller origin: here, the
call is made at line 7 of file C<demo>.

The special name "global" (without trailing () marker) is used to indicate
that the caller is the main script, i.e. there is no calling routine.

Returned values in inv() are traced as "(0.5)" and "(2)", and not as "0.5"
and "2" as one would expect, because the routine was called in non-scalar
context (within a print statement).

=head1 PROGRAMMING BY CONTRACT

=head2 Introduction

The Programming by Contract paradigm was introduced by Bertrand Meyer in
his I<Object Oriented Software Construction> book, and later implemented
natively in the Eiffel language.  It is very simple, yet extremely powerful.

Each feature (routine) of a program is viewed externally as a supplier for
some service.  For instance, the sqrt() routine computes the square root
of any positive number.  The computation could be verified, but
sqrt() probably provides an efficient algorithm for that, and it has already
been written and validated.

However, sqrt() is only defined for positive numbers.  Giving a negative
number to it is not correct.  The old way (i.e. in the old days before
Programming by Contract was formalized), people implemented that restriction
by testing the argument I<x> of sqrt(), and doing so in the routine itself
to factorize code.  Then, on error, sqrt() would return -1 for instance
(which cannot be a valid square root for a real number), and the desired
quantity otherwise.  The caller had then to check the returned value to
determine whether an error had occurred.  Here it is easy, but in languages
where no out-of-band value such as Perl's C<undef> are implemented, it can
be quite difficult to both report an error and return a result.

With Programming by Contract, the logic is reversed, and the code is greatly
simplified:

=over 4

=item *

It is up to the caller to always supply a positive value to sqrt(), i.e. to
check the value first.

=item *

In return, sqrt() promises to always return the square root of its argument.

=back

What are the benefits of such a gentlemen's agreement?  The code of the sqrt()
routine is much simpler (meaning fewer bugs) because it does not have
to bother with handling the case of negative arguments, since the caller
promised to never call with such invalid values.  And the code of the caller
is at worst as complex as before (one test to check that the argument is
positive, against a check for an error code) and at best less complex: if it is
known that the value is positive, it doesn't even have to be checked, for instance
if it is the result of an abs() call.

But if sqrt() is called with a negative argument, and there's no explicit test
in sqrt() to trap the case, what happens if sqrt() is given a negative
value, despite a promise never to do so?  Well, it's a bug, and it's a
bug in the caller, not in the sqrt() routine.

To find those bugs, one usually monitors the assertions (pre- and
post-conditions, plus any other assertion in the code, which is both a
post-condition for the code above and a pre-condition for the code below,
at the same time) during testing.  When the product is released, assertions
are no longer checked.

=head2 Formalism

Each routine is equipped with a set of pre-conditions and post-conditions.
A routine I<r> is therefore defined as:

  r(x)
    pre-condition
    body
    post-condition

The pre- and post-conditions are expressions involving the parameters of r(),
here only I<x>, and, for the post-condition, the returned value of r() as well.
Conditions satisfying this property are made visible to the clients, and become
the routine's I<contract>, which can be written as:

=over 4

=item *

You, the caller, promise to always call me with my pre-condition satisfied.
Failure to do so will be a bug in your code.

=item *

I promise you, the caller, that my implementation will then perform correctly
and that my post-condition will be satisfied.  Failure to do so will be a
bug in my code.

=back

In object-oriented programming, pre- and post-conditions can also use internal
attributes of the object, but then become debugging checks that everything
happens correctly (in the proper state, the proper order, etc...) and cannot
be part of the contract (for external users of the class) since clients cannot
check that the pre-condition is true, because it will not have access to the
internal attributes.

Furthermore, in object-oriented programming, a redefined feature must I<weaken>
the pre-condition of its parent feature and I<strengthen> its post-condition.
It can also keep them as-is.  To fully understand why, it's best to read
Meyer.  Intuitively, it's easy to understand why the pre-condition cannot
be strengthened, nor why the post-condition cannot be weakened: because of dynamic
binding, a caller of r() only has the static type of the object, not its
dynamic type.  Therefore, it cannot know in advance which of the routines will
be called amongst the inheritance tree.

=head2 Common Pitfalls

=over 4

=item *

Do not write both a pre-condition and a test with the same expression.

=item *

Never write a pre-condition when trying to validate user input!

=item *

Never write a test on an argument when failure means an error, use a
pre-condition.

If a pre-condition is so important that it needs to always be
monitored, even within the released product, then C<Carp::Datum>
provides C<VERIFY>, a pre-condition that will always be checked
(i.e. never stripped by C<Carp::Datum::Strip>).  It can be used to protect
the external interface of a module against abuse.

=head2 Implementation

With Carp::Datum, pre-conditions can be given using C<DREQUIRE> or C<VERIFY>.
Assertions are written with C<DASSERT> and post-conditions given by C<DENSURE>.

Although all assertions could be expressed with only C<DASSERT>,
stating whether it's a pre-condition with C<DREQUIRE> also has
a commentary value for the reader.  Moreover, one day, there might be an
automatic tool to extract the pre- and post-conditions of all the routines
for documentation purposes, and if all assertions are called C<DASSERT>,
the tool will have a hard time figuring out which is what.

Moreover, remember that a pre-condition failure I<always> means a bug in the
caller, whilst other assertion failures means a bug near the place of failure.
If only for that, it's worth making the distinction.

=back

=head1 INTERFACE

=head2 Control Flow

=over 4

=item DFEATURE my $f_, I<optional comment>

This statement marks the very top of any routine.  Do not omit the C<my>
which is very important to ensure that what is going to be stored in the
lexically scoped $f_ variable will be destroyed when the routine ends.
Any name can be used for that lexical, but $f_ is recommended because it is
both unlikely to conflict with any real variable and short.

The I<optional comment> part will be printed in the logs at routine entry
time, and can be used to flag object constructors, for instance, for easier
grep'ing in the logs afterwards.

=item return DVOID

This can be used in place of an ordinary C<return> from a routine.
It allows tracing of the return statement.

=item return DVAL I<scalar>

Use this form when returning something in scalar context.  Do not put any
parentheses around I<scalar>, or it will be incorrectly stripped
by C<Carp::Datum::Strip>.  Examples:

    return DVAL 5;                      # OK
    return DVAL ($a == 1) ? 2 : 4;      # WRONG (has parenthesis)
    return DVAL (1, 2, 4);              # WRONG (and will return 4)

    my $x = ($a == 1) ? 2 : 4;
    return DVAL $x;                     # OK

    return DVAL &foo();                 # Will be traced as array context

Using DVAL allows tracing of the returned value.

=item return DARY (I<list>)

Use this form when returning something in list context.
Using DARY allows tracing of the returned values.

    return DARY @x;

If a routine returns something different depending on its
calling context, then write:

    return DARY @x if wantarray;
    return DVAL $x;

Be very careful with that, otherwise the program will behave differently
when the C<DARY> and C<DVAL> tokens are stripped by C<Carp::Datum::Strip>,
thereby raising subtle bugs.

=back

=head2 Programming by Contract

=over 4

=item C<DREQUIRE> I<expr>, I<tag>

Specify a pre-condition I<expr>, along with a I<tag> that will be printed
whenever the pre-condition fails, i.e. when I<expr> evaluates to false.
The I<tag> string may be used to dump faulty values, for instance:

    DREQUIRE $x > 0, "x = $x positive";

The I<tag> is optional and may be left off.

=item C<VERIFY> I<expr>, I<tag>

This is really the same as C<DREQUIRE>, except that it will not be stripped
by C<Carp::Datum::Strip> and that it will always be monitored and cause a
fatal error, whatever dynamic configuration is setup.

=item C<DENSURE> I<expr>, I<tag>

Specify a post-condition I<expr>, along with an optional I<tag> that will be
printed whenever the post-condition fails, i.e. when I<expr> evaluates to false.

=item C<DASSERT> I<expr>, I<tag>

Specify an assertion I<expr>, and an optional I<tag> printed when I<expr>
evaluates to false.

=back

=head2 Tracing

Tracing is ensured by the C<DTRACE> routine, which is never stripped.  When
C<Carp::Datum> is off, traces are redirected to C<Log::Agent> (then channel
depends on the level of the trace).

The following forms can be used, from the simpler to the more complex:

    DTRACE "the variable x+1 is ", $x + 1, " and y is $y";
    DTRACE TRC_WARNING, "a warning message";
    DTRACE { -level => TRC_CRITICAL, -marker => "##" }, "very critical";

The first call emits a trace at the C<TRC_DEBUG> level, by default.  The
second call emits a warning at the C<TRC_WARNING> level, and the last call
emits a C<TRC_CRITICAL> message prefixed with a marker.

Markers are 2-char strings emitted in the very first columns of the
debugging output, and can be used to put emphasis on specifice messages.
Internally, C<Carp::Datum> and C<Log::Agent> use the following markers:

    !!    assertion failure and stack trace
    **    critical errors, fatal if not trapped by eval {}
    >>    a message emitted via a Log::Agent routine, not DTRACE

The table below lists the available C<TRC_> levels defined by C<Carp::Datum>,
and how they remap to C<Log::Agent> routines when C<Carp::Datum> is off:

     Carp::Datum     Log::Agent
    -------------   -------------
    TRC_EMERGENCY   logdie
    TRC_ALERT       logerr
    TRC_CRITICAL    logerr
    TRC_ERROR       logerr
    TRC_WARNING     logwarn
    TRC_NOTICE      logsay
    TRC_INFO        logtrc "info"
    TRC_DEBUG       logtrc "debug"

If an application does not configure C<Log::Agent> specifically, all the calls
map nicely to perl's native routines (die, warn and print).

=head2 Convenience Routines

=over 4

=item C<equiv> I<expr1>, I<expr2>

Returns true when both I<expr1> and I<expr2> have the same truth value,
whether they are both true or both false.

=item C<implies> I<expr1>, I<expr2>

Returns the truth value of I<expr1> implies I<expr2>, which is the same
as:

    !expr1 || expr2

It is always true except when I<expr1> is true and I<expr2> is false.

Warning: this is function, not a macro.  That is to say, both
arguments are evaluated, and there is no short-circuit when I<expr1> is false.

=back

=head1 DEBUG CONFIGURATION

=head2 Global Switch on/off

The C<Carp::Datum> module can be turned on/off. This indication must
be included when the module is imported in the main program as
followed:

 # In application's main
 use Carp::Datum qw(:all on);      # to turn on
 use Carp::Datum qw(:all off);     # to turn off

When C<Carp::Datum> is turned off, most of the specific functions
(DFEATURE, ...) continue to be invoked during the program execution
but they return immediately. In details, all the tracing functions are
disconnected, the contracts (DASSERT, DREQUIRE, DENSURE) continue to
be verified: assertion failure will stop the program.

That leads to a tiny perfomance loss when running production
release. But, the delivered code keeps the possibility to be easily
debugged. If the performance would be problematic in a production
release, there is a stripper program available that can extract all the
C<Carp::Datum> calls from a source file. (see L<Carp::Datum::Strip>).

To turn on/off debugging according to an environment variable, the  
module can be imported like the following:

 # In application's main
 use Carp::Datum (":all", $ENV{DATUM});

 # as a preamble to the program execution 
 # in your favorite shell (here /bin/ksh)
 export DATUM=on        # to turn on
 export DATUM=off       # to turn off

=head2 Dynamic Configuration

The dynamic configuration is loaded when the C<DLOAD_CONFIG> function
is invoked in the main program. The function signature passes
either a filename or directly a string (or both). 

 DLOAD_CONFIG(-file => "./debug.cf")  # filename
  - or -
 DLOAD_CONFIG(-config => <<EOM);      # string
 routine "show_inv" {
     all(yes);
     flow(no);
     trace(no);
     return(no);
 }
 EOM

The syntax used in the file or the one of the config string is
described in L<Carp::Datum::Cfg>.

The dynamic setting allows to filter the debug traces when
running. For instance, one can enforce a routine to be silent.

As an important note, the dynamic configuration is effective only when
the global debug switch is turned on.

=back

=head1 LIMITATIONS

It's not possible to insert tracing hooks like C<DFEATURE> or C<DVAL>
in stringification overloading routines.  For C<DFEATURE>, that is because
the argument list might be dumped, and printing C<$self> will re-invoke
the stringification routine recursively.  For C<DVAL>, this is implied by
the fact that there cannot be any C<DFEATURE> in the routine, hence C<DVAL>
cannot be used.

=head1 BUGS

Please report any bugs to the current maintainer.

=head1 HISTORY AND CREDITS

The seed of the C<Carp::Datum> module started to grow in 1996 when
Raphael Manfredi and Christophe Dehaudt were involved in a tricky
project involving kernel environment. It was Christophe's first experience
with I<Programming By Contract> principles. Raphael was already familar with
the concept due to his participation in the development of the
Eiffel compiler.

Written in C, the first release was based on pre-processor macros. It
already distinguished the pre-conditions, post-conditions and
assertions. Also included were the concepts of dynamic configuration and
flow tracing. The benefit of this lonely include file was very
important since the final integration was very short and, since then,
there has been no major bug reported on the delivered product.

Based on this first success, they leveraged the techniques for
developments in C++. The debug module was upgraded with the
necessary notions required for true OO programming in C++.

The Perl module was produced in 2000, when Raphael and Christophe needed
for Perl the same powerful support that they had initiated a few years prior.
Before the first official release in spring 2001, they developed
several other Perl modules and applications (mainly related to CGI
programming) that were powered by C<Carp::Datum>. Some of them have
also been published in CPAN directory (for instance:
C<CGI::Mxscreen>).

=head1 AUTHORS

Christophe Dehaudt and Raphael Manfredi are the original authors.

Send bug reports, hints, tips, suggestions to Dave Hoover at <squirrel@cpan.org>. 

=head1 SEE ALSO

Carp::Datum::Cfg(3), Carp::Datum::MakeMaker(3), Carp::Datum::Strip(3),
Log::Agent(3).

=cut

