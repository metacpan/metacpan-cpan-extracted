package App::wmiirc::Battery;
{
  $App::wmiirc::Battery::VERSION = '1.000';
}
use App::wmiirc::Plugin;
use Const::Fast;
use IO::Async::Timer::Countdown;
use POSIX qw(strftime);

const my $BATTERY_SYS => '/sys/class/power_supply';

has name => (
  is => 'ro',
  default => sub { "battery" }
);

has battery => (
  is => 'rw'
);

with 'App::wmiirc::Role::Widget';
with 'App::wmiirc::Role::Fade';

my %config = config("battery", {
    no_battery   => '-',
    on_battery   => '=%{time_empty} %{watts}w',
    on_ac        => '~(%{time_full})',
    full         => '~',
    default      => 'BAT0',
    info_minutes => 30,
    warn_minutes => 4,
  }
);

sub BUILD {
  my($self) = @_;
  $self->battery((grep $config{default} eq $_, $self->_list_bat)[0]
    || ($self->list_bat)[0]);

  $self->fade_start_color('#ffffff #aa2222 #ff44cc');
  $self->fade_end_color('#ffffff #999922 #ff4444');

  my $timer = IO::Async::Timer::Countdown->new(
    delay => 30,
    on_expire => sub {
      my($timer) = @_;
      $self->render;
      $timer->start;
    },
  );

  $self->render;
  $self->core->loop->add($timer);
  $timer->start;
}

sub render {
  my($self) = @_;
  state $previous_power = $self->_bat("power_now");

  # Take the mean of this and the previous power level, to hopefully give a
  # better estimate.
  my $power_now = ($self->_bat("power_now") + $previous_power) / 2;
  $previous_power = $self->_bat("power_now");
  my $minutes = $power_now ? 60 * $self->_bat("energy_now") / $power_now
                           : -1;
  my $minutes_to_full = $power_now ? ($self->_bat("energy_full")
                                       - $self->_bat("energy_now"))
                                     / $power_now * 60
                                   : -1;

  my %data = (
    time_full  => strftime("%-H:%M", 0, $minutes_to_full, 0, 0, 0, 0),
    # Let me know if your battery lasts for >23 hours. I'd like one too.
    time_empty => strftime("%-H:%M", 0, $minutes, 0, 0, 0, 0),
    watts      => sprintf("%d", $power_now / 1e6),
    percent    => sprintf("%d", $self->_bat("energy_now") /
                          $self->_bat("energy_full") * 100),
  );

  given($self->_bat("status")) {
    when("Discharging") {
      if($minutes <= $config{warn_minutes}) {
        $self->core->dispatch("event_msg", "Battery critical");
      }

      if($minutes <= $config{info_minutes}) {
        $self->fade_set($minutes / $config{info_minutes} * $self->fade_count);
        $self->label(\%data, $config{on_battery}, $self->fade_current_color);
      } else {
        $self->label(\%data, $config{on_battery});
      }
    }
    when("Charging") {
      $self->label(\%data, $config{on_ac});
    }
    when("Full") {
      $self->label(\%data, $config{full});
    }
    default {
      $self->label(\%data, $config{no_battery});
    }
  }
}

sub label {
  my($self, $data, $label, @opts) = @_;
  $label =~ s{%\{(.*?)\}}{$data->{$1}}g;
  $self->App::wmiirc::Role::Widget::label($label, @opts);
}

sub widget_click {
  my($self, $button) = @_;

  given($button) {
    when(1) {
      system "acpi -V | xmessage -default okay -file -&";
    }
    when(3) {
      system $self->core->main_config->{terminal} . " -e sudo powertop&";
    }
  }
}

sub _list_bat {
  my($self) = @_;
  grep $self->_bat("type", $_) eq 'Battery', map s{.*/}{}r, <$BATTERY_SYS/*>;
}

sub _bat {
  my($self, $file, $bat) = @_;
  $bat ||= $self->battery;
  open my $fh, '<', "$BATTERY_SYS/$bat/$file"
    or die "$BATTERY_SYS/$bat/$file: $!";
  <$fh> =~ s/\n//r;
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Battery

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

