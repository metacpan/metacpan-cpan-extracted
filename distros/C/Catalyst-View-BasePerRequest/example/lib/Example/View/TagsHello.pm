package Example::View::TagsHello;

use Moose;
use HTML::Tags;

extends 'Example::TagsBaseView';

has name => (is=>'ro', required=>1);

sub render {
  my ($self, $c) = @_;
  return $c->view(TagsLayout => title=>"Tags", sub {
    $self->content_for('styles', sub {
          "div { color: red }",
      });
    return <div>,
      "Hello  @{[ $self->name ]}",
    </div>;
  });
}

__PACKAGE__->config(status_codes=>[200]);
__PACKAGE__->meta->make_immutable();
