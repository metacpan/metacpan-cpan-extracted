package App::wmiirc::Role::Fade;
{
  $App::wmiirc::Role::Fade::VERSION = '1.000';
}
use Moo::Role;
use Color::Model::RGB qw(rgb blend_alpha);

has fade_start_color => (
  is => 'rw',
  coerce => sub {
    _rgb_tuple(shift)
  },
  default => sub {
    my($self) = @_;
    $self->core->main_config->{alertcolors};
  },
);

has fade_end_color => (
  is => 'rw',
  coerce => sub {
    _rgb_tuple(shift)
  },
  default => sub {
    my($self) = @_;
    $self->core->main_config->{normcolors};
  },
);

has fade_count => (
  is => 'ro',
  default => sub { 50 },
);

has _fade_pos => (
  is => 'rw',
  default => sub { 0 },
);

sub fade_current_color {
  my($self) = @_;

  return $self->_fade_pos == ($self->fade_count - 1)
    ? _rgb_tuple_fmt($self->fade_end_color)
    : _blend_alpha_tuple($self->fade_start_color,
                        1-($self->_fade_pos/$self->fade_count),
                        $self->fade_end_color,
                        $self->_fade_pos/$self->fade_count);
}

# Go on to the next position, return true if there are more iterations left.
sub fade_next {
  my($self) = @_;
  if($self->_fade_pos == $self->fade_count - 1) {
    return 0;
  } else {
    $self->_fade_pos($self->_fade_pos + 1);
    return 1;
  }
}

sub fade_set {
  my($self, $pos) = @_;
  $self->_fade_pos($pos);
}

# Utility functions to handle tuples via Color::Model::RGB's API.
sub _rgb_tuple {
  [map rgb($_), split / /, shift]
}

sub _rgb_tuple_fmt {
  my($tuple) = @_;
  join " ", map "#" . $_, @$tuple;
}

sub _blend_alpha_tuple {
  my($from, $from_a, $to, $to_a) = @_;
  my $i = 0;
  join " ", map "#" . blend_alpha($_, $from_a, $to->[$i++], $to_a), @$from
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Role::Fade

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

