package Example::View::HelloName;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

has 'name' => (is => 'ro', isa => 'Str', default => 'world');

__PACKAGE__->meta->make_immutable;

__DATA__
# Style content
% content_for('css', sub {\
      p { color: red; }
% });
    # Main content
<%= view('Page', title=>'Welcome!', sub { %>\
  <p>hello <%= $self->name %></p>   \
<% }) %>
\# End