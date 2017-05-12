package App::Framework::Feature::Run ;

=head1 NAME

App::Framework::Feature::Run - Execute external commands

=head1 SYNOPSIS

  use App::Framework '+Run' ;

  $app->run("perl t/test/runtest.pl"); 
  $app->run('cmd' => "perl t/test/runtest.pl"); 
  $app->run('cmd' => "perl t/test/runtest.pl", 'progress' => \&progress);
  
  my $results_aref = $app->run('cmd' => "perl t/test/runtest.pl");
  
  my $run = $app->run() ;
  $run->run("perl t/test/runtest.pl");
  $run->run('cmd' => "perl t/test/runtest.pl", 'timeout' => $sleep);


=head1 DESCRIPTION

Provides for external command running from within an application.

An external conmmand may be run using this feature, and the output from the command may be returned for additional processing. The feature
also provides timed execution (aborting after a certain time), exit code status, and callbacks that can be defined to be called during execution
and/or after program completion.

=head2 Arguments

The access method for this feature (called as B<$app-E<gt>run()>) allows the complete run settings to be specified as a HASH. The call sets 
the object L</FIELDS> from the values in this HASH, for example:

  $app->run(
    'cmd'   => "perl t/test/runtest.pl", 
    'progress' => \&progress,
  ) ;

which specifies the command to run along with the L</progress> field (a callback).

A simpler alternative is allowed:

  $app->run("perl t/test/runtest.pl", "some args") ;

or:

  $app->run("perl t/test/runtest.pl some args") ;

The command arguments can be specified either as part of the L</cmd> field definition, or separately in the L</args> field. One benefit of using
the L</args> field is that the command need only be specified once - subsequent calls will use the same setting, for example:

  $app->run('cmd' => "perl t/test/runtest.pl"); 
  $app->run('progress' => \&progress);
  $app->run('progress' => \&progress);

=head2 Return code

When the external command completes, it's return code can be accessed by reading the L</status> field:

  $app->run()->status ;
  
This value is set in the feature object to the result of the last run (i.e. you must save status values between runs if you want to
keep track of the values).

The status value is entirely defined by the external command and the operating system.

Also, if you want your script to automatically abort on error (rather than write your own program error handler) then you can set the 
B<on_error> field to 'fatal'.

=head2 Required Programs Check

It's a good idea to start your script with a check for all the external programs you're about to use. You can do this by specifying them
in a HASH ref using the L</required> method. This does the checking for you, returning the path of all the executables. You can also
tell the object to abort the script if some programs are not found, for example:

  $app->run->set(
      'on_error'   => 'fatal',
      'required'   => {
          'lsvob'      => 1,
          'ffmpeg'     => 1,
          'transcode'  => 1,
          'vlc'        => 1,	
      },
  ) ;

NOTE: The values you specify along with the program names are not important when you set the required list - these values get updated
with the actual executable path.

=head2 Command output

All output (both STDOUT and STDERR) is captured from the external command and can be accessed by reading the L</results> field. This returns
an ARRAY reference, where the ARRAY contains the lines of text output (one array entry per line).

NOTE: the lines have the original trailing newline B<removed>.

  my $results_aref = $app->run()->results ;
  foreach my $line (@$results_aref)
  {
      print "$line\n";
  }

=head2 Timeout

If you specify a L</timeout> then the command is executed as normal but will be aborted if it runs for longer than the specified time.

This can be useful, for example, for running commands that don't normally terminate (or run on much longer than is necessary). 
 

=head2 Callbacks

There are 2 optional callback routines that may be specified:

=over 4 

=item B<progress> 

This subroutine is called for every line of output from the external command. This can be used in an application for monitoring 
progress, checking for errors etc.

=item B<check_results> 

This subroutine is called at the end of external command completion. It allows the application to process the results to determine whether
the command passed or failed some additional criteria. The L</status> field is then set to the results of this subroutine.

=back


=head2 Examples

Run a command:

    $app->run(
        'cmd'         => "perl t/test/runtest.pl", 
    ) ;

Run a command and get a callback for each line of output:
    
    $app->run(
        'cmd'         => "perl t/test/runtest.pl", 
        'progress'    => \&progress,
    ) ;

Ping a machine for 10 seconds and use a callback routine to check the replies:

    my $run_for = 10 ;
    my $host = '192.168.0.1' ;
    my $run = $app->run() ;
    $run->run_cmd("ping", 
        'progress' => \&progress,
        'args'     => "$host",
        'timeout'  => $run_for,
    ) ;

Note the above example uses the B<run> feature object to access it's methods directly.

=cut

use strict ;
use Carp ;

use File::Which ;

our $VERSION = "1.008" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Feature ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Feature) ; 

#============================================================================================
# GLOBALS
#============================================================================================

our $ON_ERROR_DEFAULT = 'fatal' ;

=head2 Fields

=over 4

=item B<cmd> - command string (program name)

The program to run

=item B<args> - any optional program arguments

String containing program arguments (may be specified as part of the 'cmd' string instead)

=item B<timeout> - optional timeout time in secs.

When specified causes the program to be run as a forked child 

=item B<nice> - optional nice level

On operating systems that allow this, runs the external command at the specified "nice" level

=item B<on_error> - what to do when a program fails

When this field is set to something other than 'status' it causes an error to be thrown. The default 'status' 
just returns with the error information stored in the object fields (i.e. 'status', 'results' etc). This field may be set to:

=over 4

=item I<status> - error information returned in fields

=item I<warning> - throw a warning with the message string indicating the error 

=item I<fatal> - [default] throw a fatal error (and abort the script) with the message string indicating the error 

=back

=item B<required> - required programs check

This is a HASH ref where the keys are the names of the required programs. When reading the field, the values 
are set to the path for that program. Where a program is not found then it's path is set to undef.

See L</required> method.


=item B<check_results> - optional results check subroutine

results check subroutine which should be of the form:

    check_results($results_aref)

Where:

=over 4

=item I<$results_aref> = ARRAY ref to all lines of text

=back

Subroutine should return 0 = results ok; non-zero for program failed.

=item B<progress> - optional progress subroutine

progress subroutine which should be in the form:

    progress($line, $linenum, $state_href)
					   
Where:

=over 4

=item I<$line> = line of text

=item I<$linenum> = line number (starting at 1)

=item I<$state_href> = An empty HASH ref (allows progress routine to store variables between calls)
					     
=back		
			     
=item B<status> - Program exit status

Reads as the program exit status

=item B<results> - Program results

ARRAY ref of program output text lines

=item B<norun> - Flag used for debug

Evaluates all parameters and prints out the command that would have been executed

=back

=cut


my %FIELDS = (
	# Object Data
	'cmd'		=> undef,
	'args'		=> undef,
	'timeout'	=> undef,
	'nice'		=> undef,
	'dryrun'	=> 0,
	
	'on_error'	=> $ON_ERROR_DEFAULT,
	'error_str'	=> "",
	'required'	=> {},
	
	'check_results'	=> undef,
	'progress'		=> undef,
	
	'status'	=> 0,
	'results'	=> [],
	
	# Options/flags
	'norun'		=> 0,
	
	'log'		=> {
		'all'		=> 0,
		'cmd'		=> 0,
		'results'	=> 0,
		'status'	=> 0,
	},
	
	## Private
	'_logobj'	=> undef,
) ;

#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================

=item B<new([%args])>

Create a new Run.

The %args are specified as they would be in the B<set> method (see L</Fields>).

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	
	return($this) ;
}


#============================================================================================

=back

=head2 CLASS METHODS

=over 4

=cut

#============================================================================================


#-----------------------------------------------------------------------------

=item B<init_class([%args])>

Initialises the Run object class variables.

=cut

sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

	# Add extra fields
	$class->add_fields(\%FIELDS, \%args) ;

	# init class
	$class->SUPER::init_class(%args) ;

}

#============================================================================================

=back

=head2 OBJECT DATA METHODS

=over 4

=cut

#============================================================================================

#-----------------------------------------------------------------------------

=item B<required([$required_href])>

Get/set the required programs list. If specified, B<$required_href> is a HASH ref where the 
keys are the names of the required programs (the values are unimportant).

This method returns the B<$required_href> HASH ref having set the values associated with the
program name keys to the path for that program. Where a program is not found then
it's path is set to undef.

Also, if the L</on_error> field is set to 'warning' or 'fatal' then this method throws a warning
or fatal error if one or more required programs are not found. Sets the message string to indicate 
which programs were not found. 

=cut

sub required
{
	my $this = shift ;
	my ($new_required_href) = @_ ;
	
##	my $required_href = $this->SUPER::required($new_required_href) ;
	my $required_href = $this->field_access('required', $new_required_href) ;
	if ($new_required_href)
	{
		## Test for available executables
		foreach my $exe (keys %$new_required_href)
		{
			$required_href->{$exe} = which($exe) ;
		}
		
		## check for errors
		my $throw = $this->_throw_on_error($this->on_error) ;
		if ($throw)
		{
			my $error = "" ;
			foreach my $exe (keys %$new_required_href)
			{
				if (!$required_href->{$exe})
				{
					$error .= "  $exe\n" ;
				}
			}
			
			if ($error)
			{
				$this->$throw("The following programs are required but not available:\n$error\n") ;
			}
		}
	}
	
	return $required_href ;
}


#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================

#--------------------------------------------------------------------------------------------

=item B<run( [args] )>

Execute a command if B<args> are specified. Whether B<args> are specified or not, always returns the run object. 

This method has reasonably flexible arguments which can be one of:

=item (%args)

The args HASH contains the information needed to set the L</FIELDS> and then run teh command for example:

  ('cmd' => 'ping', 'args' => $host) 

=item ($cmd)

You can specify just the command string. This will be treated as if you had called the function with:

  ('cmd' => $cmd) 

=item ($cmd, $args)

You can specify the command string and the arguments string. This will be treated as if you had called the function with:

  ('cmd' => $cmd, 'args' => $args) 

NOTE: Need to get B<run> object from application to access this method. This can be done as one of:

  $app->run()->run(.....);
  
  or
  
  my $run = $app->run() ;
  $run->run(....) ;

=cut

sub run
{
	my $this = shift ;
	my (@args) = @_ ;

	# See if this is a class call
	$this = $this->check_instance() ;

$this->_dbg_prt(["run() this=", $this], 2) ;
$this->_dbg_prt(["run() args=", \@args]) ;

	my %args ;
	if (@args == 1)
	{
		$args{'cmd'} = $args[0] ;
	}
	elsif (@args == 2)
	{
		if ($args[0] ne 'cmd')
		{
			# not 'cmd' => '....' so treat as ($cmd, $args)
			$args{'cmd'} = $args[0] ;
			$args{'args'} = $args[1] ;
		}
		else
		{
			%args = (@args) ;
		}
	}
	else
	{
		%args = (@args) ;
	}
	
	## return immediately if no args
	return $this unless %args ;

	## If associated with an app, then see if Logging is enabled
	my $app = $this->app ;
	if ($app)
	{
		my $logging = $app->feature_installed('Logging') ;
		$this->_logobj($logging) ;
	}

	## create local copy of variables
	my %local = $this->vars() ;
	
	# Set any specified args
	foreach my $key (keys %local)
	{
		$local{$key} = $args{$key} if exists($args{$key}) ;
	}
	
	## set any 'special' vars
	my %set ;
	foreach my $key (qw/debug/)
	{
		$set{$key} = $args{$key} if exists($args{$key}) ;
	}
	$this->set(%set) if keys %set ;
	

	# Get command
#	my $cmd = $this->cmd() ;
	my $cmd = $local{'cmd'} ;
	$this->throw_fatal("command not specified") unless $cmd ;
	
	# Add niceness
#	my $nice = $this->nice() ;
	my $nice = $local{'nice'} ;
	if (defined($nice))
	{
		$cmd = "nice -n $nice $cmd" ;
	}
	
	
	# clear vars
	$this->set(
		'status'	=> 0,
		'results'	=> [],
		'error_str'	=> "",
	) ;
	

	# Check arguments
	my $args = $this->_check_args($local{'args'}) ;

	# Run command and save results
	my @results ;
	my $rc ;

	## Logging
	my $logopts_href = $this->log ;
	my $logging = $this->_logobj ;		

	$logging->logging("RUN: $cmd $args\n") if $logging && ($logopts_href->{all} || $logopts_href->{cmd}) ;


#	my $timeout = $this->timeout() ;
	my $timeout = $local{'timeout'} ;
	if ($local{'dryrun'})
	{
		## Print
		my $timeout_str = $timeout ? "[timeout after $timeout secs]" : "" ;
		print "RUN: $cmd $args $timeout_str\n" ;
	}
	else
	{
		## Run
		
		if (defined($timeout))
		{
			# Run command with timeout
			($rc, @results) = $this->_run_timeout($cmd, $args, $timeout, $local{'progress'}, $local{'check_results'}) ;		
		}
		else
		{
			# run command
			($rc, @results) = $this->_run_cmd($cmd, $args, $local{'progress'}, $local{'check_results'}) ;		
		}
	}

	# Update vars
	$this->status($rc) ;
	chomp foreach (@results) ;
	$this->results(\@results) ;

	$logging->logging(\@results) if $logging && ($logopts_href->{all} || $logopts_href->{results}) ;
	$logging->logging("Status: $rc\n") if $logging && ($logopts_href->{all} || $logopts_href->{status}) ;
	
	## Handle non-zero exit status
	my $throw = $this->_throw_on_error($local{'on_error'}) ;
	if ($throw && $rc)
	{
		my $results = join("\n", @results) ;
		my $error_str = $local{'error_str'} ;
		$this->$throw("Command \"$cmd $args\" exited with non-zero error status $rc : \"$error_str\"\n$results\n") ;
	}
	
	return($this) ;
}

#----------------------------------------------------------------------------

=item B< Run([%args]) >

Alias to L</run>

=cut

*Run = \&run ;

##--------------------------------------------------------------------------------------------
#
#=item B<print_run([args])>
#
#DEBUG: Display the full command line as if it was going to be run
#
#NOTE: Need to get B<run> object from application to access this method. 
#
#=cut
#
#sub print_run
#{
#	my $this = shift ;
#	my (@args) = @_ ;
#
#	# See if this is a class call
#	$this = $this->check_instance() ;
#
#	my %args ;
#	if (@args == 1)
#	{
#		$args{'cmd'} = $args[0] ;
#	}
#	elsif (@args == 2)
#	{
#		if ($args[0] ne 'cmd')
#		{
#			# not 'cmd' => '....' so treat as ($cmd, $args)
#			$args{'cmd'} = $args[0] ;
#			$args{'args'} = $args[1] ;
#		}
#		else
#		{
#			%args = (@args) ;
#		}
#	}
#	else
#	{
#		%args = (@args) ;
#	}
#	
#	# Set any specified args
#	$this->set(%args) if %args ;
#
#	# Get command
#	my $cmd = $this->cmd() ;
#	$this->throw_fatal("command not specified") unless $cmd ;
#	
#	# Check arguments
#	my $args = $this->_check_args() ;
#
#	print "$cmd $args\n" ;
#}


# ============================================================================================
# PRIVATE METHODS
# ============================================================================================

#--------------------------------------------------------------------------------------------
#
# Ensure arguments are correct
#
sub _check_args
{
	my $this = shift ;
#	my $args = $this->args() || "" ;
	my ($args) = @_ ;
	
	# If there is no redirection, just add redirect 2>1
	if (!$args || ($args !~ /\>/) )
	{
		$args .= " 2>&1" ;
	}
	
	return $args ;
}


#----------------------------------------------------------------------
# Run command with no timeout
#
sub _run_cmd
{
	my $this = shift ;
	my ($cmd, $args, $progress, $check_results) = @_ ;

$this->_dbg_prt(["_run_cmd($cmd) args=$args\n"]) ;
	
	my @results ;
#	@results = `$cmd $args` unless $this->option('norun') ;
	@results = `$cmd $args` ;
	my $rc = $? ;

	foreach (@results)
	{
		chomp $_ ;
	}

	# if it's defined, call the progress checker for each line
#	my $progress = $this->progress() ;
	if (defined($progress))
	{
		my $linenum = 0 ;
		my $state_href = {} ;
		foreach (@results)
		{
			&$progress($_, ++$linenum, $state_href) ;
		}
	}

	
	# if it's defined, call the results checker for each line
	$rc ||= $this->_check_results(\@results, $check_results) ;

	return ($rc, @results) ;
}

#----------------------------------------------------------------------
#Execute a command in the background, gather output, return status.
#If timeout is specified (in seconds), process is killed after the timeout period.
#
sub _run_timeout
{
	my $this = shift ;
	my ($cmd, $args, $timeout, $progress, $check_results) = @_ ;

$this->_dbg_prt(["_run_timeout($cmd) timeout=$timeout args=$args\n"]) ;

	## Timesout must be set
	$timeout ||= 60 ;

	# Run command and save results
	my @results ;

	# Run command but time it and kill it when timed out
	local $SIG{ALRM} = sub { 
		# normal execution
		die "timeout\n" ;
	};

	# if it's defined, call the progress checker for each line
#	my $progress = $this->progress() ;
	my $state_href = {} ;
	my $linenum = 0 ;

	# Run inside eval to catch timeout		
	my $pid ;
	my $rc = 0 ;
	my $endtime = (time + $timeout) ;
	eval 
	{
		alarm($timeout);
		$pid = open my $proc, "$cmd $args |" or $this->throw_fatal("Unable to fork $cmd : $!") ;

		while(<$proc>)
		{
			chomp $_ ;
			push @results, $_ ;

			++$linenum ;

			# if it's defined, call the progress checker for each line
			if (defined($progress))
			{
				&$progress($_, $linenum, $state_href) ;
			}

			# if it's defined, check timeout
			if (time > $endtime)
			{
				$endtime=0;
				last ;
			}
		}
		alarm(0) ;
		$rc = $? ;
print "end of program : rc=$rc\n" if $this->debug ;  
	};
	if ($@)
	{
		$rc ||= 1 ;
		if ($@ eq "timeout\n")
		{
print "timed out - stopping command pid=$pid...\n" if $this->debug ;
			# timed out  - stop command
			kill('INT', $pid) ;
		}
		else
		{
print "unexpected end of program : $@\n" if $this->debug ; 			
			# Failed
			alarm(0) ;
			$this->throw_fatal( "Unexpected error while timing out command \"$cmd $args\": $@" ) ;
		}
	}
	alarm(0) ;

print "exit program\n" if $this->debug ; 

	# if it's defined, call the results checker for each line
	$rc ||= $this->_check_results(\@results, $check_results) ;

	return($rc, @results) ;
}

#----------------------------------------------------------------------
# Check the results calling the check_results() hook if defined
#
sub _check_results
{
	my $this = shift ;
	my ($results_aref, $check_results) = @_ ;

	my $rc = 0 ;
	
	# If it's defined, run the check results hook
#	my $check_results = $this->check_results() ;
	if (defined($check_results))
	{
		$rc = &$check_results($results_aref) ;
	}

	return $rc ;
}


#----------------------------------------------------------------------
# If the 'on_error' setting is not 'status' then return the "throw" type
#
sub _throw_on_error
{
	my $this = shift ;
	my ($on_error) = @_ ;
	$on_error ||= $ON_ERROR_DEFAULT ;
	
	my $throw = "";
#	my $on_error = $this->on_error() || $ON_ERROR_DEFAULT ;
	if ($on_error ne 'status')
	{
		$throw = 'throw_fatal' ;
		if ($on_error =~ m/warn/i)
		{
			$throw = 'throw_warning' ;
		}
	}

	return $throw ;
}

# ============================================================================================
# END OF PACKAGE

=back

=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price C<< <sdprice at cpan.org> >>

=head1 BUGS

None that I know of!

=cut

1;

__END__


