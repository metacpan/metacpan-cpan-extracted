package Bot::Cobalt::Plugin::Games::RockPaperScissors;
$Bot::Cobalt::Plugin::Games::RockPaperScissors::VERSION = '0.021003';
use v5.10;
use strict; use warnings;

sub new { bless [], shift }

sub execute {
  my ($self, $msg, $rps) = @_;
  my $nick = $msg->src_nick // '';
  $rps = lc($rps // '');

  state $beats = +{
    scissors => 'paper',
    paper    => 'rock',
    rock     => 'scissors',
  };

  if (! $rps) {
    return "What did you want to throw, ${nick}?"
  } elsif (! exists $beats->{$rps}) {
    return "${nick}: You gotta throw rock, paper, or scissors!"
  }

  my $throw = (keys %$beats)[rand(keys %$beats)];

  $throw eq $rps ? "$nick threw $rps, I threw $throw -- it's a tie!"
    : $beats->{$throw} eq $rps ? "$nick threw $rps, I threw $throw -- I win!"
    : "$nick threw $rps, I threw $throw -- you win :("
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Games::RockPaperScissors - IRC rock-paper-scissors

=head1 SYNOPSIS

  !rps rock
  !rps scissors
  !rps paper

=head1 DESCRIPTION

Play rock-paper-scissors against the bot.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
