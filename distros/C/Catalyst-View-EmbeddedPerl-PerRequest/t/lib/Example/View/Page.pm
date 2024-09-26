package Example::View::Page;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

has title => (is => 'ro');

sub styles {
  my ($self, $cb) = @_;
  my $styles = $self->content('css') || return '';
  return $cb->($styles);
}

__PACKAGE__->meta->make_immutable;

__DATA__
<html>
  <head>
    <title>Example</title>
    %= $self->styles(sub { \
    <style>
      %= shift\
    </style>
    % })\
  </head>
  <body>
    <%= $self->title %>
    <%= $content =%>
  </body>
</html>