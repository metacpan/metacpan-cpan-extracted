package App::Framework::Feature::Options ;

=head1 NAME

App::Framework::Feature::Options - Handle application options

=head1 SYNOPSIS

  # Options are loaded by default as if the script contained:
  use App::Framework '+Options' ;


=head1 DESCRIPTION

Options feature that provides command line options handling. 

Options are defined once in a text format and this text format generates 
both the command line options data, but also the man pages, help text etc.

=head2 Option Definition

Options are specified in the application __DATA__ section in the format:

    -<name><specification>    <Summary>    <optional default setting>
    
    <Description> 

These user-specified options are added to the application framework options (defined dependent on whatever core/features/extensions are installed).
Also, the user may over ride default settings and descriptions on any application framework options by re-defining them in the script.

The parts of the specification are defined below.

=head3 name

The name defines the option name to be used at the command line, along with any command line option aliases (e.g. -log or -l, -logfile etc). Using the 
option in the script is via a HASH where the key is the 'main' option name.

Where an option has one or more aliases, this list of names is separated by '|'. By default, the first name defined is the 'main' option name used
as the option HASH key. This may be overridden by quoting the name that is required to be the main name.

For example, the following name definitions:

    -log|logfile|l
    -l|'log'|logfile
    -log

Are all access by the key 'log'

=head3 specification

(Note: This is a subset of the specification supported by L<Getopt::Long>).

The specification is optional. If not defined, then the option is a boolean value - is the user specifies the option on the command line
then the option value is set to 1; otherwise the option value is set to 0.

When the specification is defined, it is in the format:

   [ <flag> ] <type> [ <desttype> ]

The option requires an argument of the given type. Supported types
are:

=over 4

=item s

String. An arbitrary sequence of characters. It is valid for the
argument to start with C<-> or C<-->.

=item i

Integer. An optional leading plus or minus sign, followed by a
sequence of digits.

=item o

Extended integer, Perl style. This can be either an optional leading
plus or minus sign, followed by a sequence of digits, or an octal
string (a zero, optionally followed by '0', '1', .. '7'), or a
hexadecimal string (C<0x> followed by '0' .. '9', 'a' .. 'f', case
insensitive), or a binary string (C<0b> followed by a series of '0'
and '1').

=item f

Real number. For example C<3.14>, C<-6.23E24> and so on.

=back

The I<desttype> can be C<@> or C<%> to specify that the option is
list or a hash valued. This is only needed when the destination for
the option value is not otherwise specified. It should be omitted when
not needed.

The I<flag>, if used, can be C<dev:> to specify that the option is meant for application developer
use only. In this case, the option will not be shown in the normal help and man pages, but will
only be shown when the -man-dev option is used.

=head3 summary

The summary is a simple line of text used to summarise the option. It is used in the man pages in 'usage' mode.

=head3 default

Defaults values are optional. If they are defined, they are in the format:

    [default=<value>]

When a default is defined, if the user does not specify a value for an option then that option takes on the defualt value.

=head3 description

The summary is multiple lines of text used to fully describe the option. It is used in the man pages in 'man' mode.

=head2 Variable Expansion

Option values and default values can contain variables, defined using the standard Perl format:

	$<name>
	${<name>}

When the option is used, the variable is expanded and replaced with a suitable value. The value will be looked up from a variety of possible sources:
object fields (where the variable name matches the field name) or environment variables.

The variable name is looked up in the following order, the first value found with a matching name is used:

=over 4

=item *

Option names - the values of any other options may be used as variables in options

=item *

Application fields - any fields of the $app object may be used as variables

=item *

Environment variables - if no application fields match the variable name, then the environment variables are used

=back 

=head2 Script Usage

The application framework passes a reference to the options HASH as the second parameter to the application subroutine B<app>. Alternatively,
the script can call the app object's alias to the options accessor, i.e. the B<options> method which returns the options hash. Yet another
alternative is to call the options accessor method directly. These alternatives are shown below:


    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
        
        # use parameter
        my $log = $opts_href->{log}
        
        # access alias
        my %options = $app->options() ;
        $log = $options{log} ;
        
        # access alias
        %options = $app->Options() ;
        $log = $options{log} ;
        
        # feature object
        %options = $app->feature('Options')->options() ;
        $log = $options{log} ;
    }



=head2 Examples

With the following script definition:

    [OPTIONS]
    
    -n|'name'=s        Test name [default=a name]
    
    String option, accessed as $opts_href->{name}. 
    
    -nomacro    Do not create test macro calls
    
    Boolean option, accessed as $opts_href->{nomacro}
    
    -log=s        Override default [default=another default]
    
    Over rides the default log option (specified by the framework)
    
    -int=i        An integer
    
    Example of integer option
    
    -float=f    An float
    
    Example of float option
    
    -array=s@    An array
    
    Example of an array option
    
    -hash=s%    A hash
    
    Example of a hash option

The following command line options are valid:

    -int 1234 -float 1.23 -array a -array b -array c -hash key1=val1 -hash key2=val2 -nomacro

Giving the options HASH values:

    'name' => 'a name'
    'nomacro' => 1
    'log' => 'another default'
    'int' => 1234
    'float' => 1.23
    'array' => [ 'a', 'b', 'c' ]
    'hash' => {
    	'key1' => 'val1',
    	'key2' => 'val2',
    }

=cut

use strict ;
use Carp ;

our $VERSION = "1.005" ;


#============================================================================================
# USES
#============================================================================================
use Getopt::Long qw(:config no_ignore_case) ;

use App::Framework::Feature ;
use App::Framework::Base ;

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

=item B<user_options> - list of options

Created by the object. Once all of the options have been created, this field contains an ARRAY ref to the list
of all of the specified option specifications (see method L</append_options>).

=item B<option_names> - list of options names

Created by the object. Once all of the options have been created, this field contains an ARRAY ref to the list
of all of the option field names.

=back

=cut

my %FIELDS = (
	'user_options'	=> [],		# User-specified options
	'option_names'	=> [],		# List of option names

	'_options'				=> {},	# Final options HASH - key = option name; value = option value
	'_option_fields_hash'	=> {},	# List of HASHes, each hash contains details of an option
	'_get_options'			=> [],	# Options converted into list for GetOpts
	'_options_list'			=> [],	# Processed list of options (with duplicates removed)
) ;


#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================


=item B< new([%args]) >

Create a new Options.

The %args are specified as they would be in the B<set> method to set field values (see L</Fields>).

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args,
		'priority' 		=> $App::Framework::Base::PRIORITY_SYSTEM + 10,		# needs to be before data
#		'registered'	=> [qw/getopts_entry/],
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

=item B< init_class([%args]) >

Initialises the Options object class variables.

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

=item B< options() >

Feature accessor method (aliases on the app object as B<options>)

Returns the hash of options/values

=cut

sub options
{
	my $this = shift ;

$this->_dbg_prt( ["Options()\n"] ) ;

	my $options_href = $this->_options() ;
	return %$options_href ;
}

#----------------------------------------------------------------------------

=item B< Options([%args]) >

Alias to L</options>

=cut

*Options = \&options ;

#----------------------------------------------------------------------------

=item B<option($option_name)>

Returns the value of the named option

=cut

sub option
{
	my $this = shift ;
	my ($option_name) = @_ ;

	my $options_href = $this->_options() ;
	return exists($options_href->{$option_name}) ? $options_href->{$option_name} : undef ;
}

#----------------------------------------------------------------------------

=item B< update() >

(Called by App::Framework::Core)

Take the list of options (created by calls to L</append_options>) and process the list into the
final options list.

Returns the hash of options/values

=cut

sub update
{
	my $this = shift ;

$this->_dbg_prt( ["update()\n"] ) ;

if ( $this->debug()>=2 )
{
$this->dump_callstack() ;
}

	## get user settings
	my $options_aref = $this->user_options ;

	## set up internals
	
	# rebuild these
	my $options_href = {} ;
	my $get_options_aref = [] ;
	my $option_names_aref = [] ;

	# keep full details
#	my $options_fields_href = $this->_option_fields_hash($options_fields_href) ;
	my $options_fields_href = {} ;


	## process to see if any options are to be over-ridden
	my %options ;
	my @processed_options ;
	foreach my $option_aref (@$options_aref)
	{
		my ($spec, $summary, $default_val, $description) = @$option_aref ;
		
		# split spec into the field names
		my ($field, $option_spec, $pod_spec, $dest_type, $developer_only, $fields_aref, $arg_type) = 
			$this->_process_option_spec($spec) ;
		
		# see if any fields have been seen before
		my $in_list = 0 ;
		foreach my $fnm (@$fields_aref)
		{
	$this->_dbg_prt( ["opt: Checking '$fnm' ($option_aref)..\n"], 2 ) ;
	
			if (exists($options{$fnm}))
			{
	$this->_dbg_prt( ["opt: '$fnm' seen before\n"], 2 ) ;
				# seen before - overwrite settings
				my $aref = $options{$fnm} ;
				$in_list = 1;
				
				# [$spec, $summary, $description, $default_val]
				for (my $i=1; $i < scalar(@$option_aref); $i++)
				{
	$this->_dbg_prt( ["opt: checking $i\n"], 2 ) ;
					# if newer entry is set to something then use it
					if ($option_aref->[$i])
					{
						my $old = $aref->[$i] || '' ;
	$this->_dbg_prt( ["opt: overwrite $i : '$old' with '$option_aref->[$i]'\n"], 2 ) ;
						$aref->[$i] = $option_aref->[$i] ;
					}
				}
			}
			else
			{
	$this->_dbg_prt( ["opt: '$fnm' new $option_aref\n"], 2 ) ;
				# save for later checking
				$options{$fnm} = $option_aref ;
			}
		}
	$this->_dbg_prt( ["opt: In list $in_list ($option_aref)\n"], 2 ) ;
	
		push @processed_options, $option_aref unless $in_list ;
	}
	$options_aref = \@processed_options ;
	
	
	## fill options_href, get_options_aref
	
	# Cycle through
	foreach my $option_entry_aref (@$options_aref)
	{
		my ($option_spec, $summary, $description, $default_val, $owner_pkg) = @$option_entry_aref ;
		
		## Process the option spec
		my ($field, $spec, $dest_type, $developer_only, $fields_aref, $arg_type) ;
		($field, $option_spec, $spec, $dest_type, $developer_only, $fields_aref, $arg_type) = 
			$this->_process_option_spec($option_spec) ;
		
		# Set default if required
		$options_href->{$field} = $default_val if (defined($default_val)) ;
		
		# Add to Getopt list
		push @$get_options_aref, $option_spec => \$options_href->{$field} ;
		
		# Create full entry
		$options_fields_href->{$field} = {
				'field'=>$field, 
				'spec'=>$option_spec, 
				'summary'=>$summary, 
				'description'=>$description,
				'default'=>$default_val,
				'pod_spec'=>$spec,
				'type' => $arg_type,
				'dest_type' => $dest_type,
				'developer' => $developer_only,
				'entry' => $option_entry_aref,
				'owner' => $owner_pkg,
		} ;
		
		# add to list of names
		push @$option_names_aref, $field ;
	}
$this->_dbg_prt( ["update() set: Getopts spec=", $get_options_aref] , 2) ;
$this->_dbg_prt( ["update() - END\n"], 2 ) ;

	## Save
	$this->_options_list($options_aref) ;
	$this->_options($options_href) ;
	$this->_get_options($get_options_aref) ;
	$this->_option_fields_hash($options_fields_href) ;

	$this->option_names($option_names_aref) ;
	
	return %$options_href ;
}

#----------------------------------------------------------------------------

=item B<append_options($options_aref [, $caller_pkg])>

Append the options listed in the ARRAY ref I<$options_aref> to the current options list

Each entry in the ARRAY ref is an ARRAY ref containing:

 [ <option spec>, <option summary>, <option description>, <option default> ]

Where the <option spec> is in the format <name><specification> (see L</name> and L</specification> above). The summary and description
are as describe in L</Option Definition>. The optional default value is just the value (rather than the string '[default=...]').

Can optionally specify the caller package name (otherwise works out the caller and stores that package name)

=cut

sub append_options
{
	my $this = shift ;
	my ($options_aref, $caller_pkg) = @_ ;

$this->_dbg_prt( ["Options: append_options()\n"] ) ;

	# get caller
	unless ($caller_pkg)
	{
		$caller_pkg = (caller(0))[0] ;
	}
	
	my @combined_options = (@{$this->user_options}) ;
	foreach my $opt_aref (@$options_aref)
	{
		my @opt = ($opt_aref->[0], $opt_aref->[1], $opt_aref->[2], $opt_aref->[3], $caller_pkg) ;
		push @combined_options, \@opt ;
	}
	$this->user_options(\@combined_options) ;

$this->_dbg_prt( ["Options: append_options() new=", $options_aref] , 2) ;
$this->_dbg_prt( ["combined=", \@combined_options] , 2) ;

	## Build new set of options
	$this->update() ;
	
	return @combined_options ;
}

#----------------------------------------------------------------------------

=item B<clear_options()>

Clears the current options list.

=cut

sub clear_options
{
	my $this = shift ;

$this->_dbg_prt( ["Options: clear_options()\n"] ) ;

	$this->user_options([]) ;

}

#----------------------------------------------------------------------------

=item B<get_options()>

Use Getopt::Long to process the command line options. Returns 1 on success; 0 otherwise

=cut

sub get_options
{
	my $this = shift ;

	# Do final processing of the options
	$this->update() ;
	
	# get the list suitable for GetOpts
	my $get_options_aref = $this->_get_options() ;

$this->_dbg_prt( ["get_options() : ARGV=", \@ARGV, " Options=", $get_options_aref], 2 ) ;

	# Parse options using GetOpts
	my $ok = GetOptions(@$get_options_aref) ;

	# Expand the options variables
	$this->_expand_options() ;

$this->_dbg_prt( ["get_options() : ok=$ok  Options now=", $get_options_aref], 2 ) ;

	return $ok ;
}

#----------------------------------------------------------------------------

=item B<option_entry($option_name)>

Returns the HASH ref of option if name is found; undef otherwise.

The HASH ref contains:

	'field' => option 'main' name 
	'spec' => specification string
	'summary' => summary text 
	'description' => description text
	'default' => default value (if specified)
	'pod_spec' => specification string suitable for pod output
	'type' => option type (e.g. s, f etc)
	'dest_type' => destination type (e.g. @, %)
	'developer' => developer only option (flag set if option is to be used for developer use only)
	'entry' => reference to the ARRAY that defined the option (as per L</append_options>) 

=cut

sub option_entry
{
	my $this = shift ;
	my ($option_name) = @_ ;

	my $option_fields_href = $this->_option_fields_hash() ;
	my $opt_href ;
	if (exists($option_fields_href->{$option_name}))
	{
		$opt_href = $option_fields_href->{$option_name} ;
	}
	return $opt_href ;
}



#----------------------------------------------------------------------------

=item B<modify_default($option_name, $default)>

Changes the default setting of the named option. Returns the option value if sucessful; undef otherwise

=cut

sub modify_default
{
	my $this = shift ;
	my ($option_name, $default) = @_ ;

	$default = '' unless defined $default ;
$this->_dbg_prt( ["Options: modify_default($option_name, $default)\n"] ) ;

	my $opt_href = $this->option_entry($option_name);
	if ($opt_href)
	{
		## Update the source
		$opt_href->{'entry'}[3] = $default ;
		
		## keep derived info up to date (?)
		
		# Set default if required
		my $options_href = $this->_options() ;
		$options_href->{$option_name} = $default ;
		
		# Add to Getopt list
		$opt_href->{'default'} = $default ;

	}
$this->_dbg_prt( ["Options: after modify = ", $opt_href] , 2) ;
	return $opt_href ;
}

#----------------------------------------------------------------------------

=item B<defaults_from_obj($obj [, $names_aref])>

Scans through the options looking for any matching variable stored in $obj 
(accessed via $obj->$variable). Where there is an variable, modifies the option
default to be equal to the current variable setting. 

Optionally, you can specify an ARRAY ref of option names so that only those named are examined

This is a utility routine that can be called by extensions (or features) that want to
set the option defaults equal to their object variable settings.

=cut

sub defaults_from_obj
{
	my $this = shift ;
	my ($obj, $names_aref) = @_ ;

	my $option_fields_href = $this->_option_fields_hash() ;

$this->_dbg_prt(["## defaults_from_obj() names=", $names_aref]) ;

	# get object vars
	my %vars = $obj->vars ;
	
	my @names ;
	if ($names_aref)
	{
		# do just those specified
		@names = @$names_aref ;
	}
	else
	{
		# do them all
		@names = keys %$option_fields_href ;
	}
	
	# scan options
	foreach my $option_name (@names)
	{
		if (exists($vars{$option_name}) && defined($vars{$option_name}) && exists($option_fields_href->{$option_name}))
		{
			$this->modify_default($option_name, $vars{$option_name}) ;
$this->_dbg_prt([ " + modify default: $option_name = $vars{$option_name}\n"]) ;			
		}
	}
$this->_dbg_prt(["Options=", $option_fields_href]) ;
}

#----------------------------------------------------------------------------

=item B<obj_vars($obj [, $names_aref])>

Scans through the options looking for any matching variable stored in $obj 
(accessed via $obj->$variable). Where there is an variable, modifies the object variable value
to be equal to the current option setting. 

Optionally, you can specify an ARRAY ref of option names so that only those named are examined

This is effectively the reversal of L<defaults_from_obj>

=cut

sub obj_vars
{
	my $this = shift ;
	my ($obj, $names_aref) = @_ ;

	my $option_fields_href = $this->_option_fields_hash() ;

	# get object vars
	my %vars = $obj->vars ;

$this->_dbg_prt(["## obj_vars() names=", $names_aref, "Options=", $option_fields_href]) ;
	
	my @names ;
	if ($names_aref)
	{
		# do just those specified
		@names = @$names_aref ;
	}
	else
	{
		# do them all
		@names = keys %$option_fields_href ;
	}
	
	# scan names
	my %set ;
	foreach my $option_name (@names)
	{
		if (exists($vars{$option_name}) && exists($option_fields_href->{$option_name}))
		{
			$set{$option_name} = $this->option($option_name) ;
		}
	}

$this->_dbg_prt([" + setting=", \%set]) ;
	
	# set the variables on the object (if necessary)
	$obj->set(%set) if keys %set ;
}

#----------------------------------------------------------------------------

=item B<option_values_hash()>

Returns the options values and defaults HASH references in an array, values HASH ref
as the first element.

=cut

sub option_values_hash
{
	my $this = shift ;

	my $options_href = $this->_options() ;
	my $options_fields_href = $this->_option_fields_hash() ;

	# get defaults & options
	my (%values, %defaults) ;
	foreach my $opt (keys %$options_fields_href)
	{
		$defaults{$opt} = $options_fields_href->{$opt}{'default'} ;
		$values{$opt} = $options_href->{$opt} if defined($options_href->{$opt}) ;
	}

	return (\%values, \%defaults) ;
}


#----------------------------------------------------------------------------

=item B<option_values_set($values_href, $defaults_href)>

Sets the options values and defaults based on the HASH references passed in.

=cut

sub option_values_set
{
	my $this = shift ;
	my ($values_href, $defaults_href) = @_ ;

	my $options_href = $this->_options() ;
	my $options_fields_href = $this->_option_fields_hash() ;

	## Update
	foreach my $opt (keys %$options_fields_href)
	{
		# update defaults to reflect any user specified options
		$defaults_href->{$opt} = $values_href->{$opt} ;
		$options_fields_href->{$opt}{'default'} = $defaults_href->{$opt} ;
		
		# update values
		$options_href->{$opt} = $values_href->{$opt} if defined($options_href->{$opt}) ;
	}
}


# ============================================================================================
# PRIVATE METHODS
# ============================================================================================


#----------------------------------------------------------------------------
#
#=item B<_process_option_spec($option_spec)>
#
#Processes the option specification string, returning:
#
#	($field, $option_spec, $spec, $dest_type, $developer_only, $fields_aref, $arg_type)
#
#=cut
#
sub _process_option_spec 
{
	my $this = shift ;
	my ($option_spec) = @_ ;

$this->_dbg_prt( ["option: _process_option_spec($option_spec)"] , 2) ;

	my $developer_only = 0 ;

	# <opt spec> (subset of that supported by Getopt::Long):
	#    <type> [ <desttype> ]	
	# <type>:
	#	s = String. An arbitrary sequence of characters. It is valid for the argument to start with - or -- .
	#	i = Integer. An optional leading plus or minus sign, followed by a sequence of digits.
	#	o = Extended integer, Perl style. This can be either an optional leading plus or minus sign, followed by a sequence of digits, or an octal string (a zero, optionally followed by '0', '1', .. '7'), or a hexadecimal string (0x followed by '0' .. '9', 'a' .. 'f', case insensitive), or a binary string (0b followed by a series of '0' and '1').
	#	f = Real number. For example 3.14 , -6.23E24 and so on.
	#	
	# <desttype>:
	#   @ = store options in ARRAY ref
	#   % = store options in HASH ref
		
	# If option starts with start char then remove it
	$option_spec =~ s/^[\-\+\*]// ;
	
	# if starts with dev: then remove and flag
	if ($option_spec =~ s/^dev://i)
	{
		$developer_only = 1 ;
	}
	
	# Get field name
	my $field = $option_spec ;
	if ($option_spec =~ /[\'\"](\w+)[\'\"]/)
	{
		$field = $1 ;
		$option_spec =~ s/[\'\"]//g ;
	}
	$field =~ s/\|.*$// ;
	$field =~ s/\=.*$// ;
	
	# re-create spec with field name highlighted
	my $spec = $option_spec ;
	my $arg = "";
	if ($spec =~ s/\=(.*)$//)
	{
		$arg = $1 ;
	}
$this->_dbg_prt( ["_process_option_spec() set: pod spec=$spec arg=$arg\n"], 2 ) ;

	my @fields = split /\|/, $spec ;
	if (@fields > 1)
	{
		# put field name first
		$spec = "$field" ;
		foreach my $fld (@fields)
		{
			next if $fld eq $field ;
			
	$this->_dbg_prt( [" + $fld\n"], 2 ) ;
			$spec .= '|' if $spec;
			$spec .= $fld ;
		}	
	}
	
	my $dest_type = "" ;
	if ($arg =~ /([\@\%])/i)
	{
		$dest_type = $1 ;
	}			

	my $arg_type = "" ;
	if ($arg =~ /([siof])/i)
	{
		$arg_type = $1 ;
		if ($arg_type eq 's')
		{
			if ($dest_type eq '%')
			{
				$spec .= " <key=value>" ;
			}
			else
			{
				$spec .= " <string>" ;
			}
		}
		elsif ($arg_type eq 'i')
		{
			$spec .= " <integer>" ;
		}
		elsif ($arg_type eq 'f')
		{
			$spec .= " <float>" ;
		}
		elsif ($arg_type eq 'o')
		{
			$spec .= " <extended int>" ;
		}
		else
		{
			$spec .= " <arg>"
		}
	}

$this->_dbg_prt( ["_process_option_spec() set: final pod spec=$spec arg=$arg\n"], 2 ) ;
				
	return ($field, $option_spec, $spec, $dest_type, $developer_only, \@fields, $arg_type) ;
			
}


#----------------------------------------------------------------------------
#
#=item B<_expand_options()>
#
#Expand any variables in the options
#
#=cut
#
sub _expand_options 
{
	my $this = shift ;

$this->_dbg_prt(["_expand_options()\n"]) ;

	my $options_href = $this->_options() ;
	my $options_fields_href = $this->_option_fields_hash() ;

	# get defaults & options
	my (%defaults, %values) ;
	foreach my $opt (keys %$options_fields_href)
	{
		$defaults{$opt} = $options_fields_href->{$opt}{'default'} ;
		$values{$opt} = $options_href->{$opt} if defined($options_href->{$opt}) ;
	}
$this->_dbg_prt(["_expand_options: defaults=",\%defaults," values=",\%values,"\n"]) ;

	# get replacement vars
	my @vars ;
	my $app = $this->app ;
	if ($app)
	{
		my %app_vars = $app->vars ;
		push @vars, \%app_vars ;
	}
	push @vars, \%ENV ;
	
#	## expand
#	$this->expand_keys(\%values, \@vars) ;
#	push @vars, \%values ;	# allow defaults to use user-specified values
#	$this->expand_keys(\%defaults, \@vars) ;

$this->_dbg_prt(["_expand_options - end: defaults=",\%defaults," values=",\%values,"\n"]) ;
	
	## Update
	foreach my $opt (keys %$options_fields_href)
	{
		# update defaults to reflect any user specified options
		$defaults{$opt} = $values{$opt} ;
		$options_fields_href->{$opt}{'default'} = $defaults{$opt} ;
		
		# update values
		$options_href->{$opt} = $values{$opt} if defined($options_href->{$opt}) ;
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


