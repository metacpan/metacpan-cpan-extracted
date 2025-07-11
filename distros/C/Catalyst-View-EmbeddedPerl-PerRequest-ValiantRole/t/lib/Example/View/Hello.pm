package Example::View::Hello;

use Moose;

extends 'Example::View::Base';

has 'name' => (is => 'ro', isa => 'Str');

__PACKAGE__->meta->make_immutable;

__DATA__
%= $self->view('Page', title => 'Hello', sub {
    <h1>Hello</h1>
    <%= "<a href='/hello'>Hello</a>" %>
    %= form_for('person', {allow_method_names_outside_object=>1}, sub {
        % my ($self, $fb, $model) = @_;\
        <%= $fb->field('name')
            ->label
            ->input %>
        %= $fb->input('age');
    % });\
% });