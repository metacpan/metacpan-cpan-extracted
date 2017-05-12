package App::Framework;

=head1 NAME

App::Framework - A framework for creating applications

=head1 SYNOPSIS

  use App::Framework ;
  
  App::Framework->new()->go() ;
  
  sub app
  {
	my ($app, $opts_href, $args_href) = @_ ;
	
	# options
	my %opts = $app->options() ;
    
	# aplication code here....  	
  }


=head1 DESCRIPTION

App::Framework is a framework for quickly developing application scripts, where the majority of the mundane script setup,
documentation etc. jobs are performed by the framework (usually under direction from simple text definitions stored in the script).

This leaves the developer to concentrate on the main job of implementing the application.

To jump straight in to developing applications, please see L<App::Framework::GetStarted>.

=head2 Capabilities

The application framework provides the following capabilities: 

=over 2

=item Options definition

Text definition of options in application, providing command line options, help pages, options checking. 

Also supports variables in options definition, the variables being replaced by other option values, application field values, 
or environment variables.

=item Arguments definition

Text definition of arguments in application, providing command line arguments, help pages, arguments checking, file/directory
creation, file/directory existence, file opening

Also supports variables in arguments definition, the variables being replaced by other argument values, option values, application field values, 
or environment variables.

=item Named data sections

Multiple named __DATA__ sections, the data being readily accessible by name from the application.

Variables can be used in the data definitions, the variables being replaced by command line option values, application field values, 
or environment variables.

=item Personalities

Single line selection of the base application type (i.e. command line script, Tk application, POE application etc). 

Modular application framework allows for separate installation of new personalities in the installed Perl library space, or locally under
an application-specific directory.

=item Extensions

Single line selection of one or more application extension plugins which modify the selected personality behaviour. 

Modular application framework allows for separate installation of new extensions in the installed Perl library space, or locally under
an application-specific directory.

Example extensions (may not be installed on your system):

=over 4

=item Daemon

Selecting this extension converts the command line script into a daemon (see L<App::Framework::Extension::Daemon>)

=item Filter

Sets up the application for file filtering, the framework doing most of the work in the background (see L<App::Framework::Extension::Filter>).

=item Find

Sets up the application for file finding, the framework doing most of the work in the background

=back

=item Features

Single line selection of one or more application feature plugins which provide application targetted functionality (for example Sql support,
mail handling etc). 

Modular application framework allows for separate installation of new features in the installed Perl library space, or locally under
an application-specific directory.

Example features (may not be installed on your system):

=over 4

=item Config

Provides the application with configuration file support. Automatically uses the configuration file for all command line option
settings (see L<App::Framework::Feature::Config>).

=item Sql

Provides a simplified interface to MySQL. Provides easy set up for Sql operations delete, update, select etc (see L<App::Framework::Feature::Sql>).

=item Mail

Provides mail send support (including file attachment)  (see L<App::Framework::Feature::Mail>).

=back


=item Application directories

The framework automatically adds the location of the script (following any links) to the Perl search path. This means that perl modules
can be created in subdirectories under the application's script making the application self-contained.

The directories used for loading personalities/extensions/features also include the script install directory, meaning that new personalities/extensions/features
can also be provided with a script. 

=back


=head2 Framework Components 

The diagram below shows the relationship between the application framework object (Framework) and the other components: 

    +--------------+
    | Core         |
    +--------------+
          ^
          |
          |
    +--------------+
    | Personality  | Script, POE etc
    +--------------+
          ^
          |
          |
    ................
    : Extension(s) :..  Filter, Daemon etc
    ................ :
      :...............
          ^
          |
          |
    +--------------+                +--------------+
    | Framework    |--------------->| Features     |-+ Args, Options, Pod etc
    +--------------+                +--------------+ |
                                      +--------------+


=head3 Core and personalities

An application is built by creating an App::Framework object that is derived from the application core, and also contains 0 or more feature
objects. The application core (L<App::Framework::Core>) is not directly deriveable, you actually derive from a "personality" module that provides
the base essentials for this selected type of application (for example 'Script' for a command line script).

The personality is selected in the App::Framework 'use' command as:

    use App::Framework ':<personality>'

For example:

    use App::Framework ':Script'

Personalities add specific methods, options, arguments to the core application.

All of the methods defined in the selected personality add to the core methods and are available to the application object ($app).

(See L<App::Framework::CoreModules> for your currently installed personalities)


=head3 Extensions

When creating the App::Framework object, you can optionally select to derive it from one (or more) 'extensions'. An extension can modify how the 
application routine is called, add extra command line options, and so on. For example, the 'filter' extension sets up the application
for file filtering (calling the aplication subroutine with each line of an input file so that the file contents may be filtered).

Extensions are added in the App::Framework 'use' command as:

    use App::Framework '::<extension>'

For example:

    use App::Framework '::Daemon ::Filter'

(See L<App::Framework::ExtensionModules> for your currently installed extensions)

Like the personality, all of the methods defined in the selected extensions add to the core methods and are available to the application 
object ($app).

=head3 Features

Features provide additional application capabilities, optional modifying what the application framework does depedning on the feature. A feature
may also simply be an application-specific collection of useful methods.

Unlike core/personality/extension, features are not part of the application object - they are kept in a "feature list" that the application can 
access to use a feature's methods. For convenience, all features provide an accessor method that is aliased as an application method
with the same name as the feature. This access method provides the most commonly used functionality for that feature. For example, the 'data'
feature provides access to named data sections as:

    my $data = $app->data('named_section') ;

Alternatively, the data feature object can be retrieved and used:

    my $data_feature = $app->feature('data') ;
    my $data = $data_feature->data('named_section') ;

Features are added in the App::Framework 'use' command as:

    use App::Framework '+<feature>'

For example:

    use App::Framework '+Args +Data +Mail +Config'

(See L<App::Framework::FeatureModules> for your currently installed extensions)


=head2 Using This Module 

To create an application you need to declare: the personality to use, any optional extensions, and which features you wish to use.

You do all this in the 'use' pragma for the module, for example:

    use App::Framework ':Script ::Filter +Mail +Config' ;

By default, the 'Script' personality is assumed (and so need not be declared), and the framework ensures that all of the features it requires are always loaded (so you don't
need to declare +Args, +Options, +Data, +Pod, +Run). So, the minimum is:

    use App::Framework ;

=head3 Creating Application Object

There are two ways of creating an application object and running it. The normal way is:

    # Create application and run it
    App::Framework->new()->go() ;

As an alternative, the framework creates a subroutine in the calling namespace called B<go()> which does the same thing:

    # Create application and run it
    go() ;

You can use whatever takes your fancy. Either way, the application object will end up calling the user-defined application subroutines 



=head3 Application Subroutines

Once the application object has been created it can then be run by calling the 'go()' method. go() calls the application's registered functions
in turn:

=over 2

=item * app_start()	

Called at the start of the application. You can use this for any additional set up (usually of more use to extension developers)

=item * app()

Called once all of the arguments and options have been processed

=item * app_end()

Called when B<app()> terminates or returns (usually of more use to extension developers)

=back

The framework looks for these 3 functions to be defined in the script file. The functions B<app_start> and B<app_end> are optional, but it is expected that B<app> will be defined
(otherwise nothing happens!).

=head3 Setup

The application settings are entered into the __DATA__ section at the end of the file. All program settings are grouped under sections which are introduced by '[section]' style headings. There are many 
different settings that can be set using this mechanism, but the framework sets most of them to useful defaults. The most common sections are described below.

=head4 Summary

This should be a single line, concise summary of what the script does. It's used in the terse man page created by pod2man.

=head4 Description

As you'd expect, this should be a full description, user-guide etc. on what the script does and how to do it. Notice that this example
has used one (of many) of the variables available: $name (which expands to the script name, without any path or extension).

=head4 Options

Command line options are defined in this section in the format:

    -<name>=<specification>    <Summary>    <optional default setting>
    
    <Description> 

For example:

    -table|tbl|sql_table=s        Table [default=listings2]

For full details, see L<App::Framework::Feature::Options>.

=head4 Arguments

The command line arguments specification are similar to the options specification. In this case we use '*' to signify the
start of a new argument definition. 

Arguments are defined in the format:

    * <name>=<specification>    <Summary>    <optional default setting>
    
    <Description> 

For full details, see L<App::Framework::Feature::Args>.

=head4 Example

An example script setup is:

    __DATA__
    
    [SUMMARY]
    
    An example of using the application framework
    
    [ARGS]
    
    * infile=f        Input file
    
    Should be set to the input file
    
    * indir=d        Input dir
    
    Should be set to the input dir
    
    [OPTIONS]
    
    -table=s        Table [default=listings2]
    
    Sql table name
    
    -database=s        Database [default=tvguide]
    
    Sql database name
    
    
    [DESCRIPTION]
    
    B<$name> is an example script.



=head3 Data

After the settings (described above), one or more extra data areas can be created by starting that area with a new __DATA__ line.

If the new data area is defined simply with '__DATA__' then the area is automatically named as 'data1', 'data2' etc. Alternatively, the 
data section can be arbitrarily named by appending a text name after __DATA__. For example, the definition:

	__DATA__
	
	[DESCRIPTION]
	An example
	
	__DATA__ test.txt
	
	some text
	
	__DATA__ a_bit_of_sql.sql
	
	DROP TABLE IF EXISTS `listings2`;
	 
Creates 2 extra data areas 'test.txt' and 'a_bit_of_sql.sql'. These data area contents can be accessed using:

	my $contents1 = $app->data('text.txt') ;
	# or
	$contents1 = $app->data('data1') ;

	my $contents2 = $app->data('a_bit_of_sql.sql') ;
	# or
	$contents2 = $app->data('data2') ;


See L<App::Framework::Feature::Data> for further details.


=head2 Directories

The framework sets up various directory paths automatically, as described below.

=head3 @INC path

App::Framework automatically pushes some extra directories at the start of the Perl include library path. This allows you to 'use' application-specific
modules without having to install them globally on a system. The path of the executing Perl application is found by following any links until
an actually Perl file is found. The @INC array has the following added:

	* $progpath
	* $progpath/lib
	
i.e. The directory that the script resides in, and a sub-directory 'lib' will be searched for application-specific modules.

Note that this is the path also used when the framework loads in the core personality, and any optional extensions.

=head3 Feature modules

When the application framework loads in the various required and user-specified features, then it attempts to load the following feature modules until one is sucessfully loaded:

    * App::Framework::Feature::${personality}::${feature}
    * App::Framework::Feature::${feature}

Where ${feature} is the name of the feature being loaded (e.g. Config), and ${personality} is the specified core personality (e.g. Script). Note that it does this using the L</@INC path>, so
an application can bundle it's own feature's in under it's own install directory.


=head2 Settings

App::Framework loads some settings from L<App::Framework::Settings>. This may be modified on a site basis as required 
(in a similar fashion to CPAN Config.pm). 


=head2 Loaded modules

App::Framework pre-loads the user namespace with some common modules. See L<App::Framework::Settings> for the complete list. 

	

=head2 FIELDS

The following fields should be defined either in the call to 'new()' or as part of the application configuration in the __DATA__ section:

 * name = Program name (default is name of program)
 * summary = Program summary text
 * synopsis = Synopsis text (default is program name and usage)
 * description = Program description text
 * history = Release history information
 * version = Program version (default is value of 'our $VERSION')

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

=cut

use 5.008004;

use strict ;
use Carp ;

use App::Framework::Core ;


our $VERSION = "1.07" ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA ; 

#============================================================================================
# GLOBALS
#============================================================================================

our $class_debug = 0 ;

# Keep track of import info
my $import_args ;


#============================================================================================

=head2 METHODS

=over 4

=cut


#============================================================================================

# Set up module import
sub import 
{
    my $pkg     = shift;
    
    $import_args = join ' ', @_ ;
    
	## Set library paths
	my ($package, $filename, $line, $subr, $has_args, $wantarray) = caller(0) ;
	App::Framework::Core->set_paths($filename) ;

	## Add a couple of useful function calls into the caller namespace
	{
		no warnings 'redefine';
		no strict 'refs';

		foreach my $fn (qw/go modpod/)	
		{
			*{"${package}::$fn"} = sub {  
			    my @callinfo = caller(0);
				my $app = App::Framework->new(@_,
					'_caller_info' => \@callinfo) ;
				$app->$fn() ;
			};
		}	
	}
    
}

#----------------------------------------------------------------------------------------------

=item B< new([%args]) >

Create a new object.

The %args passed down to the parent objects.

The parameters are specific to App::Framework:

=over 4

=item B<specification> - Application definition

Instead of specifying the application in the 'use App::Framework' line, you can just specify them in this
argument when creating the object. If this is specified it will overwrite any specification in the 'use' pragma.

=back


=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

    my @callinfo = caller(0);
	$args{'_caller_info'} ||= \@callinfo ;

	print __PACKAGE__."->new() : caller=$args{'_caller_info'}->[0]\n" if $class_debug ;

	if (exists($args{'specification'}))
	{
		$import_args = delete $args{'specification'} ;
	}



	## Process the import command args
	my $personality ;
	my @features ;
	my @extensions ;
	my %extension_args ;
	my %feature_args ;
	$import_args ||= ':Script +run' ;
	
	# Expect something of the form:
	# :Personality ::Extension ::Ext(option1 option2) +Feature +Feat(opt1, opt2)
	#
	#                           type        name       args 
	while ($import_args =~ /\s*([\:\+]{1,2})([\w_]+)\s*(?:\(([^\)]+)\)){0,1}/g)
	{
		my ($type, $name, $args) = ($1, $2, $3) ;
		if ($type eq ':')
		{
			if ($personality)
			{
				croak "Sorry, App::Framework does not support multiple personalities (please see a psychiatrist!)" ;
			}
			if ($args)
			{
				warn "Sorry, personalities do not support arguments" ;
			}
			$personality = $name ;
		}
		elsif ($type eq '::')
		{
			push @extensions, $name ;
			$extension_args{$name} = $args || "" ;
		}
		elsif ($type eq '+')
		{
			push @features, $name ;
			$feature_args{$name} = $args || "" ;
		}
		else
		{
			croak "App::Framework does not understand the import string \"$import_args\" at \"$type\" " ;
		}
	}

	## sort extension list
	my @extension_modules ;
	my %extensions ;
	foreach my $extension (@extensions)
	{
		my $module = "App::Framework::Extension::$extension" ;

		print "Extension $extension - module $module\n" if $class_debug ;

		# only allow 1 instance of each extension
		if (!exists($extensions{$module}))
		{
			if (App::Framework::Core->dynamic_load($module, __PACKAGE__))
			{
				print " + loaded\n" if $class_debug ;
	
				my $priority ;
				eval "\$priority = \$${module}::PRIORITY ;" ;
				print " + $@\n" if $@ && $class_debug ;
				
				$priority ||= $App::Framework::Base::PRIORITY_DEFAULT ;
	
				print " + priority=$priority\n" if $class_debug ;
				push @extension_modules, [$extension, $module, $priority] ;
			}
			else
			{
				croak "App::Framework cannot load extension \"$extension\" " ;
			}
		}
		$extensions{$module} = 1 ;
	}
	@extension_modules = sort { $a->[2] <=> $b->[2] } @extension_modules ;
	my @modules = map { $_->[1] } @extension_modules ;
	
	# extensions are based from App::Framework::Extension
	push @modules, 'App::Framework::Extension' ;

	if ($class_debug)
	{
		print "Import: $import_args\n" ;
		print "features: @features\n" ;
		print "Extensions: @extensions\n" ;
		
		print "Extension Modules: @modules\n" ;
	}

	## load module
	$personality ||= 'Script' ;
	my $module =  "App::Framework::Core::$personality" ; 
	push @modules, $module ;

	print "Framework Inheritence Modules:\n\t". join("\n\t",@modules)."\n" if $class_debug ;


	$module = shift @modules ;
	
	my $loaded = App::Framework::Core->dynamic_isa($module, __PACKAGE__) ;
	croak "Sorry, App::Framework does not support \"$module\"" unless $loaded ;

	# Create object
	my $this = $class->SUPER::new(
		%args, 
		'_caller_info'	=> $args{'_caller_info'},
		'_inheritence'	=> \@modules,
		
		## Pass down extra information
		'personality'	=> $personality,
		'extensions'	=> \@extensions,
	) ;
	$this->set(
		'usage_fn' 		=> sub {$this->script_usage(@_);}, 
	) ;

	## Load features
	if (@features)
	{
		## Install them
		$this->install_features(\@features, \%feature_args) ;
	}


	return($this) ;
}

#----------------------------------------------------------------------------------------------

=item B< modpod() >

Create/update module pod files. Creates/updates the pod for the module lists: 
L<App::Framework::FeatureModules>,L<App::Framework::ExtensionModules>,L<App::Framework::CoreModules>

Used during installation.

=cut

sub modpod
{
	my $this = shift ;

	foreach my $name (qw/Core Extension Feature/)
	{
		my $podfile = "App/Framework/${name}Modules.pod" ;
		my %modules = App::Framework::Core->lib_glob("App/Framework/$name") ;	
		my $template = $this->_template($name) ;

		print "$podfile ...\n" ;
				
		my @list ;
		foreach my $module (sort keys %modules)
		{
			if ( open my $fh, "<$modules{$module}" )
			{
				my ($summary, $version, $line) ;
				my $modname = "App::Framework::${name}::${module}" ;
				while ( !($summary && $version) && defined($line = <$fh>) )
				{
					chomp $line ;

					# App::Framework::Feature::Args - Handle application command line arguments
					if ($line =~ m/$modname\s*\-\s*(\S.*)/)
					{
						$summary = $1 ;
					}

					# our $VERSION = "1.000" ;
					if ($line =~ m/(?:our|my)\s+\$VERSION\s*=\s*["']([\d\.]+)["']/)
					{
						$version = $1 ;
					}
				}
				close $fh ;
				
				if ($summary)
				{
					print "   $modname\n" ;
					push @list, {
						'module' 	=> $modname,
						'file'		=> $modules{$module},
						'summary'	=> $summary,
						'version'	=> $version,
					}
				}
			}
		}
		
		## Write file
		my $blib_pod = "blib/lib/$podfile" ;
		if (-f $blib_pod)
		{
			chmod 0755, $blib_pod ; 
		}
		if (open my $fh, ">$blib_pod")
		{
			my $list ;
			foreach my $href (@list)
			{
				my $version = $href->{version} ? "v$href->{version}" : "" ;
				$list .= "=item * L<$href->{module}>  $version\n\n" ;
				$list .= "$href->{summary}\n\n" ;
			}
			$template =~ s/<LIST>/$list/m ;

			print $fh $template ;
			
			close $fh ;
		}
		else
		{
			die "Error: unable to write pod file $blib_pod : $!" ;
		}
	}

}



#============================================================================================
# PRIVATE
#============================================================================================


##----------------------------------------------------------------------------------------------
## Create a new App::Framework object, then call the specified method
#sub _new_and_call
#{
#	my $class = shift ;
#	my ($method, %args) = @_ ;
#	my $this = new(%args) ;
#	$this->$method(%args) ;
#}

#----------------------------------------------------------------------------------------------
# Returns the pod file template for this named file
sub _template
{
	my $class = shift ;
	my ($name) = @_ ;
	my $template ;

	my $eq = '=' ;
	$template = <<TEMPLATE ;
${eq}head1 NAME

App::Framework::${name}Modules - Module list for installed ${name} modules 

${eq}head1 DESCRIPTION

The following list shows the ${name} modules installed on your system:

${eq}over 4

<LIST>

${eq}back

${eq}head1 AUTHOR

Steve Price, C<< <sdprice at cpan.org> >>

${eq}cut

TEMPLATE

	return $template ;
}


=back

=head1 AUTHOR

Steve Price, C<< <sdprice at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-framework at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Framework>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Framework


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Framework>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Framework>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Framework>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Framework/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Steve Price, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

# ============================================================================================
# END OF PACKAGE
1;

__END__


