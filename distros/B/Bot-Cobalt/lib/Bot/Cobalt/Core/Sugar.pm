package Bot::Cobalt::Core::Sugar;
$Bot::Cobalt::Core::Sugar::VERSION = '0.021003';
use strictures 2;
use Carp;

use parent 'Exporter::Tiny';

our @EXPORT = qw/
  core
  broadcast
  logger
  register
  unregister
  plugin_cfg
  plugin_alias
  irc_object
  irc_context
/;

sub core {
  require Bot::Cobalt::Core;
  confess "core sugar called but no Bot::Cobalt::Core instance"
    unless Bot::Cobalt::Core->has_instance;
  Bot::Cobalt::Core->instance
}

sub broadcast (@) { core->send_event(@_) }

sub logger { core->log }

sub register (@) { core->plugin_register( @_ ) }

sub unregister (@) { core->plugin_register( @_ ) }

sub plugin_cfg ($) { core->get_plugin_cfg( @_ ) }

sub plugin_alias ($) { core->get_plugin_alias( @_ ) }

sub irc_object ($) { core->get_irc_object( @_ ) }

sub irc_context ($) { core->get_irc_context( @_ ) }

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core::Sugar - Exported sugar for Bot::Cobalt plugins

=head1 SYNOPSIS

  use Bot::Cobalt;

  ## Call core methods . . .
  my $u_lev = core->auth->level($context, $nickname);
  my $p_cfg = core->get_plugin_cfg($self);  
  
  # Call plugin_register
  register $self, 'SERVER', qw/ public_msg /;
  
  ## Call send_event
  broadcast 'message', $context, $channel, $string;
  
  ## Call core->log
  logger->warn("A warning");

=head1 DESCRIPTION

This module provides the sugar imported when you 'use Bot::Cobalt';
these are simple functions that wrap L<Bot::Cobalt::Core> methods.

=head2 core

Returns the L<Bot::Cobalt::Core> singleton for the running instance.

Same as calling:

  require Bot::Cobalt::Core;
  my $core = Bot::Cobalt::Core->instance;

=head2 broadcast

Queue an event to send to the plugin pipeline.

  broadcast $event, @args;

Wraps the B<send_event> method available via L<Bot::Cobalt::Core>, which 
is a L<POE::Component::Syndicator>.

=head2 irc_context

  my $context_obj = irc_context($context);

Retrieves the L<Bot::Cobalt::IRC::Server> object for the specified 
context.

Wrapper for core->get_irc_context() -- see 
L<Bot::Cobalt::Core::Role::IRC>

=head2 irc_object

  my $irc_obj = irc_object($context);

Retrieves the IRC object assigned to a context, which is a 
L<POE::Component::IRC::State> instance unless L<Bot::Cobalt::IRC> has been 
subclassed or replaced.

Wrapper for core->get_irc_object() -- see 
L<Bot::Cobalt::Core::Role::IRC>

=head2 logger

Returns the core singleton's logger object.

  logger->info("Log message");

Wrapper for core->log->$method

=head2 plugin_alias

  my $alias = plugin_alias($self);

Returns the known alias for a specified (loaded) plugin object.

Wrapper for core->get_plugin_alias() -- see 
L<Bot::Cobalt::Core::Role::EasyAccessors>

=head2 plugin_cfg

  my $opts = plugin_cfg($self)->{Opts};

Returns plugin configuration hashref for the specified plugin.
Requires a plugin alias or blessed plugin object be specified.

Wrapper for core->get_plugin_cfg() -- see 
L<Bot::Cobalt::Core::Role::EasyAccessors>

=head2 register

  register $self, 'SERVER', @events;

Register to receive specified syndicated events.

Wrapper for core->plugin_register(); see L<Bot::Cobalt::Manual::Plugins> 
for details.

=head2 unregister

Stop listening for specified syndicated events.

Wrapper for core->plugin_unregister()

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
