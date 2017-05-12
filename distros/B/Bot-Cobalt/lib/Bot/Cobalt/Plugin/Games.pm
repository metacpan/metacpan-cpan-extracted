package Bot::Cobalt::Plugin::Games;
$Bot::Cobalt::Plugin::Games::VERSION = '0.021003';
use strictures 2;

use List::Objects::WithUtils;

use Bot::Cobalt;
use Bot::Cobalt::Core::Loader;

use Object::Pluggable::Constants ':ALL';

sub MODULES () { 0 }
sub CMDS    () { 1 }
sub OBJS    () { 2 }


sub new { 
  bless [
    [],     # MODULES
    +{},    # CMDS
    +{},    # OBJS
  ], shift
}

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  my $count = $self->_load_games();
  $core->log->info("Loaded - $count games");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  $core->log->debug("Cleaning up our games...");
  for my $module (@{ $self->[MODULES] }) {
    Bot::Cobalt::Core::Loader->unload($module);
  }
  $core->log->info("Unloaded");

  PLUGIN_EAT_NONE
}

sub _handle_auto {
  ## Handler for autoviv'd methods. See _load_games
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };

  my $context = $msg->context;

  my $cmd = $msg->cmd;

  my $game = $self->[CMDS]->{$cmd} // return PLUGIN_EAT_NONE;
  my $obj  = $self->[OBJS]->{$game};

  my $msgarr = $msg->message_array;
  my $str = join ' ', @$msgarr;

  my $resp = '';
  $resp = $obj->execute($msg, $str) if $obj->can('execute');

  broadcast( message =>
    $context,
    $msg->target,
    $resp
  ) if $resp;

  PLUGIN_EAT_NONE
}

sub _load_games {
  my ($self) = @_;

  my $pcfg  = core->get_plugin_cfg( $self );
  my $games = $pcfg->{Games} // {};

  logger->debug("Loading games");

  my $count = 0;
  for my $game (keys %$games) {
    my $module = $games->{$game}->{Module} // next;
    next unless ref $games->{$game}->{Cmds} eq 'ARRAY';

    ## attempt to load module
    ## FIXME convert to Loader.pm interface
    {
      local $@;
      eval "require $module";
      if ($@) {
        logger->warn("Failed to load $module - $@");
        next
      } else {
        logger->debug("Found: $module");
      }
    }

    push @{ $self->[MODULES] }, $module;

    my $obj = $self->[OBJS]->{$game} = $module->new;

    for my $cmd (@{ $games->{$game}->{Cmds} }) {
      $self->[CMDS]->{$cmd} = $game;
      ## install a cmd handler and register for it
      my $handler = sub { $_[0]->_handle_auto(@_[1 .. $#_]) };
      { no strict 'refs';
        *{ __PACKAGE__.'::Bot_public_cmd_'.$cmd } = $handler;
      }

      register( $self, SERVER => [ 'public_cmd_'.$cmd ] );
    }

    ++$count;
    logger->debug("Game loaded: $game");
  }

  $count
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Games - Some silly IRC games

=head1 SYNOPSIS

  !roll 2d6    -- Dice roller
  !rps <throw> -- Rock, paper, scissors
  !magic8      -- Ask the Magic 8-ball
  !rr          -- Russian Roulette

=head1 DESCRIPTION

B<Games.pm> interfaces a handful of silly games, mapped to commands
in a configuration file (usually C<etc/plugins/games.conf>).

=head1 WRITING GAMES

On the backend, commands specified in our config are mapped to
modules that are automatically loaded when this plugin is.

When the specified command is handled, the game module's B<execute>
method is called and passed the original message hash (as specified
in L<Bot::Cobalt::IRC/Bot_public_msg>) and the stripped string without
the command:

  use Bot::Cobalt;
  sub execute {
    my ($self, $msg, $str) = @_;

    my $src_nick = $msg->src_nick;

    . . .

    ## We can return a response to the channel:
    return $some_response;

    ## ...or send a message and return nothing:
    broadcast( 'message',
      $msg->context,
      $msg->channel,
      $some_response
    );
    return
  }

For more complicated games, you may want to write a stand-alone plugin.

See L<Bot::Cobalt::Manual::Plugins>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

B<Roulette.pm> provided by B<Schroedingers_hat> @ irc.cobaltirc.org

=cut
