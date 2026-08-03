package DB::Hooks::Terminal;

use strict;
use warnings;



# We can not track DB::Commands loading if 'use' it before DB::Hooks
use DB::Commands qw/ set_command get_command run /;
# Commands should be available immediately. This is important when
# we are debugging at CT: when DB is in process of loading
BEGIN {
	set_command next_command =>  \&readline;
}



my $last_command;
BEGIN{ $last_command =  '' }
sub readline {

	print $DB::OUT "\n\e[2;96m", DB::indentation( 'D', $DB::instance +1 ) ,"BG>\e[0m";
	my $command =  <$DB::IN>;
	chomp $command;

	return $last_command   unless length $command;

	return $last_command =  $command;
}



sub on_load {
	my( $file ) =  @_;

	return   unless (DB::state( 'TraceLoad' )//0) &1;

	DB::say "\e[32mLoaded\e[0m: \e[1;33m$file\e[0m";
}



sub on_goto {
	my( $sub ) =  @_;

	return   unless (DB::state( 'TraceGoto' )//0) &1;

	DB::say "Goto \e[32m$sub\e[0m";
}



sub on_trace {
	my( $source, $file, $line ) =  @_;
	$source =~ s/^\s+//;

	DB::say "\e[2;37m$file:$line\e[0m", "t: \e[1;33m$source\e[0m";
}



sub on_call {
	if( DB::state( 'TraceStack' ) ) {
		my $stack =  DB::state( 'stack' );
		DB::state( stack => $stack=[] )   unless $stack;
		push @$stack, $_[1];
	}

	return   unless (DB::state( 'TraceCall' )//0) &1;

	my( $sub, $context, @args ) =  @_;
	$context =  $context ? '@' : defined $context? '$' : ';';
	$sub     =  "\e[1;32m$sub\e[0m";
	@args    =  DB::vis_undef( @args );

	local $" = ', ';
	DB::say "$context $sub( \e[32m@args\e[0m )";
}



sub on_return {
	if( DB::state( 'TraceStack' ) ) {
		my $stack =  DB::state( 'stack' );
		pop @$stack;
	}

	return   unless (DB::state( 'TraceReturn' )//0) &1;

	my( $sub, $context, @values ) =  @_;

	$context =  $context ? '@' : defined $context? '$' : ';';
	$sub     =  "\e[32m$sub\e[0m";
	@values  =  DB::vis_undef( @values );

	local $" = ', ';
	DB::say "$context( \e[32m@values\e[0m ) <-- $sub";
}



sub on_binteract {
	run( 'l 0' );
}



sub on_interact { get_command( 'interact' )->( @_ ) };

# Subscribe subs to events
# on_interact (some debugger commands) does not work without on_call/on_return
# NOTICE: subscribe in the given order
use DB::Utils qw/ trace call return interact load goto binteract /;


1;
