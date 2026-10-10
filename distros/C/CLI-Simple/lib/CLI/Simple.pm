package CLI::Simple;
# a Simple, Fast & Easy way to create scripts

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars :log-levels @VALID_OPTIONS @DEFAULT_HELP_SECTIONS :color-config);
use CLI::Simple::Utils qw(normalize_options slurp dmp choose);
use CLI::Simple::DumpSpec qw(_cmd_dump_spec);
use CLI::Simple::Migrate qw(_cmd_migrate);
use CLI::Simple::Scaffold qw(_cmd_scaffold);
use CLI::Simple::Helpers qw(_is_class_name);
use CLI::Simple::Shell;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use FindBin qw($RealBin $RealScript);
use File::Basename qw(basename);
use File::Which qw(which);
use Getopt::Long qw(:config no_ignore_case);
use IO::Interactive;
use List::Util qw(none pairs any);
use Scalar::Util qw(reftype);

our $VERSION = '2.3.1';

our $GETOPT_EXIT_ON_ERROR = $TRUE;
our $GETOPT_STATUS;
our $GETOPT_ERROR_MESSAGE;

my %GENERATED_ACCESSOR;  # tracks accessors mk_accessors itself created, per class

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    _validate_command
    _command
    _command_args
    _commands
    _program
    _abbreviations
  )
);

our $USE_LOGGER   = $FALSE;
our $AUTO_DEFAULT = $FALSE;
our $AUTO_HELP    = $FALSE;
our $PAGER        = $TRUE;

our %INTERNAL_COMMANDS = (
  '-generate-completion' => \&_cmd_generate_completion,
  '-migrate'             => \&_cmd_migrate,
  '-dump-spec'           => \&_cmd_dump_spec,
  '-scaffold'            => \&_cmd_scaffold,
);

our @EXPORT_OK = qw($AUTO_HELP $AUTO_DEFAULT $PAGER $USE_LOGGER);

use parent qw(Exporter Class::Accessor::Fast);

# CLI::Simple 2.0.0 additions

our $MANIFEST;  # package-level, per-consumer class

caller or exit __PACKAGE__->main();

########################################################################
sub import {
########################################################################
  my ( $class, @args ) = @_;

  if ( any { $_ eq ':roles' } @args ) {
    my $caller = caller;

    if ( !${^COMPILING} ) {
      ( my $dist = $caller ) =~ s/::/-/gxsm;
      my $yaml_file = lc($dist) . '.yml';

      require File::ShareDir;
      my $path = eval { File::ShareDir::dist_file( $dist, $yaml_file ) };
      undef $path if $path && !-e $path;

      $class->_load_manifest( $caller, $path ) if $path;
    }
  }

  # preserve existing Exporter behaviour
  $class->export_to_level( 1, $class, grep { $_ ne ':roles' && !/[.]ya?ml\z/xsm } @args );

  return;
}

########################################################################
sub _load_manifest {
########################################################################
  my ( $class, $target, $yaml_file ) = @_;

  require YAML::Tiny;

  my $manifest = YAML::Tiny::LoadFile($yaml_file)
    or die "ERROR: could not load manifest: $yaml_file\n";

  my $commands = $manifest->{commands} // {};
  my $roles    = $manifest->{roles}    // {};

  foreach my $cmd ( keys %{$roles} ) {
    die sprintf "ERROR: command '%s' is defined in both commands and roles\n", $cmd
      if exists $commands->{$cmd};
  }

  my %selective_roles;

  foreach my $cmd ( keys %{$roles} ) {
    my $value = $roles->{$cmd};

    my @roles = choose {
      return @{$value}
        if ref $value && reftype($value) eq 'ARRAY';

      return ($value)
        if !ref $value;

      die sprintf "ERROR: invalid roles specification for command '%s'\n", $cmd;
    };

    foreach my $role (@roles) {
      die sprintf "ERROR: invalid role '%s' for command '%s'\n", $role, $cmd
        if !_is_class_name($role);
    }

    $selective_roles{$cmd} = \@roles;
  }

  $manifest->{_commands} = $commands;
  $manifest->{_roles}    = \%selective_roles;

  # store on the target class
  no strict 'refs'; ## no critic
  ${"${target}::_CLI_MANIFEST"} = $manifest;

  return;
}

########################################################################
sub _manifest {
########################################################################
  my ($class) = @_;

  no strict 'refs'; ## no critic
  return ${"${class}::_CLI_MANIFEST"};
}

########################################################################
sub main {
########################################################################
  my ($class) = @_;

  my $manifest = $class->_manifest;

  my $cli = $class->new(
    option_specs      => $manifest ? ( $manifest->{options} // [] )           : [],
    alias             => $manifest ? ( $manifest->{alias} // {} )             : {},
    default_options   => $manifest ? ( $manifest->{default_options} // {} )   : {},
    extra_options     => $manifest ? ( $manifest->{extra_options} // [] )     : [],
    commands          => $manifest ? {}                                       : { default => \&usage },
    manifest_commands => $manifest ? ( $manifest->{_commands} // {} )         : {},
    command_roles     => $manifest ? ( $manifest->{_roles} // {} )            : {},
    abbreviations     => $manifest ? ( $manifest->{abbreviations} // $FALSE ) : $FALSE,
  );

  return $cli->run;
}

########################################################################
sub _use_logger {
########################################################################
  return $USE_LOGGER;
}

########################################################################
sub use_log4perl {
########################################################################
  my ( $self, %args ) = @_;

  my @valid_options = qw(
    log_level
    level
    loglevel
    log-level
    config
    color
    debug_color
    info_color
    warn_color
    error_color
    trace_color
    fatal_color
  );

  foreach my $o ( keys %args ) {
    die "ERROR: unknown argument ($o)\n"
      if none { $o eq $_ } @valid_options;
  }

  eval { require Log::Log4perl; 1; }
    or die "use_log4perl() requires Log::Log4perl, which is not installed.\n"
    . "It is an opt-in feature, so CLI::Simple does not depend on it.\n"
    . "If your app calls use_log4perl(), add 'Log::Log4perl' to your requires/cpanfile.\n";

  my $class = ref $self || $self;

  die "ERROR: color and config are mutually exclusive - color uses CLI::Simple's built-in colorized config\n"
    if $args{color} && $args{config};

  my ($level) = grep {defined} @args{qw(log_level log-level loglevel level)};
  $level //= 'error';

  my $log4perl_conf = $args{config};

  if ( $args{color} && !$log4perl_conf ) {
    $log4perl_conf = $self->_set_color_config(%args);
  }

  {
    $USE_LOGGER = $TRUE;

    no strict 'refs'; ## no critic (ProhibitNoStrict)
    *{"${class}::get_log4perl_conf"}  = sub { return $log4perl_conf };
    *{"${class}::set_log4perl_conf"}  = sub { $log4perl_conf = $_[1] };
    *{"${class}::get_log4perl_level"} = sub { return $level };
  }

  if ( !$self->can('set_logger') ) {
    $self->mk_accessors('logger');
    $GENERATED_ACCESSOR{$class}{logger} = $TRUE;
  }

  if ( !$self->can('set_log_level') ) {
    $self->mk_accessors('log_level');
    $GENERATED_ACCESSOR{$class}{log_level} = $TRUE;
  }

  return $self;
}

########################################################################
sub new {
########################################################################
  my ( $class, @params ) = @_;

  my $t0 = time;

  my %args = ref $params[0] ? %{ $params[0] } : @params;

  foreach my $o ( keys %args ) {
    die "ERROR: unknown option '$o'\n"
      if none { $o eq $_ } @VALID_OPTIONS;
  }

  my (
    $default_options, $option_specs,  $commands, $command_roles,    $manifest_commands, $extra_options,
    $abbreviations,   $error_handler, $alias,    $validate_command, $help_sections
    )
    = @args{
    qw(default_options option_specs commands command_roles manifest_commands extra_options abbreviations error_handler alias validate_command help_sections)
    };

  $validate_command //= $TRUE;

  no strict 'refs'; ## no critic

  my $stash = \%{ $class . $DOUBLE_COLON };

  local *alias = *alias; ## no critic ProhibitLocalVars

  use vars qw($DEFAULT_OPTIONS $EXTRA_OPTIONS $OPTION_SPECS $COMMANDS $LOGGING);

  *DEFAULT_OPTIONS = $stash->{DEFAULT_OPTIONS} // $EMPTY;
  *EXTRA_OPTIONS   = $stash->{EXTRA_OPTIONS}   // $EMPTY;
  *OPTION_SPECS    = $stash->{OPTION_SPECS}    // $EMPTY;
  *COMMANDS        = $stash->{COMMANDS}        // $EMPTY;

  $default_options //= $DEFAULT_OPTIONS;
  $extra_options   //= $EXTRA_OPTIONS;
  $option_specs    //= $OPTION_SPECS;
  $commands        //= $COMMANDS;

  $option_specs      //= [];
  $commands          //= {};
  $manifest_commands //= {};
  $command_roles     //= {};

  foreach my $command ( keys %{$manifest_commands}, keys %{$command_roles} ) {
    $commands->{$command} //= sub { die "not implemented\n" };
  }

  croak sprintf "ERROR: 'commands' is required\nusage: %s->new( option_specs => specs, commands => commands);\n", __PACKAGE__
    if !$option_specs || !$commands;

  my %command_target = map { $_ => $_ } keys %{$commands};

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

  if ( @ARGV && $ARGV[0] =~ /^-[[:alpha:]]/xsm ) {
    if ( my $handler = $INTERNAL_COMMANDS{ $ARGV[0] } ) {
      exit $handler->( $class, $commands, $option_specs );
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
    die "ERROR: accessor must be a scalar\n"  # somebody did @extra_options = [qw( a b c )] ???
      if ref $_;

    s/\-/_/xsmg;

    # can() can't tell "a human hand-wrote this method" apart from
    # "mk_accessors already generated this on an earlier ->new() call
    # for this same class" -- both look identical. Only the latter is
    # fine (constructing multiple instances of the same class within
    # one process is completely normal); only the former is the
    # genuine naming collision this check exists to catch. Track what
    # this class has already generated, per class, so a repeat
    # construction doesn't get mistaken for a hand-written conflict.
    if ( !$GENERATED_ACCESSOR{$class}{$_} ) {
      die "ERROR: accessor for $_ already exists!\n"
        if $class->can( 'get_' . $_ ) || $class->can( 'set_' . $_ );

      $class->mk_accessors($_);

      $GENERATED_ACCESSOR{$class}{$_} = $TRUE;
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

    # command aliases are a convenience so someone doesn't have to add
    # to $commands manually

    if ( $alias->{commands} ) {
      foreach my $p ( pairs %{ $alias->{commands} } ) {
        my ( $aka, $name ) = @{$p};

        croak sprintf "ERROR: no command: %s\n", $name
          if !$commands->{$name};

        $commands->{$aka} = $commands->{$name};
        $command_target{$aka} = $name;
      }
    }
  }

  my $self = $class->SUPER::new( \%cli_options );

  if ( !$self->can('get_help_sections') ) {
    $self->mk_accessors('help_sections');
    $GENERATED_ACCESSOR{$class}{help_sections} = $TRUE;
  }
  else {
    $help_sections //= $self->get_help_sections;
  }

  $help_sections //= [@DEFAULT_HELP_SECTIONS];

  $self->set_help_sections($help_sections);

  # AUTO_DEFAULT uses the only command as the default
  if ( $AUTO_DEFAULT && scalar keys %{$commands} == 1 ) {
    my ($command) = keys %{$commands};

    if ( @ARGV && $ARGV[0] ne $command ) {
      unshift @ARGV, $command;
    }
    elsif ( !@ARGV ) {
      unshift @ARGV, $command;
    }
  }

  my $command = shift @ARGV // $EMPTY;

  if ( !$command ) {
    if ( $commands->{default} ) {
      $command = ref $commands->{default} ? 'default' : $commands->{default};
    }
    elsif ($AUTO_HELP) {
      $command = 'help';
    }
  }

  $self->set__validate_command($validate_command);

  $self->set__command($command);

  $self->set__command_args( [@ARGV] );

  $self->set__commands($commands);

  $self->set__program("$RealBin/$RealScript");

  if ( $command eq 'help' || ( $self->can('get_help') && $self->get_help ) ) {
    # custom help function?

    my $help = $commands->{help};

    if ( !$help ) {
      $self->usage;
    }

    if ( ref $help && reftype($help) eq 'ARRAY' ) {
      $help->[0]->( $self, $TRUE );
    }
    else {
      $help->( $self, $TRUE );
    }
  }

  $self->set__abbreviations( $abbreviations // $FALSE );

  $self->validate_command;
  $command = $self->command;

  if ($command) {
    my $target_command = $command_target{$command} // $command;

    if ( exists $command_roles->{$target_command} ) {
      my $roles = $command_roles->{$target_command};

      require Role::Tiny;
      Role::Tiny->apply_roles_to_package( $class, @{$roles} );

      ( my $method = "cmd_$target_command" ) =~ s/-/_/gxsm;

      die sprintf "ERROR: roles for command '%s' do not implement %s\n", $target_command, $method
        if !$class->can($method);

      my $handler = $class->can($method);

      $commands->{$target_command} = $handler;
      $commands->{$command}        = $handler;
    }
    elsif ( exists $manifest_commands->{$target_command} ) {

      #
      # Legacy semantics: selecting ONE legacy command opts into
      # composition of the entire legacy role set.
      #

      my %seen;
      my @roles = grep { !$seen{$_}++ && _is_class_name($_) } values %{$manifest_commands};

      require Role::Tiny;
      Role::Tiny->apply_roles_to_package( $class, @roles );

      foreach my $cmd ( keys %{$manifest_commands} ) {
        my $value = $manifest_commands->{$cmd};

        my $method = choose {
          return $value
            if !_is_class_name($value);

          ( my $m = "cmd_$cmd" ) =~ s/-/_/gxsm;
          return $m;
        };

        die sprintf "ERROR: %s does not implement %s\n", $value, $method
          if !$class->can($method);

        $commands->{$cmd} = $class->can($method);
      }

      #
      # Restore aliases now that the placeholder handlers have
      # been replaced by the real legacy dispatch handlers.
      #

      foreach my $aka ( keys %command_target ) {
        my $target = $command_target{$aka};

        next
          if $aka eq $target;

        $commands->{$aka} = $commands->{$target}
          if exists $commands->{$target};
      }
    }
  }

  $self->init_logger;

  $self->can('init') && $self->init();

  return $self;
}

########################################################################
sub _pod_has_section {
########################################################################
  my ( $filename, $section ) = @_;

  open my $fh, '<', $filename
    or return $FALSE;

  while ( my $line = <$fh> ) {
    return $TRUE
      if $line =~ /\A=head1\s+\Q$section\E\s*\z/xsm;
  }

  return $FALSE;
}

########################################################################
sub _get_help_sections {
########################################################################
  my ( $self, $input ) = @_;

  my $sections = $self->get_help_sections;

  return $sections
    if @{$sections} != @DEFAULT_HELP_SECTIONS;

  for my $idx ( 0 .. $#DEFAULT_HELP_SECTIONS ) {
    return $sections
      if $sections->[$idx] ne $DEFAULT_HELP_SECTIONS[$idx];
  }

  return [ _pod_has_section( $input, 'USAGE' )
    ? 'USAGE'
    : 'SYNOPSIS',
    'DESCRIPTION/Commands', 'DESCRIPTION/Options', 'OPTIONS', ];
}

########################################################################
sub _leave {
########################################################################
  my (@args) = @_;

  my ($exit_code) = ref $args[0] ? $args[1] : $args[0];

  exit $exit_code;
}

########################################################################
sub _set_color_config {
########################################################################
  my ( $self, %args ) = @_;

  return sprintf $LOG4PERL_CONF,
    $args{debug_color} // $LOG4PERL_COLOR_DEBUG,
    $args{info_color}  // $LOG4PERL_COLOR_INFO,
    $args{warn_color}  // $LOG4PERL_COLOR_WARN,
    $args{error_color} // $LOG4PERL_COLOR_ERROR,
    $args{fatal_color} // $LOG4PERL_COLOR_FATAL,
    $args{trace_color} // $LOG4PERL_COLOR_TRACE;
}

########################################################################
sub init_logger {
########################################################################
  my ($self) = @_;

  if ( $self->_use_logger && $self->can('get_log4perl_conf') ) {

    my $config = $self->get_log4perl_conf;

    my $color = $self->can('get_color') && defined $self->get_color ? $self->get_color : $config && $config eq $LOG4PERL_CONF;

    $color = $color && eval { require Term::ANSIColor; 1; };

    # color on, but not done through use_log4perl?
    if ( $color && !$config ) {
      $config = $self->_set_color_config;
    }
    elsif ( !$color && $config && $config =~ /screencoloredlevels/xsmi ) {
      $config = q{};
    }

    $self->set_log4perl_conf($config);

    if ($config) {
      Log::Log4perl->init( ref $config ? $config : \$config );
    }
    else {
      Log::Log4perl->import(':easy');
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
    if !$command || !$commands->{$command} || !ref( $commands->{command} ) || reftype( $commands->{$command} ) ne 'ARRAY';

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

########################################################################
sub set_args {
########################################################################
  my ( $self, $args ) = @_;

  $self->set__command_args($args);

  return $args;
}

########################################################################
sub get_args {
########################################################################
  my ( $self, @vars ) = @_;

  my $command_args = $self->get__command_args;

  return wantarray ? @{$command_args} : $command_args
    if !@vars;

  @vars = map { $_ ? $_ : '<undef>' } @vars;

  my %args;
  @args{@vars} = @{$command_args}[ 0 .. $#vars ];

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

  require Pod::Usage;

  my $wrapper = $ENV{MODULINO_WRAPPER} // q{};

  my $input = $wrapper eq 'cli-simple' ? $INC{'CLI/Simple/Shell.pm'} : $self->get__program;

  if ( $PAGER && IO::Interactive::is_interactive ) {
    eval {
      require IO::Pager;
      IO::Pager->new(*STDOUT);
    };
  }

  my $sections = $self->_get_help_sections($input);

  Pod::Usage::pod2usage(
    -noperldoc => 1,
    -exitval   => 'NOEXIT',
    -input     => $input,
    -verbose   => 99,
    -sections  => $sections,
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
sub command_args {
########################################################################
  my ( $self, @args ) = @_;

  return $self->get__command_args
    if !@args;

  if ( ref $args[0] ) {
    $self->set__command_args( $args[0] );
    return;
  }

  $self->set__command_args( [@args] );

  return;
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

  my $command = $self->command;

  return
    if !$command || !$self->get__validate_command;

  my $commands = $self->commands;

  return $command
    if defined $commands->{$command};

  croak sprintf "Unknown command: %s\n", $command
    if !$self->get__abbreviations;

  my $abbreviation = $command;

  my @matches = grep {/^$abbreviation/xsm} keys %{$commands};

  croak sprintf "Unknown command: %s\n", $command
    if !@matches;

  if ( @matches == 1 ) {
    $command = $matches[0];  # Unique match - accept
    $self->set__command($command);
    return $command;
  }

  croak sprintf "Ambiguous command '$abbreviation'; could match: %s\n", join q{,}, @matches;
}

########################################################################
sub _cmd_generate_completion {
########################################################################
  my ( $class, $commands, $option_specs ) = @_;

  no strict 'refs'; ## no critic
  my $stash = \%{ $class . '::' };

  my $cmd_list = join q{ }, sort grep { !/^-/xsm } keys %{$commands};

  my $program = $ENV{MODULINO_WRAPPER} // do {
    ( my $name = $class ) =~ s/::/-/gxsm;
    lc $name;
  };

  my @flags;
  my @value_opts;

  for my $spec ( @{$option_specs} ) {
    my ($name) = $spec =~ /\A([\w-]+)/xsm;
    $name =~ s/_/-/gxsm;

    if ( $spec =~ /[=:]/xsm ) {
      push @value_opts, "--$name";
    }
    else {
      push @flags, "--$name";
    }
  }

  my $flags      = join q{ }, sort @flags;
  my $value_opts = join q{ }, sort @value_opts;

  printf {*STDOUT} <<'END_COMPLETION', $program, $cmd_list, $value_opts, $flags, $program, $program;
_%s() {
  local cur prev words cword
  _init_completion || return

  local commands="%s"
  local value_opts="%s"
  local flags="%s"

  if [[ $cword -eq 1 ]]; then
    if [[ "$cur" == --* ]]; then
      COMPREPLY=( $(compgen -W "$flags $value_opts" -- "$cur") )
    else
      COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
    fi
    return
  fi

  case $prev in
    $value_opts)
      COMPREPLY=( $(compgen -f -- "$cur") )
      return ;;
  esac

  COMPREPLY=( $(compgen -W "$flags $value_opts" -- "$cur") )
}

complete -F _%s %s
END_COMPLETION

  return $SUCCESS;
}

########################################################################
sub run {
########################################################################
  my ($self) = @_;

  my $command = $self->command;

  ######################################################################
  # a blank command means that we did not have a default && AUTO_HELP
  # is off scripter has deliberately decided to allow running of
  # init() phase w/o a run phase
  ######################################################################

  return $SUCCESS
    if !$command;

  my $commands = $self->commands;

  my $program = $self->program;

  my $handler = $commands->{$command};

  if ( $handler && !ref $handler ) {
    $handler = $commands->{$handler};  # default?
  }

  die "ERROR: no such command '$command' has been registered.\n"
    if !$handler;

  if ( ref $handler ne 'ARRAY' ) {
    my $result = $handler->($self);
    return $result;
  }

  my ( $sub, $log_level ) = @{$handler};

  croak "ERROR: invalid specification for $command\n"
    if !ref $sub || reftype($sub) ne 'CODE';

  return $sub->($self);
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CLI::Simple - a minimalist object oriented base class for CLI applications

=head1 SYNOPSIS

 #!/usr/bin/env perl

 package MyScript;

 use strict;
 use warnings;

 use CLI::Simple::Constants qw(:booleans :chars);
 use CLI::Simple qw($AUTO_HELP $AUTO_DEFAULT);

 use parent qw(CLI::Simple);

 caller or exit __PACKAGE__->main();

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

   # Disable auto-default for single commands, enable auto-help
   $AUTO_DEFAULT = 0;
   $AUTO_HELP = 1;

   my $cli = MyScript->new(
    option_specs    => [ qw( help format=s file=s) ],
    default_options => { format => 'json' }, # set some defaults
    extra_options   => [ qw( content ) ], # non-option, setter/getter
    commands        => { execute => \&execute, list => \&list,  }
    alias           => { options => { fmt => 'format' }, commands => { ls => 'list' } },
   );

   return $cli->run();
 }

 1;

# role-based CLI Application (2.0.0)

# create a YAML manifest C<my-script.yml> in your project root:

  ---
  roles:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s

# create a main module

  package My::Script;

  use CLI::Simple qw(:roles);
  use parent qw(CLI::Simple);

  our $VERSION = '1.0.0';

  caller or exit __PACKAGE__->main;

  1;

# create implementation roles

  package My::Script::Role::Frobnicate;

  use Role::Tiny;
  use CLI::Simple::Constants qw(:booleans);

  sub cmd_frobnicate {
    my ($self) = @_;
    ...
    return $SUCCESS;
  }

  1;

=head1 DESCRIPTION

=begin markdown

[![CLI-Simple](https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml/badge.svg)](https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml)

=end markdown

Tired of writing the same 'ol boilerplate code for command line
scripts? Want a standard, simple way to create a Perl script that
takes options and commands?  C<CLI::Simple> makes it easy to create
scripts that take I<options>, I<commands> and I<arguments>.

C<CLI::Simple> is designed around the I<modulino> pattern - Perl
modules that can be executed directly as scripts. See L</MODULINOS>.

For common constant values (like C<$TRUE>, C<$DASH>, or C<$SUCCESS>), see
L<CLI::Simple::Constants>, which pairs naturally with this module.

Version 2.0.0 introduces optional role-based architecture for applications
that have outgrown a single module. Declare your commands and options in a
YAML manifest, implement each command in a dedicated L<Role::Tiny> role, and
C<CLI::Simple> handles composition, dispatch, and lifecycle automatically.
Your main module shrinks to a single line:

  caller or exit __PACKAGE__->main;

Not ready for a full refactor? Start smaller. The built-in C<-dump-spec>
command introspects your existing module and writes a YAML manifest that
makes your configuration data-driven without moving a single line of
implementation code. Adopt roles incrementally, one command at a time.

When you are ready to scaffold a full role-based project, C<-scaffold>
generates role stubs, a slimmed main module, and inter-module dependencies
from your manifest. Feed the resulting tarball to
L<CPAN::Maker::Bootstrapper> and you have a complete, buildable CPAN
distribution in one step.

Version 2.3.0 adds selective role composition. Commands declared with
the C<roles> manifest key compose only the roles required by the selected
command. The original C<commands> form remains supported for backward
compatibility and retains its original behavior of composing the complete
set of command roles.

=head1 VERSION

This documentation refers to version 2.3.1.

=head1 FEATURES

=over 5

=item * accept command line arguments ala L<Getopt::Long>

=item * supports commands and command arguments

=item * automatically add a logger

=item * global or custom log levels per command

=item * easily add usage notes

=item * automatically create setter/getters for your script

=item * low dependency profile

=item * selective role composition through YAML command manifests

=item * built-in scaffolding tools for migrating legacy scripts to roles

=item * bash completion script generation for modulino wrappers

=item * optional pager support for help output via L<IO::Pager>

=item * customizable help sections via C<help_sections>

=back

=head1 MODULINOS

A I<modulino> is a Perl module that can also be run directly as a
script. The term was coined by Brian D. Foy and the pattern is simple:

  caller or exit __PACKAGE__->main();

When the file is C<require>d or C<use>d by another module, C<caller>
returns the calling package and the expression short-circuits -
C<main()> is never called. When the file is executed directly by Perl,
C<caller> returns false and C<main()> runs. The same file serves as
both a reusable module and an executable script.

C<CLI::Simple> is designed around this pattern. Every C<CLI::Simple>
application is expected to be a modulino. The framework's lifecycle,
internal commands, bash completion, and scaffolding tools all assume
this dual-use design.

=head2 Why Modulinos?

The modulino pattern offers several advantages over a traditional
script:

=over 4

=item * B<Testable> - your script logic lives in a proper Perl module
that can be C<use>d in test files without executing C<main()>

=item * B<Reusable> - other scripts and modules can C<use> your
modulino and call its methods directly

=item * B<Introspectable> - tools like C<-dump-spec> and
C<-generate-completion> can load your modulino and inspect its live
state without running it as a script

=item * B<Installable> - modulinos distribute cleanly as CPAN modules
with full man page support via L<CPAN::Maker::Bootstrapper>

=back

=head2 The Bash Wrapper

Perl modulinos are invoked via a thin bash wrapper script that locates
the installed module file and passes all arguments through to Perl:

  #!/usr/bin/env bash
  #-*- mode: sh; -*-

  MODULINO_WRAPPER=my-script
  MODULE_NAME=My::Script
  MODULE_PATH=$(MODULE_PATH="${MODULE_NAME//:://}.pm" \
    perl -M$MODULE_NAME -e 'print $INC{$ENV{MODULE_PATH}};')

  MODULINO_WRAPPER=$MODULINO_WRAPPER perl $MODULE_PATH "$@"

The wrapper locates the installed C<.pm> file via C<%INC> and sets
C<MODULINO_WRAPPER> in the environment so C<CLI::Simple> knows the
name of the script the user actually typed. This is used by
C<-generate-completion> to name the bash completion function correctly
and by L<CPAN::Maker::Bootstrapper> to create man page symlinks.

=head2 create-modulino

C<CLI::Simple> ships with a C<create-modulino> tool that generates the
bash wrapper for any C<CLI::Simple> modulino:

  # create wrapper using module name convention (My::Script -> my-script)
  create-modulino -m My::Script

  # install to a specific directory
  create-modulino -m My::Script -i /usr/local/bin

  # use a custom wrapper name
  create-modulino -m My::Script -a my-alias -i /usr/local/bin

C<create-modulino> is itself a modulino - an example of the pattern it
creates. The bash wrapper template lives in its C<__DATA__> section,
keeping the tool entirely self-contained.

If you are building a CPAN distribution, L<CPAN::Maker::Bootstrapper>
integrates C<create-modulino> into the C<make modulino> target,
generating and installing the wrapper as part of the build process.

=head2 MODULINO_WRAPPER

The C<MODULINO_WRAPPER> environment variable tells C<CLI::Simple> the
name of the wrapper script that invoked the modulino. It is set by the
wrapper and used by:

=over 4

=item * C<-generate-completion> - to name the bash completion function
and C<complete> target correctly

=item * Man page symlinks via L<CPAN::Maker::Bootstrapper> - so
C<man my-script> resolves to the module's man page

=back

If C<MODULINO_WRAPPER> is not set, C<CLI::Simple> infers the script
name from the module name by convention - C<My::Script> becomes
C<my-script>. Set it explicitly when the wrapper name does not follow
this convention.

=head1 QUICK START

=head2 Single-Module Application

The simplest way to use C<CLI::Simple> is to subclass it and define
your commands as methods in the same module:

  package My::Script;

  use strict;
  use warnings;

  use CLI::Simple::Constants qw(:booleans);

  use parent qw(CLI::Simple);

  caller or exit __PACKAGE__->main;

  sub cmd_frobnicate {
    my ($self) = @_;
    my $output = $self->get_output;
    ...
    return $SUCCESS;
  }

  sub main {
    __PACKAGE__->new(
      option_specs => [ qw( help|h verbose|v output|o=s ) ],
      commands     => { frobnicate => \&cmd_frobnicate },
    )->run;
  }

  1;

=head2 Role-Based Application

For larger applications, declare your commands and options in a YAML
manifest and implement each command in a dedicated L<Role::Tiny> role.
Your main module becomes a single declaration:

  package My::Script;

  use strict;
  use warnings;

  use CLI::Simple qw(:roles);
  use parent qw(CLI::Simple);

  our $VERSION = '1.0.0';

  caller or exit __PACKAGE__->main;

  1;

B<Naming convention:> The YAML manifest filename is derived from your
module name - C<My::Script> looks for C<my-script.yml> in the
distribution share directory. You must package the spec file with your
distribution.

The manifest maps commands to roles:

  ---
  roles:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s

Each role implements one or more commands:

  package My::Script::Role::Frobnicate;

  use Role::Tiny;
  use CLI::Simple::Constants qw(:booleans);

  sub cmd_frobnicate {
    my ($self) = @_;
    ...
    return $SUCCESS;
  }

  1;

To easily generate the directory structure, role stubs, and build
files for this architecture, C<CLI::Simple> provides a built-in
C<-scaffold> tool.

See L</-scaffold> for detailed instructions on generating a role-based
project tarball from a monolithic script or a YAML manifest. For a
comprehensive guide on transitioning your application, see
L</ROLE-BASED ARCHITECTURE>.

=head1 ROLE-BASED ARCHITECTURE

C<CLI::Simple> 2.0.0 introduced an optional role-based architecture
for applications that have grown beyond a single module. Commands may
be implemented in dedicated L<Role::Tiny> roles and declared in a YAML
manifest, allowing C<CLI::Simple> to build the dispatch table and
provide an inherited C<main()> - potentially reducing your main module
to a single declaration.

Version 2.3.0 adds selective role composition through the C<roles:>
manifest key. When C<roles:> is used, only the role or roles required
by the selected command are composed. The original C<commands:>
manifest form remains supported for backward compatibility and retains
its original behavior of composing the complete set of command roles.

=head2 The YAML Manifest

The manifest is a YAML file that declares your commands, options, and
defaults. By convention the filename is derived from your module name:

  My::Script                 ->  my-script.yml
  CPAN::Maker::Bootstrapper  ->  cpan-maker-bootstrapper.yml

C<CLI::Simple> locates the manifest via L<File::ShareDir> using the
distribution name derived from the module name. The manifest must be
installed as part of the distribution - it cannot be loaded from an
arbitrary location.

I<Security note: The manifest is loaded exclusively from the
distribution share directory via L<File::ShareDir>. A manifest that
was not installed as part of the distribution cannot be loaded. This
provides the same security model as Perl module loading itself.>

I<Note: Version 2.3.0 introduces C<roles:> for selective role
composition. The original C<commands:> form remains supported for
backward compatibility. See L</roles: vs commands:>.>

A minimal manifest:

  ---
  roles:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s

A complete manifest with all supported keys:

  ---
  roles:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s
  default_options:
    verbose: 0
  extra_options:
    - dbh
    - config_data

=head2 Command Values

Entries beneath C<roles:> map a command name to either a single role
or a list of roles required by that command.

For example:

  roles:
    frobnicate: My::Script::Role::Frobnicate
    publish:
      - My::Script::Role::Publish
      - My::Script::Role::Packages

When C<frobnicate> is selected, only
C<My::Script::Role::Frobnicate> is composed into the application.

When C<publish> is selected, both C<My::Script::Role::Publish> and
C<My::Script::Role::Packages> are composed.

The selected role set must provide the command method corresponding to
the command name. Hyphens are converted to underscores when resolving
the method name, so:

  code-review

resolves to:

  cmd_code_review

The original C<commands:> form remains supported for backward
compatibility. Its values may be role class names or method names and
retain the pre-2.3.0 behavior described in
L</roles: vs commands:>.

=head2 C<roles:> vs C<commands:>

Version 2.3.0 introduces C<roles:> for selective role composition.
New applications should use C<roles:>. The original C<commands:>
manifest key remains supported for backward compatibility.

With C<commands:>, selecting a command causes all roles referenced
by the manifest's command definitions to be composed into the
application, regardless of which command is being executed.

This makes methods from every composed role available throughout
the application. However, it can also load modules that are not
needed by the selected command, increasing startup time.

For applications invoked repeatedly, such as utilities called from
C<make> recipes, this additional startup overhead can become
significant.

With C<roles:>, only the roles associated with the selected command
are composed. A command may require one role or several roles.

Selective composition reduces unnecessary dependencies and makes
the role requirements of each command explicit.

=head2 When to Use Each Approach

C<CLI::Simple> supports several approaches to organizing command-line
applications. The appropriate choice depends on the size of the
application and how its commands share functionality.

=over 4

=item * Single-module application

For small utilities with a limited number of commands, defining
command handlers in a single module is often the simplest approach.
Commands are registered directly through the C<commands> constructor
parameter.

No YAML manifest or role composition is required.

=item * Legacy C<commands:> manifest

Existing applications using a YAML manifest with C<commands:> retain
the original behavior of composing all command roles together.

This approach may be appropriate for applications whose commands
depend on methods supplied by other command roles. However, every
role class referenced by the manifest's command definitions is
composed regardless of which command is selected.

=item * Selective C<roles:> manifest

For new or growing applications, C<roles:> provides a more modular
approach. Each command declares the roles it requires, and only
those roles are composed when the command is selected.

This is particularly useful when commands have different
dependencies or when minimizing startup time is important.

=back

Applications can migrate from C<commands:> to C<roles:> incrementally,
provided each migrated command declares the roles it requires.

=head2 Sharing Methods Between Commands

With legacy C<commands:> manifests, all command roles are composed
into the application. Methods provided by one command role are
therefore available to other commands.

With selective C<roles:> composition, a command cannot assume that
roles associated with other commands have been composed.

Functionality shared by multiple commands can be placed in a
separate role and included in each command's role list:

  roles:
    publish:
      - My::Script::Role::Publish
      - My::Script::Role::Common
    deploy:
      - My::Script::Role::Deploy
      - My::Script::Role::Common

Alternatively, functionality required by every command can be
composed directly into the main application class using
L<Role::Tiny::With>.

Shared functionality can also be implemented in ordinary Perl
modules without using roles.

See L</Roles With No Commands> for an example of composing an
application-wide role.

=head2 Roles With No Commands

Some roles provide application-wide behavior rather than implementing
a command. For example, a role may provide an C<init()> method for
startup validation or other functionality required by every command.

Because these roles are not associated with a command beneath
C<roles:>, they must be composed explicitly into the main module:

  package My::Script;

  use CLI::Simple qw(:roles);
  use Role::Tiny::With;
  use parent qw(CLI::Simple);

  with 'My::Script::Role::Init';

  caller or exit __PACKAGE__->main;

  1;

Roles composed this way are always available to the application,
regardless of which command is selected.

=head2 Activating Role-Based Architecture

Add C<:roles> to your C<use CLI::Simple> statement:

  use CLI::Simple qw(:roles);

This causes C<CLI::Simple> to load the YAML manifest and retain its
command, role, option, alias, and abbreviation metadata for the
application.

Role composition does not occur while the manifest is being loaded.

When the application is started, C<CLI::Simple> first resolves the
selected command, including aliases and abbreviations. It then composes
the role or roles required by that command.

For commands declared beneath C<roles:>, only the associated role set
is composed.

For legacy commands declared beneath C<commands:>, the original
all-role composition behavior is retained for backward compatibility.

=head2 The Inherited main()

When using C<:roles>, your class inherits C<main()> from
C<CLI::Simple>:

  caller or exit __PACKAGE__->main;

The inherited C<main()> uses the manifest metadata to resolve the
requested command, composes the role or roles required for that
command, constructs the application object, and calls C<run()>.

Aliases and command abbreviations are resolved before selective role
composition, so they select the same role set as the canonical
command.

Override C<main()> in your subclass only if you need application
startup behavior that cannot be expressed through the manifest,
C<init()>, or explicitly composed application roles.

=head2 Distributing the Manifest

The YAML manifest is part of the application's runtime configuration
and must be installed with the distribution.

C<CPAN::Maker> users can add it to C<extra-files> in
F<buildspec.yml> so it is installed into the distribution's share
directory:

  extra-files:
    - share:
      - my-script.yml

During development the manifest is found via C<%INC>. After
installation it is found via L<File::ShareDir>. No code changes are
required between the two environments.

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

=item *

Optional role-based architecture via YAML manifest for larger applications

=back

The philosophy is: provide just enough infrastructure, then get out of your way.

=head2 Validation, Defaults, and Configuration

C<CLI::Simple> does not impose a validation model. You may:

=over 4

=item *

Use C<Getopt::Long> option specifications for argument types and
C<default_options> to supply default values

=item *

Write your own validation logic in C<init()>

=item *

Throw exceptions, emit usage, or exit early at any point

=back

The lifecycle is explicit and under your control. You decide how much structure
you want to add on top of it.

=head2 When to Use

C<CLI::Simple> is ideal for:

=over 4

=item * Internal tools and admin scripts

=item * Bootstrapped CLIs where you don't want a framework

=item * Users who want to subclass a clean, minimal interface

=item * Applications that have grown beyond a single module and benefit from
role-based command composition

=back

For interactive CLI handling or complex command trees, consider
L<App::Cmd> or L<CLI::Framework>.

=head2 The init-run Lifecycle

=over 4

=item * B<Phase 0: Manifest Loading>

For role-based applications using C<use CLI::Simple qw(:roles)>, the
YAML manifest is loaded during C<import> and its command, role, option,
alias, and abbreviation metadata is retained for the application.

Roles are not composed during manifest loading.

The selected command is resolved later, during application startup.
For commands declared beneath C<roles:>, only the role or roles
required by that command are composed. Legacy C<commands:> manifests
retain the original all-role composition behavior.

Single-module applications skip this phase entirely.

=item * B<Phase 1: Internal Commands>

Before anything else, C<CLI::Simple> checks C<@ARGV> for internal
commands prefixed with C<->. If one is found it executes immediately
and exits. See L</INTERNAL COMMANDS>.


=item * B<Phase 2: Initialization (C<new> => C<init>)>

The constructor parses command-line arguments via C<Getopt::Long>,
creates accessors for all options, and calls your C<init()> method.
Inside C<init()>, your application has full access to the parsed options 
and arguments. This phase is the ideal hook for all final setup tasks, 
such as:

=over 4

=item * Validating command-line arguments.

=item * Loading configuration files based on a C<--config> option.

=item * Dynamically overriding the command (e.g, C<$self-E<gt>command('new_default')>).

=item * Performing any setup required B<before> a command is run.

=back


=item * B<Phase 3: Execution (C<run>)>

Dispatches to the command method determined during initialization.

=back

=head2  Opt-in Default Command

By design, C<CLI::Simple> B<does not impose a default command>.
This provides total flexibility for the application author:

=over 4

=item * B<You Can Set a Default:> If your application needs a default
command, define a C<default> entry in the C<commands> hash passed to
the constructor, or set the command during C<init()> using C<command()>.
Alternatively, enable C<$AUTO_HELP> to display help when no command
is supplied.

=item * B<You Can Have No Default:> If you do B<not> set a default,
C<run()> will simply do nothing and return cleanly if no command
is provided on the command line.

=back

This "no default by default" behavior is what enables a powerful 
"setup-only" execution mode. A user can run your script I<without>
specifying a command. This will:

=over 4

=item 1. Run the entire C<new()> / C<init()> phase, performing all setup.

=item 2. Call C<run()>, which will find no command and exit cleanly.

=back

This provides an ideal hook for applications that need to perform
"on-demand initialization" (e.g., seeding a database, authenticating)
by checking for a specific flag inside C<init()>, without also
triggering an unwanted command.

In role-based applications using a YAML manifest, a C<default> command
that aliases another command should map to the sub name directly rather
than a role class:

  commands:
    default: cmd_install
    install: My::Module::Role::Installer

=head2 C<$AUTO_HELP> and C<$AUTO_DEFAULT>

The following package variables control automatic command selection,
help behavior, and output paging.

By default, the framework provides no default command as explained in
the sections above. Some scripters may want default behaviors that
assume a command or provide usage if no command is provided.

=over 4

=item C<$AUTO_HELP>

Set the package variable C<$AUTO_HELP> to a true value if you want
C<CLI::Simple> to provide help when no command is provided.

default: false

=item C<$AUTO_DEFAULT>

Set the package variable C<$AUTO_DEFAULT> to a true value if you want
C<CLI::Simple> to automatically select a command if you have only 1
command defined and no command is provided on the command line. When
true, it will prepend the single command name to the argument list,
allowing any subsequent arguments to be correctly parsed as args for
that command.

default: false

=item C<$PAGER>

Set the package variable C<$PAGER> to a true value to route help
output through L<IO::Pager> when C<--help> is invoked. When enabled,
C<IO::Pager> selects an appropriate pager (C<less>, C<more>, etc.)
based on the C<PAGER> environment variable, falling back to a sensible
default. Set to false to suppress pager use and write help directly to
STDOUT.

  use CLI::Simple qw($PAGER);
  $PAGER = 0;  # disable pager

default: true

Note: L<IO::Pager> must be installed for pager support. If it is not
available, help output is written directly to STDOUT regardless of the
value of C<$PAGER>.

=back

=head1 CONSTANTS

C<CLI::Simple::Constants> provides a collection of exportable constants
commonly used in command-line applications.

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

=head1 ADDING USAGE TO YOUR SCRIPTS

To provide built-in usage/help output, include a C<=head1 SYNOPSIS>
section in your script's POD:

  =head1 SYNOPSIS

  ```
  usage: myscript [options] command args

  Options
  -------
  --help, -h      Display help
  ...
  ```

If the user supplies the command C<help>, or the C<--help> option,
C<CLI::Simple> displays the configured help sections using
L<Pod::Usage>.

For backward compatibility, C<USAGE> is also supported. If a C<USAGE>
section is present, it is used as the usage section.

If no C<USAGE> section is present, C<SYNOPSIS> is used instead.

When both C<SYNOPSIS> and C<USAGE> are present, C<USAGE> is used by
default. Applications that explicitly configure C<help_sections> may
select the desired section.

=head2 Customizing Help Output

=head3 Custom help() Method

If you need full control over the help output, you can define a custom
C<help> method and assign it as a command:

  commands => {
    help => &help,
    ...
  };

This is useful if your module follows the modulino pattern and you want
to present help information that differs from the embedded POD.

=head3 C<help_sections>

By default C<CLI::Simple> renders the following POD sections when
present, subject to the usage section selection described above:

  SYNOPSIS
  DESCRIPTION/Commands
  DESCRIPTION/Options
  OPTIONS

You can override the default selection by passing an array reference of
section names during construction:

  my $cli = CLI::Simple->new(
    help_sections => [qw(SYNOPSIS COMMANDS OPTIONS)],
    ...
  );

When C<help_sections> is supplied explicitly, C<CLI::Simple> honors the
list exactly as provided. For example, an application may request both
C<SYNOPSIS> and C<USAGE>:

  help_sections => [qw(SYNOPSIS USAGE)]

Section names follow L<Pod::Usage> conventions. Subsections are
specified with a C</> separator; for example,
C<DESCRIPTION/Commands> renders only the C<Commands> subsection under
C<DESCRIPTION>.

=head1 INTERNAL COMMANDS

C<CLI::Simple> reserves command names beginning with C<-> for its own
use. These commands are intercepted before option parsing begins and
execute immediately, bypassing the normal lifecycle entirely. See
L</The init-run Lifecycle>.

Internal commands are dispatched via the C<%INTERNAL_COMMANDS> package
variable:

  our %INTERNAL_COMMANDS = (
    '-generate-completion' => \&_cmd_generate_completion,
    '-dump-spec'           => \&_cmd_dump_spec,
    '-scaffold'            => \&_cmd_scaffold,
    '-migrate'             => \&_cmd_migrate,
  );

Subclasses can add their own internal commands by extending the hash
before C<new()> is called:

  our %INTERNAL_COMMANDS = (
    %CLI::Simple::INTERNAL_COMMANDS,
    '-my-command' => \&_cmd_my_command,
  );

=head2 -generate-completion

Generates a bash completion script for the script's commands and
options, derived from the live object state. Bash completions are a
feature that allows the shell to automatically finish commands, file
paths, and options when you press the Tab key.

  my-script -generate-completion > \
    ~/.local/share/bash-completion/completions/my-script

After generating the bash completion script, source it in your current
shell to test:

  source ~/.local/share/bash-completion/completions/my-script

Test by typing your script name followed by a space and pressing Tab.
You should see the available commands. To verify option completion,
type your script name followed by a space and C<--> and press Tab.

To make completions permanent, most systems automatically source files
placed in C<~/.local/share/bash-completion/completions/> when
C<bash-completion> 2.x is installed. If your system does not pick
them up automatically, add the following to your C<~/.bashrc>:

  source ~/.local/share/bash-completion/completions/my-script

Alternatively, place the generated file in the system-wide completion
directory (requires root):

  my-script -generate-completion > \
    /etc/bash_completion.d/my-script

The script name is taken from the first argument if provided, then
C<MODULINO_WRAPPER> if set, then inferred from the module name. If the
inferred name cannot be found in C<PATH>, a warning is issued but the
completion script is still generated.

I<Note: If you created the modulino with the supplied
C<create-modulino> tool C<MODULINO_WRAPPER> is already set inside the
bash script that invokes the modulino.>

=over 4

=item Case 1: Your modulino wrapper and module name are aligned 

The modulino script C<my-modulino> refers to My::Modulino

  my-modulino -generate-completion

=item Case 2: Your modulino wrapper was created using C<create-modulino>

The modulino script C<my-alias> refers to My::Modulino. Although the wrapper name differs from the module name,
C<MODULINO_WRAPPER> is set by the generated bash wrapper.

 my-alias -generate-completion

=item Case 3: Your modulino is an alias not created by C<create-modulino>

Without C<MODULINO_WRAPPER>, the generated completion script may
use the path to the Perl module rather than the wrapper's command
name. The C<-generate-completion> script called by 
your custom wrapper most likely only resolves the program name as the path to
your Perl module:

 path-to-modules/My/Module.pm

...in this case you need to supply the alias name or set
C<MODULINO_WRAPPER> in the environment.

 my-alias -generate-completion my-alias

=back

=head2 -dump-spec

Introspects the running modulino and writes a YAML manifest to the
current directory. The filename is derived from the module name by
convention.

  my-script -dump-spec           # sub names - baby step toward roles
  my-script -dump-spec roles     # role class names - full commitment

Without the C<roles> argument, commands map to their existing sub
names so the manifest can be used immediately without moving any
code. With C<roles>, commands map to derived role class names suitable
for use with C<-scaffold>.

Alias commands - those whose coderef resolves to a sub name that does
not match the command key - are always written as sub names regardless
of mode.

=head2 -scaffold

Generates a role-based project tarball from the running modulino or
from an explicit spec file.

The C<-scaffold> command can take a monolithic application or a YAML
file like the one above and create the project hierarchy for a role
based application. The command will create a tarball that contains
role stubs, a slimmed main module with extracted POD (if your monolith
contained any), a C<project.mk> with inter-module dependencies, and
the YAML manifest.

If you've turned your monolith's package into a modulino:

  my-script -scaffold                        # introspect live module

...or use C<cli-simple> if you have a .yml file.

  cli-simple -scaffold my-script.yml         # scaffold from spec file

The tarball will be named C<my-script-roles.tar.gz> by convention (the
lower case snake cased version of the class name). The name is used to
infer the class name. If your filename is different than the
classes you want to scaffold, you will need to edit the files. 

Extract the content to a directory and start editing. If you feed the tarball
to L<CPAN::Maker::Bootstrapper> via the C<import-scaffold> command you can
produce a complete buildable CPAN distribution.

=head2 -migrate

Combines C<-dump-spec roles> and C<-scaffold> in a single step.

  my-script -migrate

Writes the YAML manifest then generates the role-based tarball. Use
this when you are ready for a full migration and do not need to inspect
or edit the manifest first. If you want to review or adjust the
manifest before scaffolding, run C<-dump-spec> and C<-scaffold>
separately.

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

If no default is provided, the behavior is controlled by the
C<$AUTO_DEFAULT> and C<$AUTO_HELP> package variables.

Setting C<$AUTO_DEFAULT> to true when your C<commands> hash
contains only a single command, will cause that command to be run
automatically when no command name is given on the command line. This
allows you to treat the program like a single-command tool, where
arguments can be passed directly without explicitly naming the
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

=item * validate_command

By default, C<CLI::Simple> validates the selected command against the
registered commands. Set C<validate_command> to a false value to
disable this validation.

Typically you might use this to allow a script to assume a default
command and allow arguments. For example suppose you have a script
C<foo> with a command "get" with arguments:

  foo get something

...but want to allow users to also do:

  foo something

To do this you should follow this recipe:

  sub init {
    my ($self) = @_;

    my @args = $self->get_args;

    if ( ! @args ) {
      $self->command_args($self->command()); # set the args to the command
      $self->command('get'); # set the command to your default
    }
    else {
      die "ERROR: unknown command\n"
        if !$self->commands->{$self->command}; # validate the command
    }
    ...
    return;
  }

I<NOTE: This only works if your commands have a deterministic number
of arguments. For example you might always require at least 1
argument. If you have no arguments as in the above recipe you would
assume command is the argument to your default command.>

=back

=head2 command

 command
 command(command)

Gets or sets the command to execute. Usually this is the first argument
on the command line after all options have been parsed. There are
times when you might want to override the argument. You can pass a new
command that will be executed when you call the C<run()> method.

=head2 command_args

 my $args = $self->command_args();

Gets or sets the argument list. Similar to C<get_args> when no
arguments are passed except it returns an array reference.

To replace or add to the argument list, pass an array or list.

  my $args = $self->command_args;
  $self->command_args(@{$args}, 'foo');

=head2 commands

 commands
 commands(command, handler)

Returns the command dispatch hash supplied to the constructor.
When called with a command name and handler, adds the command
to the dispatch hash. C<handler> must be a code reference.

 commands(foo => sub { return 'foo' });

=head2 main

  __PACKAGE__->main;

For role-based applications, C<main> is inherited from C<CLI::Simple>
and reads the YAML manifest loaded during C<import>. It constructs the
object with the manifest's options, default options, extra options, and
dispatch table, then calls C<run()>.

In a role-based modulino, the entire C<main> sub reduces to:

  caller or exit __PACKAGE__->main;

For single-module applications, override C<main> in your subclass as
usual.

=head2 run

Executes the selected command using the parsed options and arguments.
The C<run> method dispatches control to the corresponding command
subroutine.

Command subroutines should return C<0> for success and a non-zero
value for failure. The return value is used as the script's exit
status.

=head2 get_args

Return the arguments that follow the command.

  get_args(NAME, ... )     # with names
  get_args()               # raw positional args

=head3 With names

=over 4

=item In scalar context, returns a hash reference mapping each NAME to
the corresponding positional argument.

=item In list context, returns a flat list of C<(name => value)> pairs.

=back

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

  my %args = $self->get_args('message', undef, 'cc');  # skip argument 2

If there are fewer positional arguments than names, the remaining names
are set to C<undef>. Extra positional arguments (beyond the provided
names) are ignored.

=head3 With no names

=over 4

=item In scalar context returns an array reference containing the
command's positional arguments.

=item In list context returns a list containing the command's
positional arguments.

=back

=head2 init

If defined, C<init()> is invoked during application initialization,
after command-line options and arguments have been processed and
before command dispatch. Use this method to perform application-specific
initialization and validation.

=head1 USING PACKAGE VARIABLES

Constructor arguments may also be defined using package variables.
This provides a declarative alternative to passing configuration
directly to C<new()>.

Package variable names correspond to constructor argument names,
converted to uppercase.

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

Option values are accessible through automatically generated getter
methods:

  $cli->get_foo();
  $cli->get_log_level();

Option names that contain dashes (C<->) are automatically converted to
snake_case for the accessor methods. For example:

  option_specs => [ 'foo-bar=s' ]

...results in:

  $cli->get_foo_bar();

=head2 Getopt::Long Configuration

C<CLI::Simple> uses L<Getopt::Long> to parse command-line options,
with the C<no_ignore_case> configuration enabled.

Consequently:

=over 4

=item * Option names are case-sensitive.

=item * Automatic option abbreviation is enabled. An option name
may be abbreviated to any unambiguous prefix.

=item * Multiple option names may be declared using Getopt::Long's
C<|> syntax, such as C<config|c=s>.

=item * When multiple spellings of the same option are supplied,
the last occurrence determines its value.

=back

All other Getopt::Long configuration settings retain their defaults.

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
=head2 set_args

Resets the positional arguments.

 $self->set_args(qw(foo 1));

This method overrides the positional arguments originally passed to
the script. You can achieve the same behavior by calling the
C<get_args> in scalar context and modifying the reference.

 my $args = $self->get_args;
 $args->[1] = '2';

Use this technique when you want to modify individual arguments
without replacing the entire argument list.

=head1 CUSTOM ERROR HANDLER

By default, C<CLI::Simple> exits if C<Getopt::Long::GetOptions>
returns a false value, indicating an error while parsing options.

=over 4

=item * Set C<$CLI::Simple::GETOPT_EXIT_ON_ERROR> to a false value.

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

=head1 ADDING ADDITIONAL ACCESSORS

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

C<CLI::Simple> provides convenient initialization of L<Log::Log4perl>
through C<use_log4perl()>.

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

I<Note: Because it is opt-in, C<CLI::Simple> does not itself depend on
L<Log::Log4perl>. B<If your application calls C<use_log4perl>, it owns that
dependency> and must declare it in its own C<requires>/C<cpanfile>. Static
dependency scanners cannot see it -- the module is loaded dynamically
inside the method call -- so you must add it by hand.>

=head2 Colored Output

Pass C<color =E<gt> 1> to C<use_log4perl()> to default your script to
colorized log output using a built-in appender, instead of supplying
your own C<config>:

  __PACKAGE__->use_log4perl(
    level => 'info',
    color => 1,
  );

Colorizing requires L<Term::ANSIColor>. If it isn't installed,
C<CLI::Simple> quietly falls back to uncolored output rather than
failing - C<color =E<gt> 1> is a request, not a hard dependency.

If you'd like the person running your script to be able to override
that default from the command line, add C<color!> to your
C<option_specs>:

  my @option_specs = qw(
    color!
    ...
  );

This gives you C<--color> and C<--no-color> for free. Whichever way
C<use_log4perl()> set the default, an explicit flag on the command
line always wins; if neither C<--color> nor C<--no-color> is passed,
your C<use_log4perl()> setting is left alone. Declaring C<color!> is
therefore safe to add at any time - it only changes behavior for
scripts whose users actually pass the flag.

I<Note: C<color> and C<config> are mutually exclusive -
C<use_log4perl()> dies if you pass both. C<color> is specifically for
using C<CLI::Simple>'s own built-in colorized appender; if you need a
custom config, write it to include coloring yourself rather than
passing C<color =E<gt> 1>.>

=head2 Per Command Log Levels

Some commands may require more verbose logging than others. For
example, certain commands might perform complex actions that benefit
from detailed logs, while others are designed solely to produce clean,
structured output.

To assign a custom log level to a command, use an array reference as
the value for that command in the commands hash passed to the
constructor.

The first two elements of the array reference are:

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

I<Note: Per-command log levels are not currently supported in the YAML
manifest. Define them programmatically by overriding C<main()> if needed.>

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

No. If your script performs a single operation, you can register
a default command:

  commands => { default => \&main }

=item * Must I subclass C<CLI::Simple>?

No. You can instantiate C<CLI::Simple> directly and supply the
C<commands> and other configuration through the constructor.
Subclassing is useful when you want to provide application-specific
methods such as C<init()>.

=item * How do I turn my class into a script?

Use the modulino pattern: create a class that checks whether it is
being invoked directly:

  package MyScript;

  caller or exit __PACKAGE__->main();

  sub main {
    ...
  }

This lets the file be used as both a module and an executable script.

=item * How do I migrate an existing script to role-based architecture?

Run the built-in C<-dump-spec> command to generate a YAML manifest from
your existing script, then C<-scaffold> to generate role stubs:

  my-script -dump-spec        # generates my-script.yml
  my-script -scaffold         # generates my-script-roles.tar.gz

See L</ROLE-BASED ARCHITECTURE> for the full migration workflow.

=item * How do I start a new role-based project from scratch?

Write a YAML manifest and use the C<cli-simple> wrapper to scaffold it:

  cli-simple -scaffold my-script.yml

See L</ROLE-BASED ARCHITECTURE> for the manifest format.

=item * How do I enable bash completion for my script?

Your script must be invoked via a bash modulino wrapper with
C<MODULINO_WRAPPER> set. Then run:

  my-script -generate-completion > \
    ~/.local/share/bash-completion/completions/my-script

Wrappers generated by L<CPAN::Maker::Bootstrapper> set
C<MODULINO_WRAPPER> automatically.

=item * How do I add my own internal commands?

Add entries to C<%INTERNAL_COMMANDS> before calling C<new()>:

  our %INTERNAL_COMMANDS = (
    %CLI::Simple::INTERNAL_COMMANDS,
    '-my-command' => \&_cmd_my_command,
  );


=item * My application dies with "use_log4perl() requires Log::Log4perl..."

Since not all scripts require logging, C<Log::Log4perl> is an
I<optional dependency> of C<CLI::Simple>.  If your application calls
C<use_log4perl()>, C<Log::Log4perl> must be installed.

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

=item * Accessors are created for both names

Accessors are generated from all option names (canonical and aliases),
with '-' normalized to '_'. In the example, both C<get_config()> and
C<get_cfg()> are available.

=item * Values are mirrored after parsing

After option parsing and normalization, values are mirrored so either
name can be used consistently.

When both the canonical option and an alias are supplied the canonical
name wins.

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
from C<--config> (the canonical version) is used.

I<Note: In role-based applications using a YAML manifest, command
aliases are expressed by mapping the alias command directly to the
target sub name rather than a role class. See L</ROLE-BASED ARCHITECTURE>.>

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

The C<run()> method dispatches the selected command and returns its
exit status. Command handlers should return C<0> for success or a
non-zero value to indicate failure.

  exit CLI::Simple->new(commands => { foo => \&cmd_foo })->run();

=head2 Exit Codes

C<CLI::Simple> uses conventional exit codes so that calling scripts
can distinguish between normal completion and error conditions.

=over 4

=item * '0'

Successful completion of a command (C<SUCCESS>).

=item * '1'

General usage error, C<--help> display via C<pod2usage>, an
invalid command line (C<FAILURE>) or option parsing errors.

=item * Any other code

A command handler may return an application-specific numeric exit
code, which C<run()> passes through to the caller. A handler that
calls C<exit()> terminates the process directly.

=back

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
L<https://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Getopt::Long>, L<CLI::Simple::Constants>, L<CLI::Simple::Utils>,
L<Pod::Usage>, L<App::Cmd>, L<CLI::Framework>, L<Role::Tiny>,
L<CPAN::Maker::Bootstrapper>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut

