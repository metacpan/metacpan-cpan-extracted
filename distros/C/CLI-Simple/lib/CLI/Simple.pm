package CLI::Simple;

# a Simple, Fast & Easy way to create scripts

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars :log-levels);
use CLI::Simple::Utils qw(normalize_options slurp dmp);
use Carp;
use English qw(-no_match_vars);
use FindBin qw($RealBin $RealScript);
use Getopt::Long qw(:config no_ignore_case);
use List::Util qw(zip none pairs any);
use Scalar::Util qw(reftype);
use Log::Log4perl qw(:easy);

use Pod::Usage;

our $VERSION              = '1.0.8';
our $GETOPT_EXIT_ON_ERROR = $TRUE;
our $GETOPT_STATUS;
our $GETOPT_ERROR_MESSAGE;

use parent qw(Exporter Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    _command
    _command_args
    _commands
    _program
    _abbreviations
  )
);

our $USE_LOGGER = $FALSE;

########################################################################
sub _use_logger {
########################################################################
  return $USE_LOGGER;
}

########################################################################
sub use_log4perl {
########################################################################
  my ( $self, %args ) = @_;

  my $class = ref $self || $self;

  my ( $log_level, $level, $log4perl_conf ) = @args{qw(log_level level config)};
  $level //= $log_level;

  {
    no strict 'refs';  ## no critic (ProhibitNoStrict)

    $USE_LOGGER = $TRUE;

    *{"${class}::get_log4perl_conf"}  = sub { return $log4perl_conf };
    *{"${class}::set_log4perl_conf"}  = sub { $log4perl_conf = $_[1] };
    *{"${class}::get_log4perl_level"} = sub { return $level };
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

  my ( $default_options, $option_specs, $commands, $extra_options, $abbreviations, $error_handler, $alias )
    = @args{qw(default_options option_specs commands extra_options abbreviations error_handler alias)};

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

  $option_specs //= [];

  croak sprintf "ERROR: 'commands' is required\nusage: %s->new( option_specs => specs, commands => commands);\n", __PACKAGE__
    if !$option_specs || !$commands;

  $default_options //= {};

  my $options = { %{$default_options} };

  if ( $class->_use_logger && none { $_ eq 'log-level' } @{$option_specs} ) {
    push @{$option_specs}, 'log-level=s';
  }

  # if we have an option alias, make sure the option alias spec is set too
  if ( $alias && ref $alias && $alias->{options} ) {
    foreach my $p ( pairs %{ $alias->{options} } ) {
      my ( $aka, $name ) = @{$p};

      # Does an option named $aka already exist (with or without a spec)?
      my $aka_exists = any {/^\Q$aka\E(?:[^\w-].*)?$/xsm} @{$option_specs};

      if ( !$aka_exists ) {

        # Find the canonical spec for $name
        my ($spec) = grep {/^\Q$name\E(?:[^\w-].*)?$/xsm} @{$option_specs};
        croak sprintf 'ERROR: no such option defined: %s', $name if !$spec;

        # Pull just the specifier part (e.g., '=s', ':i', '!', '+', etc.)
        my ($spec_part) = $spec =~ /^\Q$name\E(?:[|].)?([^\w-].*)?$/xsm;

        $spec_part ||= q{};

        push @{$option_specs}, $aka . $spec_part;
      }
    }
  }

  $GETOPT_STATUS = sub {
    local $SIG{__WARN__} = sub { $GETOPT_ERROR_MESSAGE = shift; return; };

    return GetOptions( $options, @{$option_specs} );
    }
    ->();

  normalize_options($options);

  my %cli_options;

  my @accessors
    = ( @{ $extra_options || [] }, map { ( split /[^\w\-]/xsm )[0] } @{$option_specs} );

  foreach (@accessors) {
    s/\-/_/xsmg;

    if ( !__PACKAGE__->can( 'get_' . $_ ) ) {
      __PACKAGE__->mk_accessors($_);
    }

    $cli_options{$_} = $options->{$_};
  }

  if ( !$error_handler && !$GETOPT_STATUS ) {
    print {*STDERR} $GETOPT_ERROR_MESSAGE;
    if ($GETOPT_EXIT_ON_ERROR) {
      _leave($FAILURE);
    }
  }
  elsif ( !$GETOPT_STATUS ) {
    if ( !$error_handler->($GETOPT_ERROR_MESSAGE) ) {
      _leave($FAILURE);
    }
  }

  croak "ERROR: alias must be a hash ref with keys 'options' or 'commands'\n"
    if $alias && !ref $alias;

  if ($alias) {
    if ( $alias->{options} ) {
      foreach my $p ( pairs %{ $alias->{options} } ) {
        my ( $aka, $name ) = @{$p};
        $aka  =~ s/[-]/_/gxsm;
        $name =~ s/[-]/_/gxsm;

        if ( defined $cli_options{$name} ) {
          $cli_options{$aka} = $cli_options{$name};
        }
        elsif ( defined $cli_options{$aka} ) {
          $cli_options{$name} = $cli_options{$aka};
        }
      }
    }

    # command aliases are a convenience so someone doesn't have to add to $commands manually
    if ( $alias->{commands} ) {
      foreach my $p ( pairs %{ $alias->{commands} } ) {
        croak sprintf "ERROR: no command: %s\n"
          if !$commands->{ $p->[1] };

        $commands->{ $p->[0] } = $commands->{ $p->[1] };
      }
    }
  }

  my $self = $class->SUPER::new( \%cli_options );

  if ( scalar keys %{$commands} == 1 ) {
    my ($command) = keys %{$commands};

    if ( @ARGV && $ARGV[0] ne $command ) {
      unshift @ARGV, $command;
    }
    elsif ( !@ARGV ) {
      unshift @ARGV, $command;
    }
  }

  my $command = shift @ARGV;

  if ( !$command ) {
    $command = 'default';
    $commands->{default} //= \&usage;
  }

  $self->set__command($command);

  $self->set__command_args( [@ARGV] );

  $self->set__commands($commands);

  if ( $command eq 'help' || ( $self->can('get_help') && $self->get_help ) ) {
    # custom help function?

    my $help = $commands->{help};

    if ( !$help ) {
      $self->usage;
    }

    if ( ref $help && reftype($help) eq 'ARRAY' ) {
      $help->[0]->($self);
    }
    else {
      $help->($self);
    }
  }

  $self->set__abbreviations( $abbreviations // $FALSE );

  $self->set__program("$RealBin/$RealScript");

  $self->validate_command;

  $self->init_logger;

  $self->can('init') && $self->init();

  return $self;
}

########################################################################
sub _leave {
########################################################################
  my (@args) = @_;

  my ($exit_code) = ref $args[0] ? $args[1] : $args[0];

  exit $exit_code;
}

########################################################################
sub init_logger {
########################################################################
  my ($self) = @_;

  if ( $self->_use_logger ) {

    if ( my $config = $self->get_log4perl_conf ) {
      Log::Log4perl->init( \$config );
    }
    else {
      Log::Log4perl->easy_init( $LOG_LEVELS{error} );
    }

    my $logger = Log::Log4perl->get_logger(q{});

    $self->set_logger($logger);

    my $level = $self->get_log_level // $self->get_log4perl_level;

    $self->set_log_level($level);

    if ($level) {
      $logger->level( $LOG_LEVELS{$level} );
    }
  }

  my $commands = $self->commands;
  my $command  = $self->command;

  return $self
    if !$commands->{$command} || reftype( $commands->{$command} ) ne 'ARRAY';

  my ( $sub, $log_level ) = @{ $commands->{$command} };

  return $self
    if !$self->get_logger;

  $log_level = $self->get_log_level // $log_level;

  $self->get_logger->level( $LOG_LEVELS{$log_level} // $LOG_LEVELS{info} );

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

  @vars = map { $_ ? $_ : '<undef>' } @vars;

  my %args = map { @{$_} } zip \@vars, [ @{$command_args}[ 0 .. $#vars ] ];

  delete $args{'<undef>'};

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

  pod2usage(
    -noperldoc => 1,
    -exitval   => 'NOEXIT',
    -input     => $self->get__program
  );

  return _leave($FAILURE);
}

########################################################################
sub example {
########################################################################
  require File::ShareDir;

  print {*STDOUT} slurp File::ShareDir::dist_file( 'CLI-Simple', 'MyScript.pm' );

  return 0;
}

########################################################################
sub command {
########################################################################
  my ( $self, $command ) = @_;

  if ($command) {
    $self->set__command($command);
  }

  return $self->get__command;
}

########################################################################
sub commands {
########################################################################
  my ( $self, $command, $handler ) = @_;

  my $commands = $self->get__commands;

  if ( $command && $handler ) {

    croak "ERROR: usage: commands([command, subref])\n"
      if reftype($handler) ne 'CODE';

    $commands->{$command} = $handler;
  }

  return $commands;
}

########################################################################
sub program {
########################################################################
  my ($self) = @_;

  return $self->get__program;
}

########################################################################
sub validate_command {
########################################################################
  my ($self) = @_;

  my $commands = $self->commands;

  my $command = $self->command;

  return $command
    if defined $commands->{$command};

  croak sprintf "Unknown command: %s\n", $command
    if !$self->get__abbreviations;

  my $abbreviation = $command;

  my @matches = grep {/^$abbreviation/xsm} keys %{$commands};

  croak sprintf "Unknown command: %s\n", $command
    if !@matches;

  if ( @matches == 1 ) {
    $command = $matches[0];  # Unique match — accept
    $self->set__command($command);
    return $command;
  }

  croak sprintf "Ambiguous command '$abbreviation'; could match: %s\n", join q{,}, @matches;
}

########################################################################
sub run {
########################################################################
  my ($self) = @_;

  my $program = $self->program;
  my $command = $self->command;

  my $commands = $self->commands;

  my $handler = $commands->{$command};

  return $handler->($self)
    if ref $handler ne 'ARRAY';

  my ( $sub, $log_level ) = @{$handler};

  return $sub->($self);
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CLI::Simple - a minimalist object oriented base class for CLI applications

=head1 SYNOPSIS

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
   alias           => { options => {fmt => format}, commands => { ls => list } },
 )->run;

 1;

=head1 DESCRIPTION

Tired of writing the same 'ol boilerplate code for command line
scripts? Want a standard, simple way to create a Perl script that
takes options and commands?  C<CLI::Simple> makes it easy to create
scripts that take I<options>, I<commands> and I<arguments>.

For common constant values (like C<$TRUE>, C<$DASH>, or C<$SUCCESS>), see
L<CLI::Simple::Constants>, which pairs naturally with this module.

=head1 VERSION

This documentation refers to version 1.0.8.

=head2 Features

=over 5

=item * accept command line arguments ala L<Getopt::Long>

=item * supports commands and command arguments

=item * automatically add a logger

=item * global or custom log levels per command

=item * easily add usage notes

=item * automatically create setter/getters for your script

=item * low dependency profile

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

 caller or __PACKAGE__->main();

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

=head1 PHILOSOPHY AND DESIGN PRINCIPLES

C<CLI::Simple> is intentionally minimalist. It provides just enough
structure to build command-line tools with subcommands, option
parsing, and help handling -- but without enforcing any particular
framework or lifecycle.

=head2 Not a Framework

This module is not L<App::Cmd>, L<MooseX::Getopt>, or a full
application toolkit.  Instead, it offers:

=over 4

=item *

An object-oriented base class with a clean C<run()> dispatcher

=item *

Command-line parsing via C<Getopt::Long>

=item *

Built-in logging via C<Log::Log4perl>

=item *

Subclass hooks like C<init()> for setup and validation

=back

The philosophy is: provide just enough infrastructure, then get out of your way.

=head2 Validation, Defaults, and Configuration

C<CLI::Simple> does not impose a validation model. You may:

=over 4

=item *

Use C<Getopt::Long> features (e.g., type constraints, default values)

=item *

Write your own validation logic in C<init()>

=item *

Throw exceptions, emit usage, or exit early at any point

=back

The lifecycle is explicit and under your control. You decide how much structure
you want to add on top of it.

=head2 When to Use

CLI::Simple is ideal for:

=over 4

=item *

Internal tools and admin scripts

=item *

Bootstrapped CLIs where you don't want a framework

=item *

Users who want to subclass a clean, minimal interface

=back

For more advanced features - like command trees, plugin support, or interactive
CLI handling - consider heavier modules like L<App::Cmd>, L<CLI::Framework>, or
L<MooX::Options>.

=head1 CONSTANTS

C<CLI::Simple> does not define its own constants directly, but it is often used
in conjunction with L<CLI::Simple::Constants>, which provides a collection of
exportable values commonly needed in command-line scripts.

These include:

=over 4

=item *

Boolean flags like C<$TRUE>, C<$FALSE>, C<$SUCCESS>, and C<$FAILURE>

=item *

Common character tokens such as C<$COLON>, C<$DASH>, C<$EQUALS_SIGN>, etc.

=item *

Log level names compatible with L<Log::Log4perl>

=back

To use them in your script:

  use CLI::Simple::Constants qw(:all);

=head1 ADDITIONAL NOTES

=over 4

=item * All options are case insensitive

=item * See L<CLI::Simple::Utils> to learn about some additional
utililities that are useful when writing scripts.

=back

=head1 METHODS AND SUBROUTINES

=head2 new

  new( args )

Instantiates a new C<CLI::Simple> instance, parses options, optionally
initializes logging, and makes options available via dynamically
generated accessors.

I<Note: The C<new()> constructor uses L<Getopt::Long>'s C<GetOptions>,
which directly modifies C<@ARGV> by removing any recognized
options. The remaining elements of C<@ARGV> are treated as the command
name and its arguments.>

C<args> is a hash or hash reference containing the following keys:

=over 4

=item * abbreviations

A boolean that determines whether abbreviated command names are allowed.

When true, the C<run()> method will treat the provided command as a prefix
and compare it to the keys in the command hash. If exactly one match is
found, it will be used. If more than one match is found, or if no match is
found, C<run()> will throw an exception.

This allows for convenient shorthand like:

  mytool disable-sched    # expands to 'disable-scheduled-task'

default: false

=item * commands (required)

A hash mapping command names to either a subroutine reference or an
array reference.

If an array reference is used, the first element must be a subroutine
reference and the second should be a valid log level. (See
L</Per Command Log Levels>.)

Example:

  {
    send          => \&send_message,
    receive       => \&receive_message,
    list_messages => [ \&list_messages, 'error' ],
  }

If your script does not use command names, you may set a C<default> key
to the subroutine or method to run:

  { default => \&main }

If no default is provided, the default command becomes C<usage()>.

If your C<commands> hash contains only a single command, that command
will be run automatically when no command name is given on the command
line. This allows you to treat the program like a single-command tool,
where arguments can be passed directly without explicitly naming the
command.

=item * default_options (optional)

A hash reference providing default values for options. These values
apply if the corresponding option is not given on the command line.

=item * extra_options (optional)

An array reference of names for additional accessors you want to create,
even if they are not part of C<option_specs>.

Example:

  extra_options => [ qw(foo bar baz) ]

=item * option_specs (optional)

An array reference of option specifications, as accepted by
L<Getopt::Long>. These define the command-line options your program
recognizes.

=back

=head2 command

 command
 command(command)

Get or sets the command to execute. Usually this is the first argument
on the command line after all options have been parsed. There are
times when you might want to override the argument. You can pass a new
command that will be executed when you call the C<run()> method.

=head2 commands

 commands
 commands(command, handler)

Returns the hash you passed in the constructor as C<commands> or can
be used to insert a new command into the C<commands> hash. C<handler>
should be a code reference.

 commands(foo => sub { return 'foo' });

=head2 run

Execute the script with the given options, commands and arguments. The
C<run> method interprets the command line and passes control to your
command subroutines. Your subroutines should return a 0 for success
and a non-zero value for failure.  This error code is passed to the
shell as the script return code.

=head2 get_args

Return the arguments that follow the command.

  get_args(NAME, ... )     # with names
  get_args()               # raw positional args

With names:

- In scalar context, returns a hash reference mapping each NAME to the
  corresponding positional argument.
- In list context, returns a flat list of C<(name => value)> pairs.

With no names:

- Returns the command's positional arguments (array in list context;
  array reference in scalar context).

Example:

  sub send_message {
    my ($self) = @_;

    my %args = $self->get_args(qw(message email));

    _send_message($args{message}, $args{email});
  }

When you call C<get_args> with a list of names, values are assigned in
order: the first name gets the first argument, the second name gets the
second argument, and so on. If you only want specific positions, you may
use C<undef> as a placeholder:

  my %args = $self->get_args('message', undef, 'cc');  # args 1 and 3

If there are fewer positional arguments than names, the remaining names
are set to C<undef>. Extra positional arguments (beyond the provided
names) are ignored.

=head2 init

If you define your own C<init()> method, it will be called by the
constructor. Use this method to perform any actions you require before
you execute the C<run()> method.

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

Command-line options are defined using L<Getopt::Long>-style
specifications. You pass these into the constructor via the
C<option_specs> parameter:

  my $cli = CLI::Simple->new(
    option_specs => [ qw( help|h foo-bar=s log-level=s ) ]
  );

In your command subroutines, you can access these values using
automatically generated getter methods:

  $cli->get_foo();
  $cli->get_log_level();

Option names that contain dashes (C<->) are automatically converted to
snake_case for the accessor methods. For example:

  option_specs => [ 'foo-bar=s' ]

...results in:

  $cli->get_foo_bar();

=head1 COMMAND ARGUMENTS

If your commands accept positional arguments, you can retrieve them
using the C<get_args> method.

You may optionally provide a list of argument names, in which case the
arguments will be returned as a hash (or hashref in scalar context)
with named values.

Example:

  sub send_message {
    my ($self) = @_;

    my %args = $self->get_args(qw(phone_number message));

    send_sms_message($args{phone_number}, $args{message});
  }

If you call C<get_args()> without any argument names, it simply
returns all remaining arguments as a list:

  my ($phone_number, $message) = $self->get_args;

I<Note: When called with names, C<get_args> returns a hash in list
context and a hash reference in scalar context.>

=head1 CUSTOM ERROR HANDLER

By default, C<CLI::Simple> will exit if C<GetOptions> returns a false
value, indicating an error while parsing options. You can override this
behavior in one of two ways:

=over 4

=item * Set C<$CLI::Simple::EXIT_ON_ERROR> to a false value.

This disables automatic exiting and lets your program decide what to do
after an option-parsing failure.

=item * Provide an C<error_handler> callback in the constructor.

  my $cli = CLI::Simple->new(
    commands        => \%commands,
    default_options => \%default_options,
    extra_options   => \@extra_options,
    option_specs    => \@option_specs,
    abbreviations   => $TRUE,
    error_handler   => sub {
      my ($msg) = @_;
      print {*STDERR} $msg;
      return $TRUE;   # continue processing
    },
  );

The error handler is called with the error message from C<GetOptions>.
It must return a boolean: a true value allows processing to continue,
while a false value causes C<CLI::Simple> to exit immediately.

=back

=head1 SETTING DEFAULT VALUES FOR OPTIONS

To assign default values to your options, pass a hash reference as the
C<default_options> argument to the constructor. These values will be
used unless explicitly overridden by the user on the command line.

Example:

  my $cli = CLI::Simple->new(
    default_options => { foo => 'bar' },
    option_specs    => [ qw(foo=s bar=s) ],
    commands        => {
      foo => \&foo,
      bar => \&bar,
    },
  );

Defaulted options are accessible through their corresponding getter
methods, just like options set via the command line.

=head1 ADDING USAGE TO YOUR SCRIPTS

To provide built-in usage/help output, include a C<=head1 USAGE>
section in your script's POD:

  =head1 USAGE

    usage: myscript [options] command args

    Options
    -------
    --help, -h      Display help
    ...

If the user supplies the command C<help>, or the C<--help> option,
C<CLI::Simple> will display this section automatically:

  perl myscript.pm --help
  perl myscript.pm help

=head2 Custom help() Method

If you need full control over the help output, you can define a custom
C<help> method and assign it as a command:

  commands => {
    help => \&help,
    ...
  }

This is useful if your module follows the modulino pattern and you
want to present usage information that differs from the embedded
POD. Without a custom handler, C<CLI::Simple> defaults to displaying the
C<USAGE> POD section.

=head1 ADDING ADDITIONAL SETTERS

All command-line options are automatically available through getter
methods named C<get_*>.

If you need to create additional accessors (getters and setters) for
values that are not derived from the command line, use the
C<extra_options> parameter.

This is useful for passing runtime configuration or computed values
throughout your application.

Example:

  my $cli = CLI::Simple->new(
    default_options => { foo => 'bar' },
    option_specs    => [ qw(foo=s bar=s) ],
    extra_options   => [ qw(biz buz baz) ],
    commands        => {
      foo => \&foo,
      bar => \&bar,
    },
  );

This will generate C<get_biz>, C<set_biz>, C<get_buz>, etc., for
internal use.

=head1 LOGGING

C<CLI::Simple> integrates with L<Log::Log4perl> to provide structured
logging for your scripts.

To enable logging, call the class method C<use_log4perl()> in your
module or script:

  __PACKAGE__->use_log4perl(
    level  => 'info',
    config => $log4perl_config_string
  );

If you do not explicitly include a C<log-level> option in your
C<option_specs>, CLI::Simple will automatically add one for you.

Once enabled, you can access the logger instance via:

  my $logger = $self->get_logger;

This logger supports the standard Log4perl methods like C<info>,
C<debug>, C<warn>, etc.

=head2 Per Command Log Levels

Some commands may require more verbose logging than others. For
example, certain commands might perform complex actions that benefit
from detailed logs, while others are designed solely to produce clean,
structured output.

To assign a custom log level to a command, use an array reference as
the value for that command in the commands hash passed to the
constructor.

The array reference should contain at least two elements:

=over 4

=item A code reference to the command subroutine

=item A log level string: one of 'trace', 'debug', 'info', 'warn',
'error', or 'fatal'

=back

Example:

  CLI::Simple->new(
    option_specs    => [qw( help format=s )],
    default_options => { format => 'json' },  # set some defaults
    extra_options   => [qw( content )],       # non-option, setter/getter
    commands        => {
      execute => \&execute,
      list    => [ \&list, 'error' ],
    }
  )->run;

I<TIP: add other elements to the array for your command to process.>

=head1 FAQ

=over 4

=item * How do I execute startup code before my command runs?

Implement an C<init()> method in your class. The C<new()> constructor
will invoke this method before returning and before C<run()> is
executed.

Your C<init()> method will have access to all options and
arguments. Logging will also be initialized, so you can use
C<get_logger()> to emit messages.

=item * Do I need to implement commands?

No. If your script doesn't support multiple commands, you can specify
a C<default> key instead:

  commands => { default => \&main }

=item * Must I subclass C<CLI::Simple>?

No. You can use it procedurally or functionally.

=item * How do I turn my class into a script?

Use the modulino pattern: create a class that checks whether it is
being invoked directly:

  package MyScript;

  caller or __PACKAGE__->main();

  sub main {
    ...
  }

This lets the file be used as both a module and an executable script.

=item * How do the helper scripts work?

This distribution includes two scripts to help with modulino-style
scripts:

=over 4

=item modulino

A generic launcher that runs a Perl module as a script.

=item create-modulino.pl

Creates a symbolic link or wrapper script to make your modulino-based
module runnable from the command line.

Example:

  sudo create-modulino.pl Foo::Bar foo-bar

This creates an executable called C<foo-bar> that loads and invokes
C<Foo::Bar> as a modulino script.

=back

=back

=head1 ALIASING OPTIONS AND COMMANDS

C<CLI::Simple> lets you define short, human-friendly aliases for both
option names and command names. Use the C<alias> parameter to C<new():>

  my $app = CLI::Simple->new(
    option_specs    => [ qw(config=s verbose!) ],
    commands        => { list => \&list, execute => \&execute },
    alias => {
      options  => { cfg => 'config', v => 'verbose' },
      commands => { ls  => 'list'   }
    },
  );

=head2 How option aliases work

=over 4

=item * Spec tail is copied automatically

You only name the canonical option in C<option_specs>. For each alias,
C<CLI::Simple> finds the canonical option's spec tail (for example
C<=s>, C<:i>, C<!>, C<+>) and appends it to the alias. In the example
above, C<cfg> behaves as if you had written C<cfg=s>, and C<v> behaves
as if you had written C<v!>.

I<Note: If your option includes a one-letter short-cut and the alias
does not start with the same letter it will not be automatically
enabled as a short-cut.>

=item * Accessors are created for both names

Accessors are generated from all option names (canonical and aliases),
with '-' normalized to '_'. In the example, both C<get_config()> and
C<get_cfg()> are available.

=item * Values are mirrored after parsing

After option parsing and normalization, values are mirrored so either
name can be used consistently. If both the canonical name and its alias
are provided on the command line, the alias wins and becomes the final
value for both names.

=item * No duplicate injection

If the alias already exists in C<option_specs>, it will not be injected
again; value mirroring still occurs.

=item * Errors are explicit

If an alias points at a canonical option that does not exist,
C<CLI::Simple> croaks with a clear error.

=item * Case sensitivity

C<Getopt::Long> is used with C<:config no_ignore_case>, so option names
(and therefore aliases) are case sensitive by default.

=back

=head2 How command aliases work

=over 4

=item * Simple mapping

Provide C<alias => { commands => { alias => canonical } }> to map an alias
to an existing command. In the example, C<ls> dispatches to the C<list>
command.

=item * Applied before abbreviations

Aliases are installed before command abbreviation resolution. If you
enable abbreviations, they apply to the full set of command names,
including any aliases.

=item * Errors are explicit

If an alias points at a command that does not exist, C<CLI::Simple> croaks
with a clear error.

=back

=head2 Usage examples

  # Using an option alias
  script.pl --cfg app.json execute

  # Using a command alias
  script.pl ls

After parsing, both C<get_config()> and C<get_cfg()> will return the
same value. If the user passes both C<--config> and C<--cfg>, the value
from C<--cfg> (the alias) is used.

=head2 Recommendations

=over 4

=item * Keep the canonical spec single-named

Define a single canonical name in C<option_specs> and add other spellings
via C<alias>. Avoid multi-name specs like C<config|cfg=s>; use C<alias>
instead.

=item * Document your precedence

If you prefer the alias name to win when both are supplied, enforce
that in your application or adjust the mirroring order. By default, the
canonical name wins.

=back

=head1 ERRORS/EXIT CODES

When you execute the C<run()> method it passes control to the method
that implements the command specified on the command line. Your method
is expected to return 0 for success or an error code that you can the
pass to the shell on exit.

  exit CLI::Simple->new(commands => { foo => \&cmd_foo })->run();

=head2 Exit Codes

C<CLI::Simple> uses conventional exit codes so that calling scripts
can distinguish between normal completion and error conditions.

=over 4

=item * '0'

Successful completion of a command (C<SUCCESS>).

=item * '1'

General usage error, such as C<--help> display via C<pod2usage>, or an
invalid command line (C<FAILURE>).

=item * '2'

Option parsing failure, such as an unrecognized option or invalid
argument (also reported as C<FAILURE>).

=item * Any other code

If a user-supplied command callback explicitly calls C<exit()> or
returns a numeric value other than 0 - 2, that code is passed through
unchanged to the shell. This allows application-specific exit codes.

=back

=head1 EXAMPLE

Run the shell script that comes with the distribution to output a
working example.

 cli-simple-example > example.pl

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
L<https://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Getopt::Long>, L<CLI::Simple::Utils>, L<Pod::Usage>, L<App::Cmd>,
L<CLI::Framework>, L<MooX::Options>

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
