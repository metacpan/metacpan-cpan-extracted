#!/usr/bin/perl -w
#----------------------------------------------------------------------------
#   App::Modular - perl program modularization framewok
#   App::Modular.pm: module management class
#
#   Copyright (c) 2003-2004 Baltasar Cevc
#
#   This code is released under the L<perlartistic> Perl Artistic
#   License, which can should be accessible via the C<perldoc
#   perlartistic> command and the file COPYING provided with this
#
#   DISCLAIMER: THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS," AND
#   COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY
#   OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE
#   OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS,
#   TRADEMARKS OR OTHER RIGHTS.
#   IF YOU USE THIS SOFTWARE, YOU DO SO AT YOUR OWN RISK.
#
#   See this internet site for more details: http://technik.juz-kirchheim.de/
#
#   Creation:       02.12.03    bc
#   Last Update:    06.04.08    bc
#   Version:         0. 1. 3  
# ----------------------------------------------------------------------------

##################################
##        PRAGMA/DEPS           ##
##################################
use strict;
use warnings;
use 5.006_001;

package App::Modular;
use Carp;
use base qw(Class::Singleton);

##################################
##           VERSION            ##
##################################
our ($VERSION);
$VERSION = 0.001_003;

##################################
##           METHODS            ##
##################################
### new_instance
# only one instance of App::Modular should exist in a running program,
# so we use singleton
# => this is our "new" function which initializes the variables
#    however, the program should only use "..=instance App::Modular;"
#    to get the object, Class::Singleton will initialize everything
#    when and only if needed
sub _new_instance {
   my ($type) = @_;
   my $self  = bless { }, $type;

   $self->{'modules'} = {};             # hash modulename => object
   $self->{'modules_files'} = {};;      # hash modulename => source file
   $self->{'dependencies'} = {};;       # hast modulename => /-separated list
                                        # of modules the module depends on
   $self->{'debuglevel'} = 1;           # (default) verbose level
   $self->{'debugtrace'} = 0;           # print stack trace with debug output
   $self->{'moduledir'} = '';           # directory containing the mods
   $self->{'moduleext'} = '.mom';       # extension of the module files
   $self->{'autoload'} = 0;             # automatically load module when
                                        # it is accessed vi 
                                        # $modularizer->module{'name]}

   $self;
};

### mlog (modularizer logging/debugging)
# modularizer standarized log routine, should be used for debugging
# by any modularizer module
# depending of the trace setting, we use carp or cluck (output with or
# without a stack backtrace)
sub mlog {
   my ($self, $level, @text) = @_;
   if ($level < $self->{'debuglevel'}) {
      unless ($self->{'debugtrace'}) {
         Carp::carp (join(" ",@text));
      } else {
         Carp::cluck (join(" ",@text));
      }
   }
};

### loglevel (set modularizer logging/debugging level)
# set the level of debbuging output, 0 shows only critical errors, -1
# nothing, levels are up to 100 which shows every detail
sub loglevel {
   my ($self, $level) = @_;
   if (defined $level) {
      ($self->{'debuglevel'} = $level);
      $self->mlog (99, "setting log level from $self->{'debuglevel'}".
                       " to $level");
   }
   return $self->{'debuglevel'};
};

### logtrace (enable/disable stack backtrace on debug output)
sub logtrace {
   my ($self, $trace) = @_;
   ($self->{'debugtrace'} = $trace) if (defined $trace);
   return $self->{'debugtrace'};
};

### module_register (load a module, create an instance and save a
###                  reference to it)
# find a module (if needed) and register it in the local vars
# note: if you use a nested namespace as Input::SQL, use :: to separate the
#       levels
#       any module name containing a slash will be assumed to be a file name!
sub module_register {
   my ($self, $module, $nodepends) = @_;
   my ($modfile, $modfile2, $modfile3,
       @dependencies, $dep, $instance, $err);

   # check if called correctly
   unless ($module) {
      $self->mlog (-1, "module_register(): you must specify a module ".
                       "to register");
      return undef;
   };
   
   # check if the module has yet been loaded (in that case, just return
   # a positive status code (success)
   if ($self->module_isloaded($module)) {
      $self->mlog (90,"module_register($module):".
                      "cannot load a module twice");
      return 1;
   };
   
   # check if module exists and is readable
   unless ($module =~ m"/") {
      unless ( $self->{'module_dir'} ) {
         $self->mlog(-1, "module load: module directory not defined");
         return undef;
      };
      unless ( -d $self->{'module_dir'} ) {
         $self->mlog(-1, "module load: module directory '".
                         $self->{'module_dir'}."' does not exist");
         return undef;
      };
      unless ( defined $self->{'module_ext'} ) {
         $self->mlog(-1, "module load: module extension not defined");
         return undef;
      };
      # modfile: complete path name to module file, was:  perl package name
      # modfile2: file name relative to module directory
      # modfile3: file name relative to module dir, changed ext to .pm
      
      $modfile = $module;
      $modfile =~ s/::/\//g;
      $modfile2 = "App/Modular/module/$modfile".$self->{'module_ext'};
      $modfile3 = "App/Modular/module/$modfile.pm";
      $modfile = $self->{'module_dir'}.$modfile.
                 $self->{'module_ext'};
   } else {
      $modfile = $module;
      $module = substr $modfile, length($self->{'module_dir'}), 
                rindex($modfile, $self->{'module_ext'})
                -length($self->{'module_dir'});
      $module =~ s/\//::/g;
   };
   $self->mlog(99, "set module file for '$module' to '$modfile'");
   if ( -r $modfile)  {
      # the module file was specified (the normal case)
      # => we will load it and create an instance
      $instance = eval "do ('$modfile') && return ".
                       "(module_init App::Modular::Module::$module);";
      unless ($instance) {
         $self->mlog(1, "read module from '$modfile', however, init ".
                        "failed: $@");
         return undef;
      } else {
         $self->mlog(99, "read module $module from '$modfile'");
      }
   } else {
      # the module file was not specified or is not readable
      # we will fall back to the standard perl way of finding modules
      # in hope that will get the thing loaded.
      $self->mlog (99, "module not found in module directory, falling ".
                       "back to @INC for search");
      $instance = eval "do ('$modfile2') && return ".
                       "(module_init App::Modular::Module::$module);";
      if ($@ || ! $instance) {
         unless ($instance) {
            $err = $@;
            $self->mlog (0,
                  "unable to locate module $module via '".
                  "$modfile3' (at '$modfile')\n".
                  ($err ? "$err\n" : '') .
                  ($@ ? "$@" : '')
               );
            return undef;
         };
      }
   };
   # load and init App::Modular::module::$module);";
   $self->mlog (60,"registering module $module");

   # now we have the module file, name and instance
   # => register the module in our data structure
   $self->mlog(99, "module $module loaded as $instance");
   $self->{'modules'}{$module} = $instance; 
   $self->{'modules_files'}{$module} = $modfile; 

   # find module dependencies and load modules if needed
   $dep = eval "return \$instance->module_depends()";
   if ($dep) {
      @dependencies = split('/',$dep);
      foreach $dep (@dependencies) {
         # load the modules needed
         if (!$self->module_isloaded($dep))  {
            $self->module_register($dep);
         };
         $self->{'dependencies'}{$dep} .= '/'.$module;
      };
   };
   return $self->{'modules'}->{$module};
};

### module_isloaded (boolean: have we loaded and instanciated the mod?)
sub module_isloaded {
   my ($self, $module) = @_;
   unless ($module) {
      $self->mlog(0, "module_isloaded: no module specified");
      return undef;
   };
   $self->mlog(99, "getting status of module '$module'");
   return ($self->{'modules'}{$module} ? 1 : 0);
};

### module_deregister (unload a module, removing all references)
sub module_deregister {
   my ($self,$module) = @_;
   $self->mlog (60,"deregistering module '$module'");
   $self->mlog (99,"unloading module '$module'");
   delete ($self->{'modules'}{$module});
   delete ($self->{'modules_files'}{$module});
};

### module_deregister_all (call module_deregister for all loaded mods)
sub modules_deregister_all {
   my ($self,$module) = @_;
   foreach $module (keys %{$self->{'modules'}}) {
      $self->module_deregister ($module);
   };
};

### modules (return all loaded modules mathing a given pattern or all when no 
### pattern is given)
sub modules {
   my ($self, $pattern) = @_;
   $pattern = ".*" unless ($pattern);

   return grep { /$pattern/ } keys ( %{$self->{'modules'}});
};

### modules_list (print a list of loaded modules to mlog)
sub modules_list {
   my ($self, $pattern) = @_;
   my ($module, $module_name, $module_file, $outputstring);

   $outputstring = "currently loaded modules:\n";
   foreach $module_name ($self->modules ($pattern)) {
      $module_file = ${$self->{'modules_files'}}{$module_name};
      $outputstring .= " - $module_name: $module_file\n";
   };
   $self->mlog(-1, $outputstring);
};

### modules_register_all (load all available modules at once)
# autoload all modules at once (if recursive is set, descend to subdirs)
sub modules_register_all {
   my ($self, $recursive, $mdir, $mext, $internal) = @_;
   my ($dirhandle, $file, @modfiles);

   # we do not register all modules, unless autoload is available
   # to handle the dependencies
   unless ($self->module_autoload()) {
      $self->mlog(1,"please switch module_autoload on before trying to".
                    " auto-register all modules");
      return undef;
   };

   # use the default module directory and extension if none is given
   ($mdir = $self->module_directory() ) unless ($mdir);
   ($mext = $self->module_extension() ) unless ($mext);
   $mdir .= '/' unless ($mdir =~ /\/$/); # fix the path a bit
   
   unless (opendir ($dirhandle, $mdir)) {
      $self->mlog(-1, "modules_register_all(): cannot open ".
                      "module directory $mdir");
      return undef;
   };

   # find module files
   foreach $file (readdir ($dirhandle)) {
       next if ($file =~ /^\./);
       if ( -f $mdir.$file && -r $mdir.$file ) {
          if (length($file) - length($mext)
              == rindex $file, $mext) {
              push @modfiles, $mdir.$file;
          };
       } elsif ($recursive && -d $mdir.$file) {
          @modfiles = ( @modfiles,
             $self->modules_register_all($recursive,
                                         $mdir.$file, $mext, 1) );
       };
   };
   $self->mlog(99, "finished searching modules (found '"/
      (join "', '", @modfiles)."')");
   closedir ($dirhandle) || $self->mlog(-1, "cannot close dir $mdir");

   # some more debugging if called by an "external"
   unless ($internal) {
      foreach $file (@modfiles) {
         $self->mlog(20, "modules_register_all: autoload $file");
         $self->module_register($file, 'nodepends');
      };
   };

   # return all modules loaded
   return @modfiles;   
};

### module_autoload ((de)activate autoloading of modules when 
###                  $modularizer->module($name) is called)
# switch module autoload on/off
sub module_autoload {
   my ($self, $value) = @_;
   
   ($self->{'autoload'} = $value) if (defined $value);
   unless ( ($self->{'module_dir'}) && ($self->{'module_ext'} ) ) { 
      $self->mlog(99,"module_autoload: will only autoload when I'll have ".
                    "'module_directory' and 'module_extension' set!");
      return 2;
   };
   return $self->{'autoload'};
};

### module_directory (get or set the directory containing the mods)
sub module_directory {
   my ($self, $moduledir) = @_;

   if ($moduledir) {
      $moduledir .= '/' unless ($moduledir =~ /\/$/);
      $self->{'module_dir'} = $moduledir;
      $self->mlog(80, "set module directory to $moduledir");
   } else {
      return $self ->{'module_dir'};
   };
};

### module_extension (get or set the extension for module files)
sub module_extension {
   my ($self, $moduleext) = @_;

   if ($moduleext) {
      $self -> {'module_ext'} = $moduleext;
      $self->mlog(80, "set module extension to $moduleext");
   } else {
      return $self ->{'module_ext'};
   };
};

### module (return a reference to the loaded instance of a module,
###         undef on error or when module not loaded and autoload=0)
sub module {
   my ($self,$module_name,$noautoload)=@_;
   if ($self->module_isloaded($module_name)) {
   # just return a reference to the module object if loaded
 
      return ${$self->{'modules'}}{$module_name};
   } else { 
   # else we have to check if we can load the module. If yes, we do that and return 
   # it, otherwise we fail *return undef)
      if ($self->{'autoload'}) {
         if ($noautoload) {
         # autoloading is enabled -> check if we can load
            $self->mlog(5, "module autoload temporarily disabled");
            return undef;
         } else {
            $self->mlog(20, "autoloading module $module_name");
            $self->module_register($module_name);
            if ($self->module_isloaded($module_name)) { 
               return $self->module($module_name);
            } else {
               $self->mlog(0, "ERROR: autoload of module $module_name ".
                              "failed.");
               return undef;
            };
         };
      } else {
      # autoload disabled -> return undef as the module is not loaded yet (programmer
      # should have it loaded manually)
         $self->mlog (0,"module $module_name is not loaded");
         return undef;
      };
   };
};

### DESTROY (desturctor function which will unload all modules)
sub DESTROY {
   my ($self) = @_;
   my ($module);
   my (@loaded_modules);

   @loaded_modules = keys %{$self->{'modules'}};

   if ($#loaded_modules > 0) {

      $self->mlog(99, "App::Modular is going to be destroyed, ".
                      "modules left to destroy");
      foreach $module (@loaded_modules) {
         $self->mlog(99, " -> $module");
      }

      $self->modules_deregister_all();

   } else {
      $self->mlog(99, "App::Modular finishing, no modules left to unload");
   }
   return;
};

# return with something well-defined
1;

##################################
##        DOCUMENTATION         ##
##################################
=pod

=head1 NAME

B<App::Modular> - modularization framework for perl programs

=head1 SYNOPSIS

	package App::Modular::Module::Test;

	use base qw(App::Modular::Module);

	sub say_hello {
   		print "Hello, dear user!";
	};



	package main;

	use App::Modular;

	my $modul = instance App::Modular;

	$modul->module('Test')->say_hello();

	exit;

=head1 DESCRIPTION

App::Modular aims to provide a framework which should it make very
easy to programmes to create any kind of modular program.

It supports:

=over 4

=item * module dependency solving

=item * autoloading of modules

=item * event handling (implemented as a contributed App::Modular module)

=back

=head1 USAGE

The usage description is split into two parts, one describing what the 
main program has to do in order to work with App::Modular, one describing
how to create a module. The explanation is based on an example; I 
suggest you to try to build a little modular script yourself and you'll
soon understand how App::Modular works.
First, we will create a little module that we'll use in the main program
to greet the user.

=head2 A sample Module

Modules come in the form of perl modules; however, they are not expected
to be in one of the inlcude (@INC) directories, but rather in a specific
directory like "/usr/local/lib/app-modular/sample". Their extension does
not default to ".pm" but to ".mom" (App::Modular Module).

Every module should have C<App::Modular::Module> as a base class, as it
inherits some basic methods then automatically. As a package namespace,
you MUST use C<App::Modular::Module::*>, as App::Modular converts the
package/file name in a way that would brake otherwise.

But now, that's enough talking - let's proceed to some real code:

	#!/usr/bin/perl -w
	# File: Printer.mom
	use strict;

	package App::Modular::Module::Printer;

	use base qw(App::Modular::Module);

	sub printer { 
   		shift;
   		App::Modular->instance()->mlog(99, "printer printing!");
   		print(join ' ', @_); 
	};

	1;

As you will have noticed, the module only provides one method - a method
to print a string or an array to stdout. That's not really much. Anyway,
it's enough for our first test: we can see some action.

=head2 Main Program

Now we just need some work for our little bet... Here it comes:

   #!/usr/bin/perl -w
   # File: AppModularSample.pl
   use strict;
   
   package main;
   
   use App::Modular 0.001_001;
   
   my $mod = instance App::Modular;
   
   $mod -> module_directory ('.');
   $mod -> module_extension ('.mom');

   $mod -> module('Printer') -> printer ('Hello,' 'world!', 'How are you?');

=head2 Interdependant Modules

Now that we know how to write a simple module, we can advance to some
more complicated.

!!!FIXME!!! Here should be an example using module dependencies.

Meanwhile, see the fererence for App::Modular::Modul->depends() and the bugs
section of this document.

=head1 REFERENCE

In this man page, you will only find the method descriptions fror hte App::Modular 
object; the standard functions of the application modules can be found in 
L<App::Modular::Module>.

=over 4

=item instance (void)

Returns the one and only instance of App::Modular (inherited from Class::Singleton).

=item loglevel (int level)

Set the logging level (if the number given here is >= the value given to the 
logging function mlog, the message will be logged.

Return value: (int) current log level

=item logtrace (optional bool logtrace)

print stack backtrace on debug output? (returns setting, and sets the value if 
the optional argument is given)

Return value: (bool) value of logtrace

=item mlog (int level, string text)

Do some logging (if the given leven is <= the maximum logging level set before)

Note: Depending on the setting of logtrace the messages will either contain a 
function stack backtrace or not.

Return value: void

=item module_autoload

Set/Get status of autoloading (true => modules will be loaded automatically when needed;
false => no module will ever be loaded without the explicit command).

Return value: (bool) current setting of autoload

=item module_deregister (string module_name_

Unload a App::Modular module. (Internally, this function will delete the reference to the
module, hence perl's garbage collector will destroy the object)

Return value: (void)

=item module_directory (string path)

Get/set the directory that contains the App::Modular modules.

Return value: (string) current setting

=item module_extension (string filespec)

Get/set the extension that is common to all App::Modular modules (e.g. if the module is named
Printer and the file is saved as Printer.mom, the extension is '.mom').

Return value: (string) current value

=item module_isloaded (string module_name)

Is the module named module_name loaded in the system?

Return value: (bool) true if loaded

=item module_register (string module_name | module_path)

Load the module named module_name or from the file named module_path.

Return value: undef on failure; reference to the module object on success

=item modules ([string regexp_pattern])

Returns an array containing the names of all loaded modules. If a pattern is given, only the 
names mathing it are returned.

=item modules_deregister_all (void)

Will unload all modules. (Or to be exact, will call module_deregister for every single loaded
module).

=item modules_list (string regexp_pattern)

Print a list of all modules matching pattern (if given) or just all loaded modules (if no pattern
was given) to the log.

Return value: (void)

=item modules_register_all ( [bool recurs, string module_dir, string module_ext ]);

Register all modules in module_dir with extension module_ext (the standards are used for 
these two variables if nothing is given here). If recurs it true, it will recursively walk
trough all subdirs, with the effect of loading modules in a nested namespace, too 
(e.g. Input::Reader, found at $module_dir/Input/Reader$module_ext).
Note: module_dir and module_ext will only be valid during this procedure; they
will NOT be set as defaults!

Return value: (array of strings) names of all modules loaded

=item Internal-only use methods

=over 8

=item _new_instance (create the instance of App::Modular which will be returned by instance())

=item DESTROY (cleanup on exit/unload of App::Modular)

=back

=back

=head2 Log levels

The modulariyer code usees the following log levels: 
(in general they are all between 0 and 100)

=over 4

=item -1 ABSOLUTELY VITAL messages that should never be switched off

=item 0  FATAL ERRROR

=item 1  ERRORS


=item 2  WARNINGS

=item 10 information

=item 20 notices (more or less unimportant info)

=item 80 normal debugging info (external debugging info)

=item 99 absolute debug information (system internals)

=back

=head1 BUGS

=over 4

=item * Documentation

Documentation should be much better, user-friendly and elaborate.

=item * Testing

This set of modules is tested in a quite limited fashion; I use it in production 
code, however at the moment of this writing no one else tested it. If you have any 
reports, positive or negative, I would be pleased to hear about your experiences.

=item * Logging

The logging mechanism is quite ugly; however, I do not have any idea how a better
one could look like - if you have ideas, please contact me.

=item * Dependency handling not 100% accurate

The pre-requisites of a module are only loaded after the module has been loaded and 
initialized. This results in the module being unable to call functions of its 
pre-requisites during initialization.

=back

=head1 AUTOR

(c) 2003-2005 Baltasar Cevc (baltasar A.T. cevc-topp .D.O.T. de)

Permission to use this software is granted under the terms of the
L<perlartistic> Perl Artistic License, which can should be accessible 
via the C<perldoc perlartistic> command and the file COPYING provided 
with this package.

B<DISCLAIMER>: THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS," AND
COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE
OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS,
TRADEMARKS OR OTHER RIGHTS.
IF YOU USE THIS SOFTWARE, YOU DO SO AT YOUR OWN RISK.

=head1 SEE ALSO

L<App::Modular::Module(3pm)>, L<App::Modular::Module::Events(3pm)>

B<Similar Modules>: L<Module::Pluggable>, L<Object::Meta::Plugin>, L<OpenPlugin>,
L<Template:::Plugin>

=cut
