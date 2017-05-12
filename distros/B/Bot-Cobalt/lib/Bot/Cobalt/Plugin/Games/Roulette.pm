package Bot::Cobalt::Plugin::Games::Roulette;
$Bot::Cobalt::Plugin::Games::Roulette::VERSION = '0.021003';
use v5.10;
use strict; use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Utils qw/color/;

sub new { bless +{}, shift }

sub _suicide {
  my ($nick) = @_;
  my @ded = (
    "$nick did themselves in!",
    "$nick ended it all!",
    "$nick splattered the wall!",
    "$nick bit the big one!",
  );
  $ded[rand @ded]
}

sub execute {
  my ($self, $msg, $str) = @_;
  my $cyls = 6;

  my $context = $msg->context;
  my $nick    = $msg->src_nick;

  $self->expire;

  if ( $str && index(lc($str), 'spin') == 0 ) {
    ## clear loaded
    delete $self->{$context}->{$nick};
    return "Spun cylinders for ${nick}."
  }

  my $loaded = $self->{$context}->{$nick}->{Loaded}
               //= int rand($cyls);
  $self->{$context}->{$nick}->{TS} //= time;

  if ($loaded == 0) {
    delete $self->{$context}->{$nick};
    
    my $irc  = core->get_irc_obj($context);
    my $bot  = $irc->nick_name;
    my $chan = $msg->channel;

    if ( $irc->is_channel_operator($chan, $bot)
         || $irc->is_channel_admin($chan, $bot)
         || $irc->is_channel_owner($chan, $bot) ) {
      broadcast( 'kick', $context, $chan, $nick, "BANG!" );
    }

    return color bold => 'BANG! ' . _suicide($nick)
  }


  --$self->{$context}->{$nick}->{Loaded};
  return "${nick}: Click . . ."
}

sub expire {
  my ($self) = @_;
  for my $context (keys %$self) {
    for my $nick (keys %{ $self->{$context} }) {
      delete $self->{$context}->{$nick}
        if (time - $self->{$context}->{$nick}->{TS}) >= 600;
    }
  }
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Games::Roulette - IRC Russian Roulette

=head1 SYNOPSIS

  !rr      # Pull the trigger
  !rr spin # Spin the cylinders

=head1 DESCRIPTION

IRC Russian Roulette.

Each user gets their own gun; multiple users can play at the same time 
without interfering with each other.

If the bot has operator status, a losing try will result in a kick.

Cylinders are automatically reloaded after losing; they can also be 
manually reset via I<spin>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Significant assistance from I<Schroedingers_hat> @ B<irc.cobaltirc.org>

=cut
