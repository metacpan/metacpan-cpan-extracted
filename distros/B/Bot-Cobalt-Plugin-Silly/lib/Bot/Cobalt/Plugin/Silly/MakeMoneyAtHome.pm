package Bot::Cobalt::Plugin::Silly::MakeMoneyAtHome;
$Bot::Cobalt::Plugin::Silly::MakeMoneyAtHome::VERSION = '0.031002';
use strictures 2;

use Bot::Cobalt::Common;

use Acme::MakeMoneyAtHome;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  
  $core->plugin_register( $self, SERVER => 'public_cmd_makemoney' );
  
  $core->log->info("Loaded");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  $core->log->info("Unloaded");

  return PLUGIN_EAT_NONE
}

sub Bot_public_cmd_makemoney {
  my ($self, $core) = splice @_, 0, 2;

  my $msg     = ${ $_[0] };
  my $context = $msg->context;

  my $resp = make_money_at_home;

  my $channel = $msg->channel;

  $core->send_event( 'send_message',
    $context,
    $channel,
    $resp
  ) if $resp;
  
  return PLUGIN_EAT_ALL
}

1;
__END__
=pod

=head1 NAME

Bot::Cobalt::Plugin::Silly::MakeMoneyAtHome - Learn how to make money at home

=head1 SYNOPSIS

  !plugin load Bone Bot::Cobalt::Plugin::Silly::MakeMoneyAtHome
  !pickup

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

Simple bridge to L<Acme::MakeMoneyAtHome>.

Generates useful suggestions on ways you could make money at home.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
