package App::Framework::Extension::Daemon ;

=head1 NAME

App::Framework::Daemon - Daemonize an application

=head1 SYNOPSIS

  use App::Framework '::Daemon' ;


=head1 DESCRIPTION

App::Framework personality that provides a daemonized program (using Net::Server::Daemonize)

B<DOCUMENTATION TO BE COMPLETED>

B<BETA CODE ONLY - NOT TO BE USED IN PRODUCTION SCRIPTS>

=cut

use strict ;
use Carp ;

our $VERSION = "1.000" ;


#============================================================================================
# USES
#============================================================================================
use App::Framework::Core ;
use App::Framework::Extension ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA ; 
our $PRIORITY = 100 ;

#============================================================================================
# GLOBALS
#============================================================================================

# Set of script-related default options
my @OPTIONS = (
#	['log|L=s',			'Log file', 		'Specify a log file', ],
#	['v|"verbose"',		'Verbose output',	'Make script output more verbose', ],
#	['debug=s',			'Set debug level', 	'Set the debug level value', ],
#	['h|"help"',		'Print help', 		'Show brief help message then exit'],
#	['man',				'Full documentation', 'Show full man page then exit' ],
#	['dryrun|"norun"',	'Dry run', 			'Do not execute anything that would alter the file system, just show the commands that would have executed'],
) ;

#============================================================================================

=head2 FIELDS

None

=over 4

=cut

my %FIELDS = (
	## Object Data
	'user'		=> 'nobody',
	'group'		=> 'nobody',
	'pid'		=> undef,
) ;

#============================================================================================

=back

=head2 CONSTRUCTOR METHODS

=over 4

=cut

#============================================================================================


=item B<new([%args])>

Create a new App::Framework::Daemon.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	## Need Net::Server::Daemonize
	eval "use Net::Server::Daemonize;" ;
	if (@$)
	{
		croak "Sorry. You need to have Net::Server::Daemonize installed to be able to use $class" ;
	}

	## create object dynamically
	my $this = App::Framework::Core->inherit($class, %args) ;

	## Set options
	$this->feature('Options')->append_options(\@OPTIONS) ;
	
	## hi-jack the app function
	$this->extend_fn(
		'app_fn'	=> sub {$this->daemon_run(@_);},
	) ;

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

Initialises the object class variables.

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

=item B<daemon_run()>

Daemonize then run the application's app subroutine inside a loop.
 
=cut


sub daemon_run
{
	my $this = shift ;


my $use_net=0;
if ($use_net)
{	

print "Calling daemonize()...\n" ;
	## Daemonize
	Net::Server::Daemonize::daemonize(
	    $this->user,             # User
	    $this->group,            # Group
	    $this->pid,				 # Path to PID file - optional
	);
print "Calling application run...\n" ;
	
	## call application run
	$this->call_extend_fn('app_fn') ;

}

else
{
  ##my $pid = safe_fork();
print "Calling fork()...\n" ;
  my $pid = fork;
  unless( defined $pid ){
    die "Couldn't fork: [$!]\n";
  }


  ### parent process should do the pid file and exit
  if( $pid ){

print "Killing parent..\n" ;
    $pid && exit(0);


  ### child process will continue on
  }else{

	
print "Calling application run...\n" ;
	
	## call application run
	$this->call_extend_fn('app_fn') ;

  }
}



}



# ============================================================================================
# PRIVATE METHODS
# ============================================================================================




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


