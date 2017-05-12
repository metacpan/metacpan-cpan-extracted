package App::Framework::Feature::Pod ;

=head1 NAME

App::Framework::Feature::Pod - Application documentation

=head1 SYNOPSIS

  # Data feature is loaded by default as if the script contained:
  use App::Framework '+Pod' ;


=head1 DESCRIPTION

Used by the application framework to create pod-based man pages and help.

=cut

use strict ;
use Carp ;

our $VERSION = "1.002" ;


#============================================================================================
# USES
#============================================================================================
use Pod::Usage ;

use App::Framework::Feature ;
use App::Framework::Base ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Feature) ; 

#============================================================================================
# GLOBALS
#============================================================================================

my $POD_HEAD =	"=head" ;
my $POD_OVER =	"=over" ;


my %FIELDS = (
) ;


=head2 ADDITIONAL COMMAND LINE OPTIONS

This feature adds the following additional command line options to any application:

=over 4

=item B<-help> - show help

Displays brief help message then exits

=item B<-man> - show full man pages

Displays the application's full man pages then exits

=item B<-man-dev> - show full developer man pages

Displays the application's full developer man pages then exits. Developer man pages contain extra
information and is intended for the application developer (rather than the end user).

=item B<-pod> - show man pages as pod [I<developer use>]

Outputs the full pod text.

=back

=cut


my @OPTIONS = (
	['h|"help"',		'Print help', 		'Show brief help message then exit'],
	['man',				'Full documentation', 'Show full man page then exit' ],
	['man-dev',			'Full developer\'s documentation', 'Show full man page for the application developer then exit' ],
	['dev:pod',			'Output full pod', 	'Show full man page as pod then exit' ],
) ;


#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================


=item B< new([%args]) >

Create a new Pod.

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

Initialises the Pod object class variables.

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
$this->_dbg_prt(["pod options=",\%opts]) ;
	if ($opts{'man'} || $opts{'help'})
	{
$this->_dbg_prt(["pod man page=$opts{'man'} \n"]) ;
		my $type = $opts{'man'} ? 'man' : 'help' ;
		$app->usage($type) ;
		$app->exit(0) ;
	}
	if ($opts{'man-dev'})
	{
		$app->usage('man-dev') ;
		$app->exit(0) ;
	}
	if ($opts{'pod'})
	{
		print $this->pod() ;
		$app->exit(0) ;
	}
	
}


#----------------------------------------------------------------------------

=item B<pod([$developer])>

Return full pod of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $pod = 
		$this->pod_head($developer) .
		$this->pod_args($developer) .
		$this->pod_options($developer) .
		$this->pod_description($developer) .
		"\n=cut\n" ;
	return $pod ;
}	
	
#----------------------------------------------------------------------------

=item B< Pod([%args]) >

Alias to L</pod>

=cut

*Pod = \&pod ;

#----------------------------------------------------------------------------

=item B<pod_head([$developer])>

Return pod heading of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_head
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $name = $this->app->name() ;
	my $summary = $this->app->summary() ;
	my $synopsis = $this->get_synopsis() ;
	my $version = $this->app->version() ;

	my $pod =<<"POD_HEAD" ;

${POD_HEAD}1 NAME

$name (v$version) - $summary

${POD_HEAD}1 SYNOPSIS

$synopsis

Options:

POD_HEAD

	# Cycle through
	my $names_aref = $this->app->feature('Options')->option_names() ;
	foreach my $option_name (@$names_aref)
	{
		my $option_entry_href = $this->app->feature('Options')->option_entry($option_name) ;
		my $default = "" ;
		if ($option_entry_href->{'default'})
		{
			$default = "[Default: $option_entry_href->{'default'}]" ;
		}

		my $multi = "" ;
		if ($option_entry_href->{dest_type})
		{
			$multi = "(option may be specified multiple times)" ;
		}
				
		if ($developer)
		{
			$pod .= sprintf "       -%-20s $option_entry_href->{summary}\t$default\n", $option_entry_href->{'spec'} ;
		}
		else
		{
			# show option if it's not a devevloper option
			$pod .= sprintf "       -%-20s $option_entry_href->{summary}\t$default\t$multi\n", $option_entry_href->{'pod_spec'} 
				unless $option_entry_href->{'developer'} ;
		}
	}
	
	unless (@$names_aref)
	{
		$pod .= "       NONE\n" ;
	}

	return $pod ;
}

#----------------------------------------------------------------------------

=item B<pod_options([$developer])>

Return pod of options of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_options
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $pod ="\n${POD_HEAD}1 OPTIONS\n\n" ;

	if ($developer)
	{
		$pod .= "Get options from application object as:\n   my \%opts = \$app->options();\n\n" ;
	}

	$pod .= "${POD_OVER} 8\n\n" ;


	# Cycle through
	my $names_aref = $this->app->feature('Options')->option_names() ;
	foreach my $option_name (@$names_aref)
	{
		my $option_entry_href = $this->app->feature('Options')->option_entry($option_name) ;
$this->_dbg_prt(["entry for $option_name=",$option_entry_href]) ;
		my $default = "" ;
		if ($option_entry_href->{'default'})
		{
			$default = "[Default: $option_entry_href->{'default'}]" ;
		}

		my $show = 1 ;
		$show = 0  if ($option_entry_href->{'developer'} && !$developer) ;
		if ($show)
		{
			if ($developer)
			{
				$pod .= "=item -$option_entry_href->{spec} $default # Access as \$opts{$option_entry_href->{field}} \n" ;
			}
			else
			{
				$pod .= "=item B<-$option_entry_href->{pod_spec}> $default\n" ;
			}
			$pod .= "\n$option_entry_href->{description}\n" ;
			
			if ($option_entry_href->{dest_type})
			{
				$pod .= "This option may be specified multiple times.\n" ;
				
				if ($developer)
				{
					my $dtype = "" ;
					if ($option_entry_href->{dest_type} eq '@')
					{
						$dtype = 'ARRAY' ;
					}
					elsif ($option_entry_href->{dest_type} eq '%')
					{
						$dtype = 'HASH' ;
					}
					$pod .= "(The option values will be available internally via the $dtype ref \$opts{$option_entry_href->{field}})\n" ;
				}			
			}
			$pod .= "\n" ;
		}
	}

	unless (@$names_aref)
	{
		$pod .= "       NONE\n" ;
	}

	$pod .= "\n=back\n\n" ;

	return $pod ;
}

#----------------------------------------------------------------------------

=item B<pod_args([$developer])>

Return pod of args of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_args
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $pod ="\n${POD_HEAD}1 ARGS\n\n" ;

	if ($developer)
	{
		$pod .= "Get args from application object as:\n   my \@args = \$app->args();\n# or\n   my \%args = \$app->feature('Args')->arghash();\n\n" ;
	}

	$pod .= "${POD_OVER} 8\n\n" ;

	# Cycle through
	my $names_aref = $this->app->feature('Args')->arg_names() ;
	foreach my $arg_name (@$names_aref)
	{
		my $arg_entry_href = $this->app->feature('Args')->arg_entry($arg_name) ;

		my $default = "" ;
		if ($arg_entry_href->{'default'})
		{
			$default = "[Default: $arg_entry_href->{'default'}]" ;
		}

		my $show = 1 ;
		if ($show)
		{
			if ($developer)
			{
				$pod .= "=item * $arg_entry_href->{spec} $default # Access as \$args{$arg_entry_href->{name}} \n" ;
			}
			else
			{
				$pod .= "=item B<* $arg_entry_href->{pod_spec}> $default\n" ;
			}
			$pod .= "\n$arg_entry_href->{description}\n" ;
			
			if ($arg_entry_href->{dest_type})
			{
				$pod .= "This arg may be specified multiple times.\n" ;
			}
			$pod .= "\n" ;
		}
	}

	unless (@$names_aref)
	{
		$pod .= "       NONE\n" ;
	}

	$pod .= "\n=back\n\n" ;

	return $pod ;
}

#----------------------------------------------------------------------------

=item B<pod_description([$developer])>

Return pod of description of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_description
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $description = $this->app->description() ;

	my $pod =<<"POD_DESC" ;

${POD_HEAD}1 DESCRIPTION

$description
  
POD_DESC
	
	return $pod ;
}


#----------------------------------------------------------------------------

=item B<get_synopsis()>

Check to ensure synopsis is set. If not, set based on application name and any Args
settings

=cut

sub get_synopsis 
{
	my $this = shift ;

	my $synopsis = $this->app->synopsis() ;
	if (!$synopsis)
	{
		my %opts = $this->app->options() ;
		
		# start with basics
		my $app = $this->app->name() ;
		$synopsis = "$app [options] " ;
		
		## Get args
		my $names_aref = $this->app->feature('Args')->arg_names() ;
		foreach my $arg_name (@$names_aref)
		{
			my $arg_entry_href = $this->app->feature('Args')->arg_entry($arg_name) ;

			my $type = "" ;
			if ($arg_entry_href->{'type'} eq 'f')
			{
				$type = "file" ;
			}
			if ($arg_entry_href->{'type'} eq 'd')
			{
				$type = "directory" ;
			}

			if ($type)
			{
				my $direction = "input " ;
				if ($arg_entry_href->{'direction'} eq 'o')
				{
					$direction = "output " ;
				}
				$type = " ($direction $type)" ;
			}

			my $suffix = "" ;				
			if ($arg_entry_href->{'dest_type'})
			{
				$suffix = "(s)" ;
			}
	
			if ($arg_entry_href->{'optional'})
			{
				$synopsis .= 'I<[' ;
			}
			else
			{
				$synopsis .= 'B<' ;
			}
			
			$synopsis .= "{$arg_name$type$suffix}" ;
			$synopsis .= ']' if $arg_entry_href->{'optional'} ;
			$synopsis .= '> ' ;
		}
		
		# set our best guess
		$this->app->synopsis($synopsis) ;
	}	

	return $synopsis ;
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


