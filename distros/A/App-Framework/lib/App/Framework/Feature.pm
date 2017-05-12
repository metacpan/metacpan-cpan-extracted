package App::Framework::Feature ;

=head1 NAME

App::Framework::Feature - Application feature

=head1 SYNOPSIS

Features are accessed via the App::Framework object, for example:

  use App::Framework '+Config' ;

App::Framework::Feature is to be derived from and cannot be accessed directly.


=head1 DESCRIPTION

Provides the base object from which all features must be derived.

B<DOCUMENTATION TO BE COMPLETED>

=cut

use strict ;
use Carp ;

our $VERSION = "1.001" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Base ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Base) ; 

#============================================================================================
# GLOBALS
#============================================================================================

=head2 FIELDS

The following fields should be defined either in the call to 'new()', as part of a 'set()' call, or called by their accessor method
(which is the same name as the field):


=over 4

=item B<app> - Parent application

Set by App::Framework as a reference to the application object. If this is not set, then the feature will skip any application-specific
logic (allowing a feature to be used in the user part of an application as a stand alone object).

=item B<registered> - list of registered application functions

ARRAY ref to list of functions that this feature wants to register in the application. When a registered function is called by the framework,
then the feature's method (of the same name) is also called.

Function name is of the form <name>_entry (called at the start of <name>) or <name>_exit (called at the end of <name>)

=item B<name> - feature name

Set to the feature name (by the App::Framework). This is the name used by the application to access the feature 

=back

=cut

my %FIELDS = (
	'app'				=> undef,
	'registered'		=> [],
	'name'				=> 'feature',
	'feature_args'		=> "",			# Feature-specific arguments string

	'feature_options'	=> [],
);

#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================

=item B< new([%args]) >

Create a new feature.

The %args are specified as they would be in the B<set> method.

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(
		'priority'	=> $App::Framework::Base::PRIORITY_DEFAULT,	# will be overridden by derived object
		%args,
	) ;

	## do application-specific bits
	$this->register_app() ;
	
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

#----------------------------------------------------------------------------

=item B<allowed_class_instance()>

Returns 0 since this class can not have a class instance object
 
=cut

sub allowed_class_instance
{
	return 0 ;
}


#============================================================================================

=back

=head2 OBJECT DATA METHODS

=over 4

=cut

#============================================================================================

##-----------------------------------------------------------------------------
#
#=item B< feature_args([$args]) >
#
#Get/set the feature's arguments. If specified, I<$args> may be either an ARRAY ref (which is saved as-is),
#or a SCALAR. In the case of the SCALAR, it is expected to be a space/comma separated list of argument
#strings which are parsed and converted into an ARRAY ref
#
#=cut
#
#sub feature_args
#{
#	my $this = shift ;
#	my ($arg) = @_ ;
#	
#	if (defined($arg))
#	{
#		if (ref($arg) eq 'ARRAY')
#		{
#			# use as-is			
#		}
#		elsif (!ref($arg))
#		{
#			# convert scalar
#			my @list ;
#			while ($arg =~ m/\s*([^\s,]+)[\s,]*/g)
#			{
#				push @list, $1 ;
#			}
#			
#			$arg = \@list ;	
#		}
#		else
#		{
#			$arg = undef ;
#		}
#	}
#	
#	return $this->SUPER::feature_args($arg) ;
#}


##-----------------------------------------------------------------------------
#
#=item B< feature_args([$args]) >
#
#Get/set the feature's arguments. If specified, I<$args> may be either an ARRAY ref (which is saved as-is),
#or a SCALAR. In the case of the SCALAR, it is expected to be a space/comma separated list of argument
#strings which are parsed and converted into an ARRAY ref
#
#=cut
#
#sub feature_args
#{
#	my $this = shift ;
#	my ($arg) = @_ ;
#
#print "feature_args($arg) [$this]\n" ;
#$this->dump_callstack() ;	
#
#	return $this->SUPER::feature_args($arg) ;
#}

#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================


#-----------------------------------------------------------------------------

=item B< register_app() >

Registers this feature with the parent application framework (if specified)

=cut

sub register_app
{
	my $this = shift ;
	
	my $app = $this->app ;
	if ($app)
	{
		## if we need to, register our methods with the application framework
		my $methods_aref = $this->registered ;
		if (@$methods_aref)
		{
			$app->feature_register($this->name, $this, @$methods_aref) ;
		}
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


