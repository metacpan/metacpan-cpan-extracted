package App::TeleGramma::Plugin::Core::YearProgress;
$App::TeleGramma::Plugin::Core::YearProgress::VERSION = '0.14';
# ABSTRACT: TeleGramma plugin to tell you how the year is progressing

use Mojo::Base 'App::TeleGramma::Plugin::Base';
use App::TeleGramma::BotAction::Listen;
use App::TeleGramma::Constants qw/:const/;
use DateTime;

sub synopsis {
  "Periodically remind you how depressingly fast the year is passing"
}

sub default_config {
  my $self = shift;
  return { };
}

sub register {
  my $self = shift;

  my $start_yp = App::TeleGramma::BotAction::Listen->new(
    command  => qr{/ypstart}i,
    response => sub { $self->yp_start(@_) }
  );

  my $stop_yp = App::TeleGramma::BotAction::Listen->new(
    command  => qr{/ypstop}i,
    response => sub { $self->yp_stop(@_) }
  );

  Mojo::IOLoop->recurring(60 => sub {
    my $loop = shift;
    $self->send_out_progress_if_necessary;
  });

  return ($start_yp, $stop_yp);
}

sub send_out_progress_if_necessary {
  my $self = shift;

  my $decimals = 0;

  # what was the last progress report percentage?
  my $last_pc = $self->store->hash('last')->{percentage} || sprintf("%0.${decimals}f", 0);

  # how many seconds in a year?
  my $year_seconds = 365 * 86400; # no such thing as leap year la la la

  # how many seconds are we into this year?
  my $year_start_ts = DateTime->now->truncate(to => 'year')->epoch;
  my $year_seconds_so_far = time() - $year_start_ts;

  # as a percent?
  my $percent = sprintf("%0.${decimals}f", 100 * ($year_seconds_so_far / $year_seconds));

  # has it rolled?
  if ($percent ne $last_pc) {
    # store it
    $self->store->hash('last')->{percentage} = $percent;
    $self->store->save('last');
    # send out the alerts
    $self->send_alerts($percent);
  }
}

sub send_alerts {
  my $self     = shift;
  my $percent  = shift;
  my @alertees = keys %{ $self->store->hash('registered') };
  my $done_num = int($percent / 10);
  my $todo_num = 10 - $done_num;

  my $done = "▓";
  my $todo = "░";
  my $bar = $done x $done_num . $todo x $todo_num;
  $bar .= " ${percent}%";
  foreach my $id (@alertees) {
    my $username = $self->store->hash('registered')->{$id}->{username};
    eval {
      $self->app->send_message_to_chat_id($id, "Hey $username, the year is progressing: $bar");
    } or do {
      warn "Could not send message to $username - $@";
    };
  }
}

sub yp_start {
  my $self = shift;
  my $msg  = shift;

  # We don't really care about anything from here. They typed /ypstart
  # and that's all that matters.
  my $user_id = $msg->from->id;
  my $username = $msg->from->username;

  # Check the config to see if they are already registered.
  if (defined $self->store->hash('registered')->{$user_id}) {
    # already registered
    $self->reply_to($msg, "Hey $username, you're already down for regular updates on the depressingly fast progress of the year.");
    return PLUGIN_RESPONDED_LAST;
  }
  else {
    $self->store->hash('registered')->{$user_id} = {
      ts       => time(),
      username => $username,
      user_id  => $user_id,
    };
    $self->store->save('registered');
    $self->reply_to($msg, "OK $username, I will be sure to keep you informed of the year's progress.");
    return PLUGIN_RESPONDED_LAST;
  }

}

sub yp_stop {
  my $self = shift;
  my $msg  = shift;

  # We don't really care about anything from here. They typed /ypstart
  # and that's all that matters.
  my $user_id  = $msg->from->id;
  my $username = $msg->from->username;

  # Check the config to see if they are registered.
  if (defined $self->store->hash('registered')->{$user_id}) {
    # already registered, get rid of them
    delete $self->store->hash('registered')->{$user_id};
    $self->store->save('registered');
    $self->reply_to($msg, "OK $username, I'll no longer give you updates on the progress of the year.");
    return PLUGIN_RESPONDED_LAST;
  }
  else {
    $self->reply_to($msg, "Nice idea $username, but you aren't registered. Maybe try /ypstart ?");
    return PLUGIN_RESPONDED_LAST;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::Plugin::Core::YearProgress - TeleGramma plugin to tell you how the year is progressing

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
