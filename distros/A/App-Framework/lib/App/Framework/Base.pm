package App::Framework::Base ;

=head1 NAME

App::Framework::Base - Application feature

=head1 SYNOPSIS

use App::Framework::Base ;


=head1 DESCRIPTION

Base object for all application objects (core/extensions/features etc)

B<DOCUMENTATION TO BE COMPLETED>

=cut

use strict ;
use Carp ;

our $VERSION = "1.100" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Base::Object::ErrorHandle ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Base::Object::ErrorHandle) ; 

#============================================================================================
# GLOBALS
#============================================================================================

our $PRIORITY_CORE    = 10 ;
our $PRIORITY_SYSTEM  = 100 ;
our $PRIORITY_USER    = 1000 ;
our $PRIORITY_DEFAULT = 32767 ;

our $class_debug = 0 ;

=head2 FIELDS

The following fields should be defined either in the call to 'new()', as part of a 'set()' call, or called by their accessor method
(which is the same name as the field):


=over 4

=item B<requires> - list of required modules

ARRAY ref of a list of module names that are required to be loaded by this object.

=item B<loaded> - list of which modules have been loaded

HASH containing the modules loaded (used as key), with the value set to 1 if the module loaded ok; 0 otherwise

=item B<requires_ok> - all required modules are ok

Flag that is set if all required modules loaded correctly

=back

=cut

my %FIELDS = (
	'priority'		=> $PRIORITY_DEFAULT,
	'requires'		=> [],
	
	'loaded'		=> {},		# list of which modules have been loaded
	'requires_ok'	=> 0,		# all required modules are ok
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

print "App::Framework::Base->new() class=$class\n" if $class_debug ;

	# Create object
	my $this = $class->SUPER::new(%args) ;

	## Check for any required modules
	my $ok = 1 ;
	my %loaded ;
	foreach my $module (@{$this->requires})
	{
		eval "package $class; use $module;" ;
		if ($@)
		{
			$loaded{$module} = 0 ;
			$ok = 0 ;
		}
		else
		{
			$loaded{$module} = 1 ;
		}
	}
	$this->requires_ok($ok) ;
	$this->loaded(\%loaded) ;

	## First check that all required modules loaded correcly
	if (!$this->requires_ok)
	{
		my $loaded_href = $class->loaded ;
		my $failed_modules = join ', ', grep {$loaded_href->{$_}} keys %$loaded_href ;
		$this->throw_fatal("Failed to load: $failed_modules") ;	
	}

print "App::Framework::Base->new() - END\n" if $class_debug ;

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

=item B<expand_keys($hash_ref, $vars_aref)>

Processes all of the HASH values, replacing any variables with their contents. The variable
values are taken from the ARRAY ref I<$vars_aref>, which is an array of hashes. Each hash
containing variable name / variable value pairs.

The HASH values being expanded can be either scalar, or an ARRAY ref. In the case of the ARRAY ref each
ARRAY entry must be a scalar (e.g. an array of file lines).

=cut

sub expand_keys
{
	my $class = shift ;
	my ($hash_ref, $vars_aref, $_state_href, $_to_expand) = @_ ;

print "expand_keys($hash_ref, $vars_aref)\n" if $class_debug;
$class->prt_data("vars=", $vars_aref, "hash=", $hash_ref) if $class_debug ;

	my %to_expand = $_to_expand ? (%$_to_expand) : (%$hash_ref) ;
	if (!$_state_href)
	{
		## Top-level
		my %data_ref ;
		
		# create state HASH
		$_state_href = {} ;
		
		# scan through hash looking for variables
		%to_expand = () ;
		foreach my $key (keys %$hash_ref)
		{
			my @vals ;
			if (ref($hash_ref->{$key}) eq 'ARRAY')
			{
				@vals = @{$hash_ref->{$key}} ;
			}
			elsif (!ref($hash_ref->{$key}))
			{
				push @vals, $hash_ref->{$key} ;
			}
			
			## Set up state - provide a level of indirection so that we can handle the case where multiple keys point to the same data
			my $ref = $hash_ref->{$key} || '' ;
			if ($ref && exists($data_ref{"$ref"}))
			{
print " + already seen data for key=$key\n" if $class_debug>=2;
				# already got created a state for this data, point to it 
				$_state_href->{$key} = $data_ref{"$ref"} ;
			}
			else
			{
print " + new state key=$key\n" if $class_debug>=2;
				my $state = 'expanded' ;
				$_state_href->{$key} = \$state ;
			}

			# save data reference
			$data_ref{"$ref"} = $_state_href->{$key} if $ref ;
			
print " + check for expansion...\n" if $class_debug>=2;
			foreach my $val (@vals)
			{
				next unless $val ;

print " + + val=$val\n" if $class_debug>=2;

				if (index($val, '$') >= 0)
				{
print " + + + needs expanding\n" if $class_debug>=2;
					$to_expand{$key}++ ;
					${$_state_href->{$key}} = 'to_expand' ;
					last ;
				}
			}
		}
	}

$class->prt_data("to expand=", \%to_expand) if $class_debug;

$class->prt_data("Hash=", $hash_ref) if $class_debug;

	## Expand them
	foreach my $key (keys %to_expand)
	{
	print " # Key=$key State=${$_state_href->{$key}}\n" if $class_debug;
	
		# skip if not valid (if called recursively with a variable that is not in the hash)
		next unless exists($hash_ref->{$key}) ;

		# Do replacement iff required
		next if ${$_state_href->{$key}} eq 'expanded' ;

		my @vals ;
		if (ref($hash_ref->{$key}) eq 'ARRAY')
		{
			foreach my $val (@{$hash_ref->{$key}})
			{
				push @vals, \$val ;
			}
		}
		elsif (!ref($hash_ref->{$key}))
		{
			push @vals, \$hash_ref->{$key} ;
		}
		
		# mark as expanding
		${$_state_href->{$key}} = 'expanding' ;		

$class->prt_data("Vals to expand=", \@vals) if $class_debug;

#use re 'debugcolor' ;

		foreach my $val_ref (@vals)
		{

	print " # Expand \"$$val_ref\" ...\n" if $class_debug;

			$$val_ref =~ s{
							(?:
								[\\\$]\$					# escaped dollar
							     \{{0,1}					# optional brace
							    (\w+)                       # find a "word" and store it in $1
							     \}{0,1}					# optional brace
						    )
							|
							(?:
							     \$                         # find a literal dollar sign
							     \{{0,1}					# optional brace
							    (\w+)                       # find a "word" and store it in $1
							     \}{0,1}					# optional brace
						     )
						}{
							my $prefix = '' ;
							my ($escaped, $var) = ($1, $2) ;
	
							$escaped ||= '' ;
							$var ||= '' ;
							
	print " # esc=\"$escaped\", prefix=\"$prefix\", var=\"$var\"\n" if $class_debug;
							
							my $replace='' ;
							if ($escaped)
							{
								$prefix = '$' ;
								$replace = $escaped ;
	print " ## escaped prefix=$prefix replace=$replace\n" if $class_debug;
	print " ## DONE\n" if $class_debug;
							}
							else
							{		
								## use current HASH values before vars				
							    if (defined $hash_ref->{$var}) 
							    {
print " ## var=$var current state=${$_state_href->{$var}}\n" if $class_debug;
							    	if (${$_state_href->{$var}} eq 'to_expand')
							    	{
print " ## var=$var call expand..\n" if $class_debug;
							    		# go expand it first
							   			$class->expand_keys($hash_ref, $vars_aref, $_state_href, {$var => 1}) ; 		
							    	}
							    	if (${$_state_href->{$var}} eq 'expanded')
							    	{
print " ## var=$var already expanded\n" if $class_debug;
								        $replace = $hash_ref->{$var};            # expand variable
							    		$replace = join("\n", @{$hash_ref->{$var}}) if (ref($hash_ref->{$var}) eq 'ARRAY') ;
							    	}
							    }
print " ## var=$var  can replace from hash=$replace\n" if $class_debug;
	
								## If not found, use vars
								if (!$replace)
								{
									## use vars 
									foreach my $href (@$vars_aref)
									{
									    if (defined $href->{$var}) 
									    {
									        $replace = $href->{$var};            # expand variable
								    		$replace = join("\n", @{$hash_ref->{$var}}) if (ref($href->{$var}) eq 'ARRAY') ;
		print " ## found var=$var replace=$replace\n" if $class_debug;
									        last ;
									    }
									}					    
								}
print " ## var=$var  can replace now=$replace\n" if $class_debug;

								if (!$replace)
								{
									$replace = "" ;
	print " ## no replacement\n" if $class_debug;
	print " ## DONE\n" if $class_debug;
								}
							}
													
	print " ## ALL DONE $key: $escaped$var = \"$prefix$replace\"\n\n" if $class_debug;
							"$prefix$replace" ;
						}egxm;	## NOTE: /m is for multiline anchors; /s is for multiline dots
		}

$class->prt_data("Hash now=", $hash_ref) if $class_debug>=2;

		# mark as expanded
		${$_state_href->{$key}} = 'expanded' ;		

$class->prt_data("State now=", $_state_href) if $class_debug>=2;
	}
}



##============================================================================================
#
#=back
#
#=head2 OBJECT DATA METHODS
#
#=over 4
#
#=cut
#
##============================================================================================


##============================================================================================
#
#=back
#
#=head2 OBJECT METHODS
#
#=over 4
#
#=cut
#
##============================================================================================


#============================================================================================
#
# PRIVATE
#
#============================================================================================

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


