package CLI::Simple;

# a Simple, Fast & Easy way to create scripts

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars :log-levels);
use CLI::Simple::Utils qw(normalize_options);
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use FindBin qw($RealBin $RealScript);
use Getopt::Long qw(:config no_ignore_case);
use JSON qw(decode_json);
use List::Util qw(zip none);
use Log::Log4perl;
use Pod::Usage;

our $VERSION = '0.0.9';

use parent qw(Class::Accessor::Fast Exporter);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    _command
    _command_args
    _commands
    _program
  )
);

########################################################################
sub _use_logger {
########################################################################
  return $FALSE;
}

########################################################################
sub use_log4perl {
########################################################################
  my ( $self, %args ) = @_;

  my $class = ref $self || $self;

  my ( $level, $log4perl_conf ) = @args{qw(level config)};

  {
    no strict 'refs';  ## no critic (ProhibitNoStrict)

    *{"${class}::_use_logger"}         = sub { return $TRUE };
    *{"${class}::_get_log4perl_conf"}  = sub { return $log4perl_conf };
    *{"${class}::_get_log4perl_level"} = sub { return $level // 'error' };
  }

  if ( !$self->can('set_logger') ) {
    $self->mk_accessors('logger');
  }

  if ( !$self->can('set_log_level') ) {
    $self->mk_accessors('log_level');
  }

  return $self;
}

########################################################################
sub new {
########################################################################
  my ( $class, @params ) = @_;

  my %args = ref $params[0] ? %{ $params[0] } : @params;

  my ( $default_options, $option_specs, $commands, $extra_options )
    = @args{qw(default_options option_specs commands extra_options)};

  no strict 'refs';  ## no critic

  my $stash = \%{ $class . $DOUBLE_COLON };

  local (*alias);

  use vars qw($DEFAULT_OPTIONS $EXTRA_OPTIONS $OPTION_SPECS $COMMANDS $LOGGING);

  *DEFAULT_OPTIONS = $stash->{DEFAULT_OPTIONS} // $EMPTY;
  *EXTRA_OPTIONS   = $stash->{EXTRA_OPTIONS}   // $EMPTY;
  *OPTION_SPECS    = $stash->{OPTION_SPECS}    // $EMPTY;
  *COMMANDS        = $stash->{COMMANDS}        // $EMPTY;

  $default_options //= $DEFAULT_OPTIONS;
  $extra_options   //= $EXTRA_OPTIONS;
  $option_specs    //= $OPTION_SPECS;
  $commands        //= $COMMANDS;

  croak sprintf
    "error: both 'option_specs' and 'command' are required\n:usage: %s->new( option_specs => specs, commands => commands);\n"
    if !$option_specs || !$commands;

  $default_options //= {};

  my $options = { %{$default_options} };

  if ( $class->_use_logger && none { $_ eq 'log-level' } @{$option_specs} ) {
    push @{$option_specs}, 'log-level=s';
  }

  GetOptions( $options, @{$option_specs} );

  normalize_options($options);

  my %cli_options;

  my @accessors
    = ( @{ $extra_options || [] }, map { ( split /[^[:alpha:]\-_]/xsm )[0] } @{$option_specs} );

  foreach (@accessors) {
    s/\-/_/xsmg;

    if ( !__PACKAGE__->can( 'get_' . $_ ) ) {
      __PACKAGE__->mk_accessors($_);
    }

    $cli_options{$_} = $options->{$_};
  }

  my $self = $class->SUPER::new( \%cli_options );

  my $command = shift @ARGV // 'default';

  if ( $command eq 'help' || ( $self->can('get_help') && $self->get_help ) ) {
    # custom help function?
    if ( $commands->{help} ) {
      exit $commands->{help}->();
    }

    $self->usage;
  }

  $self->set__command($command);

  $self->set__command_args( [@ARGV] );

  $self->set__commands($commands);

  $self->set__program("$RealBin/$RealScript");

  $self->init_logger;

  $self->can('init') && $self->init();

  return $self;
}

########################################################################
sub init_logger {
########################################################################
  my ($self) = @_;

  if ( $self->_use_logger ) {

    if ( $self->_get_log4perl_conf ) {
      my $config = $self->_get_log4perl_conf;
      Log::Log4perl->init( \$config );
    }
    else {
      Log::Log4perl->easy_init( $LOG_LEVELS{error} );
    }

    $self->set_logger( Log::Log4perl->get_logger );

    my $level = $self->get_log_level // $self->_get_log4perl_level;

    $self->set_log_level($level);

    $self->get_logger->level( $LOG_LEVELS{$level} );
  }

  return $self;
}

########################################################################
sub get_kv_args {
########################################################################
  my ($self) = @_;

  my @arg_list = @{ $self->get__command_args };

  my %args;

  foreach (@arg_list) {
    my ( $k, $v ) = split /=/xsm;
    $args{$k} = $v;
  }

  return %args;
}

# sets the command args to specified keys
# example: get_args($self, qw(vpc-id key tag))
########################################################################
sub get_args {
########################################################################
  my ( $self, @vars ) = @_;

  my $command_args = $self->get__command_args;

  return @{$command_args}
    if !@vars;

  my %args = map { @{$_} } zip \@vars, $command_args;

  return wantarray ? %args : \%args;
}

########################################################################
sub default_command {
########################################################################
  goto &usage;
}

########################################################################
sub usage {
########################################################################
  my ($self) = @_;

  return pod2usage( -exitval => 1, -input => $self->get__program );
}

########################################################################
sub command {
########################################################################
  my ($self) = @_;

  return $self->get__command;
}

########################################################################
sub run {
########################################################################
  my ($self) = @_;

  my $program = $self->get__program;

  my $command = $self->get__command || 'default';

  my $commands = $self->get__commands;
  $commands->{default} //= \&usage;

  croak 'unknown command: ' . $command
    if !defined $commands->{$command};

  return $commands->{$command}->($self);
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CLI::Simple - a framework for creating option driven Perl scripts

=head1 SYNOPIS

 package MyScript;

 use strict;
 use warnings;

 use parent qw(CLI::Simple);
 
 caller or __PACKAGE__->main();
 
 sub execute {
   my ($self) = @_;

   # retrieve a CLI option   
   my $file = $self->get_file;
   ...
 }
 
 sub list { 
   my ($self) = @_

   # retrieve a command argument
   my ($file) = $self->get_args();
   ...
 }

 sub main {
  CLI::Simple->new(
   option_specs    => [ qw( help format=s ) ],
   default_options => { format => 'json' }, # set some defaults
   extra_options   => [ qw( content ) ], # non-option, setter/getter
   commands        => { execute => \&execute, list => \&list,  }
 )->run;

 1;

=head1 DESCRIPTION

Tired of writing the same 'ol boilerplate code for command line
scripts? Want a standard, simple way to create a Perl script?
C<CLI::Simple> makes it easy to create scripts that take I<options>,
I<commands> and I<arguments>.

This documentation describes version 0.0.9.

=head2 Features

=over 5

=item * accept command line arguments ala L<GetOptions::Long>

=item * supports commands and command arguments

=item * automatically add a logger

=item * easily add usage notes

=item * automatically create setter/getters for your script

=back

Command line scripts often take I<options>, sometimes a I<command> and
perhaps I<arguments> to those commands.  For example, consider the
script C<myscript> that takes options and implements a few commands
(I<send-message>, I<receive-message>) that also take arguments.

 myscript [options] command args

or

 myscript command [options] args

Examples:

 myscript --foo bar --log-level debug send-message "Hello World" now

 myscript --bar --log-level info receive-message

Using C<CLI::Simple> to implement this script looks like this...

 package MyScript;

 use parent qw(CLI::Simple);

 caller or __PACKAGE__main();

 sub send_message {...}

 sub default {...}

 sub receive_message {...}
 
 sub main {
   return __PACKAGE__->new(
     option_specs => [
       qw(
         foo=s
         bar
         log-level
       )
     ],
     commands => {
       send    => \&send_message,
       receive => \&receive_message,
     },
   )->run;
 }

 1;

=head1 METHODS AND SUBROUTINES

=head2 new

 new( args )

C<args> is a hash or hash reference containing the following keys:

=over 5

=item commands (required)

A hash reference containing the command names and a code reference to
the subroutines that implement the command.

Example:

 { 
   send    => \&send_message,
   receive => \&receive_message,
 }

If your script does not accept a command, set a C<default> key to the
subroutine or method that will implement your script.

 { default => \&main }

=item default_options (optional)

A hash reference that contains the default values for your options.  

=item extra_options

If you want to create additional setters or getters, set
C<extra_options> to an array of names.

Example:

 extra_options => [ qw(foo bar baz) ]

=item option_specs (required)

An array reference of option specifications.  These are the same as
those passed to C<Getopt::Long>.

=back

Instantiates a new C<CLI::Simple> object.

=head2 command

Returns the command presented on the command line.

=head2 run

Execute the script with the given options, commands and arguments. The
C<run> method interprets the command line and pass control to your command
subroutines. Your subroutines should return a 0 for success and a
non-zero value for failure.  This error code is passed to the shell as
the script return code.

=head2 get_args

Return the arguments that follow the command.

 get_args(var-name, ... )
 get_args()

With arguments, in scalar context returns a reference to the hash of
arguments by assigning each positional argument to a key value.  In
array context returns a list of key/value pairs.

With no arguments returns the array of command arguments.

Example:

 sub send_message {
   my ($self) = @_;

   my %args = $self->get_args(qw(message email));
   
   _send_message($arg{message}, $args{email});

  ...

=head2 init

If you define your own C<init()> function, it will be called by the
constructor.

=head1 USING PACKAGE VARIABLES

You can pass the necessary parameter required to implement your
command line scripts in the constructor or some people prefer to see
them clearly defined in the code. Accordingly, you can use package
variables with the same name as the constructor arguments (in upper
case).

 our $OPTION_SPECS = [
   qw(
     help|h
     log-level=s|L
     debug|d
   )
 ];
 
 our $COMMANDS = {
   foo => \&foo,
   bar => \&bar,
 };

=head1 COMMAND LINE OPTIONS

Command line options are set ala C<Getopt::Long>. You pass those
options into the constructor like this:

 my $cli = CLI::Simple->new(option_specs => [ qw( help|h foo bar=s log-level=s ]);

In your command subroutines you can then access these options using gettters.

 $cli->get_foo;
 $cli->get_bar;
 $cli->get_log_level;

Note that options that use dashes in the name will be automatically
converted to snake case names. (Some folks find it easier to use '-'
rather than '_' for option names.)

=head1 COMMAND ARGUMENTS

If you want to allow your commands to accept positional arguments you
can retrieve them as named hash elements.  This can make your code much
easier to read and understand.

 sub send_message {
   my ($self) = @_;

   my %args = $self->get_args(qw(phone_number message));

   send_sms_mesage($args{phone_number}, $args{message});
   ...
 }

If you pass an empty list then all of the command arguments will be
returned.

 my ($phone_number, $message) = $self->get_args;

=head1 SETTING DEFAULT VALUES FOR OPTIONS

To set default values for your option, pass a hash reference as the
C<default_options> argument to the constructor.

  my $cli = CLI::Simple->new(
    default_option => { foo => 'bar' },
    option_specs   => [ qw(foo=s bar=s) ],
    commands       => { foo => \&foo, bar => \&bar },
  );

=head1 ADDING ADDITIONAL SETTERS & GETTERS

As noted all command line options are available using getters of the
same name preceded by C<get_>.

If you want to create additional setter and getters, pass an array of
variable names as the C<extra_options> argument to the constructor.

  my $cli = CLI::Simple->new(
    default_option => { foo => 'bar' },
    option_specs   => [ qw(foo=s bar=s) ],
    extra_options  => [ qw(biz buz baz) ],
    commands       => { foo => \&foo, bar => \&bar },
  );

=head1 ADDING USAGE TO YOUR SCRIPTS

To add usage or help capability to your scripts, just add some pod
at the bottom of your script in a USAGE section (head1).

 =head1 USAGE

  usage: myscript [options] command args
  
  Options
  -------
  --help, -h      help
  ....

If the command specified is 'help' or if you have added an optional
C<--help> option, users can access the usage section.

 perl myscript.pm -h

 perl myscript.pm help

=head2 Custom C<help() Method

If you don't make this module your parent class and your module
already has POD that is what you want displayed by C<CLI::Simple>'s
help facility, create your own custom help method and set that as one
of your commands.

  ...
  commands => {
    help => \&help,
    ...
  }

This situation occurs when for example, you have a class that is
typically used by other scripts or modules but also has the capability
of running the modulino pattern. Run as a modulino the script's usage
notes might differ from those in the module itself.

 caller or __PACKAGE__->main()

Without creating your own help function, C<CLI::Simple>'s help
facility will output the usage notes in your POD. That may or may not
have been what you wanted, hence the ability to override that behavior
by providing your own C<help()> method that will be called when that
module is run as a script and either C<--help> option or help command is
used.

=head1 LOGGING

C<CLI::Simple> will enable you to automatically add logging to your
script using a L<Log::Log4perl> logger. You can pass in a C<Log4perl>
configuration string or let the class instantiate C<Log::Log4perl> in
easy mode.

Do this at the top of your class:

 __PACKAGE__->use_log4perl(level => 'info', config => $config);

The class will add a C<--log-level> option for you if you have not
added one yourself. Additionally, you can use the C<get_logger> method
to retrieve the logger.

=head1 FAQ

=over 5

=item How do I execute some startup code before my command runs?

The C<new> constructor will execute an C<init()> method prior to
returning. Implement your own L</init> function which will have of the
commands and arguments available to it at that time.

=item Do I need to implement commands?

No, but if you don't you must provide the name of the subroutine that
will implement your script logic as the C<default> command.

  use CLI::Simple;

  sub do_it {
    my ($cli) = @_;

    # do something useful...
  }

  my $cli = CLI::Simple->new(
    default_option => { foo => 'bar' },
    option_specs   => [ qw(foo=s bar=s) ],
    extra_options  => [ qw(biz buz baz) ],
    commands       => { default => \&do_it },
  );

  $cli->run;

=item Do I have to subclass C<CLI::Simple>?

No, see above example,

=item How do I turn my class into a script?

I like to implement scripts as a Perl class and use the so-called
"modulino" pattern popularized by Brian d foy. Essentially you create
a class that looks something like this:

 package Foo;

 caller or  __PACKAGE__->main();

 sub main {
   ....
 }

 1;

Using this pattern you can write Perl modules that can also be used as
a script or test harness for your class.

 package MyScript;

 use strict;
 use warnings;

 caller or  __PACKAGE__->main();

 sub do_it {
   my ($cli) = @_;

   # do something useful...
 }

 sub main {

   my $cli = CLI::Simple->new(
     default_option => { foo => 'bar' },
     option_specs   => [ qw(foo=s bar=s) ],
     extra_options  => [ qw(biz buz baz) ],
     commands       => { default => \&do_it },
   );

  exit $cli->run;
 }

 1;

To make it easy to use such a module, I've created a C<bash> script that
calls the module with the arguments passed on the command line.

The script (C<modulino>) is included in this distribution.

You can also use the included C<create-modulino.pl> script to create a
symbolic link to your class that will be executed as if it is a Perl
script if you've implemented the modulino pattern described above.

  sudo create-modulino.pl Foo::Bar foo-bar

If you do not provide an alias name as the second argument the script
will create a copy of the C<modulino> script as a normalized name of
your module but will not create a symbolic link.

The script essentially executes the recipe below.

=over 5

=item 1. Copy the C<modulino> script using a name that converts the
first letter of the class to lower case and any CamelCased words
inside the class name to lower case with all words snake cased.
Example: C<Module::ScanDeps::FindRequires> becomes:
C<module_scanDeps_findRequires>.

 sudo cp /usr/local/bin/modulino /usr/local/bin/module_scanDeps_findRequire
 
=item 2. Make sure the new script is executable.

 chmod 0755 module_scanDeps_findRequire

=item 3. Create a symlink with a name of your chosing to the new script.

 sudo ln -s /usr/local/bin/module_scanDeps_findRequire /usr/local/bin/find-requires 

=back

=back

=head1 LICENSE AND COPYRIGHT

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=head1 SEE ALSO

L<Getopt::Long>, L<CLI::Simple::Utils>

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
