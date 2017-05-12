package Bot::Cobalt::Plugin::OutputFilters::StripFormat;
$Bot::Cobalt::Plugin::OutputFilters::StripFormat::VERSION = '0.021003';


use strict;
use warnings;

use Object::Pluggable::Constants qw/ :ALL /;

use IRC::Utils qw/ strip_formatting /;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  $core->plugin_register( $self, 'USER',
    'message', 'notice', 'ctcp',
  );

  $core->log->info("Registered, filtering FORMATTING");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  $core->log->info("Unregistered");

  return PLUGIN_EAT_NONE
}

sub Outgoing_message {
  my ($self, $core) = splice @_, 0, 2;

  ${$_[2]} = strip_formatting(${$_[2]});

  return PLUGIN_EAT_NONE
}

sub Outgoing_notice { Outgoing_message(@_) }

sub Outgoing_ctcp {
  my ($self, $core) = splice @_, 0, 2;
  my $type = ${$_[1]};

  return PLUGIN_EAT_NONE unless uc($type) eq 'ACTION';

  ${$_[3]} = strip_formatting(${$_[3]});

  return PLUGIN_EAT_NONE
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::OutputFilters::StripFormat - strip bold/underline/italics

=head1 SYNOPSIS

  !plugin load StripFormat Bot::Cobalt::Plugin::OutputFilters::StripFormat

=head1 DESCRIPTION

Cobalt output filter plugin.

Strips any formatting codes from outgoing messages, such as bold, underline, 
reverse, etc.

Does not strip color codes; see L<Bot::Cobalt::Plugin::OutputFilters::StripColor>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
