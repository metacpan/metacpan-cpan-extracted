package Example::View::Hello;

use Moose;

extends 'Catalyst::View::BasePerRequest';

has name => (is=>'ro', required=>1);

sub render {
  my ($self, $c) = @_;
  return $c->view(Layout => title=>'Hello', sub {
    my $layout = shift;
    $self->content_for('css', "<style>...</style>");
    return "<div>Hello @{[ $self->name ]}!</div>";
  });
}

__PACKAGE__->config(content_type=>'text/html', status_codes=>[200]);
__PACKAGE__->meta->make_immutable();
