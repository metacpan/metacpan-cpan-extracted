package App::wmiirc::Volume;
{
  $App::wmiirc::Volume::VERSION = '1.000';
}
use 5.014;
use App::wmiirc::Plugin;
use IO::Async::Timer::Countdown;

# TODO: Split actual audio volume control into another module and fix the stupid
# logic. Anything on CPAN?

has name => (
  is => 'ro',
  default => sub { 'volume' },
);

has volume => (
  is => 'rw'
);

has device => (
  is => 'ro',
  default => sub {
    config("volume", "device", "Master")
  }
);

with 'App::wmiirc::Role::Key';
with 'App::wmiirc::Role::Widget';

sub BUILD {
  my($self) = @_;
  my $timer = IO::Async::Timer::Countdown->new(
    delay => 10,
    on_expire => sub {
      my($timer) = @_;
      $self->render;
      $timer->start;
    }
  );
  $timer->start;
  $self->core->loop->add($timer);
  $self->render;
}

sub render {
  my($self) = @_;

  my $vol = `amixer get $self->{device},0`;
  $self->volume(($vol =~ /\[(off)\]/)[0] || $vol =~ /\[(\d+)%\]/);

  $self->label($self->volume . ($self->volume =~ /\d/ && '%'));
}

sub widget_click {
  my($self, $button) = @_;

  given($button) {
    when(1) {
      $self->set($self->volume eq 'off' ? "unmute" : "mute");
    }
    when(3) {
      system config("commands", "volume") . '&';
    }
    if($self->volume ne 'off') {
      when(4) {
        $self->set($self->volume  + 2 . "%");
      }
      when(5) {
        $self->set($self->volume - 2 . "%");
      }
    }
  }
}

sub key_volume_down(XF86AudioLowerVolume) {
  my($self) = @_;
  $self->set("unmute") if $self->volume eq 'off';
  $self->set($self->volume - 6 . "%");
}

sub key_volume_up(XF86AudioRaiseVolume) {
  my($self) = @_;
  $self->set("unmute") if $self->volume eq 'off';
  $self->set($self->volume + 6 . "%");
}

sub key_volume_mute(XF86AudioMute) {
  my($self) = @_;
  $self->set($self->volume eq 'off' ? "unmute" : "mute");
}

sub set {
  my($self, $level) = @_;
  system "amixer", "set", "$self->{device},0", $level;
  $self->render;
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Volume

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

