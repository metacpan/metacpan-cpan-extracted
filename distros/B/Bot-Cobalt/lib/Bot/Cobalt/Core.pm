package Bot::Cobalt::Core;
$Bot::Cobalt::Core::VERSION = '0.021003';
## This is the core Syndicator singleton.

use strictures 2;

use v5.10;
use Carp;

use POE;

use Bot::Cobalt::Common;
use Bot::Cobalt::IRC;
use Bot::Cobalt::Lang;
use Bot::Cobalt::Logger;

use Bot::Cobalt::Core::ContextMeta::Auth;
use Bot::Cobalt::Core::ContextMeta::Ignore;
use Bot::Cobalt::Core::Loader;

use Scalar::Util 'blessed';
use Try::Tiny;

use Path::Tiny;
use Types::Path::Tiny -types;

use Moo;

has cfg => (
  required  => 1,
  is        => 'rw',
  isa       => InstanceOf['Bot::Cobalt::Conf'],
);

has var => (
  required  => 1,
  is        => 'ro',
  isa       => Path,
  coerce    => 1,
);

has etc => (
  lazy      => 1,
  is        => 'ro',
  isa       => Path,
  coerce    => 1,
  builder   => sub { shift->cfg->etc },
);

has log => (
  lazy      => 1,
  is        => 'rw',
  isa       => HasMethods[qw/debug info warn error/],
  builder   => sub {
    my ($self) = @_;
    my %opts = (
      level => $self->loglevel,
    );
    if (my $log_format = $self->cfg->core->opts->{LogFormat}) {
      $opts{log_format} = $log_format
    }
    if (my $log_time_fmt = $self->cfg->core->opts->{LogTimeFormat}) {
      $opts{time_format} = $log_time_fmt
    }
    Bot::Cobalt::Logger->new( %opts )
  },
);

has loglevel => (
  is        => 'rw',
  isa       => Str,
  builder   => sub { 'info' },
);

has detached => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { 0 },
);

has debug => (
  lazy      => 1,
  isa       => Int,
  is        => 'rw',
  builder   => sub { 0 },
);

## version/url used for var replacement:
has version => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Str,
  builder   => sub { __PACKAGE__->VERSION // 'vcs' }
);

has url => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Str,
  builder   => sub { "http://www.metacpan.org/release/Bot-Cobalt" },
);

has langset => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['Bot::Cobalt::Lang'],
  writer    => 'set_langset',
  builder   => sub {
    my ($self) = @_;
    Bot::Cobalt::Lang->new(
      use_core => 1,
      lang_dir => path( $self->etc .'/langs' ),
      lang     => $self->cfg->core->language,
    )
  },
);

has lang => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  writer    => 'set_lang',
  builder   => sub {
    my ($self) = @_;
    $self->langset->rpls
  },
);

has State => (
  lazy      => 1,
  ## global 'heap' of sorts
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub {
    {
      HEAP => { },
      StartedTS => time(),
      Counters  => {
        Sent => 0,
      },

      # nonreloadable plugin list keyed on alias for plugin mgrs:
      NonReloadable => { },
    }
  },
);

has PluginObjects => (
  lazy      => 1,
  ## alias -> object mapping
  is        => 'rw',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub { {} },
);

has Provided => (
  lazy      => 1,
  ## Some plugins provide optional functionality.
  ## This hash lets other plugins see if an event is available.
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub { {} },
);

has auth => (
  lazy      => 1,
  is        => 'rw',
  isa       => Object,
  builder   => sub {
    Bot::Cobalt::Core::ContextMeta::Auth->new
  },
);

has ignore => (
  lazy      => 1,
  is        => 'rw',
  isa       => Object,
  builder   => sub {
    Bot::Cobalt::Core::ContextMeta::Ignore->new
  },
);

## FIXME not documented
has resolver => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Object,
  builder   => sub {
    POE::Component::Client::DNS->spawn(
      Alias => 'core_resolver',
    )
  },
);


extends 'POE::Component::Syndicator';
with 'Bot::Cobalt::Core::Role::Singleton';
with 'Bot::Cobalt::Core::Role::EasyAccessors';
with 'Bot::Cobalt::Core::Role::Timers';
with 'Bot::Cobalt::Core::Role::IRC';


## FIXME test needed:
sub rpl  {
  my ($self, $rpl) = splice @_, 0, 2;

  confess "rpl() method requires a RPL tag"
    unless defined $rpl;

  my $string = $self->lang->{$rpl}
    // return "Unknown RPL $rpl, vars: ".join(' ', @_);

  rplprintf( $string, @_ )
}

sub init {
  my ($self) = @_;

  my $logfile  = $self->cfg->core->paths->{Logfile}
                // path( $self->var .'/cobalt.log' );

  if ($self->detached) {
    # Presumably our frontend closed these
    open STDOUT, '>>', $logfile or die $!;
    open STDERR, '>>', $logfile or die $!;
  } else {
    $self->log->output->add(
      'screen' => {
        type => 'Term',
      },
    );
  }

  $self->log->output->add(
    'logfile' => {
       type => 'File',
       file => $logfile,
     },
  );

  ## Language set check. Force attrib fill.
  $self->lang;

  $self->_syndicator_init(
    prefix => 'ev_',  ## event prefix for sessions
    reg_prefix => 'Cobalt_',
    types => [ SERVER => 'Bot', USER => 'Outgoing' ],
    options => { },
    object_states => [
      $self => [
        'syndicator_started',
        'syndicator_stopped',

        'shutdown',
        'sighup',

        'ev_plugin_error',

        'core_timer_check_pool',
      ],
    ],
  );

}

sub syndicator_started {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $kernel->sig(INT  => 'shutdown');
  $kernel->sig(TERM => 'shutdown');
  $kernel->sig(HUP  => 'sighup');

  $self->log->info(__PACKAGE__.' '.$self->version);

  $self->log->info("--> Initializing plugins . . .");

  my $i;
  my @plugins = sort {
    $self->cfg->plugins->plugin($b)->priority
    <=>
    $self->cfg->plugins->plugin($a)->priority
  } @{ $self->cfg->plugins->list_plugins };

  PLUGIN: for my $plugin (@plugins) {
    my $this_plug_cf = $self->cfg->plugins->plugin($plugin);
    my $module = $this_plug_cf->module;

    unless ( $this_plug_cf->autoload ) {
      $self->log->debug("Skipping $plugin - NoAutoLoad is true");
      next PLUGIN
    }

    my $obj;
    try {
      $obj = Bot::Cobalt::Core::Loader->load($module);
      unless ( Bot::Cobalt::Core::Loader->is_reloadable($obj) ) {
        $self->State->{NonReloadable}->{$plugin} = 1;
        $self->log->debug("$plugin marked non-reloadable");
      }
    } catch {
      $self->log->error("Load failure; $_");
      next PLUGIN
    };

    ## save stringified object -> plugin mapping before we plugin_add
    $self->PluginObjects->{$obj} = $plugin;

    unless ( $self->plugin_add($plugin, $obj) ) {
      $self->log->error("plugin_add failure for $plugin");
      delete $self->PluginObjects->{$obj};
      Bot::Cobalt::Core::Loader->unload($module);
      next PLUGIN
    }

    ++$i;
  }

  $self->log->info("-> $i plugins loaded");

  $self->send_event('plugins_initialized', $_[ARG0]);

  $self->log->info("-> started, plugins_initialized sent");

  ## kickstart timer pool
  $kernel->yield('core_timer_check_pool');
}

sub sighup {
  my $self = $_[OBJECT];
  $self->log->warn("SIGHUP received");

  if ($self->detached) {
    ## Caught by Plugin::Rehash if present
    ## Not documented because you should be using the IRC interface
    ## (...and if the bot was run with --nodetach it will die, below)
    $self->log->info("sending Bot_rehash (SIGHUP)");
    $self->send_event( 'Bot_rehash' );
  } else {
    ## we were (we think) attached to a terminal and it's (we think) gone
    ## shut down soon as we can:
    $self->log->warn("Lost terminal; shutting down");

    $_[KERNEL]->yield('shutdown');
  }

  $_[KERNEL]->sig_handled();
}

sub shutdown {
  my $self = ref $_[0] eq __PACKAGE__ ? $_[0] : $_[OBJECT];

  $self->log->warn("Shutdown called, destroying syndicator");

  $self->_syndicator_destroy();
}

sub syndicator_stopped {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $kernel->alarm('core_timer_check_pool');

  $self->log->debug("issuing: POCOIRC_SHUTDOWN, shutdown");

  $kernel->signal( $kernel, 'POCOIRC_SHUTDOWN' );
  $kernel->post( $kernel, 'shutdown' );

  $self->log->warn("Core syndicator stopped.");
}

sub ev_plugin_error {
  my ($kernel, $self, $err) = @_[KERNEL, OBJECT, ARG0];

  ## Receives the same error as 'debug => 1' (in Syndicator init)

  $self->log->error("Plugin err: $err");

  ## Bot_plugin_error
  $self->send_event( 'plugin_error', $err );
}

### Core low-pri timer

sub core_timer_check_pool {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  ## Timers are provided by Core::Role::Timers

  my $timerpool = $self->TimerPool;

  TIMER: for my $id (keys %$timerpool) {
    my $timer = $timerpool->{$id};

    unless (blessed $timer && $timer->isa('Bot::Cobalt::Timer') ) {
      ## someone's been naughty
      $self->log->warn("not a Bot::Cobalt::Timer: $id");
      delete $timerpool->{$id};
      next TIMER
    }

    if ( $timer->execute_if_ready ) {
      my $event = $timer->event;

      $self->log->debug("timer execute; $id ($event)")
        if $self->debug > 1;

      $self->send_event( 'executed_timer', $id );
      $self->timer_del($id);
    }

  } ## TIMER

  ## most definitely not a high-precision timer.
  ## checked every second or so
  $kernel->alarm('core_timer_check_pool' => time + 1);
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core - Bot::Cobalt core and event syndicator

=head1 DESCRIPTION

This module is the core of L<Bot::Cobalt>, tying an event syndicator
(via L<POE::Component::Syndicator> and L<Object::Pluggable>) into a
logger instance, configuration manager, and other useful tools.

Core is a singleton; within a running Cobalt instance, you can always
retrieve the Core via the B<instance> method:

  require Bot::Cobalt::Core;
  my $core = Bot::Cobalt::Core->instance;

You can also query to find out if Core has been properly instanced:

  if ( Bot::Cobalt::Core->has_instance ) {

  }

If you 'use Bot::Cobalt;' you can also access the Core singleton
instance via the C<core()> exported sugar:

  use Bot::Cobalt;
  core->log->info("I'm here now!")

See L<Bot::Cobalt::Core::Sugar> for details.

Public methods are documented in L<Bot::Cobalt::Manual::Plugins/"Core
methods"> and the classes & roles listed below.

See also:

=over

=item *

L<Bot::Cobalt::Manual::Plugins> - Cobalt plugin authoring manual

=item *

L<Bot::Cobalt::IRC> - IRC bridge / events

=item *

L<Bot::Cobalt::Core::Role::EasyAccessors>

=item *

L<Bot::Cobalt::Core::Role::IRC>

=item *

L<Bot::Cobalt::Core::Role::Timers>

=back

=head1 Custom frontends

It's trivially possible to write custom frontends to spawn a Cobalt
instance; Bot::Cobalt::Core just needs to be initialized with a valid
configuration object and spawned via L<POE::Kernel>'s run() method.

A configuration object is an instanced L<Bot::Cobalt::Conf>:

  my $conf_obj = Bot::Cobalt::Conf->new(
    etc => $path_to_etc_dir,
  );

Which is passed to Bot::Cobalt::Core before the POE kernel is started:

  ## Instance a Bot::Cobalt::Core singleton
  ## Further instance() calls will return the singleton
  my $core = Bot::Cobalt::Core->instance(
    cfg => $conf_obj,
    var => $path_to_var_dir,

    ## See perldoc Bot::Cobalt::Logger regarding log levels:
    loglevel => $loglevel,

    ## Debug levels:
    debug => $debug,

    ## Indicate whether or not we're a daemon
    ## (Changes behavior of logging and signals)
    detached => $detached,
  )->init;
  
  POE::Kernel->run;

Frontends have to worry about daemonization on their own.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
