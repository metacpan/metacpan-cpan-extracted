package ObjTest ;

use strict ;
use Carp ;

our $VERSION = "1.000" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Base::Object ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Base::Object) ; 

#============================================================================================
# GLOBALS
#============================================================================================
my %FIELDS = (
	'array'		=> [],	
	'hash'		=> {},	
	'notdef'	=> undef,
	'string'	=> 'test string',
) ;

#-----------------------------------------------------------------------------
sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	return($this) ;
}

#-----------------------------------------------------------------------------
sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

#	# Add extra fields
#	$class->add_fields(\%FIELDS, \%args) ;
#
#	# init class
#	$class->SUPER::init_class(%args) ;

	if (! keys %args)
	{
		%args = () ;
	}
	
	# Add extra fields
	foreach (keys %FIELDS)
	{
		$args{'fields'}{$_} = $FIELDS{$_} ;
	}
	$class->SUPER::init_class(%args) ;

	# Create a class instance object - allows these methods to be called via class
	$class->class_instance(%args) ;


}

1;

__END__


