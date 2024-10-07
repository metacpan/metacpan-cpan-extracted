package Example::View::Hello;

use Moose;

extends 'Example::View';

has 'name' => (is => 'ro', isa => 'Str');

__PACKAGE__->meta->make_immutable;

__DATA__
%= form_for('person', sub {
    % my ($self, $fb, $model) = @_;\
    %= $fb->input('name');
    %= $fb->input('age');
% });\
