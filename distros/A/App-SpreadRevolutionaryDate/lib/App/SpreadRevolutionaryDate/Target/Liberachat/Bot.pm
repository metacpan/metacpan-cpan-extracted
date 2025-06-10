#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::Target::Liberachat::Bot;
$App::SpreadRevolutionaryDate::Target::Liberachat::Bot::VERSION = '0.51';
# ABSTRACT: Subclass overloading L<Bot::BasicBot> to post a message on some Liberachat channels

use Moose;
use MooseX::NonMoose;
extends 'Bot::BasicBot';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has 'nb_said' => (
  traits  => ['Counter'],
  is  => 'rw',
  isa => 'Num',
  default => 0,
  handles => {
    inc_said   => 'inc',
  },
);

has 'nb_ticks' => (
  traits  => ['Counter'],
  is  => 'rw',
  isa => 'Num',
  default => 0,
  handles => {
    inc_ticks   => 'inc',
  },
);

has 'msg' => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

sub connected {
  my $self = shift;

  $self->say({who => 'NickServ', channel => 'msg', body => 'IDENTIFY ' . $self->{liberachat_nickname} . ' ' . $self->{liberachat_password}});
}

sub said {
  my ($self, $message) = @_;

  $self->nb_said(1) if ($message->{who} eq 'NickServ' && $message->{body} =~ /^You are now identified for/);
  return;
}

sub tick {
  my $self = shift;

  if ($self->nb_said) {
    if ($self->nb_said > scalar($self->channels)) {
      $self->shutdown;
    }
    foreach my $channel ($self->channels) {
      $self->say({channel => $channel, body => $self->{msg}});
      $self->inc_said;
    }
  }

  $self->inc_ticks;
  $self->shutdown if ($self->nb_ticks > 10);

  return 5;
}

sub log {
  # do nothing!
}

sub chanjoin {
  my $self = shift;

  # Remove channels added by Bot::BasicBot::irc_chanjoin_state with different case
  my %uniq_channels;
  foreach my $channel ($self->channels) {
    $uniq_channels{lc($channel)} = $channel;
  }

  if (scalar(keys %uniq_channels) != scalar($self->channels)) {
    $self->channels(values %uniq_channels);
  }

  return;
}


no Moose;
__PACKAGE__->meta->make_immutable;

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
# Idea borrowed from Jean Forget's DateTime::Calendar::FrenchRevolutionary.
"Quand le gouvernement viole les droits du peuple,
l'insurrection est pour le peuple le plus sacré
et le plus indispensable des devoirs";

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::Target::Liberachat::Bot - Subclass overloading L<Bot::BasicBot> to post a message on some Liberachat channels

=head1 VERSION

version 0.51

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Bluesky>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Telechat>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Gemini>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
