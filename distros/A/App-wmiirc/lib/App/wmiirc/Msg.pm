package App::wmiirc::Msg;
{
  $App::wmiirc::Msg::VERSION = '1.000';
}
use App::wmiirc::Plugin;
use IO::Async::Timer::Countdown;

has name => (
  is => 'ro',
  default => sub { '!notice' }
);

has _timer => (
  is => 'rw',
);

with 'App::wmiirc::Role::Widget';
with 'App::wmiirc::Role::Fade';

sub event_msg {
  my($self, @msg) = @_;
  my $msg = "@msg";
  $msg =~ s/\n//g;

  my $timer = IO::Async::Timer::Countdown->new(
    delay => .3,
    on_expire => sub {
      my $timer = shift;
      if(!defined $self->_timer || $self->_timer != $timer) {
        # Cancelled
        $self->core->loop->remove($timer);
        return;
      }

      $self->label($msg, $self->fade_current_color);

      if($self->fade_next) {
        $timer->start
      } else {
        $self->_timer(undef);
        $self->core->loop->remove($timer);
      }
    }
  );
  $timer->start;
  $self->core->loop->add($timer);
  $self->_timer($timer);

  $self->fade_set(0);
  $self->label($msg, $self->fade_current_color);
}

# Lower priority notification, don't interrupt an active msg.
sub event_notice {
  my($self, @msg) = @_;
  my $msg = "@msg";
  $msg =~ s/\n//g;

  if(!$self->_timer) {
    $self->label($msg);
  }
}

sub widget_click {
  my($self, $button) = @_;
  $self->label(" ");
  $self->_timer(undef);
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Msg

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

