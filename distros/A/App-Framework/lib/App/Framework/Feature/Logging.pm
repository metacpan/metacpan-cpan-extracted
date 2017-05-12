package App::Framework::Feature::Logging ;

=head1 NAME

App::Framework::Feature::Logging - Application logging

=head1 SYNOPSIS

  # Include logging feature by:
  use App::Framework '+Logging' ;


=head1 DESCRIPTION

Logging feature that provides log file handling for applications. 

If the user specified -log command line option and specifies a valid log filename, then this module will
manage any logging() calls, writing the data into the specified log file. 

=cut

use strict ;
use Carp ;

our $VERSION = "1.001" ;


#============================================================================================
# USES
#============================================================================================

use App::Framework::Feature ;
use App::Framework::Base ;

use App::Framework::Base::Object::DumpObj qw/prtstr_data/ ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Feature) ; 

#============================================================================================
# GLOBALS
#============================================================================================

=head2 FIELDS

The following fields should be defined either in the call to 'new()', as part of a 'set()' call, or called by their accessor method
(which is the same name as the field):


=over 4

=item B<logfile> - Name of log file

Created by the object. When the application starts, if the -log option has been specified, then the filename is copied into this
field.

=item B<mode> - Log file create mode

May be 'truncate' or 'append': 'truncate' clears any previous log file contents; 'append' appends the logging to previous
file contents. Default is 'truncate'

=item B<to_stdout> - flag to echo logging

When set, causes all logging to be echoed to STDOUT

=back

=cut


my %FIELDS = (
	'logfile'		=> undef,
	'mode'			=> 'truncate',
	'to_stdout'		=> 0,
	
	## private
	'_started'		=> 0,
) ;


=head2 ADDITIONAL COMMAND LINE OPTIONS

This feature adds the following additional command line options to any application:

=over 4

=item B<-log> - Specify a log file

If a logfile is specified at the command line, then the file is created and all logging messages get written to that file.
Otherwise, log messages are ignored. 

=back

=cut


my @OPTIONS = (
	['log=s',			'Log file', 		'Specify a log file', ],
) ;


#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================


=item B< new([%args]) >

Create a new Logging.

The %args are specified as they would be in the B<set> method (see L</Fields>).

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args,
		'feature_options'		=> \@OPTIONS,
		'registered'			=> [qw/application_entry/],
	) ;

#$this->debug(2);

	
	return($this) ;
}



#============================================================================================

=back

=head2 CLASS METHODS

=over 4

=cut

#============================================================================================


#-----------------------------------------------------------------------------

=item B< init_class([%args]) >

Initialises the Logging object class variables.

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

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<application_entry()>

Called by the application framework at the start of the application.
 
This method checks for the user specifying any of the options described above (see L</ADDITIONAL COMMAND LINE OPTIONS>) and handles
them if so.

=cut


sub application_entry
{
	my $this = shift ;

$this->_dbg_prt(["application_entry()\n"]) ;

	## Handle special options
	my $app = $this->app ;
	my %opts = $app->options() ;

$this->_dbg_prt(["logging options=",\%opts]) ;

	if ($opts{'log'})
	{
		$this->logfile($opts{'log'}) ;
	}
	
}


#----------------------------------------------------------------------------

=item B<logging($arg1, [$arg2, ....])>

Log the argument(s) to the log file iff a log file has been specified.

The list of arguments may be: SCALAR, ARRAY reference, HASH reference, SCALAR reference. SCALAR and SCALAR ref are printed
as-is without any extra newlines. ARRAY ref is printed out one entry per line with a newline added. The HASH ref is printed out
in the format produced by L<App::Framework::Base::Object::DumpObj>.


=cut

sub logging
{
	my $this = shift ;
	my (@args) = @_ ;

	my $tolog = "" ;
	foreach my $arg (@args)
	{
		if (ref($arg) eq 'ARRAY')
		{
			foreach (@$arg)
			{
				$tolog .= "$_\n" ;
			}
		}
		elsif (ref($arg) eq 'HASH')
		{
			$tolog .= prtstr_data($arg) . "\n" ;
		}
		elsif (ref($arg) eq 'SCALAR')
		{
			$tolog .= $$arg ;
		}
		elsif (!ref($arg))
		{
			$tolog .= $arg ;
		}
		else
		{
			$tolog .= prtstr_data($arg) . "\n" ;
		}
	}
		
	## Log
	my $logfile = $this->logfile ;
	if ($logfile)
	{
		## start if we haven't yet
		if (!$this->_started)
		{
			$this->_start_logging() ;
		}

		open my $fh, ">>$logfile" or $this->throw_fatal("Error: unable to append to logfile \"$logfile\" : $!") ;
		print $fh $tolog ;
		close $fh ;
	}

	## Echo
	if ($this->to_stdout)
	{
		print $tolog ;
	}

	return($this) ;
}	
	
#----------------------------------------------------------------------------

=item B<echo_logging($arg1, [$arg2, ....])>

Same as L</logging> but echoes output to STDOUT.

=cut

sub echo_logging
{
	my $this = shift ;
	my (@args) = @_ ;
	
	# Temporarily force echoing to STDOUT on, then do logging
	my $to_stdout = $this->to_stdout ;
	$this->to_stdout(1) ;
	$this->logging(@args) ;
	$this->to_stdout($to_stdout) ;

	return($this) ;
}	
	
#----------------------------------------------------------------------------

=item B< Logging([%args]) >

Alias to L</logging>

=cut

*Logging = \&logging ;



# ============================================================================================
# PRIVATE METHODS
# ============================================================================================

#----------------------------------------------------------------------------
#
#=item B<_start_logging()>
#
#Create/append log file
#
#=cut
#
sub _start_logging
{
	my $this = shift ;

	my $logfile = $this->logfile() ;
	if ($logfile)
	{
		my $mode = ">" ;
		if ($this->mode eq 'append')
		{
			$mode = ">>" ;
		}
		
		open my $fh, "$mode$logfile" or $this->throw_fatal("Unable to write to logfile \"$logfile\" : $!") ;
		close $fh ;
		
		## set flag
		$this->_started(1) ;
	}
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


