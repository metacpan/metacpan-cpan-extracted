package Bot::Cobalt::Plugin::Silly::Rot13;
$Bot::Cobalt::Plugin::Silly::Rot13::VERSION = '0.031002';
use strictures 2;

use Object::Pluggable::Constants qw/ :ALL /;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  
  $core->plugin_register( $self, 'SERVER',
    'public_cmd_rot13'
  );
  
  $core->log->info("Loaded");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  $core->log->info("Unloaded");

  return PLUGIN_EAT_NONE
}

sub Bot_public_cmd_rot13 {
  my ($self, $core) = splice @_, 0, 2;

  my $msg     = ${ $_[0] };
  my $context = $msg->context;

  my @message = @{ $msg->message_array };
  my $str = join ' ', @message;

  $str =~ tr/a-zA-Z/n-za-mN-ZA-M/;

  my $channel = $msg->channel;

  $core->send_event( 'send_message',
    $context,
    $channel,
    "rot13: ".$str
  );  
  
  return PLUGIN_EAT_ALL
}

1;
__END__
=pod

=head1 NAME

Bot::Cobalt::Plugin::Silly::Ro13 - Rot13-encode a string

=head1 SYNOPSIS

  !plugin load Rot13 Bot::Cobalt::Plugin::Silly::Rot13
  !rot13 some text

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

Rotate every character of a string 13 positions.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
