package App::wmiirc::Loadavg;
{
  $App::wmiirc::Loadavg::VERSION = '1.000';
}
use 5.014;
use App::wmiirc::Plugin;
use IO::Async::Timer::Countdown;
use Unix::Uptime;

has name => (
  is => 'ro',
  default => sub { "loadavg" }
);

has _show_all => (
  is => 'rw',
  default => sub {
    my($self) = @_;
    config('loadavg', 'show', 'one') eq 'all';
  }
);

with 'App::wmiirc::Role::Widget';
#with 'App::wmiirc::Role::Fade';

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
  $self->label(join " ", (Unix::Uptime->load)[0 .. $self->{_show_all} && 2]);
}

sub widget_click {
  my($self, $button) = @_;

  given($button) {
    when(1) {
      $self->{_show_all} ^= 1;
      $self->render;
    }
    when(3) {
      system $self->core->main_config->{terminal}
        . " -e " . (config("commands", "top") || "top") . "&";
    }
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Loadavg

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

