package App::Framework::Core ;

=head1 NAME

App::Framework::Core - Base application object

=head1 SYNOPSIS


  use App::Framework::Core ;
  
  our @ISA = qw(App::Framework::Core) ; 


=head1 DESCRIPTION

B<The details of this module are only of interest to personality/extension/feature developers.>

Base class for applications. Expected to be derived from by an implementable class (like App::Framework::Core::Script).

=cut

use strict ;
use Carp ;

our $VERSION = "1.015" ;


#============================================================================================
# USES
#============================================================================================
use App::Framework::Base ;
use App::Framework::Settings ;

use App::Framework::Base::Object::DumpObj ;

use File::Basename ;
use File::Spec ;
use File::Path ;
use File::Copy ;

use Cwd ; 


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Base) ; 

#============================================================================================
# GLOBALS
#============================================================================================

=head2 FIELDS

The following fields should be defined either in the call to 'new()' or as part of the application configuration in the __DATA__ section:

 * name = Program name (default is name of program)
 * summary = Program summary text
 * synopsis = Synopsis text (default is program name and usage)
 * description = Program description text
 * history = Release history information
 * version = Program version (default is value of 'our $VERSION')

 * feature_config = HASH ref containing setup information for any installed features. Each feature must have it's own
                    HASH of values, keyed by the feature name
 
 * app_start_fn = Function called before app() function (default is application-defined 'app_start' subroutine if available)
 * app_fn = Function called to execute program (default is application-defined 'app' subroutine if available)
 * app_end_fn = Function called after app() function (default is application-defined 'app_end' subroutine if available)
 * usage_fn = Function called to display usage information (default is application-defined 'usage' subroutine if available)

During program execution, the following values can be accessed:

 * package = Name of the application package (usually main::)
 * filename = Full filename path to the application (after following any links)
 * progname = Name of the program (without path or extension)
 * progpath = Pathname to program
 * progext = Extension of program
 

=over 4

=cut

my %FIELDS = (
	## Object Data
	
	# User-specified
	'name'			=> '',
	'summary'		=> '',
	'synopsis'		=> '',
	'description'	=> '',
	'history'		=> '',
	'version'		=> undef,
	'feature_config'=> {},
	
	'app_start_fn'	=> undef,	
	'app_fn'		=> undef,	
	'app_end_fn'	=> undef,
	'usage_fn'		=> undef,
	
	'exit_type'		=> 'exit',
	
	# Created during init
	'package'		=> undef,
	'filename'		=> undef,
	'progname'		=> undef,
	'progpath'		=> undef,
	'progext'		=> undef,

	'feature_list'		=> [],	# all registered feature names, sorted by priority
	'_feature_list'		=> {},	# all registered features
	'_feature_methods'	=> {},	# HASH or ARRAYs of any methods registered to a feature
	
	'_required_features'	=> [qw/Data Options Args Pod/],

	'personality'		=> undef,
	'extensions'		=> [],
) ;

# Set of default options
my @BASE_OPTIONS = (
	['debug=i',			'Set debug level', 	'Set the debug level value', ],
) ;

our %LOADED_MODULES ;

our $class_debug = 0 ;


#============================================================================================

=back

=head2 CONSTRUCTOR METHODS

=over 4

=cut

#============================================================================================

=item B<new([%args])>

Create a new App::Framework::Core.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	## stop 'app' entry from being displayed in Features 
	App::Framework::Base::Object::DumpObj::exclude('app') ;
	
print "App::Framework::Core->new() class=$class\n" if $class_debug ;
	
	my $caller_info_aref = delete $args{'_caller_info'} || croak "$class must be called via App::Framework" ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	# Set up error handler
	$this->set('catch_fn' => sub {$this->catch_error(@_);} ) ;

	## Get caller information
	my ($package, $filename, $line, $subr, $has_args, $wantarray) = @$caller_info_aref ;
	$this->set(
		'package'	=> $package,
		'filename'	=> $filename,
	) ;

	## now import packages into the caller's namespace
	$this->_import() ;


	## Set program info
	$this->set_paths($filename) ;
	
	## set up functions
#	foreach my $fn (qw/app_start app app_end usage/)
	foreach my $fn_aref (
		# prefered
		['app_start',	'app_start'],
		['app',			'app'],
		['app_end',		'app_end'],
		['usage',		'usage'],

		# alternates
		['app_begin',	'app_start'],
		['app_enter',	'app_start'],
		['app_init',	'app_start'],
		['app_finish',	'app_end'],
		['app_exit',	'app_end'],
		['app_term',	'app_end'],
	)
	{
		my ($fn, $alias) = @$fn_aref ;
		
		# Only add function if it's not already been specified
		$this->_register_fn($fn, $alias) ;
	}

	## Get version
	$this->_register_scalar('VERSION', 'version') ;

	## Ensure name set
	if (!$this->name())
	{
		$this->name($this->progname() ) ;		
	}


	## Set up default timezone
	if (exists($LOADED_MODULES{'Date::Manip'}))
	{
		my $tz = $App::Frameowrk::Settings::DATE_TZ || 'GMT' ;
		my $fmt = $App::Frameowrk::Settings::DATE_FORMAT || 'non-US' ;
		eval {
			my $date = new Date::Manip::Date;
			$date->config("setdate", "zone,$tz") ;
			
			#&Date_Init("TZ=$tz", "DateFormat=$fmt") ;
		} ;
	}

	## Install required features
	$this->install_features($this->_required_features) ;
	
	## Need to do some init of required features
	$this->feature('Options')->append_options(\@BASE_OPTIONS) ;

print "App::Framework::Core->new() - END\n" if $class_debug ;

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

Initialises the App::Framework::Core object class variables.

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

Class instance object is not allowed
 
=cut

sub allowed_class_instance
{
	return 0 ;
}

#----------------------------------------------------------------------------

=item B<dynamic_load($module [, $pkg])>

Attempt to load the module into the specified package I<$pkg> (or load it into a temporary space).

Then checks that the load was ok by checking the module's version number.

Returns 1 on success; 0 on failure.
 
=cut

sub dynamic_load
{
	my $class = shift ;
	my ($module, $pkg) = @_ ;

	my $loaded = 0 ;
	
	# for windoze....
	if ($^O =~ /MSWin32/i)
	{
		return 0 unless $class->find_lib($module) ;
	}
	
	$pkg ||= 'temp_app_pkg' ;
	
print "dynamic_load($module) into $pkg\n" if $class_debug ;	

	my $version ;
	eval "
		package $pkg; 
		use $module; 
		\$version = \$${module}::VERSION ;
	" ;
#print "Version = $version\n" ;	
	if ($@)
	{
print "dynamic_load($module, $pkg) : error : $@\nAborting dynamic_load.\n" if $class_debug ;
	}
	elsif (defined($version))
	{
		$loaded = 1 ;
	}
print "dynamic_load($module, $pkg) : loaded = $loaded.\n" if $class_debug ;

	return $loaded ;
}

#----------------------------------------------------------------------------

=item B<dynamic_isa($module)>

Load the module into the caller's namespace then set it's @ISA ready for that
module to call it's parent's new() method
 
=cut

sub dynamic_isa
{
	my $class = shift ;
	my ($module, $pkg) = @_ ;

	unless ($pkg)
	{
	    my @callinfo = caller(0);
	    $pkg = $callinfo[0] ;
	}
	my $loaded = $class->dynamic_load($module, $pkg) ;

	if ($loaded)
	{
	no strict 'refs' ;
	
		## Create ourself as if we're an object of the required type (but only if ISA is not already set)
		if (!scalar(@{"${pkg}::ISA"}))
		{
print "dynamic_isa() $pkg set ISA=$module\n" if $class_debug  ;			
			@{"${pkg}::ISA"} = ( $module ) ;
		}
		else
		{
print "dynamic_isa() - $pkg already got ISA=",@{"${pkg}::ISA"}," (wanted to set $module)\n" if $class_debug  ;			
		}

	}	

	return $loaded ;
}


#-----------------------------------------------------------------------------

=item B< inherit($caller_class, [%args]) >

Initialises the object class variables.

=cut

sub inherit
{
	my $class = shift ;
	my ($caller_class, %args) = @_ ;

	## get calling package
	my $caller_pkg = (caller(0))[0] ;

print "\n\n----------------------------------------\n" if $class_debug ;
print "Core:inherit() caller=$caller_pkg\n" if $class_debug ;
	
	## get inheritence stack, grab this object's class, restore list
	my $inheritence = delete $args{'_inheritence'} || [] ;

print " + inherit=\n\t".join("\n\t", @$inheritence)."\n" if $class_debug ;

	## Get parent and restore new list
	my $parent = shift @$inheritence ;
	$args{'_inheritence'} = $inheritence ;

print "Core: $caller_class parent=$parent inherit=@$inheritence\n" if $class_debug ;

	## load in base objects
	my $_caller = $parent ;
	foreach my $_parent (@$inheritence)
	{
print " + Preloading: load $_parent into $_caller\n" if $class_debug ;

		## Dynamic load this parent into this caller
		my $loaded = App::Framework::Core->dynamic_isa($_parent, $_caller) ;
		croak "Sorry, failed to load \"$_parent\"" unless $loaded ;

App::Framework::Core::_dumpvar($_caller) if $class_debug ;
App::Framework::Core::_dumpvar($_parent) if $class_debug ;

		# update caller for next time round
		$_caller = $_parent ;
	}

print " + Loading: load $parent into $caller_pkg\n" if $class_debug ;

	## Dynamic load this object
	my $loaded = App::Framework::Core->dynamic_isa($parent, $caller_pkg) ;
	croak "Sorry, failed to load \"$parent\"" unless $loaded ;

App::Framework::Core::_dumpvar($caller_pkg) if $class_debug ;
App::Framework::Core::_dumpvar($parent) if $class_debug ;

print "Core: calling $caller_pkg -> $parent ::new()\n" if $class_debug ;
App::Framework::Core::_dumpisa($caller_pkg) if $class_debug ;

	## Create object
	my $this ;
	{
	no strict 'refs' ;

		$this = &{"${parent}::new"}(
			$caller_class,
			%args, 
		) ;
		
	}

print "Core:inherit() - END\n" if $class_debug ;
print "----------------------------------------\n\n" if $class_debug ;
	
	return $this ;
}


#----------------------------------------------------------------------------

=item B< find_lib($module) >

Looks for the named module in the @INC path. If found, checks the package name inside the file
to ensure that it really matches the capitalisation.

(Mainly for Microsoft Windows use!)

=cut

sub find_lib
{
	my $class = shift ;
	my ($module) = @_ ;

	my @module_dirs = split /::/, $module ;
	my $pm = pop @module_dirs ;

#print "find_lib($module)\n" ;
	
	my $found ;
	foreach my $dir (@INC)
	{
		my $file = File::Spec->catfile($dir, @module_dirs, "$pm.pm") ;

#print " + checking $file\n" ;
		if (-f $file)
		{
			if (open my $fh, "<$file")
			{
				my $line ;
				while (defined($line = <$fh>))
				{
					chomp $line ;
					if ($line =~ m/^\s*package\s+$module\s*;/)
					{
						$found = $module ;
						last ;
					}
				}
				close $fh ;
			}
			last if $found ;
		}
	}

#print "find_lib() = $found\n" ;

	return $found ;
}

#----------------------------------------------------------------------------

=item B< lib_glob($module_path) >

Looks for any perl modules contained under the module path. Looks at all possible locations
in the @INC path, returning the first found.

Returns a HASH contains the module name as key and the full filename path as the value.
 
=cut

sub lib_glob
{
	my $class = shift ;
	my ($module_path) = @_ ;

	my %libs ;
	foreach my $dir (@INC)
	{
		my $module_path = File::Spec->catfile($dir, $module_path, "*.pm") ;
		my @files = glob($module_path) ;
		foreach my $file (@files)
		{
			my ($base, $path, $ext) = fileparse($file, '\..*') ;
			if (!exists($libs{$base}))
			{
				$libs{$base} = $file ;
			}
		}
	}

	return %libs ;
}

#----------------------------------------------------------------------------

=item B<isa_tree(package)>

Starting at I<package>, return a HASH ref in the form of a tree of it's parents. They keys are the parent module
names, and the values are HASH refs of their parents and so on. Value is undef when last parent 
is reached.

=cut

sub isa_tree
{
no strict "vars" ;
no strict "refs" ;

	my $class = shift ;
    my ($packageName) = @_;
    
    my $tree_href = {} ;
    
    
    foreach my $isa (@{"${packageName}::ISA"})
    {
    	$tree_href->{$isa} = $class->isa_tree($isa) ;
    }
    
	return $tree_href ;
}

#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<set_paths($filename)>

Get the full path to this application (follows links where required)

=cut

sub set_paths
{
	my $this = shift ;
	my ($filename) = @_ ;

	# Follow links
	$filename = File::Spec->rel2abs($filename) ;
	while ( -l $filename)
	{
		$filename = readlink $filename ;
	}
	
	# Get info
	my ($progname, $progpath, $progext) = fileparse($filename, '\.[^\.]+') ;
	if (ref($this))
	{
		# set if not class call
		$this->set(
			'progname'	=> $progname,
			'progpath'	=> $progpath,
			'progext'	=> $progext,
		) ;
	}

	# Set up include path to add script home + script home /lib subdir
	my %inc = map {$_=>1} @INC ;
	foreach my $path ($progpath, "$progpath/lib")
	{
		# add new paths
     	unshift(@INC,$path) unless exists $inc{$path} ;
     	$inc{$path} = 1 ;
		push @INC, $path unless exists $inc{$path} ;
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

# Does nothing!

$this->_dispatch_entry_features($error) ;
	
$this->_dispatch_exit_features($error) ;

}


#----------------------------------------------------------------------------

=item B<install_features($feature_list [, $feature_args])>

Add the listed features to the application. List is an ARRAY ref list of feature names.

Note: names need correct capitalisation (e.g. Sql not sql) - or just use first char capitalised(?)

Method/feature name will be all lowercase 

Optionally, can specify I<$feature_args> HASH ref. Each feature name in I<$feature_list> should be a key
in the HASH, the value of which is an arguments string (which is a list of feature arguments separated by space and/or
commas)

=cut

sub install_features
{
	my $this = shift ;
	my ($feature_list, $feature_args_href) = @_ ;

	$feature_args_href ||= {} ;
	
	my $features_href = $this->_feature_list() ;

	## make a list of features
	my @features = @$feature_list ;
	
$this->_dbg_prt(["install_features()", \@features, "features args=", $feature_args_href]) ;
$class_debug = $this->debug if $this->debug >= 5 ;

	
	## Now try to install them
	foreach my $feature (@features)
	{
		my $feature_args = $feature_args_href->{$feature} || "" ;
		
		my $loaded ;
		my $feature_guess = ucfirst(lc($feature)) ;
		
		## skip if already loaded
		if (exists($features_href->{$feature}) || exists($features_href->{$feature_guess}))
		{
			## Just need to see if we've got any new args
			foreach my $feat ($feature, $feature_guess)
			{
				if (exists($feature_args_href->{$feat}))
				{
					## override args 
					my $feature_obj = $features_href->{$feature}{'object'} ;
					$feature_obj->feature_args($feature_args_href->{$feat}) ;
				}						
			}
			next ;
		}

		# build list of module names to attempt. If personality name is set, try looking for feature
		# under personality subdir first. This allows for personality override of feature (e.g. POE:app overrides Script:app)
		#
		my @tries ;
		my $personality = $this->personality ;
		my $root = "App::Framework::Feature" ;
		if ($personality)
		{
			push @tries, "${root}::${personality}::$feature" ; 
			push @tries, "${root}::${personality}::$feature_guess" ; 
		}
		push @tries, "${root}::$feature" ; 
		push @tries, "${root}::$feature_guess" ; 
		
		foreach my $module (@tries)
		{
			if ($this->dynamic_load($module))
			{
				$loaded = $module ;
				last ;
			}
		}

		my $cwd = cwd() ;
$this->_dbg_prt(["Feature: $feature - unable to load. CWD=$cwd.\n", "Tried=", \@tries, "\n\@INC=", \@INC]) unless ($loaded) ;

		croak "Feature \"$feature\" not supported" unless ($loaded) ;

$this->_dbg_prt(["Feature: $feature - loaded=$loaded\n"]) ;
		
		if ($loaded)
		{
			# save in list
			my $module = $loaded ;
			my $specified_name = $feature ;
			$feature = lc $feature ;

			$features_href->{$feature} = {
				'module'	=> $module,		# loaded module name
				'specified'	=> $specified_name,	# as specified by user
				'name'		=> $feature,	# name used as a method
				'object'	=> undef, 
				'priority'	=> $App::Framework::Base::PRIORITY_DEFAULT,
			} ;
			
			# see if we have some extra init values to pass to the feature
			my $feature_init_href = $this->_feature_init($feature) ;
			
			# create feature
			my $feature_obj = $module->new(
				%$feature_init_href,
				
				'app'			=> $this,
				'name'			=> $feature,		# ensure it matches with what the app expects
				'feature_args'	=> $feature_args,

				# Set up error handler
				'catch_fn' 		=> sub {$this->catch_error(@_);},

			) ;

			# add to list (may already have been done if feature registers any methods)
			$features_href->{$feature}{'object'} = $feature_obj ;
			$features_href->{$feature}{'priority'} = $feature_obj->priority ;
			
			# set up alias
			{
				no warnings 'redefine';
				no strict 'refs';
				
				## alias <feature>()
				my $alias = lc $feature ; 
				*{"App::Framework::Core::${alias}"} = sub {  
					my $this = shift ;
					return $feature_obj->$alias(@_) ;
				};

				## alias <Feature>()
				$alias = ucfirst $feature ;
				*{"App::Framework::Core::${alias}"} = sub {  
					my $this = shift ;
					return $feature_obj->$alias(@_) ;
				};
			}
		}
	}


	## Ensure list is sorted by priority
	$this->feature_list( [ sort {$features_href->{$a}{'priority'} <=> $features_href->{$b}{'priority'}} keys %$features_href ] ) ;

	
$this->_dbg_prt(["installed features = ", $features_href]) ;
	
}


#----------------------------------------------------------------------------
#
#=item B<_feature_init($feature)>
#
#Get any initialisation values for this feature. Returns an empty HASH ref if no
#init specified
#
#=cut
#
sub _feature_init
{
	my $this = shift ;
	my ($feature) = @_ ;
	
	my $feature_init_href = {} ;

	## May have some initialisation values for the feature
	my $feature_config_href = $this->feature_config ;

	## See if we can find a name match
	foreach my $name (keys %$feature_config_href)
	{
		if (lc $name eq lc $feature)
		{
			$feature_init_href = $feature_config_href->{$name} ;
#$this->prt_data("_feature_init($feature)=", $feature_init_href) ;
			last ;
		}
	}
	
	return $feature_init_href ;
}

##----------------------------------------------------------------------------
#
#=item B<feature_list()>
#
#Return list of installed features 
#
#=cut
#
#sub feature_list
#{
#	my $this = shift ;
#
#	my $features_href = $this->_feature_list() ;
#	my @list = map {$features_href->{$_}{'specified'}} keys %$features_href ;
#	return @list ;
#}

##----------------------------------------------------------------------------
#
#=item B<_feature_info($name)>
#
#Return HASH ref of feature information for this feature.
#
#=cut
#
sub _feature_info
{
	my $this = shift ;
	my ($name, %args) = @_ ;

	my $features_href = $this->_feature_list() ;
	$name = lc $name ;
	
	my $info_href ;
	if (exists($features_href->{$name}))
	{
		$info_href = $features_href->{$name} ;
	}	
	else
	{
		$this->throw_fatal("Feature \"$name\" not found") ;
	}

	return $info_href ;	
}

#----------------------------------------------------------------------------

=item B<feature_installed($name)>

Return named feature object if the feature is installed; otherwise returns undef.

=cut

sub feature_installed
{
	my $this = shift ;
	my ($name) = @_ ;

	my $features_href = $this->_feature_list() ;
	$name = lc $name ;
	
	my $feature = undef ;
	if (exists($features_href->{$name}))
	{
		my $feature_href = $features_href->{$name} ;
		$feature = $feature_href->{'object'} ;
	}	

	return $feature ;	
}



#----------------------------------------------------------------------------

=item B<feature($name [, %args])>

Return named feature object. Alternative interface to just calling the feature's 'get/set' method.

For example, 'sql' feature can be accessed either as:

	my $sql = $app->feature("sql") ;
	
or:

	my $sql = $app->sql() ;
 

=cut

sub feature
{
	my $this = shift ;
	my ($name, %args) = @_ ;

	my $feature_href = $this->_feature_info($name) ;

	my $feature = $feature_href->{'object'} ;
	if (%args)
	{
		$feature->set(%args) ;
	}

	return $feature ;	
}


#----------------------------------------------------------------------------

=item B<feature_register($feature, $feature_obj, @function_list)>

API for feature objects. Used so that they can register their methods to be called
at the start and end of the registered functions.

Function list is a list of strings where the string is in the format:

	<method name>_entry
	<method_name>_exit

To register a call at the start of the method and/or at the end of the method.

This is usually called when the feature is being created (which is usually because this Core object
is installing the feature). To ensure the core's lists are up to date, this function sets the feature object
and priority.

=cut

sub feature_register
{
	my $this = shift ;
	my ($feature, $feature_obj, @function_list) = @_ ;
	
	## Add methods
	my $feature_methods_href = $this->_feature_methods() ;
	foreach my $method (@function_list)
	{
		my $feature_href = $this->_feature_info($feature) ;

		# update info (ensure's core has latest info)
		$feature_href->{'object'} = $feature_obj ;
		$feature_href->{'priority'} = $feature_obj->priority ;

#$this->prt_data("Feature info=", $feature_href);
		
		$feature_methods_href->{$method} ||= [] ;
		push @{$feature_methods_href->{$method}}, {
			'feature'	=> $feature,
			'obj'		=>  $feature_href->{'object'},
			'priority'	=>  $feature_href->{'priority'},
		}
		
	}

#$this->prt_data("Raw feature list=", $feature_methods_href);

	## Ensure all lists are sorted by priority
	foreach my $method (@function_list)
	{
		$feature_methods_href->{$method} = [ sort {$a->{'priority'} <=> $b->{'priority'}} @{$feature_methods_href->{$method}} ] ;
	}

#$this->prt_data("Sorted feature list=", $feature_methods_href);

}


#----------------------------------------------------------------------------
#
#=item B<_dispatch_features($method, 'entry|exit')>
#
#INTERNAL: For the specified method, run any features that registered for this method.
#
#=cut
#
sub _dispatch_features
{
	my $this = shift ;
	my ($method, $status, @args) = @_ ;

@args = () unless @args ;
$this->_dbg_prt(["_dispatch_features(method=$method, status=$status) : args=", \@args]) ;
	
	# remove package name (if specified)
	$method =~ s/^(.*)::// ;
	
	my $feature_methods_href = $this->_feature_methods() ;
	my $fn = "${method}_${status}" ;
$this->_dbg_prt([" + method=$method fn=$fn\n"])  ;

	if (exists($feature_methods_href->{$fn}))
	{
		foreach my $feature_entry (@{$feature_methods_href->{$fn}})
		{
$this->_dbg_prt([" + dispatching fn=$fn feature=$feature_entry->{feature}\n"]) ;
$this->_dbg_prt(["++ entry=", $feature_entry], 2) ;

			my $feature_obj = $feature_entry->{'obj'} ;
			$feature_obj->$fn(@args) ;
		}
	}	
	
}

#----------------------------------------------------------------------------
#
#=item B<_dispatch_entry_features(@args)>
#
#INTERNAL: Calls _dispatch_features with the correct method name, and $status='entry'
#
#=cut
#
sub _dispatch_entry_features
{
	my $this = shift ;
	my (@args) = @_ ;
	
	my $method = (caller(1))[3] ;
	return $this->_dispatch_features($method, 'entry', @_) ;	
}


#----------------------------------------------------------------------------
#
#=item B<_dispatch_exit_features(@args)>
#
#INTERNAL: Calls _dispatch_features with the correct method name, and $status='exit'
#
#=cut
#
sub _dispatch_exit_features
{
	my $this = shift ;

	my $method = (caller(1))[3] ;
	return $this->_dispatch_features($method, 'exit', @_) ;	
}


#----------------------------------------------------------------------------
#
#=item B<_dispatch_label_entry_features($label, @args)>
#
#INTERNAL: Calls _dispatch_features with the correct method name, and $status='entry'
#
#=cut
#
sub _dispatch_label_entry_features
{
	my $this = shift ;
	my ($label, @args) = @_ ;
	
	my $method = (caller(1))[3] ;
	$method .= "_$label" if $label ;
	return $this->_dispatch_features($method, 'entry', @args) ;	
}


#----------------------------------------------------------------------------
#
#=item B<_dispatch_label_exit_features($label, @args)>
#
#INTERNAL: Calls _dispatch_features with the correct method name, and $status='exit'
#
#=cut
#
sub _dispatch_label_exit_features
{
	my $this = shift ;
	my ($label, @args) = @_ ;

	my $method = (caller(1))[3] ;
	$method .= "_$label" if $label ;
	return $this->_dispatch_features($method, 'exit', @args) ;	
}



#= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 

=back

=head3 Application execution methods

=over 4

=cut




#----------------------------------------------------------------------------

=item B<go()>

Execute the application.

Calls the following methods in turn:

* app_start
* application
* app_end
* exit
 
=cut


sub go
{
	my $this = shift ;

$this->_dispatch_entry_features() ;

	$this->app_start() ;
	$this->application() ;
	$this->app_end() ;

$this->_dispatch_exit_features() ;

	$this->exit(0) ;
}

#----------------------------------------------------------------------------

=item B<getopts()>

Convert the (already processed) options list into settings. 

Returns result of calling GetOptions

=cut

sub getopts
{
	my $this = shift ;

$this->_dispatch_entry_features() ;

	# Parse options using GetOpts
	my $opt = $this->feature('Options') ;
	my $args = $this->feature('Args') ;
	
	my $ok = $opt->get_options() ;

	# If ok, get any specified filenames
	if ($ok)
	{
		# Get args
		my $arglist = $args->get_args() ;

		$this->_dbg_prt(["getopts() : arglist=", $arglist], 2) ;
	}
	
	## Expand vars
	my %values ;
	my ($opt_values_href, $opt_defaults_href) = $opt->option_values_hash() ;
	my ($args_values_href) = $args->args_values_hash() ;
	
	%values = (%$opt_values_href) ;
	my %args_clash ;
	foreach my $key (keys %$args_values_href)
	{
		if (exists($values{$key}))
		{
			$args_clash{$key} = $args_values_href->{$key} ;
		}
		else
		{
			$values{$key} = $args_values_href->{$key} ;
		}
	}

	my @vars ;
	my %app_vars = $this->vars ;
	push @vars, \%app_vars ;
	push @vars, \%ENV ;

	## expand all vars
	$this->expand_keys(\%values, \@vars) ;
	
	# set new values
	foreach my $key (keys %$opt_values_href)
	{
		$opt_values_href->{$key} = $values{$key} ;
	}
	foreach my $key (keys %$args_values_href)
	{
		$args_values_href->{$key} = $values{$key} ;
	}

	## handle any name clash
	if (keys %args_clash)
	{
		unshift @vars, \%values ;
		$this->expand_keys(\%args_clash, \@vars) ;

		# set new values
		foreach my $key (keys %args_clash)
		{
			$args_values_href->{$key} = $args_clash{$key} ;
		}
	}

	## update settings
	$opt->option_values_set($opt_values_href, $opt_defaults_href) ;
	$args->args_values_set($args_values_href) ;

$this->_dispatch_exit_features() ;

	return $ok ;
}


#----------------------------------------------------------------------------

=item B<app_start()>

Set up before running the application.

Calls the following methods in turn:

* getopts
* [internal _expand_vars method]
* options
* (Application registered 'app_start' function)
 
=cut


sub app_start
{
	my $this = shift ;

$this->_dispatch_entry_features() ;

	## process the data
	$this->feature('data')->process() ;
	
	## allow features to add their options
	my $features_aref = $this->feature_list() ;
	foreach my $feature (@$features_aref)
	{
		my $feature_obj = $this->feature($feature) ;
		my $feature_options_aref = $feature_obj->feature_options() ;
		if (@$feature_options_aref)
		{
			$this->feature('Options')->append_options($feature_options_aref, $feature_obj->class) ;
		}		
	}

	## Add user-defined options last
	$this->feature('Data')->append_user_options() ;


	## Get options
	# NOTE: Need to do this here so that derived objects work properly
	my $ret = $this->getopts() ;
	
	## Expand any variables in the data
	$this->_expand_vars() ;

	# Handle options errors here after expanding variables
	unless ($ret)
	{
		$this->usage('opt') ;
		$this->exit(1) ;
	} 

	# get options
	my %options = $this->options() ;
	
	## function
	$this->_exec_fn('app_start', $this, \%options) ;
	
$this->_dispatch_exit_features() ;
	
}


#----------------------------------------------------------------------------

=item B<application()>

Execute the application.
 
Calls the following methods in turn:

* (Application registered 'app' function)
 

=cut


sub application
{
	my $this = shift ;

$this->_dispatch_entry_features() ;

	## Execute function
	my %options = $this->options() ;

	## Check args here (do this AFTER allowing derived objects/features a chance to check the options etc)
	$this->feature("Args")->check_args() ;
	
	# get args
	my %args = $this->feature("Args")->arg_hash() ;

	## Run application function
	$this->_exec_fn('app', $this, \%options, \%args) ;

	## Close any open arguments
	$this->feature("Args")->close_args() ;
	

$this->_dispatch_exit_features() ;

}

#----------------------------------------------------------------------------

=item B<app_end()>

Tidy up after the application.

Calls the following methods in turn:

* (Application registered 'app_end' function)
 

=cut


sub app_end
{
	my $this = shift ;

$this->_dispatch_entry_features() ;

	# get options
	my %options = $this->options() ;

	## Execute function
	$this->_exec_fn('app_end', $this, \%options) ;

$this->_dispatch_exit_features() ;
}



#----------------------------------------------------------------------------

=item B<exit()>

Exit the application.
 
=cut


sub exit
{
	my $this = shift ;
	my ($exit_code) = @_ ;

die "Expected generic exit to be overridden: exit code=$exit_code" ;
}

#----------------------------------------------------------------------------

=item B<usage()>

Show usage

=cut

sub usage
{
	my $this = shift ;
	my ($level) = @_ ;

$this->_dispatch_entry_features($level) ;
	$this->_exec_fn('usage', $this, $level) ;
$this->_dispatch_exit_features($level) ;

}

#= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 

=back

=head3 Utility methods

=over 4

=cut





#----------------------------------------------------------------------------

=item B<file_split($fname)>

Utility method

Parses the filename and returns the full path, basename, and extension.

Effectively does:

	$fname = File::Spec->rel2abs($fname) ;
	($path, $base, $ext) = fileparse($fname, '\.[^\.]+') ;
	return ($path, $base, $ext) ;

=cut

sub file_split
{
	my $this = shift ;
	my ($fname) = @_ ;

	$fname = File::Spec->rel2abs($fname) ;
	my ($path, $base, $ext) = fileparse($fname, '\.[^\.]+') ;
	return ($path, $base, $ext) ;
}


## ============================================================================================
#
#=back
#
#=head2 PRIVATE METHODS
#
#=over 4
#
#=cut
#
## ============================================================================================


#----------------------------------------------------------------------------
#
#=item B<_exec_fn($function, @args)>
#
#Execute the registered function (if one is registered). Passes @args to the function.
# 
#=cut
#
sub _exec_fn
{
	my $this = shift ;
	my ($fn, @args) = @_ ;

	# Append _fn to function name, get the function, and call it if it's defined
	my $fn_name = "${fn}_fn" ;
	my $sub = $this->$fn_name() || '' ;

$this->_dbg_prt(["_exec_fn($fn) this=$this fn=$fn_name sub=$sub\n"], 2) ;
#$this->prt_data("_exec_fn($fn) args[1]=", \$args[1], "args[2]=",\$args[2]) ;
#if $this->debug()>=2 ;

	&$sub(@args) if $sub ;
}

#----------------------------------------------------------------------------
#
#=item B<_import()>
#
#Load modules into caller package namespace.
# 
#=cut
#
sub _import 
{
	my $this = shift ;

	my $package = $this->package() ;
	
	# Debug
	if ($this->debug())
	{
		unless ($package eq 'main')
		{
			print "\n $package symbols:\n"; dumpvar($package) ;
		}
	}

	## Load useful modules into caller package	
	my $code ;
	
	# Set of useful modules
	foreach my $mod (@App::Framework::Settings::MODULES)
	{
		$code .= "use $mod;" ;
	}
	
	# Get modules into this namespace
	foreach my $mod (@App::Framework::Settings::MODULES)
	{
		eval "use $mod;" ;
		if ($@)
		{
			warn "Unable to load module $mod\n" ;
		}	
		else
		{
			++$LOADED_MODULES{$mod} ;
		}
	}

	# Get modules into caller package namespace
	eval "package $package;\n$code\n" ;
#	if ($@)
#	{
#		warn "Unable to load modules : $@\n" ;
#	}	
}


#----------------------------------------------------------------------------
#
#=item B<_register_fn()>
#
#Register a function provided as a subroutine in the caller package as an app method
#in this object.
#
#Will only set the field value if it's not already set.
#
#=cut
#
sub _register_fn 
{
	my $this = shift ;
	my ($function, $alias) = @_ ;
	
	$alias ||= $function ;
	my $field ="${alias}_fn" ; 

	$this->_register_var('CODE', $function, $field) unless $this->$field() ;
}

#----------------------------------------------------------------------------
#
#=item B<_register_scalar($external_name, $field_name)>
#
#Read the value of a variable in the caller package and copy that value as a data field
#in this object.
#
#Will only set the field value if it's not already set.
#
#=cut
#
sub _register_scalar 
{
	my $this = shift ;
	my ($external_name, $field_name) = @_ ;
	
	$this->_register_var('SCALAR', $external_name, $field_name) unless $this->$field_name() ;
}

#----------------------------------------------------------------------------
#
#=item B<_register_var($type, $external_name, $field_name)>
#
#Read the value of a variable in the caller package and copy that value as a data field
#in this object. $type specifies the variable type: 'SCALAR', 'ARRAY', 'HASH', 'CODE'
# 
#NOTE: This method overwrites the field value irrespective of whether it's already set.
#
#=cut
#
sub _register_var 
{
	my $this = shift ;
	my ($type, $external_name, $field_name) = @_ ;

	my $package = $this->package() ;

    local (*alias);             # a local typeglob

$this->_dbg_prt(["_register_var($type, $external_name, $field_name)\n"], 2) ;

    # We want to get access to the stash corresponding to the package
    # name
no strict "vars" ;
no strict "refs" ;
    *stash = *{"${package}::"};  # Now %stash is the symbol table

	if (exists($stash{$external_name}))
	{
		*alias = $stash{$external_name} ;

$this->_dbg_prt([" + found $external_name in $package\n"], 2) ;

		if ($type eq 'SCALAR')
		{
			if (defined($alias))
			{
				$this->set($field_name => $alias) ;
			}
		}
		if ($type eq 'ARRAY')
		{
			# was - if (defined(@alias)) - removed due to "deprecated" warning
			if (@alias)
			{
				$this->set($field_name => \@alias) ;
			}
		}
		if ($type eq 'HASH')
		{
			if (%alias)
			{
				$this->set($field_name => \%alias) ;
			}
		}
		elsif ($type eq 'CODE')
		{
			if (defined(&alias))
			{
$this->_dbg_prt([" + + Set $type - $external_name as $field_name\n"], 2) ;
				$this->set($field_name => \&alias) ;
			}
		}

	}
}


#----------------------------------------------------------------------------
#
#=item B<_expand_vars()>
#
#Run through some of the application variables/fields and expand any instances of variables embedded
#within the values.
#
#Example:
#
#	__DATA_  
#
#	[SYNOPSIS]
#	
#	$name [options] <rrd file(s)>
#
#Here the 'synopsis' field contains the $name field variable. This needs to be expanded to the value of $name.
#
#NOTE: Currently this will NOT cope with cross references (so, if in the above example $name also contains a variable
#then that variable may or may not be expanded before the synopsis field is processed)
#
#
#=cut
#
sub _expand_vars 
{
	my $this = shift ;

$this->_dbg_prt(["_expand_vars() - START\n"], 2) ;

	# Get hash of fields
	my %fields = $this->vars() ;

#$this->_dbg_prt([" + fields=", \%fields], 2) ;
	
	# work through each field, create a list of those that have changed
	my %changed ;
	foreach my $field (sort keys %fields)
	{
		# Skip non-scalars
		next if ref($fields{$field}) ;
		
		# First see if this contains a '$'
		$fields{$field} ||= "" ;
		my $ix = index $fields{$field}, '$' ; 
		if ($ix >= 0)
		{
$this->_dbg_prt([" + + $field = $fields{$field} : index=$ix\n"], 3) ;

			# Do replacement
			$fields{$field} =~ s{
								     \$                         # find a literal dollar sign
								     \{{0,1}					# optional brace
								    (\w+)                       # find a "word" and store it in $1
								     \}{0,1}					# optional brace
								}{
								    no strict 'refs';           # for $$1 below
								    if (defined $fields{$1}) {
								        $fields{$1};            # expand global variables only
								    } else {
								        "\${$1}";  				# leave it
								    }
								}egx;


$this->_dbg_prt([" + + + new = $fields{$field}\n"], 3) ;
			
			# Add to list
			$changed{$field} = $fields{$field} ;
		}
	}

$this->_dbg_prt([" + changed=", \%changed], 2) ;
	
	# If some have changed then set them
	if (keys %changed)
	{
$this->_dbg_prt([" + + set changed\n"], 2) ;
		$this->set(%changed) ;
	}

$this->_dbg_prt(["_expand_vars() - END\n"], 2) ;
}



#----------------------------------------------------------------------------

=item B<debug_prt($items_aref [, $min_debug])>

Print out the items in the $items_aref ARRAY ref iff the application's debug level is >0. 
If $min_debug is specified, will only print out items if the application's debug level is >= $min_debug.

=cut

sub debug_prt
{
	my $this = shift ;
	my ($items_aref, $min_debug) = @_ ;

	$min_debug ||= 1 ;
	
	## check debug level setting
	if ($this->options->option('debug') >= $min_debug)
	{
		$this->prt_data(@$items_aref) ;
	}
}



# ============================================================================================
# PRIVATE FUNCTIONS
# ============================================================================================

#----------------------------------------------------------------------------
#
#=item B<_dumpisa(package)>
#
#Starting at I<package>, show the parents
#
#=cut
#
sub _dumpisa
{
no strict "vars" ;
no strict "refs" ;

    my ($packageName, $level) = @_;
    
    
    if (!defined($level)) 
    {
    	print "#### PACKAGE: $packageName  ISA HIERARCHY ###########################\n" ;
    }
    else
    {
    	print " "x$level ;
    	print "$packageName\n" ;
    }
    
    foreach my $isa (@{"${packageName}::ISA"})
    {
    	_dumpisa($isa, ++$level) ;
    }
    
     
    if (!defined($level)) 
    {
    	print "######################################################\n" ;
    }     
}

#----------------------------------------------------------------------------
#
#=item B<_dumpvar(package)>
#
#Dump out all of the symbols in package I<package>
#
#=cut
#
sub _dumpvar 
{
no strict "vars" ;
no strict "refs" ;

    my ($packageName) = @_;
    
    print "#### PACKAGE: $packageName ###########################\n" ;
    
    local (*alias);             # a local typeglob
    # We want to get access to the stash corresponding to the package
    # name
    *stash = *{"${packageName}::"};  # Now %stash is the symbol table
    $, = " ";                        # Output separator for print
    # Iterate through the symbol table, which contains glob values
    # indexed by symbol names.
    while (($varName, $globValue) = each %stash) {
        print "$varName ============================= \n";
        *alias = $globValue;
        if (defined ($alias)) {
            print "\t \$$varName $alias \n";
        } 
        if (@alias) {
            print "\t \@$varName @alias \n";
        } 
        if (%alias) {
            print "\t \%$varName ",%alias," \n";
        }
        if (defined (&alias)) {
            print "\t \&$varName \n";
        } 
     }
     
    print "######################################################\n" ;
     
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


