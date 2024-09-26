package Example::View::Captures;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';


__PACKAGE__->meta->make_immutable;

__DATA__
<% $self->content_for('name', sub { %>\
  <p>joe</p>
<% }) %>\
% content_append('name', sub {\
  <p>john</p>\
% });\
%= $self->mtrim($self->content('name'))