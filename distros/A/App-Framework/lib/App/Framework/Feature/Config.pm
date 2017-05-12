package App::Framework::Feature::Config ;

=head1 NAME

App::Framework::Feature::Config - Configuration file read/write

=head1 SYNOPSIS

  use App::Framework '+Config' ;


=head1 DESCRIPTION

Provides a standard interface for reading/writing application configuration files. When this feature is included into an application, it attempts to read
a configuration file for the application (which may be stored in one of severeal places). If found, the configuartion file is processed and may update
the application options (see L<App::Framework::Feature::Options>).

Also, an application may create one or more extra instances of the feature to read addtional configuration files.


=head2 Configuration File Definition

Configuration files are text files containing variable / value pairs. Optionally these variable/value pairs may be gouped into 'sections' (see L</sections>).


=head3 Simple format

The simplest format consists of an optional description line followed immediately by a variable/value setting:

    # description
    var=value

(NOTE: There can be no empty lines between the description "comment" and the variable).

=head3 Extended format

An alternative to the simple format is as shown below. This contains additional information useful for checking the value setting.

    ## Summary:  Configuration for Apache 2
    ## Type:     s
    #
    # Here you can name files, separated by spaces, that should be Include'd from 
    # httpd.conf. 
    #
    # This allows you to add e.g. VirtualHost statements without touching 
    # /etc/apache2/httpd.conf itself, which makes upgrading easier. 
    #
    apache_include_files="mod_dav"

The lines prefixed by ## are extra information about the variable and are used to specify a summary, and a variable
type. The extra information prefixed by # is used as the description. The above example will be
shown in the application man page as:

    -apache_include_files <string> [Default: "mod_dav"]
            Config option:Here you can name files, separated by spaces, that
            should be Include'd from httpd.conf. This allows you to add e.g.
            VirtualHost statements without touching /etc/apache2/httpd.conf
            itself, which makes upgrading easier.

Any configuration variables specified in this manner will automatically be put into the application's options, but will also be available
via the application's 'Config' feature.


=head3 Sections

Each section is defined by a string contained within '[]'. Where there are multiple sections with the same name, they are added to an array. All variables
defined before the sections are treated as "global".

    global=string

    [top]
    a=1
    
    [instance]
    a=11

    [instance]
    a=22

The above example will be stored as the HASH:

    {
        global => 'string'
        top => [
            {
                a => 1
            }
        ]
        instance => [
            {
                a => 11
            },
            {
                a => 22
            }
        ],
    }

Even if a section has only one instance, it is always stored as an array.


=head2 Configuration as Options

As stated above, any variables defined in the configuration file before the sections are treated as "global" (see L</Sections>). These global variables
have the additional property that they are automatically treated like options definitions (see L<App::Framework::Feature::Options>). 

This means that the global variables are indistinguishable from options (in fact all of the options variables appear in the global area of the configurations and
vice versa). Also, you do not need to specify options in the application script - you can just define them once in the configuration file (although see L</Writing>).

=head2 File Paths

The configuration file is searched for using the path specification. This path is actually one or more paths, specified 
in the order in which to search for the configuration file. The search is stopped as soon as the first valid file is found.

The application configuration search path is set to the following default, unless it is over-ridden by either the application
script or by the user (via command line options):

=over 4

=item * $HOME/$app_dir

User-specific configuration. $HOME is replaced with the user's home directory, and $app_dir is replaced by ".I<name>" (or "I<name>" on Windows)
where I<name> is the name of the script. 

This allows users to set up their own settings.

=item * $SYSTEM/$name

System configuration. $SYSTEM is replaced with "/etc" (or "C:" on Windows), and $name is replaced by the name of the script.

This allows sysadmins to set up a common set of settings.

=item * $app_path/config

Application-specific configuration. $app_path is replaced by the path to the installed script.

This allows script developers to bundle their settings with the installed script.

=back 

As an example, the script 'test_script' installed on a Linux under '/usr/local/bin' will, by default, have the following search path:

    $HOME/.test_script
    /etc/test_script
    /usr/local/bin/config 

In addition to the search path described above, there is also a write search path. This path is searched until a file 
(and it's path) can be written to by the script user. It is set, by default, to:

=over 4

=item * $HOME/$app_dir

User-specific configuration. $HOME is replaced with the user's home directory, and $app_dir is replaced by ".I<name>" (or "I<name>" on Windows)
where I<name> is the name of the script. 

This allows users to set up their own settings.

=item * $SYSTEM/$name

System configuration. $SYSTEM is replaced with "/etc" (or "C:" on Windows), and $name is replaced by the name of the script.

This allows sysadmins to set up a common set of settings.

=back 

(i.e. the same as the read path, but without the application-bundle directory).

Uses L<App::Framework::Base::SearchPath> to provide the path search. 


=head2 Creating Config Files

You can, of course, just write your config files from scratch. Alternatively, if you predominantly use "global" settings, then you specify
them as application options (L<App::Framework::Feature::Options>). Run your script with '-config_write' and it will automatically create 
a formatted configuration file (see L</ADDITIONAL COMMAND LINE OPTIONS> for other command line settings). 

=head2 Addtional Config Instances

In addition to having the application tied in with it's own configuration file, you can create multiple extra configuration files and read/write
then using this feature. To do this, create a new App::Framework::Feature::Config object instance per configuration file. You can then access
the contents of the file using the object's methods.

For example:

    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
     
        ## use application config object to create a new one
        my $new_cfg = $app->feature('Config')->new(
            'filename'        => 'some_file.conf',
            'path'            => '$HOME,/etc/new_config',
            'write_path'    => '$HOME',
        ) ;
        $new_cfg->read() ;
    
        # do stuff with configuration
        ...
     
        # (debug) show configuration
        $app->prt_data("Readback config=", $new_cfg->config) ;
         
        ## write out file
        $new_cfg->write() ;
    }


=head2 Raw Configuration HASH

Configuration files are stored in a HASH, where the keys are the variable names and the values are a HASH of information for 
that variable:

    'summary'        => Summary string
    'default'        => Default value
    'description'    => Description string
    'type'           => Variable option type (s, i, f)
    'value'          => Variable value
    

=cut

use strict ;

our $VERSION = "0.11" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Feature ;
use App::Framework::Base ;
use App::Framework::Base::SearchPath ;

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

=item B<filename> - Name of config file

User-specified config filename. This is searched for using the search path


=item B<path> - search path

A comma seperated list (in scalar context), or an ARRAY ref list of paths to be searched (for a file).

=item B<write_path> - search path for writing

A comma seperated list (in scalar context), or an ARRAY ref list of paths to be searched (for a file) when writing. If not set, then
B<path> is used.

=item B<file_path> - configuration file path

Created when config file is read. Full path of configuration file accessed in last read or write.  


=item B<sections> - section names list

Created when config file is read. ARRAY ref list of any section names.  


=item B<config> - configuration HASH ref

Created when config file is read. This is a HASH ref to the raw configuration file entries  

=back

=cut

my %FIELDS = (
	# user settings
	'filename' 		=> undef,
	
	# Created during execution
	'configuration'	=> {},
	'file_path'		=> undef,
	'sections'		=> [],
		
	'_search_path'	=> undef,
) ;


=head2 ADDITIONAL COMMAND LINE OPTIONS

This feature adds the following additional command line options to any application:

=over 4

=item B<-config_path> - Config file path

Comma/semicolon separated list of search paths for the config file

=item B<-config_writepath> - Config file write path

Comma/semicolon separated list of paths for writing the config file. Uses -config_path setting if not specified.

=item B<-config> - Config filename

Specify the configuration filename to use

=item B<-config_write> - Write config file

When specified, writes the configuration file using the write path

=back

=cut


my $OPT_CFGPATH = "config_path" ;
my $OPT_CFGWRPATH = "config_writepath" ;
my $OPT_CFG = "config" ;
my $OPT_CFGWR = "config_write" ;

my $OPT_CFGPATH_AREF = 
	["$OPT_CFGPATH=s",		'Config file path', 		'Comma/semicolon separated list of search paths for the config file', ] ;
my $OPT_CFGWRPATH_AREF = 
	["$OPT_CFGWRPATH=s",	'Config file write path', 	'Comma/semicolon separated list of paths for writing the config file', ] ;
my $OPT_CFG_AREF = 
	["$OPT_CFG=s",			'Config file name', 		'Config filename'] ;
my $OPT_CFGWR_AREF = 
	["$OPT_CFGWR",			'Write config file', 		'When specified, writes the configuration file using the write path'] ;

# Set of default options
my @EXTRA_OPTIONS = (
	$OPT_CFGPATH_AREF,
	$OPT_CFGWRPATH_AREF,
	$OPT_CFG_AREF,
	$OPT_CFGWR_AREF,
) ;

my @CONFIG_OPTIONS = (
	$OPT_CFGPATH,
	$OPT_CFGWRPATH,
	$OPT_CFG,
	$OPT_CFGWR,
) ;

#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================


=item B< new([%args]) >

Create a new Config object.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;
	
	my $class = ref($obj) || $obj ;

	# create search path object
	my $search_obj = App::Framework::Base::SearchPath->new(%args) ;
	
	# Create object
	my $this = $class->SUPER::new(%args,
		'priority'		=> $App::Framework::Base::PRIORITY_SYSTEM + 15,		# needs to be after options, but before data
		'registered'	=> [qw/go_entry getopts_entry application_entry/],
		'_search_path'	=> $search_obj,
	) ;
	
	## Map the search path object's methods into this object
	foreach my $method (qw/path write_path read_filepath write_filepath/)
	{
		no warnings 'redefine';
		no strict 'refs';
		
		*{ __PACKAGE__."::${method}"} = sub {  
			my $this = shift ;
			$this->_dbg_prt( ["Config: calling searchpath->$method() ", \@_] ) ;			
			return $search_obj->$method(@_) ;
		};
	}
	
	## If associated with an app, then add the app's variables to the search path
	my $app = $this->app ;
	if ($app)
	{
		## only interested in scalar values
		my %vars = $app->vars() ;
		my %app_vars ;
		foreach my $var (keys %vars)
		{
			$app_vars{$var} = $vars{$var} if !ref($vars{$var}) || ref($vars{$var}) eq 'SCALAR' ;
		}
		$search_obj->env(\%app_vars) ;
	}

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

Initialises the Config object class variables.

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

#----------------------------------------------------------------------------

=item B<set(%args)>

Overrides the parent 'set()' method to send the parameters off to the L<App::Framework::Base::SearchPath> object
as well as itself.

=cut

sub set
{
	my $this = shift ;
	my (%args) = @_ ;

	if (keys %args)
	{

$this->_dbg_prt( ["settings args = ", \%args] ) ;

		# send to search path obj (if created yet)
		my $search_obj = $this->_search_path ;
$this->_dbg_prt( ["settings args on search_obj\n"] ) if $search_obj ;
		$search_obj->set(%args) if $search_obj ;
				
		# handle the args
		$this->SUPER::set(%args) ;
	}

}

#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================


#-----------------------------------------------------------------------------

=item B< go_entry() >

Application hook: When application calls go() set up config options.

=cut

sub go_entry
{
	my $this = shift ;

$this->_dbg_prt( ["Config: go_entry()\n"] ) ;

	## must be under application to get here...
	my $app = $this->app ;

	my $home = $ENV{'HOME'} || $ENV{'USERPROFILE'} || "$ENV{'HOMEDRIVE'}$ENV{'HOMEPATH'}" ;
	my $app_name = $app->name ;
	my $app_path = $app->progpath ;
	
	my $app_dir = ".$app_name" ;
	my $sys = "/etc" ;
	if ($^O =~ /MSWin/)
	{
		$app_dir = "$app_name" ;
		$sys = "c:/" ;
	}
	
	## Set up write path, if not already set
	my $write_path = $this->write_path() ;
$this->_dbg_prt( ["current write path=$write_path\n"] ) ;
	unless ($write_path)
	{
$this->_dbg_prt( ["set default write path\n"] ) ;
		$this->write_path("$home/$app_dir;$sys/$app_name") ;
	}
	
	## Set up search path, if not already set
	my $path = $this->path() ;
$this->_dbg_prt( ["current path=$path\n"] ) ;
	unless ($path)
	{
$this->_dbg_prt( ["set default path\n"] ) ;
		$this->path("$home/$app_dir;$sys/$app_name;$app_path/config") ;
	}
	
	## Set up filename, if not already set
	my $filename = $this->filename() || '' ;
$this->_dbg_prt( ["current filename=$filename\n"] ) ;
	unless ($filename)
	{
$this->_dbg_prt( ["set default filename\n"] ) ;
		$this->filename("$app_name.conf") ;
	}

	# Set defaults
	$OPT_CFGPATH_AREF->[3] = $this->path() ;
	$OPT_CFG_AREF->[3] = $this->filename() ;
	$OPT_CFGWRPATH_AREF->[3] = $this->write_path() ;

	## Set options
$this->_dbg_prt( ["$this go_entry - append_options\n"] ) ;
$this->dump_callstack()  if $this->debug ;
	$app->feature('Options')->append_options(\@EXTRA_OPTIONS) ;

}


#-----------------------------------------------------------------------------

=item B< getopts_entry() >

Application hook: When application calls getopts() initialise the object and read config.

=cut

sub getopts_entry
{
	my $this = shift ;

$this->_dbg_prt( ["Config: getopts_entry()\n"] ) ;

	## must be under application to get here...
	my $app = $this->app ;

	## do first pass at getting options
	my @saved_argv = @ARGV ;

	## Allow any config command line options through, otherwise just get option defaults
	@ARGV=() ;
	for (my $argc=0; $argc < scalar(@saved_argv); ++$argc)
	{
		if ($saved_argv[$argc] =~ m/^\-($OPT_CFGPATH|$OPT_CFGWRPATH|$OPT_CFG)$/)
		{
			push @ARGV, $saved_argv[$argc] ;
			push @ARGV, $saved_argv[++$argc] ;
		}
	}

	# Parse options using GetOpts
	my $opt = $app->feature('Options') ;
	my $ok = $opt->get_options() ;

	# If ok, we can continue...
	if ($ok)
	{
		## Now got the actual config file path we want to use (either from latest options or from command line)...
		
		## Get filename & search path
		my $filename = $opt->option($OPT_CFG) ;
		my $path = $opt->option($OPT_CFGPATH) ;
		my $wr_path = $opt->option($OPT_CFGWRPATH) ;

		## update config to reflect latest settings
		$this->path($path) ;
		$this->filename($filename) ;
		$this->write_path($wr_path) ;

$this->_dbg_prt( ["Config: options path=$path filename=$filename write path=$wr_path\n"] ) ;
$this->_dbg_prt( ["Config: current path=",$this->path," filename=",$this->filename, " write path=",$this->write_path,"\n"] ) ;

		## read config
		$this->read() ;
		
		my @new_options ;

my $complete_config = $this->configuration ;
$this->_dbg_prt( ["Config: config=", $complete_config] ) ;
		
		## Set default values in options based on the config file
		my %config = $this->get_raw_hash() ;
		
$this->_dbg_prt( ["Config: top-level hash=", \%config] ) ;
		foreach my $field (keys %config)
		{
			my $default = $config{$field}{'value'} || $config{$field}{'default'} ;
			my $opt_href = $opt->modify_default($field, $default) ;
			
			# if not got this option, need to add it
			unless ($opt_href)
			{
				#  [ <option spec>, <option summary>, <option description> ]
				my $spec = "$field" ;
				$spec .= "=$config{$field}{type}" if $config{$field}{type} ;
				
				my $summary = $config{$field}{'summary'} ;
				my $description = "" ;
				$description = "Config option:" . $config{$field}{'description'} if $config{$field}{'description'} ;
				
				push @new_options, [$spec, $summary, $description, $default] ;
			}
		}
		
		## append new options
		if (@new_options)
		{
			$opt->append_options(\@new_options) ;
		}
	}
	
	# restore args and allow Options feature to process them properly
	@ARGV = @saved_argv ;

}

#-----------------------------------------------------------------------------

=item B< application_entry() >

Application hook: When application calls application() check options.

=cut

sub application_entry
{
	my $this = shift ;

$this->_dbg_prt( ["Config: application_entry()\n"] ) ;

	## must be under application to get here...
	my $app = $this->app ;
	my $opt = $this->app->feature('Options') ;

	my $config_href = $this->configuration ;

	## Update config from options
	my $order=1 ;
	my $options_fields_aref = $opt->option_names() ;
	foreach my $option_name (@$options_fields_aref)
	{
		my $option_entry_href = $opt->option_entry($option_name) ;

		# skip developer options
		next if $option_entry_href->{developer} ;

		# skip help options
		## Remove all 'Pod' options
		next if $option_entry_href->{'owner'} =~ m/::Pod$/ ;
			
$this->_dbg_prt( [" + CFG Option=$option_name\n"] ) ;
			
		# copy option settings
		if (exists($config_href->{$option_name}))
		{
$this->_dbg_prt( [" + + Already got option in config: ", $config_href->{$option_name}, "Option entry: ", $option_entry_href] ) ;

			# update value
			$config_href->{$option_name}{'value'} = $opt->option($option_name) ;
			foreach my $field (qw/summary description default/)
			{
				$config_href->{$option_name}{$field} = $option_entry_href->{$field}
					if !defined($config_href->{$option_name}{$field}) ;
			}
			my $type = $option_entry_href->{type} ;
			$type = $option_entry_href->{dest_type} if $option_entry_href->{dest_type} ;
			$config_href->{$option_name}{type} = $type
				if !defined($config_href->{$option_name}{type}) ;
			
			
		}
		else
		{
$this->_dbg_prt( [" + + Creating new config entry\n"] ) ;

			my $type = $option_entry_href->{type} ;
			$type .= $option_entry_href->{dest_type} if $option_entry_href->{dest_type} ;
			
			$config_href->{$option_name} = $this->_new_cfg(
				$option_name,
				$opt->option($option_name),
				$option_entry_href->{summary},
				$option_entry_href->{description},
				$type,
				$option_entry_href->{default},
				$order++,
			) ;
		}
	}

$this->_dbg_prt( ["write config option. Updated config=", $config_href] ) ;
		
	## update
	$this->configuration($config_href) ;

	
	## Handle special options
	if ($opt->option($OPT_CFGWR))
	{

$this->_dbg_prt( ["write config option. Current config=", $config_href] ) ;

		## write out config file
		$this->write() ;
	}
	
}

#----------------------------------------------------------------------------

=item B< config([%args]) >

Returns the config object. If %args are specified they are used to set the L</FIELDS>

=cut

sub config
{
	my $this = shift ;
	my (%args) = @_ ;

	$this->set(%args) if %args ;
	return $this ;
}

#----------------------------------------------------------------------------

=item B< Config([%args]) >

Alias to L</config>

=cut

*Config = \&config ;

#----------------------------------------------------------------------------

=item B< read([%args]) >

Read in the config file (located somewhere in the searchable path). Expects the filename and path
fields to already have been set. Optionally can specify these setting as part of the %args hash.

Updates the field 'file_path' with the full path to the read config file.

Returns the top-level HASH ref.

=cut

sub read
{
	my $this = shift ;
	my (%args) = @_ ;

$this->_dbg_prt( ["Config: read() args=", \%args] ) ;
	
	$this->set(%args) ;
	
	## Read the file - or barf

$this->_dbg_prt( ["calling read_filepath()...\n"] ) ;
	
	# get file path
	my $read_filepath = $this->read_filepath($this->filename) ;

$this->_dbg_prt( ["Config: read() file=$read_filepath\n"] ) ;
	
	# if none found, just stop
	if ($read_filepath)
	{
		$this->file_path($read_filepath) ;
		
		# process file into hash
		my %new_config = $this->_process($read_filepath) ;
		
		# add to existing contents
		$this->add_config(%new_config) ;
		
	}
	
	# return top-level hash
	return $this->get_hash() ;
}

#----------------------------------------------------------------------------

=item B< write() >

Writes the configuration information to the specified file.

Updates the field 'file_path' with the full path to the written config file.

=cut

sub write
{
	my $this = shift ;

	## write out config - or barf
	
	# get file path
	my $write_filepath = $this->write_filepath($this->filename) ;
	$this->file_path($write_filepath) ;
	
	# write out config
	$this->_write($write_filepath) ;
}


#----------------------------------------------------------------------------

=item B< add_config(%config) >

Adds the contents of the specified HASH to the current configuration settings.

=cut

sub add_config
{
	my $this = shift ;
	my (%config) = @_ ;

	my $config_href = $this->configuration ;

	## merge hashes
	my %merged ;
	foreach my $href ($config_href, \%config)
	{
		while (my ($k, $v) = each %$href)
		{
			$merged{$k} = $v ;
		}
	}

	$this->configuration(\%merged) ;
}

#----------------------------------------------------------------------------

=item B< clear_config() >

Clear out the current configuration settings.

=cut

sub clear_config
{
	my $this = shift ;

	$this->configuration({}) ;
}

#----------------------------------------------------------------------------

=item B< get_hash([$name]) >

Returns a "flat" HASH (of variable/value pairs) where any arrays are removed. 
If the I<$name> is specified, returns the HASH that the named key refers to, 
unrolling it if it is an array.

Returns an empty HASH if I<$name> does not exist.

=cut

sub get_hash
{
	my $this = shift ;
	my ($name) = @_ ;

	## Get raw entries
	my %raw = $this->get_raw_hash($name) ;
	
	## convert
	my %config = $this->raw_to_vals(\%raw) ;

	return %config ;
}

#----------------------------------------------------------------------------

=item B< get_array([$name]) >

Returns an ARRAY of HASHes of variable/value pairs. If the I<$name> is specified, returns
the ARRAY that the named key refers to. In either case, if the item is not 
an array, then it is rolled into a single entry ARRAY.

Returns an empty ARRAY if I<$name> does not exist.

=cut

sub get_array
{
	my $this = shift ;
	my ($name) = @_ ;
	
	$name ||= '' ;
	my @config ;
	
	## Get raw entries
	my @to_copy = $this->get_raw_array($name) ;

$this->_dbg_prt( ["get_array($name) to_copy=", \@to_copy] ) ;

	
	## copy values
	foreach my $href (@to_copy)
	{
		my %config = $this->raw_to_vals($href) ;
		push @config, \%config ;
	}

$this->_dbg_prt( ["get_array($name) - array=", \@config] ) ;
	
	return @config ;
}


#----------------------------------------------------------------------------

=item B< get_raw_hash([$name]) >

Returns a "flat" HASH (containing full config entry) where any arrays are removed. 
If the I<$name> is specified, returns the HASH that the named key refers to, 
unrolling it if it is an array.

Returns an empty HASH if I<$name> does not exist.

=cut

sub get_raw_hash
{
	my $this = shift ;
	my ($name) = @_ ;

	my %config ;
	
	# start at top
	my $config_href = $this->configuration ;

	# see if we want a sub-branch
	if ($name && exists($config_href->{$name}))
	{
		$config_href = $config_href->{$name} ;
	}

	# Flatten array - copy over just those key/scalar pairs
	#	instance => [
	#		{
	#			{a} => {'value'=>11, ...}
	#		},
	#		{
	#			{a} => {'value'=>22, ...}
	#		}
	#	],
	my @array = ($config_href) ;
	if (ref($config_href) eq 'ARRAY')
	{
		@array = @$config_href ;
	}
	
	# now process from this point
	foreach my $href (@array)
	{
		foreach my $key (keys %$href)
		{
			# copy over just those key/scalar pairs
			if (ref($href->{$key}) eq 'HASH')
			{
				$config{$key} = $href->{$key} ;
			}
		}
	}
	
	return %config ;
}

#----------------------------------------------------------------------------

=item B< get_raw_array([$name]) >

Returns an ARRAY of HASHes (containing full config entry). If the I<$name> is specified, returns
the ARRAY that the named key refers to. In either case, if the item is not 
an array, then it is rolled into a single entry ARRAY.

Returns an empty ARRAY if I<$name> does not exist.

=cut

sub get_raw_array
{
	my $this = shift ;
	my ($name) = @_ ;
	
	$name ||= '' ;

	# start at top
	my $config_href = $this->configuration ;

	# see if we want a sub-branch
	if ($name && exists($config_href->{$name}))
	{
		$config_href = $config_href->{$name} ;
	}
	
	# now process from this point
	my @config ;
	if (ref($config_href) eq 'ARRAY')
	{
		@config = @$config_href ;
	}
	else
	{
		@config = ($config_href) ;
	}

	return @config ;
}


#----------------------------------------------------------------------------

=item B< raw_to_vals($href) >

Given a HASH ref containing hashes of full config entries, convert into a hash
of variable/value pairs

=cut

sub raw_to_vals
{
	my $this = shift ;
	my ($href) = @_ ;
	
	# copy values
	my %config ;
	foreach my $key (keys %$href)
	{
$this->_dbg_prt( [" + key=$key\n"] ) ;
		# copy over just those key/scalar pairs
		if (ref($href->{$key}) eq 'HASH')
		{
			$config{$key} = $href->{$key}{'value'} ;
			my $val = $href->{$key}{'value'} || '';
$this->_dbg_prt( [" + $key = $val\n"] ) ;
		}
	}
		
	return %config ;
}




#============================================================================================
# PRIVATE METHODS 
#============================================================================================

#	#  TAG: authenticate_cache_garbage_interval
#	#       The time period between garbage collection across the username cache.
#	#       This is a tradeoff between memory utilization (long intervals - say
#	#       2 days) and CPU (short intervals - say 1 minute). Only change if you
#	#       have good reason to.
#	#
#	#Default:
#	# authenticate_cache_garbage_interval 1 hour
#	authenticate_cache_garbage_interval 1 hour

#	## Path:        Network/WWW/Apache2
#	## Description: Configuration for Apache 2
#	## Type:        string
#	## Default:     ""
#	## ServiceRestart: apache2
#	#
#	# Here you can name files, separated by spaces, that should be Include'd from 
#	# httpd.conf. 
#	#
#	# This allows you to add e.g. VirtualHost statements without touching 
#	# /etc/apache2/httpd.conf itself, which makes upgrading easier. 
#	#
#	APACHE_CONF_INCLUDE_FILES=""



#----------------------------------------------------------------------------
#
#=item B< _process($filename) >
#
#Read in the config file (located somewhere in the searchable path). 
#
#Returns a HASH of the config.
#
#=cut
#
sub _process
{
	my $this = shift ;
	my ($filename) = @_ ;
	my %config ;
	my %sections ;
	my @sections ;
	my $order=1 ;
		
$this->_dbg_prt( ["Config: _process($filename)\n"] ) ;

	open my $fh, "<$filename" or $this->throw_fatal("Feature:Config : unable to read file $filename : $!") ;
	my $line ;
	my %params ;
	my $href = \%config ;
	while (defined($line = <$fh>))
	{
		chomp $line ;

$this->_dbg_prt( [" + <$line>\n"] ) ;
$this->_dbg_prt( ["Params:", \%params] ) ;						

		$line =~ s/^\s+// ;
		$line =~ s/\s+$// ;
		unless ($line)
		{
			## Empty line, see if we were creating a new entry - if so, save it
			if ($params{name})
			{
				$href->{$params{name}} = $this->_new_cfg(
					$params{name},
					undef,
					$params{summary},
					$params{description},
					$params{type},
					$params{default},
					$order++,
				) ;

			}

			# clear params ready for new entry
			foreach my $param (qw/summary description type name default/)
			{
				$params{$param} = undef ;
			}
			
			next ;
		}

		## Parameter setting
		#
		# e.g. 
		#    ## Description: Configuration for Apache 2
		#
		if ($line =~ /^##\s*([^\s:]+)(?:\s*:){0,1}(.*)/)
		{
			my ($var, $val) = ($1, $2) ;
$this->_dbg_prt( [" + Param: <$var> = <$val>\n"] ) ;

			$val =~ s/^\s+// ;
			$val =~ s/\s+$// ;
			$params{lc $var} = $val ;
		}
		
		## Description
		elsif ($line =~ /^#\s*(\S+.*)/)
		{
			$params{'description'} .= "$1\n" ;

$this->_dbg_prt( [" + Description: $params{'description'}\n"] ) ;
		}
		
		## Section
		elsif ($line =~ /^\s*\[([^\]]+)\]/)
		{
			## new section	
			my $section = $1 ;
			
			# see if already seen
			if (!exists($sections{$section}))
			{
				# Add to section list
				push @sections, $section ;
				$sections{$section} = 1 ;
			}

			# new hash for storing vars
			$href = {} ;
			
			# add to section array
			$config{$section} ||= [] ;
			push @{$config{$section}}, $href ; 
		}
		
		## var = value
		if ($line =~ /^\s*([^\s#]+)\s*=\s*(.*)/)
		{
			my ($var, $val) = ($1, $2) ;
			$val =~ s/^['"](.*)['"]$/$1/ ;
			$val =~ s/^\s+// ;
			$val =~ s/\s+$// ;

$this->_dbg_prt( ["Params before new_cfg:", \%params] ) ;						
			$href->{$var} = $this->_new_cfg(
				$var,
				$val,
				$params{summary},
				$params{description},
				$params{type},
				$params{default},
				$order++,
			) ;

			# clear params ready for new entry
			foreach my $param (qw/summary description type name default/)
			{
				$params{$param} = undef ;
			}
			
$this->_dbg_prt( [" + + $var = $val\n"] ) ;
		}
	}
	close $fh ;

	## if we were creating a new entry then save it now
	if ($params{name})
	{
		$href->{$params{name}} = $this->_new_cfg(
			$params{name},
			undef,
			$params{summary},
			$params{description},
			$params{type},
			$params{default},
			$order++,
		) ;
	}

	## save sections
	$this->sections(\@sections) ;
		
	## return complete config HASH
	return %config ;
}


#----------------------------------------------------------------------------
#
#=item B< _new_cfg($var, $value, $summary, $description, $type, $default) >
#
#Create a new config entry. 
#
#Returns a HASH of the config entry.
#
#=cut
#
sub _new_cfg
{
	my $this = shift ;
	my ($var, $value, $summary, $description, $type, $default, $order) = @_ ;

{
my ($dvar, $dvalue, $dsummary, $ddescription, $dtype, $ddefault, $dorder) = ($var||'', $value||'', $summary||'', $description||'', $type||'', $default||'', $order||'') ;
$this->_dbg_prt( ["_new_cfg($dvar) val=<$dvalue> summary=<$dsummary> desc=<$ddescription> type=<$dtype> index=<$dorder>\n"] ) ;	
}
	
	## set defaults
	
	# default to string type
	$type = 's' unless (defined($type)) ;
	
	# if either summary or description is not set, then use the other for both
	$summary ||= '' ;
	$description ||= '' ;
	if ("$description$summary")
	{
		if (!$description)
		{
			$description = $summary ;
		}
		elsif (!$summary)
		{
			$summary = $description ;
			$summary =~ s/\s+$// ;
		}
	}
	
	
$this->_dbg_prt( [" + type=<$type>\n"] ) ;	

	my $cfg_href = {
		'summary'		=> $summary,
		'default'		=> $default,
		'description'	=> $description,
		'type'			=> $type || '',
		'value'			=> $value,
		'index'			=> $order || 32767,
	} ;
	
	return $cfg_href ;
}

#----------------------------------------------------------------------------
#
#=item B< _write($write_file) >
#
#Write the config file (located somewhere in the searchable path). 
#
#=cut
#
sub _write
{
	my $this = shift ;
	my ($write_file) = @_ ;
	
$this->_dbg_prt( ["Config: _write($write_file)\n"] ) ;

	open my $fh, ">$write_file" or $this->throw_fatal("Feature:Config : unable to write file $write_file : $!") ;

	## Global options
	my %config = $this->get_raw_hash() ;
	
	# skip config options
	my $skip=0;
	foreach my $opt (@CONFIG_OPTIONS)
	{
		delete $config{$opt} ;
	}

	## write global settings
	$this->_write_vars($fh, \%config) ;
	
	## Sections
	my $sections_aref = $this->sections ;
$this->_dbg_prt( ["Section", $sections_aref] );
	foreach my $section (@$sections_aref)
	{
		my @section_vars = $this->get_raw_array($section) ;
$this->_dbg_prt( ["Section vars", \@section_vars] );

		foreach my $href (@section_vars)
		{
			print $fh "\n[$section]\n" ;
			$this->_write_vars($fh, $href) ;
		}
	}
	close $fh ;
}

#----------------------------------------------------------------------------
#
#=item B< _write_vars($fh, $href) >
#
#Write the config file variables - skipping arrays. 
#
#=cut
#
sub _write_vars
{
	my $this = shift ;
	my ($fh, $href) = @_ ;
	
$this->_dbg_prt( ["_write_vars()", $href] );


	foreach my $var (sort {$href->{$a}{'index'} <=> $href->{$b}{'index'}} keys %$href)
	{
		my $description = $href->{$var}{description} || '' ;
		my $summary = $href->{$var}{summary} || '' ;
		
		# see if we use the short form
		if ((!"$description$summary") && ($href->{$var}{type} eq 's'))
		{
			## shortest form
			print $fh "$var=$href->{$var}{value}\n" ;
		}
		elsif (($description =~ /^$summary/) && ($href->{$var}{type} eq 's'))
		{
			## shorter form
			print $fh "# $summary\n" ;
			print $fh "$var=$href->{$var}{value}\n" ;
		}
		else
		{
			$description =~ s/\n/\n# /gs ;
			my $type = $href->{$var}{type} || '' ;
			my $val = $href->{$var}{value} || '' ;
			print $fh <<WRVAR;
## Name:        $var
## Summary:     $summary
## Type:        $type
#
# $description
#
$var=$val

WRVAR
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


