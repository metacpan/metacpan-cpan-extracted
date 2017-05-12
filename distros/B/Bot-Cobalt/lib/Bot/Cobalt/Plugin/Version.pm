package Bot::Cobalt::Plugin::Version;
$Bot::Cobalt::Plugin::Version::VERSION = '0.021003';
use strictures 2;

use Bot::Cobalt;
use Bot::Cobalt::Utils 'secs_to_str';

use Object::Pluggable::Constants ':ALL';

sub new { bless [], shift  }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  register $self, SERVER => 'public_msg';
  logger->info("Loaded");
  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  logger->info("Unloaded");
  PLUGIN_EAT_NONE
}

sub Bot_public_msg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};
  my $context = $msg->context;
  return PLUGIN_EAT_NONE unless $msg->highlight;

  my $resp;

  my $cmd = lc($msg->message_array->[1] || return PLUGIN_EAT_NONE);

  CMD: {
    if ($cmd eq 'info') {
      my $startedts = $core->State->{StartedTS} // 0;
      my $delta = time() - $startedts;

      my $randstuffs = $core->Provided->{randstuff_items} // 0;
      my $infoglobs  = $core->Provided->{info_topics}    // 0;

      $resp = core->rpl( q{RPL_INFO},
        version => 'Bot::Cobalt '.$core->version,
        plugins => scalar keys %{ $core->plugin_list },
        uptime  => secs_to_str($delta),
        sent    => $core->State->{Counters}->{Sent},
        topics  => $infoglobs,
        randstuffs => $randstuffs,
      );

      last CMD
    }

    if ($cmd eq 'version') {
      $resp = core->rpl( q{RPL_VERSION},
        version => 'Bot::Cobalt '.$core->version,
        perl_v  => sprintf("%vd", $^V),
        poe_v   => $POE::VERSION,
        pocoirc_v => $POE::Component::IRC::VERSION,
      );

      last CMD
    }

    if ($cmd eq 'os') {
      $resp = core->rpl( q{RPL_OS}, { os => $^O } );
      last CMD
    }

    return PLUGIN_EAT_NONE
  }

  broadcast('message', $context, $msg->channel, $resp)
    if defined $resp;

  PLUGIN_EAT_NONE
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Version - Retrieve bot version and info

=head1 SYNOPSIS

  ## Get uptime and other info:
  <JoeUser> botnick: info
  
  ## Get version information:
  <JoeUser> botnick: version
  
  ## Find out what OS we're using:
  <JoeUser> botnick: os

=head1 DESCRIPTION

Retrieves information about the running Cobalt instance.

If L<Bot::Cobalt::Plugin::Info3> is available, the number of Info3 topics 
is included.

If L<Bot::Cobalt::Plugin::RDB> is available, the number of items in the 'main' 
RDB will be reported.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
