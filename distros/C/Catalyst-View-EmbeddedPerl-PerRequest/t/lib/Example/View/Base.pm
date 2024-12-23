package Example::View::Base;

use Moose;
use MooseX::MethodAttributes;

extends 'Example::View::Empty';

has aaa => (is => 'ro', export=>1);

sub title :Helper { 'Missing title' }
sub ccc :Helper { 'ccc1' }

sub styles {
  my ($self, $cb) = @_;
  my $styles = $self->content('css') || return '';
  return $cb->($styles);
}

sub helpers {
  my ($class) = @_;
  return (
    test_name1 => sub { 'joe1' }
  );
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(
  helpers => {
    test_name3 => sub { 'joe3' }
  }
);

__DATA__
<html>
  <head>
    <title><%= title() %>: <%= $aaa %></title>
    %= $self->styles(sub { \
    <style>
      %= shift\
    </style>
    % })\
  </head>
  <body><%= ccc() %>
    <%= $self->title %>
    <%= $content =%>
  </body>
</html>