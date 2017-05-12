# $Id: Pluggable.pm,v 1.5 2002/12/10 13:23:34 matt Exp $

package Bot::Pluggable;
use POE::Component::IRC::Object;
use base qw(POE::Component::IRC::Object);

$VERSION = '0.03';

use strict;
use POE;

sub add_module {
    my ($self, @modules) = @_;
    my %new_modules = map { $_ => 1 } (@{$self->{Modules}}, @modules);
    @{$self->{Modules}} = keys %new_modules;
}

sub remove_module {
    my ($self, @modules) = @_;
    my %new_modules = map { $_ => 1 } @{$self->{Modules}};
    foreach my $mod (@modules) { delete $new_modules{$mod} }
    @{$self->{Modules}} = keys %new_modules;
}

sub modules {
    my ($self) = @_;
    return @{$self->{Modules}};
}

sub add_object {
    my ($self, @objects) = @_;
    push @{$self->{Objects}}, @objects;
}

sub objects {
    my ($self) = @_;
    return @{$self->{Objects}};
}

BEGIN {
    sub add_event {
        my $class = shift;
        my $method = shift;
        eval "sub $method {\n" .
          '    my $self = $_[OBJECT];
               $_[SENDER] = $self;
               shift(@_);
               foreach my $obj ($self->objects) {
                 my $meth = $obj->can(' . "'$method'" . ');
                 next unless $meth;
                 my $ret = $meth->($obj, @_);
                 return if $ret;
               }
               foreach my $class ($self->modules) {
                 my $meth = $class->can(' . "'$method'" . ');
                 next unless $meth;
                 my $ret = $meth->($class, @_);
                 return if $ret;
               }
             }';
        die "Compilation of $method failed: $@" if $@;
    }
    
    my @methods = qw(
        irc_001 
        irc_public 
        irc_join 
        irc_invite 
        irc_kick 
        irc_mode 
        irc_msg 
        irc_nick 
        irc_notice 
        irc_part 
        irc_ping 
        irc_quit
        irc_dcc_chat
        irc_dcc_done
        irc_dcc_error
        irc_dcc_get
        irc_dcc_request
        irc_dcc_send
        irc_dcc_start
        irc_snotice

        irc_ctcp_finger
        irc_ctcp_version
        irc_ctcp_source
        irc_ctcp_userinfo
        irc_ctcp_clientinfo
        irc_ctcp_errmsg
        irc_ctcp_ping
        irc_ctcp_time
        irc_ctcp_action
        irc_ctcp_dcc
    );
    
    foreach my $method (@methods) {
        __PACKAGE__->add_event($method);
    }
}

1;

__END__

=head1 NAME

Bot::Pluggable - A plugin based IRC bot

=head1 SYNOPSIS

  use Bot::Pluggable;
  use MyPlugin::Joiner;
  use MyPlugin::Factoid;
  use MyPlugin::OpBot;
  use POE;
  
  my $factoid = MyPlugin::Factoid->new();
  my $opper = MyPlugin::OpBot->new();
  
  my $bot = Bot::Pluggable->new(
      Modules => [qw(MyPlugin::Joiner)],
      Objects => [$factoid, $opper],
      Nick => 'my_bot',
      Server => 'grou.ch',
      Port => 6667,
      );
  
  $poe_kernel->run();
  exit(0);

=head1 DESCRIPTION

This is a very small (but important) part of a pluggable IRC bot framework.
It provides the developer with a simply framework for writing Bot components
as perl modules.

Each module gets a chance to listen to an event on the IRC network it joins
and respond to those events accordingly. For example an IRC joiner plugin
might look like:

  package MyPlugin::Joiner;
  use POE;
  
  sub new {
      my $class = shift;
      return bless { channels => [ '#perl', '#axkit-dahut' ] }, $class;
  }
  
  sub irc_001 {
      my ($self, $bot) = @_[OBJECT, SENDER];
      $bot->join($_) for @{$self->{channels}};
      return 0;
  }
  
  1;

Each plugin gets a chance to respond to the event. If no other plugin
should respond then it should return 1. If other plugins are allowed
to respond to this event then return 0.

All the events correspond to those listed in L<POE::Component::IRC>.
The C<$bot> object is stored in the C<$_[SENDER]> parameter (C<SENDER>
is a constant exported by POE). This object is your Bot::Pluggable
instance, which inherits its methods from POE::Component::IRC::Object,
allowing you to join channels, send msgs, etc.

If an event isn't available (check the source code for the list of
events supported by default), then you can add it with:

  Bot::Pluggable->add_event('irc_ctcp_foo');

This is neccessary for CTCP events that aren't defined by default.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

This is free software. You may use it or redistribute it under the same terms
as perl itself.

=cut
