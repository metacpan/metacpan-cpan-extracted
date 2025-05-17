package Crop::Error;
use base qw/ Exporter /;

=begin nd
Class: Crop::Error
	Basic error-handle functions.
	
	This module redefines original perl function warn that has the 'true' return value, instead of
	the return value of this function. Be aware.
=cut

use v5.14;
use warnings;

use Time::Stamp -stamps => {dt_sep => ' ', ms => 1};

use Crop;

=begin nd
Constants: Error levels.

	Semantics is comming from the kernel error messages.

Constant: EMERG
	The system is broken absolutly.

	The most critically strong level.
	Unique sufficient choise for this state is to die silently and securitily is possible.

Constant: ALERT
	Fatal error of the main system.
	
	System can not do their work correctly so it must be stopped gracefully
	and terminate current request with respect to the user.

Constant: CRIT
	Critical resource error.
	
	May be temporary error. This state require sufficient reaction.

	Tipical causes are: unreachable third-party service or resource is busy, missing config file, etc.

Constant: ERR
	Business logic error.
	
	System is still in working state, but normal logic of request hadnler is broken. Reaction for
	this situation is defined by upper level code.

Constant: WARNING
	Default level.
	
	User input is wrong.

Constant: NOTICE
	Notable event that have not error semanitcs.

	For example, user has registered.

Constant: INFO
	User-defined event. It is not error.
=cut
use constant {
	EMERG   => 'EMERG',    # 0
	ALERT   => 'ALERT',    # 1
	CRIT    => 'CRIT',     # 2
	ERR     => 'ERR',      # 3
	WARNING => 'WARNING',  # 4
	NOTICE  => 'NOTICE',   # 5
	INFO    => 'INFO',     # 6
};

=begin nd
Variable: our @EXPORT
	By default is exported only basic <warn ( )> function.
	
Variable: our @EXPORT_OK
	Exported by order <all_right ( )> and <has_error ( )>.
=cut
our @EXPORT = qw/ &warn /;
our @EXPORT_OK = qw/ &all_right &has_error /;

=begin nd
Variable: my @Level
	Logging levels in order of decreasing fatality (strong errors first).

Variable: my %Level
	Maps LogLevel to the index number.
=cut
my @Level = (
	EMERG,
	ALERT,
	CRIT,
	ERR,
	WARNING,
	NOTICE,
	INFO,
);
my (%Level_ix, $i, $level);
$Level_ix{$level} = $i while ($i, $level) = each @Level;

=begin nd
Variable: my @Stack
	Stack of error Codes.
=cut
my @Stack;

=begin nd
Function: all_right ( )
	Is exist an error?
	
Returns:
	1 - if no errors
	0 - an error has occured
=cut
sub all_right { not @Stack }

=begin nd
Function: bind ($node)
	Bind all errors to specified $node.

	Errors are presented as a hashref where keys are error codes and values are 1.
	
	Server loop uses this function to put in error codes to the output flow.

	> Crop::Error::bind $server->O->{ERROR};

Params:
	$node - where to put in the errors; not a reference, but direct place

Returns:
	Nothing, but result go to the $node.
=cut
sub bind($) { $_[0]->{$_} = 1 for @Stack }

=begin nd
Method: erase ( )
	Erase all the errors.
	
	<all_right ( )> function will now return true.
=cut
sub erase { @Stack = () }

=begin nd
Function: _parse ($msg)
	Parse error message.
	
	Result consists 3 parts: log Level, short code, instant message.

	'logLevel' directive in  main config file determines either print a message to the log file.

Parameters:
	$msg - source text

Returns:
	An array of:
	
	$log_level - print to log file?
	$code      - error code
	$text      - human readabe text
=cut
sub _parse {
	my $msg = shift;

	my ($code, $log_level, $text) = $msg =~ /
		^\s*				# skip spaces at the begining
		(?:
			(?:(\w*)\s*)?		# Code
			(?:\|\s*(\w*)\s*)?	# Log Level
		:)?
		\s*(.*)$			# Text
	/sx;

	$text      ||= 'Undefined error';
	$log_level ||= WARNING;

	my $level = 0;
	my @cur_stack;

	# examine the stack of the current call
	while ( my ($package, $file, $line) = caller $level++) {
		push @cur_stack, " $package:$line ";
	}
	$text .= ' at' . join ' => ', reverse @cur_stack;

	($log_level, $code, $text);
}

=begin nd
Function: warn (@msg_parts)
	Set error.
	
	Remember the error code, print error message to the log file, and return undef.

	@message item format: 'CODE | LEVEL : Message'. Consists:
	
		CODE    -  user defined string will be added to the output
		LEVEL   -  restrictes print to log for slight errors
		Message -  text of an error to print as is

	LEVEL is one of:
	
		- EMERG   - the system is broken absolutely
		- ALERT   - fatal error of the main system
		- CRIT    - critical resource error
		- ERR     - business logic error
		- WARNING - default level; user input is wrong
		- NOTICE  - notable event that have not error semanitcs
		- INFO    - user defined event
	
	Separators only have meaning, not spaces.

	Note <Crop::Debug::debug()> is not related to LEVELs.
	
 	In contrast to standard warn() this <warn (messge) returns undef.
 	
 	In order to redefine standard warn() function you have to 'use Crop::Error'. It is important, since can produce awkward situations.

Parameters:
	@msg_parts - entire message;
		Message consists of 3 components: Error, Level, Text.

Returns:
	undef

Example:
(start code)
# Full example: Error + Level + Text
warn 'NOUSER|ERR: User not defined';

# Error + Text
warn 'SYSTEM:', $!;

# Level + Text
warn '| NOTICE : New user has registered';

# Text only
warn("Letter has received...");
(end)
=cut
sub warn {
	my ($important, $code, $text) = _parse(join ' ', map defined ? $_ : 'undef', @_);

	push @Stack, $code if defined $code;
	
	# print to log
	if ($Level_ix{Crop->C->{logLevel}} >= $Level_ix{$important}) {
		my $log_message;
		$log_message .= "<$code> " if $code;
		$log_message .= "$text"    if $text;
		$log_message .= "\n";

		my $script = $0 =~ /public_html(\S+)/ ? $1 : '';
		print STDERR localstamp . " $script (pid=$$): $log_message";
		flush STDERR;
	}

	undef;
}

1;
