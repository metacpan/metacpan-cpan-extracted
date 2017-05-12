package App::Framework::Feature::Args ;

=head1 NAME

App::Framework::Feature::Args - Handle application command line arguments

=head1 SYNOPSIS

  # Args are loaded by default as if the script contained:
  use App::Framework '+Args' ;
  
  # Alternatives...
  
  # Open no file handles 
  use App::Framework '+Args(open=none)' ;
  
  # Open only input file handles 
  use App::Framework '+Args(open=in)' ;
  
  # Open only output file handles 
  use App::Framework '+Args(open=out)' ;
  
  # Open all file handles (the default)
  use App::Framework '+Args(open=all)' ;


=head1 DESCRIPTION

Args feature that provides command line arguments handling. 

Arguments are defined once in a text format and this text format generates 
both the command line arguments data, but also the man pages, help text etc.

=head2 Argument Definition

Arguments are specified in the application __DATA__ section in the format:

    * <name>=<specification>    <Summary>    <optional default setting>
    
    <Description> 

The parts of the specification are defined below.

=head3 name

The name defines the name of the key to use to access the argument value in the arguments hash. The application framework
passes a reference to the argument hash as the third parameter to the application subroutine B<app> (see L</Script Usage>)

=head3 specification

The specification is in the format:

   [ <direction> ] [ <binary> ] <type> [ <multiple> ]

The optional I<direction> is only valid for file or directory types. For a file or directory types, if no direction is specified then
it is assumed to be input. Direction can be one of: 

=over 4

=item <

An input file or directory

=item >

An output file or directory

=item >>

An output appended file

=back

An optional 'b' after the direction specifies that the file is binary mode (only used when the type is file).

The B<type> must be specified and may be one of:

=over 4

=item f

A file

=item d

A directory

=item s

Any string

=back

Additionally, an optional multiple can be specified. If used, this can only be specified on the last argument. When it is used, this tells the
application framework to use the last argument as an ARRAY, pushing all subsequent specified arguments onto this. Accessing the argument
in the script returns the ARRAY ref containing all of the command line argument values.

Multiple can be:

=over 4

=item '@'

One or more items

=item '*'

Zero or more items. There is also a special case (the real reason for *) where the argument specification is of the form '<f*' (input file multiple). Here, if the script user does not
specify any arguments on the command line for this argument then the framework opens STDIN and provides it as a file handle.  

=back


=head3 summary

The summary is a simple line of text used to summarise the argument. It is used in the man pages in 'usage' mode.

=head3 default

Defaults values are optional. If they are defined, they are in the format:

    [default=<value>]

When a default is defined, if the user does not specify a value for an argument then that argument takes on the defualt value.

Also, all subsequent arguments must also be defined as optional.

=head3 description

The summary is multiple lines of text used to fully describe the option. It is used in the man pages in 'man' mode.

=head2 Feature Options

The Args feature allows control over how it opens files. By default, any input or output file definitions also create equivalent file handles
(the files being opened for read/write automatically). These file handles are made available only in the arguments HASH. The key name for the handle
being the name of the argument with the suffix '_fh'.

For example, the following definition:

    [ARGS]
    
    * file=f		Input file
    
    A simple input directory name (directory must exist)
    
    * out=>f		Output file (file will be created)
    
    An output filename

And the command line arguments:

    infile.txt outfile.txt

Results in the arguments HASH:

    'file'    => 'infile.txt'
    'out'     => 'outfile.txt'
    'file_fh' => <file handle of 'infile.txt'>
    'out_fh'  => <file handle of 'outfile.txt'>

If this behaviour is not required, then you can get the framework to open just input files, output files, or none by using the 'open' option.

Specify this in the App::Framework 'use' line as an argument to the Args feature: 

    # Open no file handles 
    use App::Framework '+Args(open=none)' ;
    
    # Open only input file handles 
    use App::Framework '+Args(open=in)' ;
    
    # Open only output file handles 
    use App::Framework '+Args(open=out)' ;
    
    # Open all file handles (the default)
    use App::Framework '+Args(open=all)' ;

=head2 Variable Expansion

Argument values can contain variables, defined using the standard Perl format:

	$<name>
	${<name>}

When the argument is used, the variable is expanded and replaced with a suitable value. The value will be looked up from a variety of possible sources:
object fields (where the variable name matches the field name) or environment variables.

The variable name is looked up in the following order, the first value found with a matching name is used:

=over 4

=item *

Argument names - the values of any other arguments may be used as variables in arguments

=item *

Option names - the values of any command line options may be used as variables in arguments

=item *

Application fields - any fields of the $app object may be used as variables

=item *

Environment variables - if no application fields match the variable name, then the environment variables are used

=back 



=head2 Script Usage

The application framework passes a reference to the argument HASH as the third parameter to the application subroutine B<app>. Alternatively,
the script can call the app object's alias to the args accessor, i.e. the B<args> method which returns the arguments value list. Yet another
alternative is to call the args accessor method directly. These alternatives are shown below:


    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
        
        # use parameter
        my $infile = $args_href->{infile}
        
        # access alias
        my @args = $app->args() ;
        $infile = $args[0] ;
        
        # access alias
        @args = $app->Args() ;
        $infile = $args[0] ;

        ($infile) = $app->args('infile') ;
        
        # feature object
        @args = $app->feature('Args')->args() ;
        $infile = $args[0] ;
    }



=head2 Examples

With the following script definition:

    [ARGS]
    
    * file=f		Input file
    
    A simple input file name (file must exist)
    
    * dir=d			Input directory
    
    A simple input directory name (directory must exist)
    
    * out=>f		Output file (file will be created)
    
    An output filename
    
    * outdir=>d		Output directory
    
    An output directory name (path will be created) 
    
    * append=>>f	Output file append
    
    An output filename (an existing file will be appended; otherwise file will be created)
    
    * array=<f*		All other args are input files
    
    Any other command line arguments will be pushced on to this array. 

The following command line arguments:

    infile.txt indir outfile.txt odir append.txt file1.txt file2.txt file3.txt 

Give the arguments HASH values:

    'file'     => 'infile.txt'
    'file_fh'  => <infile.txt file handle>
    'dir'      => 'indir'
    'out'      => 'outfile.txt'
    'out_fh'   => <outfile.txt file handle>
    'outdir'   => 'odir'
    'append'   => 'append.txt'
    'append_fh'=> <append.txt file handle>
    'array'    => [
    	'file1.txt'
    	'file2.txt'
    	'file3.txt'
    ]
    'array_fh' => [
    	<file1.txt file handle>
    	<file2.txt file handle>
    	<file3.txt file handle>
    ]


An example script that uses the I<multiple> arguments, along with the default 'open' behaviour is:

    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
        
        foreach my $fh (@{$args_href->{array_fh}})
        {
            while (my $data = <$fh>)
            {
                # do something ... 
            }
        }
    }    
    
    __DATA__
    [ARGS]
    * array=f@    Input file
    

This script can then be called with one or more filenames and each file will be processed. Or it can be called with no 
filenames and STDIN will then be used.



=cut

use strict ;
use Carp ;

our $VERSION = "1.007" ;

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


=head2 FIELDS

The following fields should be defined either in the call to 'new()', as part of a 'set()' call, or called by their accessor method
(which is the same name as the field):


=over 4

=item B<user_args> - list of argument definitions

Created by the object. Once all of the arguments have been created, this field contains an ARRAY ref to the list
of all of the specified option specifications (see method L</append_args>).

=item B<arg_names> - list of argument names

Created by the object. Once all of the arguments have been created, this field contains an ARRAY ref to the list
of all of the argument names.

=item B<argv> - list of command line arguments

Reference to @ARGV array.

=back

=cut

my %FIELDS = (
	## User specified
	'user_args'		=> [],		# User-specified args
	'argv'		=> [],		# ref to @ARGV
	'arg_names'	=> [],		# List of arg names

	## Created
	'_arg_list'			=> [],	# Final ARRAY ref of args - EXCLUDING any opened files
	'_args'				=> {},	# Final args HASH - key = arg name; value = arg value
	'_arg_names_hash'	=> {},	# List of HASHes, each hash contains details of an arg
	'_fh_list'			=> [],	# List of any opened file handles
) ;

#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================


=item B< new([%args]) >

Create a new Args.

The %args are specified as they would be in the B<set> method (see L</Fields>).

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args,
	) ;


my $args = $this->feature_args() ;
$this->_dbg_prt(["NEW: feature args=", $args]) ;
$this->_dbg_prt(["OBJ=", $this]) ;
	
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

Initialises the Args object class variables.

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

=item B< args([$name]) >

When called with no arguments, returns the full arguments list (same as call to method L</arg_list>).

When a name (or list of names) is specified: if the named arguments hash is available, returns the 
argument values as a list; otherwise just returns the complete args list.

=cut

sub args
{
	my $this = shift ;
	my (@names) = @_ ;
	
	my $args_href = $this->_args() ;
	my @args = $this->arg_list ;

	if (keys %$args_href)
	{
		# do named args
		if (@names)
		{
			@args = () ;
			foreach my $name (@names)
			{
				push @args, $args_href->{$name} if exists($args_href->{$name}) ;
			}			
		}
	}	
	
	return @args ;
}

#----------------------------------------------------------------------------

=item B< Args([$name]) >

Alias to L</args>

=cut

*Args = \&args ;


#----------------------------------------------------------------------------

=item B< arg_list() >

Returns the full arguments list. This is the list of arguments, as specified
at the command line by the user.

=cut

sub arg_list
{
	my $this = shift ;

	my $args_aref = $this->_arg_list() ;

	return @$args_aref ;
}

#----------------------------------------------------------------------------

=item B< arg_hash() >

Returns the full arguments hash.

=cut

sub arg_hash
{
	my $this = shift ;

	my $args_href = $this->_args() ;
	return %$args_href ;
}


#----------------------------------------------------------------------------

=item B<append_args($args_aref)>

Append the options listed in the ARRAY ref I<$args_aref> to the current args list

=cut

sub append_args
{
	my $this = shift ;
	my ($args_aref) = @_ ;

$this->_dbg_prt(["Args: append_args()\n"]) ;

	my @combined_args = (@{$this->user_args}, @$args_aref) ;
	$this->user_args(\@combined_args) ;

$this->_dbg_prt(["Options: append_args() new=", $args_aref], 2)   ;
$this->_dbg_prt(["combined=", \@combined_args], 2)   ;

	## Build new set of args
	$this->update() ;
	
	return @combined_args ;
}

#----------------------------------------------------------------------------

=item B< update() >

Take the list of args (created by calls to L</append_args>) and process the list into the
final args list.

Each entry in the ARRAY is an ARRAY ref containing:

 [ <arg spec>, <arg summary>, <arg description>, <arg default> ]

Returns the hash of args/values

=cut

sub update
{
	my $this = shift ;

$this->_dbg_prt(["Args: update()\n"]) ;

	## get user settings
	my $args_aref = $this->user_args ;

	## set up internals
	
	# rebuild these
	my $args_href = {} ;

	# keep full details
	my $args_names_href = {} ;

	## fill args_href, get_args_aref
	my $args_list = [] ;
	
	# Cycle through
	my $optional = 0 ;
	my $last_dest_type ;
	foreach my $arg_entry_aref (@$args_aref)
	{
$this->_dbg_prt(["Arg entry=", $arg_entry_aref], 2)   ;

		my ($arg_spec, $summary, $description, $default_val) = @$arg_entry_aref ;
		
		## Process the arg spec
		my ($name, $pod_spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode) ;
		($name, $arg_spec, $pod_spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode) =
			$this->_process_arg_spec($arg_spec) ;

		if ($last_dest_type)
		{
			$this->throw_fatal("Application definition error: arg $name defined after $last_dest_type defined as array") ;
		}
		$last_dest_type = $name if $dest_type ;
		
		# Set default if required
		$args_href->{$name} = $default_val if (defined($default_val)) ;

		# See if optional
		$arg_optional++ if defined($default_val) ;
		if ($optional && !$arg_optional)
		{
			$this->throw_fatal("Application definition error: arg $name should be optional since previous arg is") ;
		}		
		$optional ||= $arg_optional ;

$this->_dbg_prt(["Args: update() - arg_optional=$arg_optional optional=$optional\n"]) ;
		
		# Create full entry
		my $href = $this->_new_arg_entry($name, $arg_spec, $summary, $description, $default_val, $pod_spec, $arg_type, $arg_direction, $dest_type, $optional, $arg_append, $arg_mode) ;
		$args_names_href->{$name} = $href ;

$this->_dbg_prt(["Arg $name HASH=", $href], 2)   ;

		# save arg in specified order
		push @$args_list, $name ; 
	}

$this->_dbg_prt(["update() - END\n"], 2) ;

	## Save
	$this->arg_names($args_list) ;
	$this->_args($args_href) ;
	$this->_arg_names_hash($args_names_href) ;

	return %$args_href ;
}



#-----------------------------------------------------------------------------

=item B< check_args() >

At start of application, check the arguments for valid files etc.

=cut

sub check_args 
{
	my $this = shift ;

	# specified args
	my $argv_aref = $this->argv ;
	# values
	my $args_href = $this->_args() ;
	# details
	my $arg_names_href = $this->_arg_names_hash() ;

	# File handles
	my $fh_aref = $this->_fh_list() ;

$this->_dbg_prt(["check_args() Names=", $arg_names_href, "Values=", $args_href, "Name list=", $this->arg_names()], 2)   ;
	
		
	## Check feature settings
	my ($open_out, $open_in) = (1, 1) ;
	my $feature_args = $this->feature_args ;
	if ($feature_args =~ m/open\s*=\s*(out|in|no)/i)
	{
		if ($1 =~ /out/i)
		{
			++$open_out ;
		}
		elsif ($1 =~ /in/i)
		{
			++$open_in ;
		}
		else
		{
			# none
			$open_in = 0;
			$open_out = 0;
		}
	}	
#	elsif ($feature_args =~ m/open/i)
#	{
#		## open both
#		++$open_out ;
#		++$open_in ;
#	}	
	
	## Process each arg checking that it's been specified (where required)
	my $idx = -1 ;
	my $arg_list = $this->arg_names() ;
	foreach my $name (@$arg_list)
	{
#		# skip if optional
#		next if $arg_names_href->{$name}{'optional'} ;

		# create file handle name
		my $fh_name = "${name}_fh";		

		my $type = "" ;
		if ($arg_names_href->{$name}{'type'} eq 'f')
		{
			$type = "file " ;
		}
		if ($arg_names_href->{$name}{'type'} eq 'd')
		{
			$type = "directory " ;
		}

		my $value = $args_href->{$name} ;
		my @values = ($value) ;

		## Special handling for @* spec
		if ($arg_names_href->{$name}{'dest_type'})
		{
	$this->_dbg_prt([" + + special dest type\n"], 2) ;
			if (defined($value))
			{
				@values = @$value ;
			}
			
			push @values, '' unless @values ;

			if ($open_in && ($arg_names_href->{$name}{'type'} eq 'f'))
			{
				$args_href->{$fh_name} = [] ;
			}
		}

$this->_dbg_prt([" + values (@values) [".scalar(@values)."]\n"], 2) ;

		## Very special case of * spec with no args - set fh to STDIN if required
		if ($arg_names_href->{$name}{'dest_type'} eq '*')
		{
			if (!defined($value) || scalar(@$value)==0)
			{
				if ($open_in && ($arg_names_href->{$name}{'type'} eq 'f'))
				{
					# Create new entry
					my $href = $this->_new_arg_entry($fh_name) ;
					$arg_names_href->{$fh_name} = $href ;
					
					# set value
					$args_href->{$fh_name} = [\*STDIN] ;

					$args_href->{$name} ||= [] ;
					push @{$args_href->{$name}}, 'STDIN' ;
					
					next ;
				}
			}
		}
		
		
		## Check all of the values
		foreach my $val (@values)
		{
			
			++$idx ;
			my $arg_optional = $arg_names_href->{$name}{'optional'} ;
			
$this->_dbg_prt([" + checking $name value=$val, type=$type, optional=$arg_optional ..\n"], 2) ;
		
			# First check that an arg has been specified
			if ($idx >= scalar(@$argv_aref))
			{
				# Ignore if * type -OR- optional
				if ( ($arg_names_href->{$name}{'dest_type'} ne '*') && (! $arg_optional) )
				{
					$this->_complain_usage_exit("Must specify input $type\"$name\"") ;
				}
			}
			
			next unless $val ;
			
			## Input
			if ($arg_names_href->{$name}{'direction'} eq 'i')
			{
	$this->_dbg_prt([" + Check $val for existence\n"], 2) ;
				
				## skip checks if optional and no value specified (i.e. do the check if a default is specified)
				if (!$arg_optional && $val)
				{
					# File check
					if ( ($arg_names_href->{$name}{'type'} eq 'f') && (! -f $val) )
					{
						$this->_complain_usage_exit("Must specify a valid input filename for \"$name\"") ;
					}
					# Directory check
					if ( ($arg_names_href->{$name}{'type'} eq 'd') && (! -d $val) )
					{
						$this->_complain_usage_exit("Must specify a valid input directory for \"$name\"") ;
					}
				}
				else
				{
	$this->_dbg_prt([" + Skipped checks opt=$arg_optional val=$val bool=".."...\n"], 2) ;
					
				}	
				
				
				## File open
				if ($open_in && ($arg_names_href->{$name}{'type'} eq 'f'))
				{
					open my $fh, "<$val" ;
					if ($fh)
					{
						push @$fh_aref, $fh ;
						
						if ($arg_names_href->{$name}{'mode'} eq 'b')
						{
							binmode $fh ;
						}
	
						# Create new entry
						my $href = $this->_new_arg_entry($fh_name) ;
						$arg_names_href->{$fh_name} = $href ;
						
						# set value
						if ($arg_names_href->{$name}{'dest_type'})
						{
							$args_href->{$fh_name} ||= [] ;
							push @{$args_href->{$fh_name}}, $fh ;
						}
						else
						{
							$args_href->{$fh_name} = $fh ;
						}
					}
					else
					{
						$this->_complain_usage_exit("Unable to read file \"$val\" : $!") ;
					}
				}
			}
			
			## Output
			if ($open_out)
			{
				if (($arg_names_href->{$name}{'direction'} eq 'o') && ($arg_names_href->{$name}{'type'} eq 'f'))
				{
					my $mode = '>' ;	
					if ($arg_names_href->{$name}{'append'})
					{
						$mode .= '>' ;
					}
					
					open my $fh, "$mode$val" ;
					if ($fh)
					{
						push @$fh_aref, $fh ;
						
						if ($arg_names_href->{$name}{'mode'} eq 'b')
						{
							binmode $fh ;
						}
	
						# Create new entry
						my $href = $this->_new_arg_entry($fh_name) ;
						$arg_names_href->{$fh_name} = $href ;
						
						# set value
						$args_href->{$fh_name} = $fh ;
					}
					else
					{
						my $md = $arg_names_href->{$name}{'append'} ? 'append' : 'write' ;
		
						$this->_complain_usage_exit("Unable to $md file \"$val\" : $!") ;
					}
				}
			}
		}
	}
		
}

#-----------------------------------------------------------------------------

=item B< close_args() >

If any arguements cause files/devices to be opened, this shuts them down

=cut

sub close_args 
{
	my $this = shift ;

	# File handles
	my $fh_aref = $this->_fh_list() ;
	
	foreach my $fh (@$fh_aref)
	{
		close $fh ;
	}

}



#----------------------------------------------------------------------------

=item B<get_args()>

Finish any args processing and return the arguments list

=cut

sub get_args
{
	my $this = shift ;

	# save @ARGV
	$this->argv(\@ARGV) ;
	my @args = @ARGV ;

	# Copy values over
	$this->_process_argv() ;

	my %args ;
	
	%args = $this->arg_hash() ;
$this->_dbg_prt(["Args before expand : hash=", \%args]) ;

	# Expand the args variables
	$this->_expand_args() ;

	# Set arg list
	my @arg_array ;
	%args = $this->arg_hash() ;
	my $arg_list = $this->arg_names() ;
	foreach my $name (@$arg_list)
	{
		push @arg_array, $args{$name} ;
	}
	$this->_arg_list(\@arg_array) ;


	# return arglist
	return $this->arg_list ;
}

#----------------------------------------------------------------------------

=item B<arg_entry($arg_name)>

Returns the HASH ref of arg if name is found; undef otherwise

=cut

sub arg_entry
{
	my $this = shift ;
	my ($arg_name) = @_ ;

	my $arg_names_href = $this->_arg_names_hash() ;
	my $arg_href ;
	if (exists($arg_names_href->{$arg_name}))
	{
		$arg_href = $arg_names_href->{$arg_name} ;
	}
	return $arg_href ;
}


#----------------------------------------------------------------------------

=item B<args_values_hash()>

Returns the args values HASH reference.

=cut

sub args_values_hash 
{
	my $this = shift ;

	my $args_href = $this->_args() ;
	my $args_names_href = $this->_arg_names_hash() ;

	# get args
	my %values ;
	foreach my $arg (keys %$args_names_href)
	{
		$values{$arg} = $args_href->{$arg} if defined($args_href->{$arg}) ;
	}

	return \%values ;
}

#----------------------------------------------------------------------------

=item B<args_values_set($values_href)>

Sets the args values based on the values in the HASH reference B<$values_href>.

=cut

sub args_values_set 
{
	my $this = shift ;
	my ($values_href) = @_ ;

	my $args_href = $this->_args() ;
	my $args_names_href = $this->_arg_names_hash() ;

	## Update
#	foreach my $arg (keys %$args_names_href)
#	{
#		$args_href->{$arg} = $values_href->{$arg} if defined($args_href->{$arg}) ;
#	}

	# Cycle through
	my $names_aref = $this->arg_names() ;
	foreach my $arg (@$names_aref)
	{
		if ( defined($args_href->{$arg}) )
		{
			my $arg_entry_href = $this->arg_entry($arg) ;
			
			$args_href->{$arg} = $values_href->{$arg} ;
			$arg_entry_href->{'default'} = $values_href->{$arg} ;
		}
	}
}

# ============================================================================================
# PRIVATE METHODS
# ============================================================================================

#----------------------------------------------------------------------------
#
#=item B<_expand_args()>
#
#Expand any variables in the args
#
#=cut
#
sub _expand_args 
{
	my $this = shift ;

	my $args_href = $this->_args() ;
	my $args_names_href = $this->_arg_names_hash() ;

	# get args
	my %values ;
	foreach my $arg (keys %$args_names_href)
	{
		$values{$arg} = $args_href->{$arg} if defined($args_href->{$arg}) ;
	}

	# get replacement vars
	my @vars ;
	my $app = $this->app ;
	if ($app)
	{
		my %app_vars = $app->vars ;
		push @vars, \%app_vars ;
		my %opt_vars = $app->options() ;
		push @vars, \%opt_vars ;
	}
	push @vars, \%ENV ;
	
#	## expand
#	$this->expand_keys(\%values, \@vars) ;
		
	## Update
	foreach my $arg (keys %$args_names_href)
	{
		$args_href->{$arg} = $values{$arg} if defined($args_href->{$arg}) ;
	}
	
}

#----------------------------------------------------------------------------
#
#=item B<_process_argv()>
#
#Processes the @ARGV array
#
#=cut
#
sub _process_argv
{
	my $this = shift ;

	my $argv_aref = $this->argv() ;
	my @args = @$argv_aref ;
	$argv_aref = [] ;		# clear our args, rebuild the list as we process them
	my $idx = 0 ;

$this->_dbg_prt(["_process_argv() : args=", \@args]) ;
	
	# values
	my $args_href = $this->_args() ;
	# details
	my $args_names_href = $this->_arg_names_hash() ;
	
	my $dest_type ;
	my $arg_list = $this->arg_names() ;
	foreach my $name (@$arg_list)
	{
		if ($args_names_href->{$name}{'dest_type'}) 
		{
			# set value
			$args_href->{$name} = [] ;	
		}	
	}
				
	foreach my $name (@$arg_list)
	{
		last unless @args ;
		my $arg = shift @args ;
		
		# set value
		$args_href->{$name} = $arg ;	
		push @$argv_aref, $arg ;
		
		# get this dest type
		$dest_type = $name if $args_names_href->{$name}{'dest_type'} ;

		++$idx ;
	}

	# If last arg specified as ARRAY, then convert  value to ARRAY ref
	if ($dest_type)
	{
		my $arg = $args_href->{$dest_type} ;
		$args_href->{$dest_type} = [] ;
		pop @$argv_aref ;

		## Handle wildcards (mainly to cope with Windoze)
		if ($arg =~ m/[\*\?]/)
		{
			my @files = glob("$arg") ;
			if (@files)
			{
				push @{$args_href->{$dest_type}}, @files ;
				push @$argv_aref, @files ;
				$arg = undef ;		
			}
		}

		if ($arg)
		{
			push @{$args_href->{$dest_type}}, $arg ;			
			push @$argv_aref, $arg ;
		}
		
	}

$this->_dbg_prt(["_process_argv() : args hash (so far)=", $args_href, "args now=", \@args]) ;
	
	# If there are any args left over, handle them
	foreach my $arg (@args)
	{
		# If last arg specified as ARRAY, then just add all ARGS
		if ($dest_type)
		{
			## Handle wildcards (mainly to cope with Windoze)
			if ($arg =~ m/[\*\?]/)
			{
				my @files = glob("$arg") ;
				if (@files)
				{
					push @{$args_href->{$dest_type}}, @files ;
					push @$argv_aref, @files ;
					$arg = undef ;		
				}
			}
			
			if ($arg)
			{
				push @{$args_href->{$dest_type}}, $arg ;			
				push @$argv_aref, $arg ;
			}
		}
		else
		{
			push @$argv_aref, $arg ;

			# create name
			my $name = sprintf "arg%d", $idx++ ;		
			
			# Create new entry
			my $href = $this->_new_arg_entry($name) ;
			$args_names_href->{$name} = $href ;
			
			# save arg in specified order
			push @$arg_list, $name ; 
	
			# set value
			$args_href->{$name} = $arg ;
			
		}

	}

	$this->argv($argv_aref) ;
}

#----------------------------------------------------------------------------
#
#=item B<_process_arg_spec($arg_spec)>
#
#Processes the arg specification string, returning:
#
#	($name, $arg_spec, $spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode)
#
#=cut
#
sub _process_arg_spec 
{
	my $this = shift ;
	my ($arg_spec) = @_ ;

$this->_dbg_prt(["arg: _process_arg_spec($arg_spec)"], 2)   ;

	my $developer_only = 0 ;

	# If arg starts with start char then remove it
	$arg_spec =~ s/^[\-\+\*]// ;
	
	# Get arg name
	my $name = $arg_spec ;
	if ($arg_spec =~ /[\'\"](\w+)[\'\"]/)
	{
		$name = $1 ;
		$arg_spec =~ s/[\'\"]//g ;
	}
	$name =~ s/\=.*$// ;

	my $spec = $arg_spec ;
	my $arg = "";
	if ($spec =~ s/\=(.*)$//)
	{
		$arg = $1 ;
	}
$this->_dbg_prt(["_process_arg_spec() set: pod spec=$spec arg=$arg\n"], 2) ;
	
	my $dest_type = "" ;
	if ($arg =~ /([\@\*])/i)
	{
		$dest_type = $1 ;
	}			
	
	my $arg_type = "" ;
	if ($arg =~ /([sfd])/i)
	{
		$arg_type = $1 ;
		if ($arg_type eq 's')
		{
			$spec .= " <string>" ;
		}
		elsif ($arg_type eq 'f')
		{
			$spec .= " <file>" ;
		}
		elsif ($arg_type eq 'd')
		{
			$spec .= " <dir>" ;
		}
	}

	my $arg_direction = "i" ;
	my $arg_append = "" ;
	if ($arg =~ /(i|<)/i)
	{
		$arg_direction = 'i' ;
		$spec .= " <input>" ;
	}
	elsif ($arg =~ /a|>>/i)
	{
		$arg_direction = 'o' ;
		$arg_append = "a" ;
		$spec .= " <output>" ;
	}
	elsif ($arg =~ /(o|>)/i)
	{
		$arg_direction = 'o' ;
		$spec .= " <output>" ;
	}
	
	my $arg_optional = 0 ;
	if ($arg =~ /\?/i)
	{
$this->_dbg_prt(["_process_arg_spec() set: optional\n"], 2) ;
		$arg_optional = 1 ;
	}	

	my $arg_mode = "" ;
	if ($arg =~ /b/i)
	{
		$arg_mode = 'b' ;
	}
	
$this->_dbg_prt(["_process_arg_spec() set: final pod spec=$spec arg=$arg\n"], 2) ;
				
	return ($name, $arg_spec, $spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode) ;
}


#----------------------------------------------------------------------------
#
#=item B<_new_arg_entry($name, $arg_spec, $summary, $description, $default_val, $pod_spec, $arg_type, $arg_direction, $dest_type, $optional, $arg_append, $arg_mode)>
#
#Create a new HASH with the specified values. Sets the values to defaults if not specified
#
#=cut
#
sub _new_arg_entry
{
	my $this = shift ;
	my ($name, $arg_spec, $summary, $description, $default_val, $pod_spec, $arg_type, $arg_direction, $dest_type, $optional, $arg_append, $arg_mode) = @_ ;
	
	$summary ||= "Arg" ;
	$description ||= "" ;
	$arg_type ||= "s" ;
	$arg_direction ||= "i" ;
	$dest_type ||= "" ;
	$optional ||= 0 ;
	$arg_spec ||= "$arg_type" ;
	$arg_append ||= "" ;
	$arg_mode ||= "" ;
	my $entry_href = 
	{
		'name'=>$name, 
		'spec'=>$arg_spec, 
		'summary'=>$summary, 
		'description'=>$description,
		'default'=>$default_val,
		'pod_spec'=>$pod_spec,
		'type' => $arg_type,
		'direction' => $arg_direction,
		'dest_type' => $dest_type,
		'optional' => $optional,
		'append' => $arg_append,
		'mode' => $arg_mode,
	} ;

	return $entry_href ;
}

#----------------------------------------------------------------------------
# Output message, usage info, then exit
sub _complain_usage_exit
{
	my $this = shift ;
	my ($complain, $exit_code) = @_ ;

	print "Error: $complain\n" ;
	$this->app->usage() ;
	$this->app->exit( $exit_code || 1 ) ;
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


