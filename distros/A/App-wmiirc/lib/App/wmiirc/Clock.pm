package App::wmiirc::Clock;
{
  $App::wmiirc::Clock::VERSION = '1.000';
}
use App::wmiirc::Plugin;
use IO::Async::Timer::Absolute;
use POSIX qw(strftime);

has name => (
  is => 'ro',
  default => sub { '~clock' }
);

has format => (
  is => 'ro',
  default => sub {
    config("clock", "format", "%a %H:%M")
  }
);

has format_other_tz => (
  is => 'ro',
  default => sub {
    config("clock", "format_other_tz", "%a %b %d %H:%M:%S %Z")
  }
);

has extra_tz => (
  is => 'ro',
  default => sub {[
    split /,\s*/, config("clock",
      extra_tz => "America/Los_Angeles, America/New_York, Europe/Paris")
  ]}
);

has current_tz => (
  is => 'rw',
  default => sub { -1 }
);

has _timer => (
  is => 'rw'
);

with 'App::wmiirc::Role::Widget';

sub BUILD {
  my($self) = @_;
  $self->render;
}

sub render {
  my($self) = @_;
  my($text, $color, $next);

  if($self->current_tz == -1) {
    ($text, $next) = _format($self->format, localtime);
  } else {
    local $ENV{TZ} = $self->extra_tz->[$self->current_tz];
    ($text, $next) = _format($self->format_other_tz, localtime);
    $color = $self->core->main_config->{focuscolors};
  }

  $self->label($text, $color);

  $self->core->loop->add($self->_timer(IO::Async::Timer::Absolute->new(
    time => $next,
    on_expire => sub {
      my($timer) = @_;
      $self->render unless $self->_timer != $timer;
    }
  )));
}

sub _format {
  my($format, @args) = @_;
  # Not sure it's worth going to these lengths to maybe save some wakeups, but
  # why not...
  my $next = $format =~ /%[^\w]?[EO]?[sSTr]/
      ? time + 1 : 60 * int(time / 60) + 60;
  return strftime($format, @args), $next;
}

sub widget_click {
  my($self, $button) = @_;

  if($button == 1) {
    return unless @{$self->extra_tz};

    if($self->current_tz < 0) {
      $self->current_tz(0);
    } else {
      $self->current_tz($self->current_tz + 1);
      if($self->current_tz == @{$self->extra_tz}) {
        $self->current_tz(-1);
      }
    }
    $self->render;

  } elsif($button == 3) {
    system "zenity", "--calendar";
    system "cal -y | xmessage -file -" if $? == -1;
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Clock

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

