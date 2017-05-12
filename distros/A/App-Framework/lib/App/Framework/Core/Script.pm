package App::Framework::Core::Script ;

=head1 NAME

App::Framework::Core::Script - App::Framework command line script personality

=head1 SYNOPSIS

  # Script is loaded by default as if the script contained:
  use App::Framework ':Script' ;


=head1 DESCRIPTION

This personality implements a standard command line script.

B<DOCUMENTATION TO BE COMPLETED>

Derived object from App::Framework::Core. Should only be called via App::Framework import.

Adds command line script specific additions to base properties. Adds the following
additional options:

	'v|"verbose"'		Make script output more verbose
	'dryrun|"norun"'	Do not execute anything that would alter the file system, just show the commands that would have executed
	
Defines the exit() method which just calls standard exit.

Defines a usage_fn which gets called by App::Framework::Core->uage(). This function calls pod2usage to display help, man page
etc. 

=cut

use strict ;
use Carp ;

our $VERSION = "1.003" ;


#============================================================================================
# USES
#============================================================================================
use App::Framework::Core ;

use File::Temp ();
use Pod::Usage ;


 
#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Core) ; 

#============================================================================================
# GLOBALS
#============================================================================================

our $class_debug = 0 ;

# Set of script-related default options
my @SCRIPT_OPTIONS = (
	['v|"verbose"',		'Verbose output',	'Make script output more verbose', ],
	['dryrun|"norun"',	'Dry run', 			'Do not execute anything that would alter the file system, just show the commands that would have executed'],
) ;


#============================================================================================

=head2 FIELDS

None

=over 4

=cut



#============================================================================================

=back

=head2 CONSTRUCTOR METHODS

=over 4

=cut

#============================================================================================


=item B<new([%args])>

Create a new App::Framework::Script.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;
print "App::Framework::Core::Script->new() class=$class\n" if $class_debug;
	
	# Create object
	my $this = $class->SUPER::new(
		%args, 
	) ;
	$this->set(
		'usage_fn' 	=> sub { $this->script_usage(@_); }, 
	) ;

	## Set options
	$this->feature('Options')->append_options(\@SCRIPT_OPTIONS) ;

print "App::Framework::Core::Script->new() - END\n" if $class_debug;
	
	return($this) ;
}



#============================================================================================

=back

=head2 CLASS METHODS

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<allowed_class_instance()>

Class instance object is not allowed
 
=cut

sub allowed_class_instance
{
	return 0 ;
}

#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================



#----------------------------------------------------------------------------

=item B<exit()>

Exit the application.
 
=cut


sub exit
{
	my $this = shift ;
	my ($exit_code) = @_ ;

$this->_dbg_prt(["EXIT: $exit_code\n"]) ;

	my $exit_type = $this->exit_type() ;
	if (lc($exit_type) eq 'die')
	{
		die '' ;
	}
	else
	{
		exit $exit_code ;
	}

}

#----------------------------------------------------------------------------

=item B<catch_error($error)>

Function that gets called on errors. $error is as defined in L<App::Framework::Base::Object::ErrorHandle>

=cut

sub catch_error
{
	my $this = shift ;
	my ($error) = @_ ;

$this->_dbg_prt(["catch_error()\n"]) ;

	$this->SUPER::catch_error($error) ;

#TODO: This is just the App::Framework::Base::Object::ErrorHandle default_error_handler() code - could just use that (return handled=0)
	my $handled = 0 ;

	# If it's an error, stop
	if ($this->is_error($error))
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		die "Error: $msg\n" ;
		$handled = 1 ;
	}
	if ($this->is_warning($error))
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		warn "Warning: $msg\n" ;
		$handled = 1 ;
	}
	if ($this->is_note($error))
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		print "Note: $msg\n" ;
		$handled = 1 ;
	}

	return $handled ;
}


# ============================================================================================
# NEW METHODS
# ============================================================================================

# TODO: Move to Pod feature

#----------------------------------------------------------------------------

=item B<script_usage($level)>

Show usage.

$level is a string containg the level of usage to display

	'opt' is equivalent to pod2usage(2)

	'help' is equivalent to pod2usage(1)

	'man' is equivalent to pod2usage(-verbose => 2)

=cut

sub script_usage
{
	my $this = shift ;
	my ($app, $level) = @_ ;

	$level ||= "" ;

#$this->debug(1);
$this->_dbg_prt(["Start of script_usage($level)\n"]) ;
	
	# TODO: Work out a better way to convert pod without the use of external file!
	
	# get temp file
	my $fh = new File::Temp();
	my $fname = $fh->filename;
	
	# write pod
	my $developer = $level eq 'man-dev' ? 1 : 0 ;
	print $fh $this->pod($developer) ;
	close $fh ;

	# pod2usage 
	my ($exitval, $verbose) = (0, 0) ;
	($exitval, $verbose) = (2, 0) if ($level eq 'opt') ;
	($exitval, $verbose) = (1, 0) if ($level eq 'help') ;
	($exitval, $verbose) = (0, 2) if ($level =~ /^man/) ;

#print "level=$level, exit=$exitval, verbose=$verbose\n";

	# make file readable by all - in case we're running as root
	chmod 0644, $fname ;

#	system("perldoc",  $fname) ;
	pod2usage(
		-verbose	=> $verbose,
#		-exitval	=> $exitval,
		-exitval	=> 'noexit',
		-input		=> $fname,
		-noperldoc =>1,
		
		-title => $this->name(),
		-section => 1,
	) ;

$this->_dbg_prt(["End of script_usage()\n"]) ;
	
	# remove temp file
	unlink $fname ;

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


