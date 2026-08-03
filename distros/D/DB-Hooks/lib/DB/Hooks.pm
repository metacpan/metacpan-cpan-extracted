package DB::Hooks;

our $VERSION =  '0.0201';

=head1 NAME

C<DB::Hooks> - Hooks for perl debugger

=cut

=head2 Possible options

undef - configures visible representation for 'undef' during dumps.

=cut


=head2 Possible events

load - after module is compiled
goto - after 'goto' was executed
call - before calling a subroutine
return - before returning from a subroutine
Next events occur only during 'interact' and when additionally:
trace - $DB::trace is true
trap - $DB::trap configured for that file:line
stop - DB::state('single') is true
binteract, interact, ainteract - 'trap' and 'stop' handlers did not cancel interaction
	OR $DB::signal is true

User defined events.

=cut



=head2 Debugger verbosity

DB::state( 'ddd' )

&64 - shows when context is stored and restored

&32 - display the information about:
  what events were emitted
  what expressions were evaluated in user context during 'process'
  state of a debug debugging for the next call depending on DB::state( 'dd' )
  what callbacks were run during 'process' and finished
  when 'dbcall' (call to the debugger) happened and who called it
  when 'dbcall' finished. Start and stop info lines are marked by 'D<random'
  the next value of $DB::single when nested debugger was destroyed

&16 - display information when debugger is created/destroyed with the information
  about its state. Also displays messages when compilation was started/finished.
&8 - track reads to DB::state
&4 - track writes to DB::state
&2 - track subroutine calls
&1 - enable basic messages from debugger
  display which additional debugger modules are loaded
  display info from debugger commands

=cut

=head2

DB::flags displayed during debugging debugger: s:0 t:0 i:0 c:1

	"s:$DB::single t:$DB::trace i:$DB::instance c:".@DB::state;

s -- step-by-step debugging enabled or not.
t -- tracing enabled or note.
i -- current debugger instance.
c -- number of contexts. TODO? Should we name it d -- number of debuggers.

=cut

# PERLDB_OPTS='CTddd=2 white_box=~' PERL5DB="use DB::Hooks qw'::Terminal ::TraceLoad ::TraceSubs ::TraceVariable NonStop'" PERL5OPT='-d' prove -v ./script.pl


# The precendence is next:
# 1. Module is compiled
# 2. on_load event if emitted
# 3. Module is run
# 4. If it return 1 its &import is called

# NOTICE: We do not inherit DB:: interface, we use it
sub import {
	my( $class ) =  shift;

	DB::parse_options( @_ );

	my $ddd =  DB::state( 'ddd' ) &1;
	if( $class eq 'DB::Hooks' ) {
		for my $module ( @_ ) {
			next   unless $module =~ m/^::/;
			my( $package, $args ) =  $module =~ m/^::([^=]+)=?(.*)$/;
			$args //=  '';
			my $dbg =  "DB::Hooks::$package";
			$package  =~ s/::/\//;
			DB::say( "Requiring " .DB::_c( "DB::Hooks::$package", '32' ) ." $args" )   if $ddd;
			require "DB/Hooks/$package.pm";
			$dbg->import( split ':', $args );
		}
	}


	DB::_leave( $class, @_ );
	DB::say( DB::_c( "DB::Hooks import done", 31 ) )   if $ddd;
	return;
}



package DB::Error;
use overload bool => sub {1}, '""' => sub { shift->error }, fallback => 1;

sub error {
	return shift->{ error };
}



package DB;

## Managment routines

# Hooks to Perl's internals should be first.
# Because debugger or its descendants may call them at compile time
use DB::Utils();

# Though this is located before BEGIN{ #INIT } block, this will be executed later,
# after DB:: compilation.
DB::say "DB:: Initialization is started"   if DB::state( 'ddd' ) &17;

use strict;
use warnings;

# Used perl internal variables:
# ${ ::_<filename }  # maintained at 'file' and 'sources'
# @{ ::_<filename }  # maintained at 'source' and 'can_break'
# %{ ::_<filename }  # maintained at 'traps'
# $DB::single
# $DB::signal
# $DB::trace
# $DB::sub   # NOTICE: this maybe the reference to sub, not just the name of it
# %DB::sub   # maintained at 'location' and 'subs'
# %DB::postponed  # Run callback after 'subname' was compiled
# @DB::args  # maintained at 'frames'

# $^P -- http://perldoc.perl.org/perlvar.html#$^P
# Default values
#      1 x
# 0111 0011 1111
# |||| |||| |||^-- Debug subroutine enter/exit.
# |||| |||| ||^--- Line-by-line debugging.
# |||| |||| |^---- Switch off optimizations.
# |||| |||| ^----- Preserve more data for future interactive inspections.
# |||| ||||
# |||| |||^------- Keep info about source lines on which a subroutine is defined.
# |||| ||^-------- Start with single-step on.         { NonStop }
# |||| |^--------- Use subroutine address instead of name when reporting.
# |||| ^---------- Report goto &subroutine as well.   # We always turn it ON
# ||||
# |||^------------ Provide informative "file" names for evals based on the place they were compiled.
# ||^------------- Provide informative names to anonymous subroutines based on the place they were compiled.
# |^-------------- Save source code lines into @{"_<$filename"}.
# ^--------------- When saving source, include evals that generate no subroutines.
# < When saving source, include source that did not compile.

# Perl sets up $DB::single to 1 after the 'script.pl' is compiled, so we are able
# to debug it from first OP. We can disable this feature by $^P &= ~0x20 { NonStop }





our $IN;
our $OUT;
our @state;          # The array of debugger instances
our %options;
our $commands;       # hash of commands available in debugger
our %variables;      # Hash which defines behaviour for values available through &DB::state
	# There three types of variables:
	# Debugger internal variables -- global values from DB:: package
	# Debugger instance variables -- values which exists in current debugger instance
	# Frame variables -- values for each sub call
our $instance;BEGIN{ $instance =  0 }   # The default debugger instance visible for DB::state calls

our $_fix_caller;    # For easier debugger debugging we prettify __ANON__ stack frames at &save_context
our $after_dbcall;   # Setup handler for 'dbcall'. Used to destroy CT debugger instance.


sub dbcall {
	local $_; # See save_context
	my( $level, $ctx, $sub ) =  (shift,shift,shift);

	my @args;
	my $ddd =  DB::state( 'ddd' );
	if( $ddd &32 ) {
		local $" =  ', ';
		@args    =  vis_undef( @_ );
		$args[0] =  "\e[33m" .$args[0] ."\e[2;33m"   if @args;
	}

	# save_context (&64) adds an empty line too. Do not double it here.
	my @new_line =  $ddd &64? () : '';
	my $sub_name =  DB::sub_name( $sub );
	my @msg      =  ( @new_line, DB::who ." " .DB::_c( DB::flags, '1;90' ),
		   "  $sub_name( @args\e[0m )" );

	# if( $sub_name eq 'DB::emit'  &&  !DB::events( $_[0] ) ) {
	# 	DB::say @msg, "<-- dbcall No subscribers. Skipped."   if $ddd &32;

	# 	restore_context( $ctx );

	# 	DB::say ''   if $ddd &32;

	# 	return;
	# }


	my $rand;
	if( $ddd &32 ) {
		$rand    =  int rand( 65535 );
		$msg[1] .=  " D>$rand";
		DB::say @msg;
	}

	my @res;
	{
		# IT: 2+2;e;
		# This will require Data::Dump which triggers postpone method to be called
		# and reenter the debugger. So we should check recurse when DB::dbcall is made:
		# TODO? Should we move this into DB::new?
		DB::start_dd   if DB::state( 'dbcall' );


		# NOTICE: Old value of $DB::single/trace/signal is stored by constructor
		# and restored when we leave this block
		my $dd_frame =  DB::new( $ctx );


		# Here we control debugger debugging (also see DB::process)
		$^D |= (1<<30)   if DB::state( 'dd' );

		DB::state( dbcall => 1 +$level );
		defined wantarray? @res= &$sub : &$sub;
		DB::state( dbcall => undef );

		# $^D &= ~(1<<30)   if DB::state( 'dd' ); # TODO??? Should we turn off flag at the end
	}

	($DB::after_dbcall->(), undef $DB::after_dbcall)   if $DB::after_dbcall;

	DB::say '<-- dbcall'. " " .DB::_c( DB::flags, '1;90' ) ." D<$rand"   if $ddd &32;
	return defined wantarray? @res : ();
}


# NOTICE:
# In theory any additional pakcage usage may break user's code
# because this usage cause packages to be loaded in different order under debugger
# in compare to the order they are loaded without it
use Sub::Metadata qw/ mutate_sub_is_debuggable /;


## The debugger instance
mutate_sub_is_debuggable( \&state, 0 );
sub state {
	my( $name, $value ) =  @_;
	# During a global destruction if something was loaded before the debugger it will be
	# destroyed after the debugger. Calls to `DESTROY` will still fire DB::sub, but the
	# debugger does not exists already, thus @DB::state is empty
	# TODO: We can undefine DB::sub if last instance was destroyed instead of frequently
	# checks here
	return @_>1 ? $DB::state[-1]{ ddd } =  $value : $DB::state[-1] && $DB::state[-1]{ ddd } // 0
	   if $name eq 'ddd';

	my $hash =  $DB::state[$DB::instance];

	my $ddd =  $hash->{ ddd } // 0;
	# Track changes to DB::state  OR  reads from DB::state
	if( $ddd&4 && @_>1  ||  $ddd&8 && @_<=1 ) {
		my( $sub ) =  (caller(1))[3];
		my( $file, $line ) =  (caller)[1,2];
		my $old_value =  vis_undef( $hash->{ $name } );
		my $new_value =  @_ > 1 ? ' -> ' .vis_undef( $value ) : '';

		DB::say "Access from $sub ($file:$line) to "
			.DB::_c( $name, 36 ) ." state($DB::instance): "
			.DB::_c( "$old_value$new_value", '3;37' )
	}

	return $hash->{ $name }   unless @_ > 1;
	delete $hash->{ $name }, return   unless defined $value;

	$DB::trace = $value   if $name eq 'trace';
	return $hash->{ $name } =  $value;

	$name =  '*'   unless exists $DB::variables{ $name };
	return $DB::variables{ $name }( @_ );
}



sub int_vrbl {
	my( $name, $value ) =  @_;

	if( @_ > 1 ) {
		${ "DB::$name" } =  $value;
	}

	return dbg_vrbl( @_ );
}



sub dbg_vrbl {
	my( $name, $value ) =  @_;

	# TODO: Assert the change to saved 'context'
	# We should not rewrite saved context otherwise we restore to wrong context
	# Access to context(0) state: ARRAY -> ARRAY

	my $hash =  $DB::state[-1];
	if( @_ > 1 ) {
		defined $value
			? $hash->{ $name } =  $value
			: delete $hash->{ $name };
	}

	return $hash->{ $name };
}



sub new {
	my $ctx =  shift;

	my( $ddd, $t, $dd ) =  0;
	if( @DB::state ) { # There is no debugger states if debugger loading is in progress
		# Save internal flags when we enter debugger
		DB::state( context =>  $ctx        );
		DB::state( single  =>  $DB::single );
		DB::state( trace   =>  $DB::trace  );
		# DB::state( signal  =>  $DB::signal );

		# Update debugger cursor
		my( $p, $f, $l ) =  @{ $ctx->[0] }[0..2];
		DB::state( 'package', $p );
		DB::state( 'file',    $f );
		DB::state( 'line',    $l );


		$ddd =  DB::state( 'ddd'   );
		$t   =  DB::state( 'trace' );
		$dd  =  DB::state( 'dd'    );
	}
	else {
		$ddd =  $DB::options{ CTddd } //0;
	}


	# Display this message instantly after $ddd becomes available
	DB::say "", DB::who, "IN  DEBUGGER  >>>>>>>>>>>>>>>>>>>>>> " .DB::_c( DB::flags ."+1", '1;90' )
	   if $ddd &17;


	push @DB::state, { events => {} };
	DB::state( ddd   => $ddd )   if $ddd;
	DB::state( trace => --$t )   if $t;

	DB::say DB::_c( "New debugger instance ", '2;92' ), DB::dumper \@DB::state   if $ddd &16;

	return bless{ cleaner => shift }, 'DB';
}



sub DESTROY {
	my $ddd =  DB::state( 'ddd' );

	DB::say DB::_c( "Destroy debugger instance ", '2;92' ), DB::dumper \@DB::state           if $ddd &16;
	DB::say "OUT DEBUGGER  <<<<<<<<<<<<<<<<<<<<<< " .DB::_c( DB::flags ."-1", '1;90' ), ""   if $ddd &17;

	pop @DB::state;


	# Cleanup stuff when frame is restored
	my $cleaner =  shift->{ cleaner };
	$cleaner  &&  $cleaner->();

	# Restore internal flags when we leave debugger
	# Find testcase for this condition
	if( @DB::state ) { # There is no debugger states if main script was terminated
		$DB::single =  DB::state( 'single' ) // 0;
		$DB::trace  =  DB::state( 'trace'  ) // 0;
		DB::say 'Debug flag is restored: $single =  ' .$DB::single   if $ddd &32;

		my $ctx =  DB::state( 'context' );
		# WARNING: Do not keep any references to user's data eg. @_
		# Otherwise we postpone object desctruction process.
		DB::state( context => undef ); # $ctx->[0] =  undef # TODO: IT
		DB::finish_dd       if DB::state( 'xx' );
		# TODO: Flag should be restored from main frame if we do not continue debugging
		# TODO: IT; Compare with 090da7c: NOTICE: Create debugger instance only ...
		restore_context( $ctx );
	}
}



# Parse x=y pairs. Options in different format are skipped. Eg. ::Name will be handled
# later by ::import.
sub parse_options {
	my @opts =  split ' ', $ENV{ PERLDB_OPTS }   if defined $ENV{ PERLDB_OPTS };

	for( @opts, @_ ) {
		if( /^([:\w]+)=(.*)/ ) {
			$DB::options{ $1 } =  $2;
		}
		else {
			$DB::options{ $_ } =  1;
		}
	}
}



# This sub applies options from $DB::options to DB::state
# NOTICE: This sub is called twice: at compile time and before run time of 'main' package
sub apply_options {
	$DB::options{ DumpObjects } //=  1;
	if( $DB::options{ DumpObjects } ) {
		require Scalar::Util;
		Scalar::Util->import(qw/ reftype blessed /);
		mutate_sub_is_debuggable( \&DB::reftype, 0 );
		mutate_sub_is_debuggable( \&DB::blessed, 0 );
	}


	my $ct =  shift // '';
	# { ddd } flag should be first to see debugging messages for next
	for( qw/ ddd dd trace TraceLoad TraceGoto TraceCall TraceStack TraceReturn / ) {
		DB::state( $_ =>  $DB::options{ "${ct}$_" } );
	}

	# When we are going to work at white_box we must activate black_box
	# because white_box can be activated only from black_box (see DB::sub)
	if( $DB::options{ "${ct}white_box" } ) {
		DB::state( black_box_active => 1 );
	}

	# We may check if (caller)[3] eq 'import' to distinguish CT and RT
	$^P &= ~0x20               if $DB::options{ NonStop };
	DB::state( 'single', 1 )   if $DB::options{ Stop }; # IT: commit:1191c38
}



sub _leave {
	my $class =  shift;

	# Now debugger and all required modules are loaded (except Descendant).
	# We should inspect %DB::options and setup corresponding perl debugger
	# *internal* values
	# When <DEBUGGER>::import returns the next OP will be first OP from main::

	# We are leaving debugger
	my $handler; $handler =  DB::on( return => sub{
		#TODO? Should be call this from 'postpone'?
		return   unless $_[0] eq $class .'::import';

		DB::unsubscribe( return => $handler );
		$DB::after_dbcall = sub{
			my $dbg =  DB::new;              # Create RT debugger
			$DB::instance++;
			# NOTICE: Circular reference is here.
			# The debugger instance exists until main script is terminated
			DB::state( debugger => $dbg );   # Make debugger instance accessable via state
			#TODO? Probably we want apply options as soon as possible, but keep an eye to
			# DB::instance, because we may apply them to a wrong instance.
			apply_options();

			# TODO: Because RT and CT options are differ on command line
			# We may leave CT debugger alive for history reasons
			# Delete CT debugger
			push @DB::state, shift @DB::state; # Swap RT and CT debuggers
			DB::state( debugger => undef );
			$DB::instance--;


			no strict 'refs'; no warnings 'redefine';
			*{ "DB::on" }          =  \&{ "DB::RT_on" };
			*{ "DB::unsubscribe" } =  \&{ "DB::RT_unsubscribe" };

			DB::say DB::c_( "RT debugger initialized:" , '1;32' ), DB::dumper \@DB::state
			   if DB::state( 'ddd' ) &16;
		};

		return;
	});
}



## Evaluation in usercontext
# We put code here to execute it only once
my $usercontext; BEGIN {
($usercontext =  <<'CODE') =~ s#^\t##gm;
	BEGIN {
		( $^H, ${^WARNING_BITS}, my $hr ) =  @{ DB::state( 'context' )->[0] }[8..10];
		%^H =  %$hr   if $hr;
	}
	# $@ is cleared when compiller enters *eval* or *BEGIN* block
	$@ =  (DB::state( 'context' ))[2];
CODE
}
sub eval {
	my $expr =  shift // return;

	DB::state( last_eval => $expr );

	my $ctx =  DB::state( 'context' );
	my $pkg =  $ctx->[0][0];
	# Read BEWARE at DebugHooks.pod about localization of globals
	local $^D;
	local $_ =  $ctx->[3];
	local @_ =  @{ $ctx->[1] };
	# TODO: Beware that using eval neither silences Perl from printing warnings to STDERR,
	# nor does it stuff the text of warning messages into $@
	# How to reproduce: $expr = '234asd';
	eval "$usercontext; package $pkg;\n$expr";
	#NOTICE: perl implicitly add semicolon at the end of expression
	#HOWTO reproduce. Run command: X::X;1+2
	#
	# print $DB::OUT "Error occur while evaluating: $@"   if $@
	# But if we do this we return wrong value
}

# In theory &save_context should be called as soon, as possible.
sub save_context {
	# TODO: What to save:
	# https://metacpan.org/source/OPI/Perl-AtEndOfScope-0.03/lib/Perl/AtEndOfScope.pm
	# also see perl5db.pl
	# TODO: Debugger destroyes $1, $2 etc variables in scope

	my $ctx =  [ [caller 1], \@_, $@, $_ ]; # The benefit of this is access to stored global values
	DB::say '', "Context is stored for $DB::_fix_caller"   if DB::state( 'ddd' ) &64;

	# Replace __ANON__[lib/DB/Hooks.pm:-2] with target sub
	$ctx->[0][3] =  $DB::_fix_caller   if $DB::_fix_caller;
	$ctx->[0][1] =~  s/$DB::options{ pwd }/~/;

	return $ctx;
}



# WORKAROUND: &restore_context is called outside of DB::DB, so we should stop debugging it
# to prevent $file:$line updated in unexpected way
# mutate_sub_is_debuggable( \&restore_context, 0 );

sub restore_context {
	my $ctx =  shift;
	# $_ is implicitly localized at &emit by 'for'
	# But we still beware about it in &DB::interact if you change it there
	# then it will broke the user's context. TODO: IT
	( $@ ) =  @$ctx[ 2 ];
	DB::say 'Context is restored'   if DB::state( 'ddd' ) &64;
}


### Initialization
# NOTICE: Everything should be defined before first subroutine call


no strict 'refs';


# Do DB:: configuration stuff here
# Default debugger behaviour while it is loading
# NOTICE: Order is important. Once subs, which are hooks into Perl internals, are compiled,
# they are invoked immediately when their conditions are met. Perl will crash if required
# subroutines are not available yet.
BEGIN { #INIT
	# TODO: This does not work if program is run: script.pl < input
	$DB::IN  //= \*STDIN   if -t STDIN;

	#TODO: cache output until debugger is connected
	$DB::OUT //= \*STDOUT;
	my $ofh =  select $DB::OUT; $|= 1; select $ofh;

	$DB::ERR //= \*STDERR;
	$ofh =  select $DB::ERR; $|= 1; select $ofh;


	srand(0); # Required for the same values between runs # if $ddd &32
		# It is useful when we diff debugger's output between separate runs.

	# This call will read options from PERLDB_OPTS only. All other options passed to
	# 'use DB::Hooks XXX' will be available after the compilation and 'import' call.
	parse_options();
	# NOTICE: options becomes available via DB::state only after the debugger
	# instance is created and 'apply_options' call. Thus access 'ddd' directly.
	my $ddd =  $DB::options{ CTddd }  // 0;   # The first access to 'ddd' option
	DB::say "DB:: Compilation is started"   if $ddd &17;

	%DB::variables =  (()
		,'*'         =>  \&dbg_vrbl
		,single      =>  \&int_vrbl
	);

	my $pwd =  $ENV{NO_ROOT}? '!!!%%%' : `pwd`; chomp $pwd;
	$DB::options{ undef } //=  'undef';        # Text to print for undefined values
	$DB::options{ pwd   } //=  "$pwd/";


	#NOTICE: we should always trace goto frames. Hiding them will prevent
	# us to complete our work - debugging.
	# But we still allow to control this behaviour at compiletime & runtime
	# !!! $options{ trace_goto };    #see DH:import  # compile time & runtime option
	# See the summarized flag description above or full one in the official documentation:
	# http://perldoc.perl.org/perlvar.html#$^P
	$^P |= 0x80;

	my $dbg =  DB::new;             # Create CT debugger and new state buffer
	DB::state( debugger => $dbg );  # Save debugger instance into that buffer
	DB::state( init => 1 );


	# NOTICE: Because of DB::DB, DB::sub, DB::postpone etc. subs take effect as soon as they
	# compiled we should &apply_options before that at compile time
	apply_options( 'CT' );

	# Though we can use "DB::state( 'ddd' )" here the $ddd is used for performance.
	DB::say DB::_c( "CT debugger initialized: ", '1;32' ) .DB::_c( DB::flags, '1;90' ),
	   DB::dumper \@DB::state   if $ddd &16;

	# When DB package is loaded its &import subroutine is called (see comment there)
}



# HOOKS
# NOTICE: They take effect as soon as compiled
# NOTICE: If you 'use' something or make call then next subs will not be defined atomary
# calls will be made to them

sub postponed {
	return   if !DB::events( 'load' );

	local $DB::_fix_caller =  'DB::postponed';

	dbcall 0, &save_context, \&emit, 'load', @_;
}



sub goto {
	return   if !DB::events( 'goto' );

	my $sub_name =  sub_name( my $tmp =  $DB::sub );
	local $DB::_fix_caller =  "$sub_name; DB::goto";

	# dbcall 1, [ [caller 1], [ @DB::args ], $@, $_ ], \&emit, 'goto', sub_name( $DB::sub );
	# panic: Attemt to copy freed scalar at ... when ::TraceSubs
	# PERL5DB="use DB::Hooks qw'::Terminal NonStop ::TraceLoad ::TraceSubs'"
	# The problem occur at HiRes::AUTOLOAD:51 where we goto ...
	dbcall 1, [ [caller 1], [ ], $@, $_ ], \&emit, 'goto', $sub_name;
}



# This is called from DB::DB when user's program reaches a point that can hold a breakpoint.
sub interact {
	my( $f, $l ) =  @_;

	# Perl has bug: after eval the source is not available through
	# DB::source interface. It is available lately at some point
	my $source =  DB::source( $f )->[ $l ]  //''; chomp $source;
	emit( 'trace', $source, $f, $l )   if $DB::trace;

	my @trap;
	if( my $info =  DB::traps( $f )->{ $l } ) {
		@trap =  emit( 'trap', $info, $f, $l );
		# Stop unconditionally if there is no subscribers for the event
		@trap =  (1)   unless @trap;
	}


	# DB::state( 'single' ) may be changed by some 'trap' handler: a 4 go 6
	my @stop;
	if( DB::state( 'single' ) ) {
		@stop =  emit( 'stop', $f, $l );
		# Stop unconditionally if there is no subscribers for the event
		@stop =  (1)   unless @stop;
	}

	return   unless (grep{$_} @stop)  ||  (grep{$_} @trap)  ||  ($DB::signal);
	# Stop if required or we are in step-by-step mode



	emit( 'binteract', $source, $f, $l );
	emit( 'interact' );
	emit( 'ainteract' );
}



sub db {
	DB::say DB::_c( 'DB::DB', '2;33' ) ." is called: Breakpoint meet"
	   if DB::state( 'ddd' ) &1;

	# die "DDD $DB::instance" . DB::dumper( \@DB::state ) .DB::dumper \%DB::options;

	my $ctx =  shift;
	dbcall 1, $ctx, \&interact, @{ $ctx->[0] }[1,2];
}



# Hook to Perl internals
# https://perldoc.perl.org/perldebguts
# When the execution of your program reaches a point that can hold a breakpoint,
# the DB::DB() subroutine is called if any of the variables $DB::trace, $DB::single,
# or $DB::signal is true.
sub DB {
	local $DB::_fix_caller =  'DB::DB';

	# WORKAROUND for perl before 5.18: Thanks for mst
	# the 'sub DB' pad isn't getting pushed to allocate a new pad if
	# you set '$^D|=(1<<30) and reenter DB::DB
	# So I call general sub. '&' used to leave @_ intact
	db( &save_context );
}



# Hook to perl internals
# https://perldoc.perl.org/perldebguts
# When execution of the program reaches a subroutine call, a call to &DB::sub(args)
# is made instead

# NOTICE: This call does not create frames
sub sub {
	DB::say DB::who( sub_name( my $tmp1 =  $DB::sub ) ) .' ' .DB::_c( "SUB " .DB::flags, '1;90' )
	   if sub{ DB::state( 'ddd' ) }->() &2;

	my $dbg =  $DB::state[$DB::instance];

	# Do not trace call/return when we are in debugger
	return &$DB::sub   if $dbg->{ dbcall };

	# my @s =  ( $1, $2, $3, $4, $5, $6, $7, $8, $9 ); # IT. See commit
	# FIX: https://github.com/Perl/perl5/issues/19767

	# bb/wb functionality
	my $sub_name =  sub_name( my $tmp2 =  $DB::sub );
	my $wb       =  $DB::options{ white_box };
	my $match_wb =  $wb  &&  $sub_name eq $wb  &&  $dbg->{ black_box_active };

	# my $match =  join '-', map{ $_ //'#' } @s;
	# @s =  map{ $_ //'' } @s;
	# $match =~ m/^(?:(\Q$s[0]\E)|#)-(?:(\Q$s[1]\E)|#)-(?:(\Q$s[2]\E)|#)-(?:(\Q$s[3]\E)|#)-(?:(\Q$s[4]\E)|#)-(?:(\Q$s[5]\E)|#)-(?:(\Q$s[6]\E)|#)-(?:(\Q$s[7]\E)|#)-(?:(\Q$s[8]\E)|#)$/;

	# Do not trace call/return when we are in blackbox
	return &$DB::sub   if $dbg->{ black_box_active }  &&  !$match_wb;


	# Store state and prepare context
	DB::state( black_box_active => undef )   if $match_wb;

	# NOTICE: $sub_name, $context and @$args/@ret/$ret are paramters for the event handler.
	# Though $sub_name and $context could be accessed from a handler via saved context,
	# they are passed in hope to simplify their life. Also these parameters are visible
	# during a debugger debugging with &32 ddd flag.
	if( DB::events( 'call' ) ) {
		local $DB::_fix_caller =  "$sub_name; DB::sub call " .scalar @_;
		my $ctx     =  sub{ &save_context }->( @_ );
		my $context =  $ctx->[0][5];   # wantarray
		my $args    =  \@_;            # TODO? Pass the copy
		sub{ dbcall 0, $ctx, \&emit, 'call', $sub_name, $context, @$args }->();
	}


	local $DB::_fix_caller =  "$sub_name; DB::sub return";
	my $context =  sub{ (caller 0)[5] }->();
	if( $context ) {                             # list context
		my @ret =  &$DB::sub;

		if( DB::events( 'return' ) ) {
			my $ctx =  sub{ &save_context }->( @ret );
			sub{ dbcall 0, $ctx, \&emit, 'return', $sub_name, $context, @ret }->();
		}

		DB::state( black_box_active => 1 )   if $match_wb;

		return @ret;
	}
	elsif( defined $context ) {                  # scalar context
		my $ret =  &$DB::sub;

		if( DB::events( 'return' ) ) {
			my $ctx =  sub{ &save_context }->( $ret );
			sub{ dbcall 0, $ctx, \&emit, 'return', $sub_name, $context, $ret }->();
		}

		DB::state( black_box_active => 1 )   if $match_wb;

		return $ret;
	}
	else {                                        # void context
		&$DB::sub;

		if( DB::events( 'return' ) ) {
			# TODO: IT: check $hasargs. Should be same as calling sub
			my $ctx =  sub{ &save_context }->();
			sub{ dbcall 0, $ctx, \&emit, 'return', $sub_name, $context }->();
		}

		DB::state( black_box_active => 1 )   if $match_wb;

		return;
	}

	die "This should be reached never";
	#NOTICE: This reached when someone leaves sub by calling 'next/last' outside of LOOP block
}

# Hook to perl internals
# https://perldoc.perl.org/perldebguts
# NOTICE: This does not work as documented?
sub lsub : lvalue { &$DB::sub }


DB::say "DB:: Initialization is finished"   if DB::state( 'ddd' ) &17;
1;

=head1 AUTHOR

Eugen Konkov <debugger@konkov.top>

=head1 COPYRIGHT

Copyright (c) 2015-2026 Eugen Konkov

=head1 LICENSE

This module is distributed under the Perl Debugger Evaluation and Commercial
License. See the LICENSE file included with this distribution.

=cut

# These code lines are very handy in understanding the stages during DB activation.
# Eg. "Compiliation" occurs before "Initialization".
BEGIN{ DB::say "DB:: Compilation is finished"   if DB::state( 'ddd' ) &17 }
package DB::Compilation;
BEGIN{} #IT

__END__
TODO: Source lines are disappeared for
/home/kes/work/projects/safevpn/repo2/local/lib/perl5/DBIx/Class/ResultSet.pm
   x1886:   my $attrs = { %{$self->_resolved_attrs} };
    1887:
   x1888:   my $join_classifications;
   x1889:   my ($existing_group_by) = delete @{$attrs}{qw(group_by _grouped_by_distinct)};
    1890:
    1891:   # do we need a subquery for any reason?
    1892:   my $needs_subq = (
    1893:     defined $existing_group_by
    1894:       or
    1895:     ref($attrs->{from}) ne 'ARRAY'
    1897:       or
    1898:     $self->_has_resolved_attr(qw/rows offset/)
    1900:   );
    1901:
    1902:   # simplify the joinmap, so we can further decide if a subq is necessary
   x1903:   if (!$needs_subq and @{$attrs->{from}} > 1) {
    1904:
   x1905:     ($attrs->{from}, $join_classifications) =
    1906:       $storage->_prune_unused_joins ($attrs);
    1907:
    1908:     # any non-pruneable non-local restricting joins imply subq
   x1909:     $needs_subq = defined List::Util::first { $_ ne $attrs->{alias} } keys %{ $join_classifications->{restricting} || {} };
    1910:   }
    1911:
    1912:   # check if the head is composite (by now all joins are thrown out unless $needs_subq)
    1913:   $needs_subq ||= (
    1914:     (ref $attrs->{from}[0]) ne 'HASH'
    1915:       or
    1916:     ref $attrs->{from}[0]{ $attrs->{from}[0]{-alias} }


TODO #IT: see commit:
09630efb86ec7a4aa71180e66e4b74526a623a79
Setup $DB::single for each call to user^s handler when DB::state( 'dd' ) is TRUE

for last source for tests in 26_cmd_r.t
s;s;DB::state( dd => 1 );r 1;r;r;r;r;r;r;
There are problem that for second subscriber $DB::single should be setted again,
because when first $handler is return the state is restored as for main script frame
but because 'dd' flag is TRUE we should setup $DB::single == 1 to be able to
debug this $handler too


# FIX: Debugger can not stop on return line
$wizard = \{ a => 1 };
$DB::single =  1;
return { %$wizard };


TODO:
If source consist of next lines:
1:	or return
2:
3: # Validate @keys from data object against $expect'ed
4: # or pattern matched
5: # or $extra keys
6: my @e;
The 3-4-5-6 lines are not defined in source and not displayed by debugger
Actually 6 line is displayed on 2 line


TODO:
l -1
d engine->serialize($content)
Global symbol "$content" requires explicit package name (did you forget to declare "my $content"?) at

Проблема заключается в том, что я не могу перезапустить функцию с аргументами,
когда отматываю на один уровень выше


TODO:

Если функция умирает, то через неё нельзя сделать n
Тут мы видимо должны останавливаться в следующем шаге после исключения

TODO:
l -
to see upper frame
