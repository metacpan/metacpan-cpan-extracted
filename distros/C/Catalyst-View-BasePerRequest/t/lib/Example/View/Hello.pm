package Example::View::Hello;

use Moose;

extends 'Catalyst::View::BasePerRequest';

has name => (is=>'ro', required=>1);

sub prepare_build_args {
  my ($class, $c, %args) = @_;
  $args{name} = "prepared_$args{name}";
  return %args;
}

sub render {
  my ($self, $c) = @_;
  return $c->view(Layout => title=>'Hello', sub {
    my $layout = shift;
    $self->content_for('css', "<style>...</style>");
    $self->content_prepend('css', '<!-- 111 -->');
    $self->content_append('css', '<!-- 222 -->');
    $self->content_around('css', sub {
      my $css = shift;
      return "wrapped $css end wrap";
    });

    return
      $c->view(Factory => name=>"joe"),
      $c->view(Factory => name=>"jon"),
      "<div>Hello @{[ $self->name ]}!</div>";
  });
}

__PACKAGE__->config(content_type=>'text/html', status_codes=>[200,201,400]);
__PACKAGE__->meta->make_immutable();
