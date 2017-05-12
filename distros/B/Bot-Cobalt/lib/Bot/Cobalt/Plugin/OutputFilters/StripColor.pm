package Bot::Cobalt::Plugin::OutputFilters::StripColor;
$Bot::Cobalt::Plugin::OutputFilters::StripColor::VERSION = '0.021003';


use strictures 2;

use Object::Pluggable::Constants qw/ :ALL /;

use IRC::Utils qw/ strip_color /;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  $core->plugin_register( $self, 'USER',
    'message', 'notice', 'ctcp',
  );

  $core->log->info("Registered, filtering COLORS");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  $core->log->info("Unregistered");

  return PLUGIN_EAT_NONE
}

sub Outgoing_message {
  my ($self, $core) = splice @_, 0, 2;

  ${$_[2]} = strip_color(${$_[2]});

  return PLUGIN_EAT_NONE
}

sub Outgoing_notice { Outgoing_message(@_) }

sub Outgoing_ctcp {
  my ($self, $core) = splice @_, 0, 2;
  my $type = ${$_[1]};

  return PLUGIN_EAT_NONE unless uc($type) eq 'ACTION';

  ${$_[3]} = strip_color(${$_[3]});

  return PLUGIN_EAT_NONE
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::OutputFilters::StripColor - strip outgoing color codes

=head1 SYNOPSIS

  !plugin load StripColor Bot::Cobalt::Plugin::OutputFilters::StripColor

=head1 DESCRIPTION

Cobalt output filter plugin.

Strips color codes from any outgoing IRC messages (including actions and 
notices).

Does not strip formatting (bold, underline, ...); see 
L<Bot::Cobalt::Plugin::OutputFilters::StripFormat>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
