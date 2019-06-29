package App::TeleGramma::Plugin::Core::Timer;
$App::TeleGramma::Plugin::Core::Timer::VERSION = '0.14';
# ABSTRACT: TeleGramma plugin to set timers

use Mojo::Base 'App::TeleGramma::Plugin::Base';
use App::TeleGramma::BotAction::Listen;
use App::TeleGramma::Constants qw/:const/;
use Time::Duration::Parse qw/parse_duration/;

sub synopsis {
  "Set timers for a future reminder"
}

sub default_config {
  my $self = shift;
  return { };
}

sub register {
  my $self = shift;

  my $timer_help = App::TeleGramma::BotAction::Listen->new(
    command  => qr{/timer}i,
    response => sub { $self->timer_help(@_) }
  );

  my $timer_set_exact = App::TeleGramma::BotAction::Listen->new(
    command  => qr{/timer\s(.*)}i,
    response => sub { $self->timer_set(@_) }
  );

  return ($timer_set_exact, $timer_help);
}

sub timer_help {
  my $self = shift;
  my $msg  = shift;
  $self->reply_to($msg, "examples: /timer remind me to weed and feed in 3 hours");
  return PLUGIN_RESPONDED_LAST;
}

sub timer_set {
  my $self = shift;
  my $msg  = shift;

  my $text = $msg->text;
  my ($request) = ($text =~ m{/timer\s+(.*)}i);

  # remove some common prefixes from the request
  $request =~ s/^remind me to//;
  $request =~ s/^remind me//;
  $request =~ s/^tell me to//;

  # try to parse the thing, starting at the first number
  my ($timer_text, $duration_text) = ($request =~ /^\s*(.+)\s+in\s+(\d.*)/);
  if (! $duration_text) {
    $self->reply_to($msg, "Sorry, I can't work out when you mean from '$text'");
    return PLUGIN_RESPONDED_LAST;
  }

  my $duration = eval { parse_duration($duration_text) };
  if ($@ || ! $duration) {
    $self->reply_to($msg, "Sorry, I can't work out when you mean from '$duration_text'");
    return PLUGIN_RESPONDED_LAST;
  }

  Mojo::IOLoop->timer($duration => sub {
    my $loop = shift;
    my $message = "Hey \@" . $msg->from->username . ", this is your reminder to $timer_text";
    $self->reply_to($msg, $message);
  });

  $self->reply_to($msg, "Will remind you '$timer_text' in $duration_text");
  return PLUGIN_RESPONDED_LAST;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::Plugin::Core::Timer - TeleGramma plugin to set timers

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
