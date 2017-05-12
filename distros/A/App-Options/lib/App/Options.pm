
#############################################################################
## $Id: Options.pm 14478 2010-10-12 15:49:12Z spadkins $
#############################################################################

package App::Options;

use vars qw($VERSION);
use strict;

use Carp;
use Sys::Hostname;
use Cwd 'abs_path';
use File::Spec;
use Config;

$VERSION = "1.12";

=head1 NAME

App::Options - Combine command line options, environment vars, and option file values (for program configuration)

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;

    use App::Options;   # reads option values into %App::options by default

    # do something with the options (in %App::options)
    use DBI;
    $dsn = "dbi:mysql:database=$App::options{dbname}";
    $dbh = DBI->connect($dsn, $App::options{dbuser}, $App::options{dbpass});
    ...

  Get help from the command line (assuming program is named "prog") ...

    prog -?
    prog --help

  Option values may be provided on the command line, in environment
  variables, and option files.  (i.e. $ENV{APP_DBNAME} would set
  the value of %App::options{dbname} by default.)

  The "dbname" and other options could also be set in one of the
  following configuration files

    /etc/app/policy.conf
    $HOME/.app/prog.conf
    $HOME/.app/app.conf
    $PROGDIR/prog.conf
    $PROGDIR/app.conf
    $PREFIX/etc/app/prog.conf
    $PREFIX/etc/app/app.conf
    /etc/app/app.conf

  with a file format like

    [prog]
    dbname = prod
    dbuser = scott
    dbpass = tiger

  See below for a more detailed explanation of these and other
  advanced features.

=head1 DESCRIPTION

App::Options combines command-line arguments, environment variables,
option files, and program defaults to produce a hash of
option values.

=head1 RELATION TO OTHER CONFIGURATION/OPTION PARSING MODULES

A number of modules are posted on CPAN which do command-line
processing.

 http://search.cpan.org/modlist/Option_Parameter_Config_Processing

App::Options is different than most of the Getopt::* modules
because it integrates the processing of command line options,
environment variables, and config files.

Furthermore, its special treatment of the "perlinc"
option facilitates the inclusion ("use") of application-specific
perl modules from special places to enable the installation of
multiple versions of an application on the same system (i.e.
/usr/myproduct/version).

The description of the AppConfig distribution sounds similar
to what is described here.  However, the following are some key
differences.

 * App::Options does its option processing in the BEGIN block.
   This allows for the @INC variable to be modified in time
   for subsequent "use" and "require" statements.

 * App::Options "sections" (i.e. "[cleanup]") are conditional.
   It is conditional in App::Options, allowing you to use one
   set of option files to configure an entire suite of programs
   and scripts.  In AppConfig, the section name is simply a 
   prefix which gets prepended to subsequest option names.

 * App::Options consults a cascading set of option files.
   These files include those which are system global, project
   global, and user private.  This allows for system
   administrators, project developers, and individual
   users to all have complementary roles in defining
   the configuration values.

 * App::Options is not a toolkit but a standardized way of
   doing option processing.  With AppConfig, you still have
   to decide where to put config files, and you still have to
   code the "--help" feature.  With App::Options, you simply
   "use App::Options;" and all the hard work is done.
   Advanced options can be added later as necessary as args
   to the "use App::Options;" statement.

App::Options is also the easiest command-line processing system
that I have found anywhere. It then provides a smooth transition to
more advanced features only as they are needed.  Every single
quick and dirty script I ever write from now on can afford
to use App::Options.

The documentation of App::Options takes three forms below.

  API Reference - describing the API (methods, args)
  Logic Flow - describing the order and logic of processing
  Usage Tutorial - describing how to use the API in practical situations

=head1 RELATION TO THE P5EE PROJECT

App::Options was motivated by and supports the P5EE/App-Context variant
of the Perl 5 Enterprise Environment (P5EE).  However, App::Options has no
dependency on any other module in the P5EE project, and it is very useful
without any knowledge or use of other elements of the P5EE project.

See the P5EE web sites for more information on the P5EE project.

    http://www.officevision.com/pub/p5ee/index.html

=head1 API REFERENCE: Methods

=cut

#############################################################################
# init()
#############################################################################

=head2 init()

    * Signature: App::Options->init();
    * Signature: App::Options->init(%named);
    * Signature: App::Options->init($myvalues);
    * Signature: App::Options->init($myvalues, %named);
     (NOTE: %named represents a list of name/value pairs used as named args.
            Params listed below without a $ are named args.)
    * Param:  $myvalues     HASH
              specify a hash reference other than %App::options to put
              configuration values in.
    * Param:  values        HASH
              specify a hash reference other than %App::options to put
              configuration values in.
    * Param:  options       ARRAY
              specify a limited, ordered list of options to be displayed
              when the "--help" or "-?" options are invoked
    * Param:  option        HASH
              specify additional attributes of any of
              the various options to the program (see below)
    * Param:  no_cmd_args 
              do not process command line arguments
    * Param:  no_env_vars 
              do not read environment variables
    * Param:  no_option_file 
              do not read in the option file(s)
    * Param:  print_usage 
              provide an alternate print_usage() function
    * Return: void
    * Throws: "App::Options->init(): must have an even number of vars/values for named args"
    * Throws: "App::Options->init(): 'values' arg must be a hash reference"
    * Throws: "App::Options->init(): 'option' arg must be a hash reference"
    * Throws: "App::Options->init(): 'options' arg must be an array reference"
    * Since:  0.60

    Sample Usage: (normal)

    use App::Options;       # invokes init() automatically via import()

    This is functionally equivalent to the following, but that's not
    near as nice to write at the top of your programs.

    BEGIN {
        use App::Options qw(:none); # import() does not call init()
        App::Options->init();       # we call init() manually
    }

    Or we could have used a more full-featured version ...

    use App::Options (
        values => \%MyPackage::options,
        options => [ "option_file", "prefix", "app",
                     "perlinc", "debug_options", "import", ],
        option => {
            option_file   => { default => "~/.app/app.conf" },         # set default
            app           => { default => "app", type => "string" }, # default & type
            prefix        => { type => "string", required => 1; env => "PREFIX" },
            perlinc       => undef,         # no default
            debug_options => { type => "int" },
            import        => { type => "string" },
            flush_imports => 1,
        },
        no_cmd_args => 1,
        no_env_vars => 1,
        no_option_file => 1,
        print_usage => sub { my ($values, $init_args) = @_; print "Use it right!\n"; },
    );

The init() method is usually called during the import() operation
when the normal usage ("use App::Options;") is invoked.

The init() method reads the command line args (@ARGV),
then finds an options file, and loads it, all in a way which
can be done in a BEGIN block (minimal dependencies).  This is
important to be able
to modify the @INC array so that normal "use" and "require"
statements will work with the configured @INC path.

The following named arguments are understood by the init() method.

    values - specify a hash reference other than %App::options to
             put option values in.
    options - specify a limited, ordered list of options to be
              displayed when the "--help" or "-?" options are invoked
    option - specify optional additional information about any of
             the various options to the program (see below)
    no_cmd_args - do not process command line arguments
    no_env_vars - do not read environment variables
    no_option_file - do not read in the option file
    show_all - force showing all options in "--help" even when
             "options" list specified
    print_usage - provide an alternate print_usage() function
    args_description - provide descriptive text for what the args
             of the program are (command line args after the options).
             This is printed in the usage page (--help or -?).
             By default, it is simply "[args]".

The additional information that can be specified about any individual
option variable using the "option" arg above is as follows.

    default - the default value if none supplied on the command
        line, in an environment variable, or in an option file
    required - the program will not run unless a value is provided
        for this option
    type - if a value is provided, the program will not run unless
        the value matches the type ("string", "integer", "float",
        "boolean", "date", "time", "datetime", "/regexp/").
    env - a list of semicolon-separated environment variable names
        to be used to find the value instead of "APP_{VARNAME}".
    description - printed next to the option in the "usage" page
    secure - identifies an option as being "secure" (i.e. a password)
        and that it should never be printed in plain text in a help
        message (-?).  All options which end in "pass", "passwd", or
        "password" are also assumed to be secure unless a secure => 0
        setting exists. If the value of the "secure" attribute is greater
        than 1, a heightened security level is enforced: 2=ensure that
        the value can never be supplied on a command line or from the
        environment but only from a file that only the user running the
        program has read/write access to.  This value will also never be
        read from the environment or the command line because these are
        visible to other users.  If the security_policy_level variable
        is set, any true value for the "secure" attribute will result in
        the value being set to the "security_policy_level" value.
    value_description - printed within angle brackets ("<>") in the
        "usage" page as the description of the option value
        (i.e. --option_name=<value_description>)

The init() method stores command line options and option
file values all in the global %App::options hash (unless the
"values" argument specifies another reference to a hash to use).

The special options are as follows.

    option_file - specifies the exact file name of the option file to be
       used (i.e. "app --option_file=/path/to/app.conf").

    app - specifies the tag that will be used when searching for
       an option file. (i.e. "app --app=myapp" will search for "myapp.conf"
       before it searches for "app.conf")
       "app" is automatically set with the stem of the program file that 
       was run (or the first part of PATH_INFO) if it is not supplied at
       the outset as an argument.

    prefix - This represents the base directory of the software
       installation (i.e. "/usr/myproduct/1.3.12").  If it is not
       set explicitly, it is detected from the following places:
          1. PREFIX environment variable
          2. the real path of the program with /bin or /cgi-bin stripped
          3. /usr/local (or whatever "prefix" perl was compiled with)
       If it is autodetected from one of those three places, that is
       only provisional, in order to find the "option_file".  The "prefix"
       variable should be set authoritatively in the "option_file" if it
       is desired to be in the $values structure.

    perlinc - a path of directories to prepend to the @INC search path.
       This list of directories is separated by any combination of
       [,; ] characters.

    debug_options - if this is set, a variety of debug information is
       printed out during the option processing.  This helps in debugging
       which option files are being used and what the resulting variable
       values are.  The following numeric values are defined.

          1 = print the basic steps of option processing
          2 = print each option file searched, final values, and resulting @INC
          3 = print each value as it is set in the option hash
          4 = print overrides from ENV and variable substitutions
          5 = print each line of each file with exclude_section indicator
          6 = print option file section tags, condition evaluation, and
              each value found (even if it is not set in the final values)
          7 = print final values

    import - a list of additional option files to be processed.
       An imported file goes on the head of the queue of files to be
       processed.

    hostname - the hostname as returned by the hostname() function
       provided by Sys::Hostname (may or may not include domain
       qualifiers as a fully qualified domain name).

    host - same as hostname, but with any trailing domain name removed.
       (everything after the first ".")

    flush_imports - flush all pending imported option files.

    security_policy_level - When set, this enforces that whenever secure
       attributes are applied, they are set to the same level. When set
       0, all of the security features are disabled (passwords can be
       viewed with "--security_policy_level=0 --help").  When set to 2,
       all secure options can only be read from files which do not have
       read/write permission by any other user except the one running the
       program.

=cut

my ($default_option_processor);  # a reference to the singleton App::Options object that parsed the command line
my (%path_is_secure);

# This translates the procedural App::Options::import() into the class method App::Options->_import() (for subclassing)
sub import {
    my ($package, @args) = @_;
    $package->_import(@args);
}

sub _import_test {
    my ($class, @args) = @_;
    $default_option_processor = undef;
    $class->_import(@args);
}

sub _import {
    my ($class, @args) = @_;

    # We only do this once (the default App::Options option processor is a singleton)
    if (!$default_option_processor) {
        # can supply initial hashref to use for option values instead of global %App::options
        my $values = ($#args > -1 && ref($args[0]) eq "HASH") ? shift(@args) : \%App::options;

        ($#args % 2 == 1) || croak "App::Options::import(): must have an even number of vars/values for named args";
        my $init_args = { @args };

        # "values" in named arg list overrides the one supplied as an initial hashref
        if (defined $init_args->{values}) {
            (ref($init_args->{values}) eq "HASH") || croak "App::Options->new(): 'values' arg must be a hash reference";
            $values = $init_args->{values};
        }

        my $option_processor = $class->new($init_args);
        $default_option_processor = $option_processor;   # save it in the singleton location

        $option_processor->read_options($values);        # read in all the options from various places
        $option_processor->{values} = $values;           # store it for future (currently undefined) uses
    }
}

sub new {
    my ($this, $init_args) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    $self->{init_args} = $init_args;
    $self->{argv}      = [ @ARGV ];
    $self->{options}   = [ ];
    bless $self, $class;
    return($self);
}

sub read_options {
    my ($self, $values) = @_;

    #######################################################################
    # populate "option" (the information about each option!)
    #######################################################################

    my ($var, $value, @vars);
    my $init_args = $self->{init_args};
    my $option_defs = $init_args->{option} || {};
    my (%secure_options, %option_source);

    if ($option_defs) {
        croak "App::Options->read_options(): 'option' arg must be a hash reference"
            if (ref($option_defs) ne "HASH");

        my (@args, $option_def, $arg);
        # Convert archaic forms where everything is packed in a scalar, to the newer,
        # more verbose form where attributes of an option are in a hashref.
        foreach $var (keys %$option_defs) {
            $value = $option_defs->{$var};
            if (ref($value) eq "") {
                $option_def = {};
                $option_defs->{$var} = $option_def;
                @args = split(/ *; */,$value);
                foreach $arg (@args) {
                    if ($arg =~ /^([^=]+)=(.*)$/) {
                        $option_def->{$1} = $2;
                    }
                    elsif (! defined $option_def->{default}) {
                        $option_def->{default} = $arg;
                    }
                    else {
                        $option_def->{$arg} = 1;
                    }
                }
            }
            else {
                $option_def = $value;
            }
            if (! defined $option_def->{secure} && $var =~ /(pass|password|passwd)$/) {
                $option_def->{secure} = 1;
            }
        }
    }
    if ($init_args->{options}) {
        foreach $var (@{$init_args->{options}}) {
            if (! defined $option_defs->{$var}{secure} && $var =~ /(pass|password|passwd)$/) {
                $option_defs->{$var}{secure} = 1;
            }
        }
    }

    #################################################################
    # we do all this within a BEGIN block because we want to get an
    # option file and update @INC so that it will be used by
    # "require" and "use".
    # The global option hash (%App::options) is set from 3 sources:
    # command line options, environment variables, and option files.
    #################################################################

    #################################################################
    # 0. Set system-supplied values (i.e. hostname/host)
    #################################################################
    my $host = hostname;
    $values->{hostname} = $host;
    $host =~ s/\..*//;   # get rid of extra domain name qualifiers
    $values->{host} = $host;

    #################################################################
    # 1. Read the command-line options
    # (anything starting with one or two dashes is an option var
    # i.e. --debugmode=record  -debugmode=replay
    # an option without an "=" (i.e. --help) acts as --help=1
    # Put the var/value pairs in %$values
    #################################################################
    my $debug_options = $values->{debug_options} || 0;
    my $show_help = 0;
    my $show_version = 0;
    my $exit_status = -1;

    if (! $init_args->{no_cmd_args}) {
        my $options = $self->{options};
        while ($#ARGV >= 0 && $ARGV[0] =~ /^--?([^=-][^=]*)(=?)(.*)/) {
            $var = $1;
            $value = ($2 eq "") ? 1 : $3;
            push(@$options, shift @ARGV);
            if ($option_defs->{$var} && $option_defs->{$var}{secure} && defined $values->{security_policy_level} && $values->{security_policy_level} >= 2) {
                $exit_status = 1;
                print "Error: \"$var\" may not be supplied on the command line because it is a secure option.\n";
            }
            $values->{$var} = $value;
            $option_source{$var} = "CMDLINE";
        }
        if ($#ARGV >= 0 && $ARGV[0] eq "--") {
            shift @ARGV;
        }
        if ($values->{help}) {
            $show_help = 1;
            delete $values->{help};
        }
        elsif ($values->{"?"}) {
            $show_help = 1;
            delete $values->{"?"};
        }
        elsif ($values->{version}) {
            $show_version = $values->{version};
            delete $values->{version};
        }
        $debug_options = $values->{debug_options} || 0;
        print STDERR "1. Parsed Command Line Options. [@$options]\n" if ($debug_options);
    }
    else {
        print STDERR "1. Skipped Command Line Option Parsing.\n" if ($debug_options);
    }

    #################################################################
    # 2. find the directory the program was run from.
    #    we will use this directory to search for the
    #    option file.
    #################################################################

    my ($prog_cat, $prog_dir, $prog_file);
    # i.e. C:\perl\bin\app, \app
    ($prog_cat, $prog_dir, $prog_file) = File::Spec->splitpath($0);
    $prog_dir =~ s!\\!/!g;   # transform to POSIX-compliant (forward slashes)
    $prog_dir =~ s!/$!! if ($prog_dir ne "/");   # remove trailing slash
    $prog_dir =  "." if ($prog_dir eq "");
    $prog_dir =  $prog_cat . $prog_dir if ($^O =~ /MSWin32/ and $prog_dir =~ m!^/!);

    #################################################################
    # 3. guess the "prefix" directory for the entire
    #    software installation.  The program is usually in
    #    $prefix/bin or $prefix/cgi-bin.
    #################################################################
    my $prefix = $values->{prefix};  # possibly set on command line
    my $prefix_origin = "command line";

    # it can be set in environment.
    if (!$prefix && $ENV{PREFIX}) {
        $prefix = $ENV{PREFIX};
        $prefix_origin = "environment";
    }

    # Using "abs_path" gets rid of all symbolic links and gives the real path
    # to the directory in which the script runs.
    if (!$prefix) {
        my $abs_prog_dir = abs_path($prog_dir);
        $abs_prog_dir =~ s!\\!/!g;   # transform to POSIX-compliant (forward slashes)
        $abs_prog_dir =~ s!/$!! if ($abs_prog_dir ne "/");   # remove trailing slash
        if ($abs_prog_dir =~ s!/bin$!!) {
            $prefix = $abs_prog_dir;
            $prefix_origin = "parent of bin dir";
        }
        elsif ($abs_prog_dir =~ s!/cgi-bin.*$!!) {
            $prefix = $abs_prog_dir;
            $prefix_origin = "parent of cgi-bin dir";
        }
    }

    if (!$prefix) {   # last resort: perl's prefix
        $prefix = $Config{prefix};
        $prefix =~ s!\\!/!g;   # transform to POSIX-compliant
        $prefix =~ s!/$!! if ($prefix ne "/");   # remove trailing slash
        $prefix_origin = "perl prefix";
    }
    print STDERR "3. Provisional prefix Set. prefix=[$prefix] origin=[$prefix_origin]\n"
        if ($debug_options);

    #################################################################
    # 4. find the app.
    #    by default this is the basename of the program
    #    in a web application, this is overridden by any existing
    #    first part of the PATH_INFO
    #################################################################
    my $app = $values->{app};
    my $app_origin = "command line";
    if (!$app) {
        ($app, $app_origin) = App::Options->determine_app($prefix, $prog_dir, $prog_file, $ENV{PATH_INFO}, $ENV{HOME});
        $values->{app} = $app;
    }
    print STDERR "4. Set app variable. app=[$app] origin=[$app_origin]\n" if ($debug_options);
    #print STDERR "04 option_defs [", join("|", sort keys %$option_defs), "]\n";

    my ($env_var, @env_vars, $regexp);
    if (! $init_args->{no_option_file}) {
        #################################################################
        # 5. Define the standard places to look for an option file
        #################################################################
        my @option_files = ();
        push(@option_files, "/etc/app/policy.conf");
        push(@option_files, $values->{option_file}) if ($values->{option_file});
        push(@option_files, "$ENV{HOME}/.app/$app.conf") if ($ENV{HOME} && $app ne "app");
        push(@option_files, "$ENV{HOME}/.app/app.conf") if ($ENV{HOME});
        push(@option_files, "$prog_dir/$app.conf") if ($app ne "app");
        push(@option_files, "$prog_dir/app.conf");
        push(@option_files, "\${prefix}/etc/app/$app.conf") if ($app ne "app");
        push(@option_files, "\${prefix}/etc/app/app.conf");
        push(@option_files, "/etc/app/app.conf");

        #################################################################
        # 5. now actually read in the file(s)
        #    we read a set of standard files, and
        #    we may continue to read in additional files if they
        #    are indicated by an "import" line
        #################################################################
        print STDERR "5. Scanning Option Files\n" if ($debug_options);

        $self->read_option_files($values, \@option_files, $prefix, $option_defs);

        $debug_options = $values->{debug_options} || 0;
    }
    else {
        print STDERR "5. Skip Option File Processing\n" if ($debug_options);
    }
    #print STDERR "05 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");
    if ($values->{perl_restart} && !$ENV{MOD_PERL} && !$ENV{PERL_RESTART}) {
        $ENV{PERL_RESTART} = 1;
        exec($^X, $0, @{$self->{argv}});
    }

    #################################################################
    # 6. fill in ENV vars
    #################################################################

    if (!$init_args->{no_env_vars}) {
        @vars = ();
        if ($init_args->{options}) {
            croak "App::Options->read_options(): 'options' arg must be an array reference"
                if (ref($init_args->{options}) ne "ARRAY");
            push(@vars, @{$init_args->{options}});
        }

        if ($option_defs) {
            push(@vars, (sort keys %$option_defs));
        }

        print STDERR "6. Scanning for Environment Variables.\n" if ($debug_options);

        foreach $var (@vars) {
            if (!defined $values->{$var}) {
                $value = undef;
                if (!$init_args->{no_env_vars}) {
                    if ($option_defs && defined $option_defs->{$var}{env}) {
                        if ($option_defs->{$var}{env} eq "") {
                            @env_vars = ();
                        }
                        else {
                            @env_vars = split(/[,;]/, $option_defs->{$var}{env});
                        }
                    }
                    else {
                        @env_vars = ( "APP_" . uc($var) );
                    }
                    foreach $env_var (@env_vars) {
                        if ($env_var && defined $ENV{$env_var}) {
                            $value = $ENV{$env_var};
                            print STDERR "         Env Var Found : [$var] = [$value] from [$env_var] of [@env_vars].\n"
                                if ($debug_options >= 4);
                            last;
                        }
                    }
                }
                # do variable substitutions, var = ${prefix}/bin, var = $ENV{PATH}
                if (defined $value) {
                    if ($value =~ /\{.*\}/) {
                        $value =~ s/\$\{([a-zA-Z0-9_\.-]+)\}/(defined $values->{$1} ? $values->{$1} : "")/eg;
                        $value =~ s/\$ENV\{([a-zA-Z0-9_\.-]+)\}/(defined $ENV{$1} ? $ENV{$1} : "")/eg;
                        print STDERR "         Env Var Underwent Substitutions : [$var] = [$value]\n"
                            if ($debug_options >= 4);
                    }
                    else {
                        print STDERR "         Env Var : [$var] = [$value]\n"
                            if ($debug_options >= 3);
                    }
                    $values->{$var} = $value;    # save all in %App::options
                    $option_source{$var} = "ENV";
                }
            }
        }

        foreach $env_var (keys %ENV) {
            next if ($env_var !~ /^APP_/);
            $var = lc($env_var);
            $var =~ s/^app_//;
            if (! defined $values->{$var}) {
                if ($option_defs->{$var} && $option_defs->{$var}{secure} && defined $values->{security_policy_level} && $values->{security_policy_level} >= 2) {
                    $exit_status = 1;
                    print "Error: \"$var\" may not be supplied from the environment ($env_var) because it is a secure option.\n";
                }
                $values->{$var} = $ENV{$env_var};
                $option_source{$var} = "ENV";
                print STDERR "         Env Var [$var] = [$value] from [$env_var] (assumed).\n"
                    if ($debug_options >= 3);
            }
        }
        $debug_options = $values->{debug_options} || 0;
    }
    else {
        print STDERR "6. Skipped Environment Variable Processing\n" if ($debug_options);
    }
    #print STDERR "06 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");

    #################################################################
    # 7. establish the definitive (not inferred) $prefix
    #################################################################
    if ($values->{prefix}) {
        if ($prefix eq $values->{prefix}) {
            print STDERR "7. Definitive prefix found [$prefix] (no change)\n" if ($debug_options);
        }
        else {
            print STDERR "7. Definitive prefix found [$prefix] => [$values->{prefix}]\n" if ($debug_options);
            $prefix = $values->{prefix};
        }
    }
    else {
        $values->{prefix} = $prefix;
        print STDERR "7. prefix Made Definitive [$prefix]\n" if ($debug_options);
    }
    #print STDERR "07 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");

    #################################################################
    # 8. set defaults
    #################################################################
    if ($option_defs) {
        @vars = (defined $init_args->{options}) ? @{$init_args->{options}} : ();
        push(@vars, (sort keys %$option_defs));

        print STDERR "8. Set Defaults.\n" if ($debug_options);

        foreach $var (@vars) {
            if (!defined $values->{$var}) {
                if (defined $option_defs->{$var} && defined $option_defs->{$var}{default} && $option_defs->{$var}{secure} &&
                    defined $values->{security_policy_level} && $values->{security_policy_level} >= 2) {
                    $exit_status = 1;
                    print "Error: \"$var\" may not be supplied as a program default because it is a secure option.\n";
                }
                $value = $option_defs->{$var}{default};
                # do variable substitutions, var = ${prefix}/bin, var = $ENV{PATH}
                if (defined $value) {
                    if ($value =~ /\{.*\}/) {
                        $value =~ s/\$\{([a-zA-Z0-9_\.-]+)\}/(defined $values->{$1} ? $values->{$1} : "")/eg;
                        $value =~ s/\$ENV\{([a-zA-Z0-9_\.-]+)\}/(defined $ENV{$1} ? $ENV{$1} : "")/eg;
                        print STDERR "   Default Underwent Substitutions : [$var] = [$value]\n"
                            if ($debug_options >= 4);
                    }
                    $values->{$var} = $value;    # save all in %App::options
                    $option_source{$var} = "DEFAULT";
                    print STDERR "         Default Var [$var] = [$value]\n" if ($debug_options >= 3);
                }
            }
        }
    }
    else {
        print STDERR "8. Skipped Defaults (no option defaults defined)\n" if ($debug_options);
    }
    #print STDERR "08 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");

    #################################################################
    # 9. add "perlinc" directories to @INC, OR
    #    automatically include (if not already) the directories
    #    $PREFIX/lib/$^V and $PREFIX/lib/site_perl/$^V
    #    i.e. /usr/mycompany/lib/5.6.1 and /usr/mycompany/lib/site_perl/5.6.1
    #################################################################

    if (defined $values->{perlinc}) {    # add perlinc entries
        if ($values->{perlinc}) {
            unshift(@INC, split(/[,; ]+/,$values->{perlinc}));
            if ($debug_options >= 2) {
                print STDERR "9. perlinc Directories Added to \@INC\n   ",
                    join("\n   ", @INC), "\n";
            }
        }
        else {
            print STDERR "9. No Directories Added to \@INC\n" if ($debug_options >= 2);
        }
    }
    else {
        my $libdir = "$prefix/lib";
        my $libdir_found = 0;
        # Look to see whether this PREFIX has been included already in @INC.
        # If it has, we do *not* want to automagically guess which directories
        # should be searched and in which order.
        foreach my $incdir (@INC) {
            if ($incdir =~ m!^$libdir!) {
                $libdir_found = 1;
                last;
            }
        }

        # The traditional way to install software from CPAN uses
        # ExtUtils::MakeMaker via Makefile.PL with the "make install"
        # command.  If you are installing this software to non-standard
        # places, you would use the "perl Makefile.PL PREFIX=$PREFIX"
        # command.  This would typically put modules into the
        # $PREFIX/lib/perl5/site_perl/$perlversion directory.

        # However, a newer way to install software (and recent versions
        # of CPAN.pm understand this) uses Module::Build via Build.PL
        # with the "Build install" command.  If you are installing this
        # software to non-standard places, you would use the 
        # "perl Build.PL install_base=$PREFIX" command.  This would
        # typically put modules into the $PREFIX/lib directory.

        # So if we need to guess about extra directories to add to the
        # @INC variable ($PREFIX/lib is nowhere currently represented
        # in @INC), we should add directories which work for software
        # installed with either Module::Build or ExtUtils::MakeMaker.

        if (!$libdir_found) {
            unshift(@INC, "$libdir");
            if ($^V) {
                my $perlversion = sprintf("%vd", $^V);
                unshift(@INC, $libdir);
                if (-d "$libdir/perl5") {
                    unshift(@INC, "$libdir/perl5/site_perl/$perlversion");  # site_perl goes first!
                    unshift(@INC, "$libdir/perl5/$perlversion");
                }
                elsif (-d "$libdir/perl") {
                    unshift(@INC, "$libdir/perl/site_perl/$perlversion");   # site_perl goes first!
                    unshift(@INC, "$libdir/perl/$perlversion");
                }
                if (-d "$prefix/share/perl") {
                    unshift(@INC, "$prefix/share/perl/site_perl/$perlversion");   # site_perl goes first!
                    unshift(@INC, "$prefix/share/perl/$perlversion");
                }
            }
        }
        if ($debug_options >= 2) {
            print STDERR "9. Standard Directories Added to \@INC (libdir_found=$libdir_found)\n   ",
                join("\n   ", @INC), "\n";
        }
    }
    #print STDERR "09 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");

    #################################################################
    # 10. print stuff out for options debugging
    #################################################################

    if ($debug_options >= 7) {
        print STDERR "FINAL VALUES: \%App::options (or other) =\n";
        foreach $var (sort keys %$values) {
            if (defined $values->{$var}) {
                print STDERR "   $var = [$values->{$var}]\n";
            }
            else {
                print STDERR "   $var = [undef]\n";
            }
        }
    }

    #################################################################
    # 11. print version information (--version)
    #################################################################

    if ($show_version) {
        &print_version($prog_file, $show_version, $values);
        exit(0);
    }

    #################################################################
    # 12. perform validations, print help, and exit
    #################################################################

    if ($show_help) {
        $exit_status = 0;
    }
    #print STDERR "12 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");

    #################################################################
    # These are the actual Perl regular expressions which match
    # numbers.  The regexes we use are approximately correct.
    #################################################################
    # \d(_?\d)*(\.(\d(_?\d)*)?)?[Ee][\+\-]?(\d(_?\d)*)  12 12.34 12.
    # \.\d(_?\d)*[Ee][\+\-]?(\d(_?\d)*)                 .34
    # 0b[01](_?[01])*
    # 0[0-7](_?[0-7])*
    # 0x[0-9A-Fa-f](_?[0-9A-Fa-f])*

    my ($type);
    if ($option_defs) {
        @vars = (sort keys %$option_defs);
        foreach $var (@vars) {
            $type = $option_defs->{$var}{type};
            next if (!$type);  # nothing to validate against
            $value = $values->{$var};
            next if (! defined $value);
            if ($type eq "integer") {
                if ($value !~ /^-?[0-9_]+$/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must be of type \"$type\" (not \"$value\")\n";
                }
            }
            elsif ($type eq "float") {
                if ($value !~ /^-?[0-9_]+\.?[0-9_]*([eE][+-]?[0-9_]+)?$/ &&
                    $value !~ /^-?\.[0-9_]+([eE][+-]?[0-9_]+)?$/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must be of type \"$type\" (not \"$value\")\n";
                }
            }
            elsif ($type eq "string") {
                # anything is OK
            }
            elsif ($type eq "boolean") {
                if ($value !~ /^[01]$/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must be of type \"$type\" (\"0\" or \"1\") (not \"$value\")\n";
                }
            }
            elsif ($type eq "date") {
                if ($value !~ /^[0-9]{4}-[01][0-9]-[0-3][0-9]$/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must be of type \"$type\" (format \"YYYY-MM-DD\") (not \"$value\")\n";
                }
            }
            elsif ($type eq "datetime") {
                if ($value !~ /^[0-9]{4}-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]$/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must be of type \"$type\" (format \"YYYY-MM-DD HH:MM:SS\") (not \"$value\")\n";
                }
            }
            elsif ($type eq "time") {
                if ($value !~ /^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must be of type \"$type\" (format \"HH:MM:SS\") (not \"$value\")\n";
                }
            }
            elsif ($type =~ m!^/(.*)/$!) {
                $regexp = $1;
                if ($value !~ /$regexp/) {
                    $exit_status = 1;
                    print "Error: \"$var\" must match \"$type\" (not \"$value\")\n";
                }
            }
        }
        foreach $var (@vars) {
            next if (!$option_defs->{$var}{required} || defined $values->{$var});
            $exit_status = 1;
            print "Error: \"$var\" is a required option but is not defined\n";
        }
    }

    #print STDERR "13 option_defs [", join("|", sort keys %$option_defs), "]\n" if ($prefix eq "/usr");
    if ($exit_status >= 0) {
        if ($init_args->{print_usage}) {
            &{$init_args->{print_usage}}($values, $init_args);
        }
        else {
            App::Options->print_usage($values, $init_args);
        }
        exit($exit_status);
    }
}

# ($app, $app_origin) = App::Options->determine_app($prefix, $prog_dir, $prog_file, $ENV{PATH_INFO}, $ENV{HOME});
sub determine_app {
    my ($class, $prefix, $prog_dir, $prog_file, $path_info, $home_dir) = @_;
    my ($app, $app_origin);
    $path_info ||= "";
    $path_info =~ s!/+$!!;    # strip off trailing slashes ("/")
    if ($path_info && $path_info =~ m!^/([^/]+)!) {
        my $path_info_app = $1;  # first part of PATH_INFO (without slashes)
        if ($home_dir && -f "$home_dir/.app/$path_info_app.conf") {
            $app = $path_info_app;
            $app_origin = "PATH_INFO=$path_info matches $home_dir/.app/$path_info_app.conf";
        }
        elsif (-f "$prog_dir/$path_info_app.conf") {
            $app = $path_info_app;
            $app_origin = "PATH_INFO=$path_info matches $prog_dir/$path_info_app.conf";
        }
        elsif (-f "$prefix/etc/app/$path_info_app.conf") {
            $app = $path_info_app;
            $app_origin = "PATH_INFO=$path_info matches $prefix/etc/app/$path_info_app.conf";
        }
    }
    if (!$app) {
        $app = $prog_file;    # start with the full program name
        $app =~ s/\.[^.]+$//; # strip off trailing file type (i.e. ".pl")
        $app_origin = "program name ($0)";
    }
    if (wantarray) {
        return($app, $app_origin);
    }
    else {
        return($app);
    }
}

sub print_usage {
    my ($self, $values, $init_args) = @_;
    $values = {} if (!$values);
    $init_args = {} if (!$init_args);

    my ($args_description);
    if (defined $init_args->{args_description}) {
        $args_description = " " . $init_args->{args_description};
    }
    else {
        $args_description = " [args]";
    }

    print STDERR "Usage: $0 [options]$args_description\n";
    printf STDERR "       --%-32s print this message (also -?)\n", "help";
    my (@vars, $show_all, %option_seen);
    $show_all = $init_args->{show_all};
    $show_all = $values->{show_all} if (defined $values->{show_all});
    $show_all = 1 if (!defined $show_all && !defined $init_args->{option} && !defined $init_args->{options});
    #print "DEBUG: show_all=[$show_all] option=[$init_args->{option}] options=[$init_args->{options}]\n" if ($values->{foo});
    if ($init_args->{options}) {
        @vars = @{$init_args->{options}};
    }
    if ($init_args->{option}) {
        push(@vars, (sort keys %{$init_args->{option}}));
    }
    if ($show_all) {
        push(@vars, (sort keys %$values));
    }
    my ($var, $value, $type, $desc, $option_defs);
    my ($var_str, $value_str, $type_str, $desc_str, $val_desc, $secure);
    $option_defs = $init_args->{option} || {};
    foreach $var (@vars) {
        next if ($option_seen{$var});
        $option_seen{$var} = 1;
        next if ($var eq "?" || $var eq "help");
        $value  = $values->{$var};
        $type   = $option_defs->{$var}{type} || "";
        $desc   = $option_defs->{$var}{description} || "";
        $secure = $option_defs->{$var}{secure};
        $secure = 1 if (! defined $secure && $var =~ /(pass|password|passwd)$/);
        $secure = $values->{security_policy_level} if (defined $secure && defined $values->{security_policy_level});
        $val_desc  = $option_defs->{$var}{value_description} || "";
        $var_str   = ($type eq "boolean") ? $var : ($val_desc ? "$var=<$val_desc>" : "$var=<value>");
        $value_str = (defined $value) ? ($secure ? "********" : $value) : "undef";
        $type_str  = ($type) ? " ($type)" : "";
        $desc_str  = ($desc) ? " $desc"   : "";
        $desc_str  =~ s/%/%%/g;
        printf STDERR "       --%-32s [%s]$type_str$desc_str\n", $var_str, $value_str;
    }
    #print STDERR "PU option_defs [", join("|", sort keys %$option_defs), "]\n" if ($values->{prefix} eq "/usr");
}

sub print_version {
    my ($self, $prog_file, $show_version, $values) = @_;
    print "Program: $prog_file\n";
    print "(use --version_packages to see version info for specific perl packages)\n";
    my ($module, $package, $version, $full_path);
    if ($values->{version_packages}) {
        foreach my $package (split(/[ ;,]+/,$values->{version_packages})) {
            $module = "$package.pm";
            $module =~ s!::!/!g;
            if ($package =~ /^[A-Z][A-Za-z0-9:_]*$/) {
                eval {
                    require $module;
                };
                if ($@) {
                    my $error = $@;
                    $error =~ s/ *\(\@INC contains:.*//s;
                    print "WARNING: $package: $error\n";
                }
            }
        }
    }
    print "Version Package\n";
    print "------- ----------------------------\n";
    printf("%7s main\n", $main::VERSION || "undef");

    my ($show_module, @package_pattern, $version_sys_packages);

    # There are lots of modules which get loaded up which have
    # nothing to do with your program and which you would ordinarily
    # not want to see.  So ...
    #    --version=1  will show only the packages you specify
    #    --version=2  will show all packages
    if ($values->{version_packages}) {
        $version_sys_packages = $values->{version_sys_packages};
        $version_sys_packages = "App::Options,Carp,Sys::Hostname,Cwd,File::Spec,Config"
            if (!defined $version_sys_packages);
        @package_pattern = split(/[ ;,]+/,$version_sys_packages);
        if ($values->{version_packages}) {
            push(@package_pattern, split(/[ ;,]+/,$values->{version_packages}));
        }
    }

    # I should look into doing this from the symbol table rather
    # than %INC which reflects the *modules*, not the packages.
    # For most purposes, this will be good enough.
    foreach $module (sort keys %INC) {
        $full_path = $INC{$module};
        $package = $module;
        $package =~ s/\.p[lm]$//;
        $package =~ s!/!::!g;

        if ($values->{version_packages} && $show_version ne "all") {
            $show_module = 0;
            foreach my $package_pattern (@package_pattern) {
                if ($package =~ /$package_pattern/) {
                    $show_module = 1;
                    last;
                }
            }
        }
        else {
            $show_module = 1;
        }

        if ($show_module) {
            $version = "";
            eval "\$version = \$${package}::VERSION;";
            $version = "undef" if (!$version);
            printf("%7s %-20s\n", $version, $package);
            #printf("%7s %-20s %s\n", "", $module, $full_path);
        }
    }
}

sub read_option_files {
    my ($self, $values, $option_files, $prefix, $option_defs) = @_;
    my $init_args = $self->{init_args};
    local(*App::Options::FILE);
    my ($option_file, $exclude_section, $var, @env_vars, $env_var, $value, $regexp);
    my ($cond, @cond, $exclude, $heredoc_end);
    my $debug_options = $values->{debug_options} || 0;
    my $is_mod_perl = $ENV{MOD_PERL};
    while ($#$option_files > -1) {
        $option_file = shift(@$option_files);
        if ($option_file =~ m!\$\{prefix\}!) {
            if ($values->{prefix}) {
                $option_file =~ s!\$\{prefix\}!$values->{prefix}!;
            }
            else {
                $option_file =~ s!\$\{prefix\}!$prefix!;
            }
        }
        $exclude_section = 0;
        print STDERR "   Looking for Option File [$option_file]" if ($debug_options);
        if (open(App::Options::FILE, "< $option_file")) {
            print STDERR " : Found\n" if ($debug_options);
            my ($orig_line);
            while (<App::Options::FILE>) {
                chomp;
                s/\r$//;   # remove final CR (for Windows files)
                $orig_line = $_;
                # for lines that are like "[regexp]" or even "[regexp] var = value"
                # or "[value;var=value]" or "[/regexp/;var1=value1;var2=/regexp2/]"
                if (s!^\s*\[(.*)\]\s*!!) {
                    print STDERR "         Checking Section : [$1]\n" if ($debug_options >= 6);
                    @cond = split(/;/,$1);   # separate the conditions that must be satisfied
                    $exclude = 0;            # assume the condition allows inclusion (! $exclude)
                    foreach $cond (@cond) {  # check each condition
                        if ($cond =~ /^([^=]+)=(.*)$/) {  # i.e. [city=ATL] or [name=/[Ss]tephen/]
                            $var = $1;
                            $value = $2;
                        }
                        else {              # i.e. [go] matches the program (app) named "go"
                            $var = "app";
                            $value = $cond;
                        }
                        if ($value =~ m!^/(.*)/$!) {  # variable's value must match the regexp
                            $regexp = $1;
                            $exclude = ((defined $values->{$var} ? $values->{$var} : "") !~ /$regexp/) ? 1 : 0;
                            print STDERR "         Checking Section Condition var=[$var] [$value] matches [$regexp] : result=",
                                ($exclude ? "[ignore]" : "[use]"), "\n"
                                if ($debug_options >= 6);
                        }
                        elsif ($var eq "app" && ($value eq "" || $value eq "ALL")) {
                            $exclude = 0;   # "" and "ALL" are special wildcards for the "app" variable
                            print STDERR "         Checking Section Condition var=[$var] [$value] = ALL : result=",
                                ($exclude ? "[ignore]" : "[use]"), "\n"
                                if ($debug_options >= 6);
                        }
                        else {  # a variable's value must match exactly
                            $exclude = ((defined $values->{$var} ? $values->{$var} : "") ne $value) ? 1 : 0;
                            print STDERR "         Checking Section Condition var=[$var] [$value] = [",
                                (defined $values->{$var} ? $values->{$var} : ""),
                                "] : result=",
                                ($exclude ? "[ignore]" : "[use]"), "\n"
                                if ($debug_options >= 6);
                        }
                        last if ($exclude);
                    }
                    s/^#.*$//;               # delete comments
                    print STDERR "      ", ($exclude ? "[ignore]" : "[use]   "), " $orig_line\n" if ($debug_options >= 5);
                    if ($_) {
                        # this is a single-line condition, don't change the $exclude_section flag
                        next if ($exclude);
                    }
                    else {
                        # this condition pertains to all lines after it
                        $exclude_section = $exclude;
                        next;
                    }
                }
                else {
                    print STDERR "      ", ($exclude_section ? "[ignore]" : "[use]   "), " $orig_line\n" if ($debug_options >= 5);
                }
                next if ($exclude_section);

                s/#.*$//;        # delete comments
                s/^\s+//;         # delete leading spaces
                s/\s+$//;         # delete trailing spaces
                next if (/^$/);  # skip blank lines

                # look for "var = value" (ignore other lines)
                if (/^([^\s=]+)\s*=\s*(.*)/) {  # untainting also happens
                    $var = $1;
                    $value = $2;

                    if (!$is_mod_perl) {
                        if ($var eq "perl_restart" && $value && $value ne "1") {
                            foreach my $env_var (split(/,/,$value)) {
                                if (!$ENV{$env_var}) {
                                    $value = 1;
                                    last;
                                }
                            }
                        }
                    }

                    # "here documents": var = <<EOF ... EOF
                    if ($value =~ /^<<(.*)/) {
                        $heredoc_end = $1;
                        $value = "";
                        while (<App::Options::FILE>) {
                            last if ($_ =~ /^$heredoc_end\s*$/);
                            $value .= $_;
                        }
                        $heredoc_end = "";
                    }
                    # get value from a file
                    elsif ($value =~ /^<\s*(.+)/ || $value =~ /^(.+)\s*\|$/) {
                        $value =~ s/\$\{([a-zA-Z0-9_\.-]+)\}/(defined $values->{$1} ? $values->{$1} : "")/eg;
                        if (open(App::Options::FILE2, $value)) {
                            $value = join("", <App::Options::FILE2>);
                            close(App::Options::FILE2);
                        }
                        else {
                            $value = "Can't read file [$value] for variable [$var]: $!";
                        }
                    }
                    # get additional line(s) due to continuation chars
                    elsif ($value =~ s/\\\s*$//) {
                        while (<App::Options::FILE>) {
                            if ($_ =~ s/\\\s*[\r\n]*$//) {   # remove trailing newline
                                s/^\s+//;  # remove leading space when following a line continuation character
                                $value .= $_;
                            }
                            else {
                                chomp;     # remove trailing newline when following a line continuation character
                                s/^\s+//;  # remove leading space when following a line continuation character
                                $value .= $_;
                                last;
                            }
                        }
                    }
                    else {
                        $value =~ s/^"(.*)"$/$1/;  # quoting, var = " hello world " (enables leading/trailing spaces)
                    }

                    print STDERR "         Var Found in File : var=[$var] value=[$value]\n" if ($debug_options >= 6);
                    
                    # only add values which have never been defined before
                    if ($var =~ /^ENV\{([^{}]+)\}$/) {
                        $env_var = $1;
                        $ENV{$env_var} = $value;
                    }
                    elsif (!defined $values->{$var}) {
                        if (!$init_args->{no_env_vars}) {
                            if ($option_defs && defined $option_defs->{$var} && defined $option_defs->{$var}{env}) {
                                if ($option_defs->{$var}{env} eq "") {
                                    @env_vars = ();
                                }
                                else {
                                    @env_vars = split(/[,;]/, $option_defs->{$var}{env});
                                }
                            }
                            else {
                                @env_vars = ( "APP_" . uc($var) );
                            }
                            foreach $env_var (@env_vars) {
                                if ($env_var && defined $ENV{$env_var}) {
                                    $value = $ENV{$env_var};
                                    print STDERR "       Override File Value from Env : var=[$var] value=[$value] from [$env_var] of [@env_vars]\n" if ($debug_options >= 4);
                                    last;
                                }
                            }
                        }
                        # do variable substitutions, var = ${prefix}/bin, var = $ENV{PATH}
                        if (defined $value) {
                            if ($value =~ /\{.*\}/) {
                                $value =~ s/\$\{([a-zA-Z0-9_\.-]+)\}/(defined $values->{$1} ? $values->{$1} : ($1 eq "prefix" ? $prefix : ""))/eg;
                                $value =~ s/\$ENV\{([a-zA-Z0-9_\.-]+)\}/(defined $ENV{$1} ? $ENV{$1} : "")/eg;
                                print STDERR "         File Var Underwent Substitutions : [$var] = [$value]\n"
                                    if ($debug_options >= 4);
                            }
                            print STDERR "         Var Used : var=[$var] value=[$value]\n" if ($debug_options >= 3);
                            if ($option_defs->{$var} && $option_defs->{$var}{secure} &&
                                defined $values->{security_policy_level} && $values->{security_policy_level} >= 2 && !&file_is_secure($option_file)) {
                                print "Error: \"$var\" may not be supplied from an insecure file because it is a secure option.\n";
                                print "       File: [$option_file]\n";
                                print "       (The file and all of its parent directories must be readable/writable only by the user running the program.)\n";
                                exit(1);
                            }
                            $values->{$var} = $value;    # save all in %App::options
                        }
                    }
                }
            }
            close(App::Options::FILE);

            if ($values->{flush_imports}) {
                @$option_files = ();  # throw out other files to look for
                delete $values->{flush_imports};
            }
            if ($values->{import}) {
                unshift(@$option_files, split(/[,; ]+/, $values->{import}));
                delete $values->{import};
            }
        }
        else {
            print STDERR "\n" if ($debug_options);
        }
    }
}

sub file_is_secure {
    my ($file) = @_;
    my ($secure, $dir);
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
    if ($^O =~ /MSWin32/) {
        $secure = 1; # say it is without really checking
    }
    else {
        $secure = $path_is_secure{$file};
        if (!defined $secure) {
            ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
            if (!($mode & 0400)) {
                $secure = 0;
                print "Error: Option file is not secure because it is not readable by the owner.\n";
            }
            elsif ($mode & 0077) {
                $secure = 0;
                print "Error: Option file is not secure because it is readable/writable by users other than the owner.\n";
            }
            else {
                $dir =~ s!/?[^/]+$!!;
                while ($dir && $secure) {
                    $secure = $path_is_secure{$file};
                    if (!defined $secure) {
                        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$dir/.");  # navigate symlink to the directory
                        if ($uid >= 100 && $uid != $>) {
                            $secure = 0;
                            print "Error: Option file is not secure because a parent directory is owned by a different user.\n";
                            print "       Dir=[$dir]\n";
                        }
                        elsif ($mode & 0077) {
                            $secure = 0;
                            print "Error: Option file is not secure because a parent directory is readable/writable by other users.\n";
                            print "       Dir=[$dir]\n";
                        }
                        $path_is_secure{$file} = 1;  # I don't know this yet, but if we ever get around to asking again, it means that the directory was secure.
                    }
                    $dir =~ s!/?[^/]+$!!;
                }
                $secure = 1 if (!defined $secure);
            }
            $path_is_secure{$file} = $secure;
        }
    }
    return($secure);
}

=head1 LOGIC FLOW: OPTION PROCESSING DETAILS

Basic Concept - By calling App::Options->init(),
your program parses the command line, environment variables,
and option files, and puts var/value pairs into a
global option hash, %App::options.
Just include the following at the top of your program
in order to imbue it with many valuable option-setting
capabilities.

    use App::Options;

When you "use" the App::Options module, the import() method
is called automatically.  This calls the init() method,
passing along all of its parameters.

One of the args to init() is the "values" arg, which allows
for a different hash to be specified as the target of all
option variables and values.

    use App::Options (values => \%Mymodule::opts);

Throughout the following description of option processing,
the %App::options hash may be referred to as the "options hash".
However it will be understood that some other hash (as
specified by the "values" arg) may actually be used.

=head2 Command Line Arguments

Unless the "no_cmd_args" arg is specified to init(), the
first source of option values is the command line.

Each command line argument that begins with a "-" or a "--" is
considered to be an option.  It may take any form such as

    --verbose      # long option, no arg
    --verbose=5    # long option, with arg
    --city=ATL     # long option, with arg
    -x             # short option, no arg
    -t=12:30       # short option, with arg

All detected options are shifted out of @ARGV and the values are
set in the options hash (%App::options).  Options without args
are understood to have a value of "1".  So "--verbose" is
identical to "--verbose=1".

Naturally, the "--" option terminates command line option processing.

=head2 Command Line Argument Variable Substitution

Any value which includes a variable undergoes variable substitution
before it is placed in the option hash. i.e.

    logdir = ${prefix}/log

This line will be expanded properly.
(Of course, the variable and its value should be already set in the
option hash.)

Variable substitution is also performed to interpolate values from
the environment.

    port = $ENV{HTTP_PORT}

=head2 Special Option "app"

If the special option, "app", was not given on the command line,
it is initialized.  This option is useful for including or excluding
different sections of the option files.

To handle the special case that the program is running in a CGI
environment, the PATH_INFO variable is checked first.
The first segment of the PATH_INFO is stripped off, and that becomes
the value of the "app" option.

Otherwise, the stem of the program name becomes the value of the
"app" option.  The stem is the program name without any trailing
extension (i.e. ".exe", ".pl", etc.).

=head2 The Program Directory

One of the places that will be searched for option files is the
directory in which the program exists on the file system.
This directory is known internally as "$prog_dir".

=head2 Special Option "prefix"

The special option, "prefix", represents the root directory of the
software installation.  On a Unix system, a suite of software might
by installed at "/usr/myproduct/thisversion", and that would be
the "prefix".  Under this directory, you would expect to find the
"src", "bin", "lib", and "etc" directories, as well as perhaps
"cgi-bin", "htdocs", and others.

If the "prefix" option is not specified on the command line,
the $PREFIX environment variable is used.

If that is not set, the $prog_dir with the trailing "/bin" or
"/cgi-bin" stripped off is used.

=head2 Option Files

Unless the "no_option_file" arg is specified to init(), the
next source of option values is the option files.

By default, a cascading set of option files are all consulted
to allow individual users to specify values that override the
normal values for certain programs.  Furthermore, the
values for individual programs can override the values configured
generally system-wide. 

The resulting value for an option variable comes from the first
place that it is ever seen.  Subsequent mentions of the option
variable within the same or other option files will be ignored.

The following files are consulted in order.

    $ENV{HOME}/.app/$app.conf
    $ENV{HOME}/.app/app.conf
    $prog_dir/$app.conf
    $prog_dir/app.conf
    $prefix/etc/app/$app.conf
    $prefix/etc/app/app.conf
    /etc/app/app.conf

Thus, a system administrator might set up the $prefix/etc/app/app.conf
file with system-wide defaults.  All option configuration could be done
in this single file, separating the relevant variables into different
sections for each different program to be configured.

However, if the administrator decided that there were too many parameters
for a single program such that it cluttered this file, he might put the
option values for that program into the $prefix/etc/app/$app.conf file.
This distinction is a matter of preference, as both methods are equally
functional.

A program developer may decide to override some of the system-wide
option values for everyone by putting option files in the program's own
directory.

Furthermore, a user may decide to override some of the resulting
option values by putting some option files in the appropriate
place under his home directory.

This separation of config files also allows for secure information
(such as database passwords) to be required to be provided in the
user's own (secured) option files rather than in read-only
system-wide option files.

Specifying the "--debug_options" option on the command line will
assist in figuring out which files App::Options is looking at.

=head2 Option File Format

In general an option file takes the form of lines with "var = value".

   dbname   = prod     # this is the production database
   dbuser   = scott
   dbpass   = tiger

Trailing comments (preceded by a "#") are trimmed off.
Spaces before and after the variable, and before and after the value
are all trimmed off.  Then enclosing double-quotes (") are trimmed
off.  Variables can be any of the characters in
[a-zA-Z0-9_.-].  Values can be any printable characters or the
empty string.  Any lines which aren't recognizable as "var = value"
lines or section headers (see below) are ignored.

If certain variables should be set only for certain programs (or
under certain other conditions), section headers may be introduced.
The special section headers "[ALL]" and "[]" specify the end of a
conditional section and the resumption of unconditional option
variables.

   [progtest]
   dbname   = test     # this is the test database
   [ALL]
   dbname   = prod     # this is the production database
   dbuser   = scott
   dbpass   = tiger

In this case, the "progtest" program will get "dbname = test" while
all other programs will get "dbname = prod".

Note that you would not get the desired results if
the "dbname = prod" statement was above the "[progtest]"
header.  Once an option variable is set, no other occurrence
of that variable in any option file will override it.

For the special case where you want to specify a section for
only one variable as above, the following shortcut is provided.

   [progtest] dbname = test # this is the test database
   dbname   = prod          # this is the production database
   dbuser   = scott
   dbpass   = tiger

The "[progtest]" section header applied for only the single line.

Furthermore, if it were desired to make this override for all
programs containing "test" in them, you would use the following
syntax.

   [/test/] dbname = test   # this is the test database
   dbname   = prod          # this is the production database
   dbuser   = scott
   dbpass   = tiger

The "[/test/]" section header tested the "app" option using
an arbitrary regular expression.

The section headers can create a condition for inclusion
based on any of the variables currently in the option
hash.  In fact, "[progtest]" is just a synonym for
"[app=progtest]" and "[/test/]" is a synonym for "[app=/test/]".

If, for instance, the usernames and passwords were different
for the different databases, you might have the following.

   [/test/] dbname = test   # progs with "test" go to test database
   dbname   = prod          # other progs go to the production database
   [dbname=test]            # progs
   dbuser   = scott
   dbpass   = tiger
   [dbname=prod]
   dbuser   = mike
   dbpass   = leopard

The conditions created by a section header may be the result of more
than a single condition.

   [dbname=test;dbuser=scott]
   dbpass = tiger
   [dbname=test;dbuser=ken]
   dbpass = ocelot
   [dbname=prod;dbuser=scott]
   dbpass = tiger62
   [dbname=prod;dbuser=ken]
   dbpass = 3.ocelot_

Any number of conditions can be included with semicolons separating
them.

Each time a variable/value pair is found in an option file,
it is only included in the option hash if that variable is
currently not defined in the option hash.  Therefore, option
files never override command line parameters.

=head2 Option Environment Variables and Variable Substitution

For each variable/value pair that is to be inserted into the
option hash from the option files, the corresponding environment
variables are searched to see if they are defined.  The environment
always overrides an option file value.  (If the
"no_env_vars" arg was given to the init() method, this whole
step of checking the environment is skipped.)

By default, the environment variable for an option variable named
"dbuser" would be "APP_DBUSER".  However, if the "env" attribute
of the "dbuser" option is set, a different environment variable
may be checked instead (see the Tutorial below for examples).

After checking the environment for override values,
any value which includes a variable undergoes variable substitution
before it is placed in the option hash.

=head2 Setting Environment Variables from Option Files

Any variable of the form "ENV{XYZ}" will set the variable XYZ in
the environment rather than in the options hash.  Thus, the syntax

  ENV{LD_LIBRARY_PATH} = ${prefix}/lib

will enhance the LD_LIBRARY_PATH appropriately.

Note that this only works for options set in an options file.
It does not work for options set on the command line, from the
environment itself, or from the program-supplied default.

Under some circumstances, the perl interpreter will
need to be restarted in order to pick up the new LD_LIBRARY_PATH.
In that case, you can include the special option

  perl_restart = 1

An example of where this might be useful is for CGI scripts that
use the DBI and DBD::Oracle because the Oracle libraries are 
dynamically linked at runtime.

NOTE: The other standard way to handle CGI scripts which require special
environment variables to be set is with Apache directives in the
httpd.conf or .htaccess files. i.e.

  SetEnv LD_LIBRARY_PATH /home/oracle/oracle/product/10.2.0/oraclient/lib
  SetEnv ORACLE_HOME /home/oracle/oracle/product/10.2.0/oraclient

NOTE: Yet another standard way to handle CGI scripts which require
an enhanced LD_LIBRARY_PATH specifically is to use the /etc/ld.so.conf
file.  Edit /etc/ld.so.conf and then run ldconfig (as root).
This adds your specific path to the "standard system places" that
are searched for shared libraries.  This has nothing to do with
App::Options or environment variables of course.

=head2 import and flush_imports

After each option file is read, the special option "flush_imports"
is checked.  If set, the list of pending option files to be
parsed is cleared, and the flush_imports option is also cleared.

This is useful if you do not want to inherit any of the option
values defined in system-wide option files.

The special option "import" is checked next.  If it is set, it is
understood to be a list of option files (separated by /[,; ]+/)
to be prepended to the list of pending option files.
The import option itself is cleared.

=head2 Other Environment Variables and Defaults

After command line options and option files have been parsed,
all of the other options which are known to the program are
checked for environment variables and defaults.

Options can be defined for the program with either the
"options" arg or the "option" arg to the init() method
(or a combination of both).

    use App::Options (
        options => [ "dbname", "dbuser", "dbpass" ],
        option => {
            dbname => {
                env => "DBNAME",
                default => "devel",
            },
            dbuser => {
                env => "DBUSER;DBI_USER",
            },
            dbpass => {
                env => "", # password in %ENV is security breach
            },
        },
    );

For each option variable known, if the value is not already set,
then the environment is checked, the default is checked, variable
expansion is performed, and the value is entered into the 
option hash.

=head2 Special Option prefix

The special option "prefix" is reconciled and finalized next.

Unless it was specified on the command line, the original "prefix"
was autodetected.  This may have resulted in a path which was 
technically correct but was different than intended due to 
symbolic linking on the file system.

Since the "prefix" variable may also be set in an option file,
there may be a difference between the auto-detected "prefix"
and the option file "prefix".  If this case occurs, the
option file "prefix" is the one that is accepted as authoritative.

=head2 Special Option perlinc

One of the primary design goals of App::Options was to be able
to support multiple installations of software on a single machine.

Thus, you might have different versions of software installed
under various directories such as

    /usr/product1/1.0.0
    /usr/product1/1.1.0
    /usr/product1/2.1.5

Naturally, slightly different versions of your perl modules will
be installed under each different "prefix" directory.
When a program runs from /usr/product1/1.1.0/bin, the "prefix"
will by "/usr/product1/1.1.0" and we want the @INC variable to
be modified so that the appropriate perl modules are included
from $prefix/lib/*.

This is where the "perlinc" option comes in.

If "perlinc" is set, it is understood to be a list of paths
(separated by /[ ,;]+/) to be prepended to the @INC variable.

If "perlinc" is not set,
"$prefix/lib/perl5/$perlversion" and
"$prefix/lib/perl5/site_perl/$perlversion" are automatically
prepended to the @INC variable as a best guess.

=head2 Special Option debug_options

If the "debug_options" variable is set (often on the command
line), the list of option files that was searched is printed
out, the resulting list of variable values is printed out,
and the resulting list of include directories (@INC) is printed
out.

=head2 Version

After all values have been parsed, various conditions are
checked to see if the program should print diagnostic information
rather than continue running.  Two of these examples are --version
and --help.

If the "--version" option is set on the command line,
the version information for all loaded modules is printed,
and the program is exited.  (The version of a package/module is
assumed to be the value of the $VERSION variable in that package.
i.e. The version of the XYZ::Foo package is $XYZ::Foo::VERSION.)

 prog --version

Of course, this is all done implicitly in the BEGIN block (during
"use App::Options;").  If your program tried to set
$main::VERSION, it may not be set unless it is set explicitly
in the BEGIN block.

 #!/usr/bin/perl
 BEGIN {
   $VERSION = "1.12";
 }
 use App::Options;

This can be integrated with CVS file versioning using something 
like the following.

 #!/usr/bin/perl
 BEGIN {
   $VERSION = do { my @r=(q$Revision: 14478 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};
 }
 use App::Options;

Furthermore, the version information about some modules that you
might expect to have seen will not be printed because those modules
have not yet been loaded.  To fix this, use the --version_packages
option (or set it in an option file).  This option contains a
comma-separated list of modules and/or module regular expressions.
The modules are loaded, and the version information from all
resulting packages that match any of the patterns is printed.

 prog --version --version_packages=CGI
 prog --version --version_packages=CGI,Template

This also cuts down on the miscellaneous
modules (and pragmas) which might have cluttered up your view
of the version information you were interested in.
If you really wish to see version information for all
modules, use the --version=all option.

 prog --version=all --version_packages=CGI,Template

=head2 Help and Validations

If the "-?" or "--help" options were set on the command line,
the usage statement is printed, and the program is exited.

Then each of the options which is defined may be validated.

If an option is designated as "required", its value must be
defined somewhere (although it may be the empty string).
(If it is also required to be a non-empty string, a regex
may be provided for the type, i.e. type => "/./".)

If an option is designated as having a "type", its value
must either be undefined or match a specific regular expression.

    Type       Regular Expression
    =========  =========================================
    string     (any)
    integer    /^-?[0-9_]+$/
    float      /^-?[0-9_]+\.?[0-9_]*([eE][+-]?[0-9_]+)?$/
          (or) /^-?\.[0-9_]+([eE][+-]?[0-9_]+)?$/
    boolean    /^[01]$/
    date       /^[0-9]{4}-[01][0-9]-[0-3][0-9]$/
    datetime   /^[0-9]{4}-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]$/
    time       /^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$/
    /regexp/   /regexp/

Note that an arbitrary regular expression may be designated
as the "type" by enclosing it in slashes (i.e. "/^[YN]$/").

If the options fail any of the "required" or "type" validation
tests, the App::Options::print_usage() function is called
to print out a usage statement and the program is exited.

=head1 USAGE TUTORIAL

=head2 Getting Started

Create a perl program called "demo1".

    #!/usr/bin/perl
    use App::Options;
    print "Wow. Here are the options...\n";
    foreach (sort keys %App::options) {  # options appear here!
        printf("%-20s => %s\n", $_, $App::options{$_});
    }

Run it different kinds of ways to see how it responds.

    demo1
    demo1 -x
    demo1 -x --verbose
    demo1 --x -verbose
    demo1 -x=5 --verbose=10 --foo=bar
    demo1 --help
    demo1 -x=8 --help
    demo1 -?
    demo1 --debug_options -?
    demo1 -x=5 --verbose=10 --foo=bar --debug_options -?

    demo1 --version
    demo1 --version --version_packages=CGI

Now create a copy of the program.

    cp demo1 demo2

Start putting entries like the following

    x = 7
    hello = world
    [demo2]
    verbose=3
    [/demo/]
    baz = foo

in the following files

    $HOME/.app/demo1.conf
    $HOME/.app/demo2.conf
    $HOME/.app/app.conf
    demo1.conf  (same directory as the demo* programs)
    demo2.conf  (same directory as the demo* programs)
    app.conf    (same directory as the demo* programs)
    $PREFIX/etc/app/demo1.conf
    $PREFIX/etc/app/demo2.conf
    $PREFIX/etc/app/app.conf
    /etc/app/app.conf

and see how the programs respond in each different case.

Next set environment variables like the following and
see how the programs respond.

    export APP_X=14
    export APP_VERBOSE=7
    export APP_FOO=xyzzy
    export APP_HELLO=Plugh!

You are well on your way.

=head2 A Development Scenario

Now let's imagine that we are writing a suite of programs which operate
on a relational database.  These programs are part of a larger
system which goes through a development cycle of development,
test, and production.  Each step in the development cycle, the
programs will run against different databases, but we don't want
that to affect the code.

Let's suppose that we write a program which lists the customers
in a customer table.

    create table person (
        person_id      integer       not null auto_increment primary key,
        first_name     varchar(99)   null,
        last_name      varchar(99)   null,
        birth_dt       date          null,
        company_id     integer       null,
        wholesale_ind  char(1)       null,
        change_dttm    datetime      not null,
    );

We call this program "listcust".

    #!/usr/bin/perl -e
    use strict;
    use App::Options;
    use DBI;
    my $dsn = "dbi:$App::options{dbdriver}:database=$App::options{dbname}";
    my $dbh = DBI->connect($dsn, $App::options{dbuser}, $App::options{dbpass});
    my $sql = "select first_name, last_name, birth_dt, company_id, wholesale_ind, change_dttm from person";
    my $cust = $dbh->selectall_arrayref($sql);
    foreach my $row (@$cust) {
        printf("%-24 %-24 %s %9d %s\n", @$row);
    }
    $dbh->disconnect();

Then you can invoke this program with all of the command line options
and everything works fine.

    listcust --dbdriver=mysql --dbname=prod --dbuser=scott --dbpass=tiger

However, if you don't use all of the options, you will get a DBI error.
Furthermore, "listcust --help" doesn't help very much.  A system administrator
confronting this problem would put the following lines into
"$PREFIX/etc/app/app.conf" or "$PREFIX/etc/app/listcust.conf".

    dbdriver = mysql
    dbname   = prod
    dbuser   = scott
    dbpass   = tiger

If, however, your projects were not in the habit of using the
PREFIX environment variable and the program is not installed in
$PREFIX/bin, he would have to put the above lines
in either the "app.conf" file or the "listcust.conf" file
in the same directory as "listcust" or in the global
"/etc/app/app.conf" option file.

A user (without privileges to the "$PREFIX/etc/app" directory
or the directory in which "listcust" lives) would have to put
the described lines into "$HOME/.app/app.conf" or
"$HOME/.app/listcust.conf".

Putting the options in any of those files would make "--help"
print something intelligent.

A developer, however, might decide that the program should
have some defaults.

    use App::Options (
        option => {
            dbdriver => "mysql",
            dbname   => "prod",
            dbuser   => "scott",
            dbpass   => "tiger",
        },
    );

(This supplies defaults and also makes "--help" print something
intelligent, regardless of whether there are any configuration
files.)

If all you wanted to do was provide defaults for options,
this format would be fine.  However, there are other useful
attributes of an option besides just the "default".
To use those, you generally would use the more complete form
of the "option" arg.

    use App::Options (
        option => {
            dbdriver => { default => "mysql", },
            dbname   => { default => "prod",  },
            dbuser   => { default => "scott", },
            dbpass   => { default => "tiger", },
        },
    );

Then we can indicate that these options are all required.
If they are not provided, the program will not run.

Meanwhile, it makes no sense to provide a "default" for a
password.  We can remove the default, but if we ever tried to run
the program without providing the password, it would not get
past printing a "usage" statement.

    use App::Options (
        option => {
            dbdriver => { required => 1, default => "mysql", },
            dbname   => { required => 1, default => "prod",  },
            dbuser   => { required => 1, default => "scott", },
            dbpass   => { required => 1, },
        },
    );

We now might enhance the code in order to list only the 
customers which had certain attributes.

    my $sql = "select first_name, last_name, birth_dt, company_id, wholesale_ind, change_dttm from person";
    my (@where);
    push(@where, "first_name like '%$App::options{first_name}%'")
        if ($App::options{first_name});
    push(@where, "last_name like '%$App::options{last_name}%'")
        if ($App::options{last_name});
    push(@where, "birth_dt = '$App::options{birth_dt}'")
        if ($App::options{birth_dt});
    push(@where, "company_id = $App::options{company_id}")
        if ($App::options{company_id});
    push(@where, "wholesale_ind = '$App::options{wholesale_ind}'")
        if ($App::options{wholesale_ind});
    push(@where, "change_dttm >= '$App::options{change_dttm}'")
        if ($App::options{change_dttm});
    if ($#where > -1) {
        $sql .= "\nwhere " . join("\n  and ", @where) . "\n";
    }
    my $cust = $dbh->selectall_arrayref($sql);

The init() method call might be enhanced to look like this.
Also, the order that the options are printed by "--help" can
be set with the "options" argument.  (Otherwise, they would
print in alphabetical order.)

    use App::Options (
        options => [ "dbdriver", "dbname", "dbuser", "dbpass",
            "first_name", "last_name", "birth_dt", "company_id",
            "wholesale_ind", "change_dttm",
        ],
        option => {
            dbdriver => {
                description => "dbi driver name",
                default => "mysql",
                env => "DBDRIVER",  # use a different env variable
                required => 1,
            },
            dbname   => {
                description => "database name",
                default => "prod", 
                env => "DBNAME",  # use a different env variable
                required => 1,
            },
            dbuser   => {
                description => "database user",
                default => "scott",
                env => "DBUSER;DBI_USER",  # check both
                required => 1,
            },
            dbpass   => {
                description => "database password",
                env => "",  # disable env for password (insecure)
                required => 1,
                secure => 1,   # FYI. This is inferred by the fact that "dbpass"
                               # ends in "pass", so it is not necessary.
            },
            first_name => {
                description => "portion of customer's first name",
            },
            last_name  => {
                description => "portion of customer's last name",
            },
            birth_dt   => {
                description => "customer's birth date",
                type => "date",
            },
            company_id => {
                description => "customer's company ID",
                type => "integer",
            },
            wholesale_ind => {
                description => "indicator of wholesale customer",
                type => "/^[YN]$/",
            },
            change_dttm => {
                description => "changed-since date/time",
                type => "datetime",
            },
        },
    );

It should be noted in the example above that the default environment
variable name ("APP_${varname}") has been overridden for some of 
the options.  The "dbname" variable will be set from "DBNAME"
instead of "APP_DBNAME".  The "dbuser" variable will be set
from either "DBUSER" or "DBI_USER".

It should also be noted that if only the order of the options rather
than all of their attributes were desired, the following could
have been used. 

    use App::Options (
        options => [ "dbdriver", "dbname", "dbuser", "dbpass",
            "first_name", "last_name", "birth_dt", "company_id",
            "wholesale_ind", "change_dttm",
        ],
    );

Using the "options" arg causes the options to
be printed in the order given in the "--help" output.  Then the
remaining options defined in the "option" arg are printed in 
alphabetical order.  All other options which are set
on the command line or in option files are printed if the
"show_all" option is set.  This option is off by default if
either the "options" arg or the "option" arg are supplied
and on if neither are supplied.

If, for some reason, the program needed to put the options
into a different option hash (instead of %App::options) or directly
specify the option file to use (disregarding the standard option
file search path), it may do so using the following syntax.

    use App::Options (
        values => \%Mymodule::opts,
        option_file => "/path/to/options.conf",
    );

If, for some reason, the program needs to inhibit one or more
of the sources for options, it can do so with one of the
following arguments.  Of course, inhibiting all three would
be a bit silly.

    use App::Options (
        no_cmd_args => 1,
        no_option_file => 1,
        no_env_vars => 1,
    );

=head2 A Deployment Scenario

Sometimes a software system gets deployed across many machines.
You may wish to have a single option file set different values
when it is deployed to different machines.

For this purpose, the automatic "host" and "hostname" values
are useful.  Suppose you have four servers named "foo1", "foo2",
"foo3", and "foo4".  You may wish the software to use different
databases on each server.  So app.conf might look like this.

    [host=foo1] dbname = devel
    [host=foo2]
    dbname = test
    [host=foo3]
    dbname = prod
    [ALL]
    dbname = prod

Hopefully, that's enough to get you going.

I welcome all feedback, bug reports, and feature requests.

=head1 ACKNOWLEDGEMENTS

 * (c) 2010 Stephen Adkins
 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

1;

