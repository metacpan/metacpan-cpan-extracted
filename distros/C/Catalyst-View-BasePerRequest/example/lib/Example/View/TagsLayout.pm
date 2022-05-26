package Example::View::TagsLayout;

use Moose;
use HTML::Tags;

extends 'Example::TagsBaseView';

has title => (is=>'ro', required=>1);

sub render {
  my ($self, $c, $inner) = @_;

  $self->content_around('styles', sub {
    return <style>, shift, </style>;
  }) if $self->content('styles');

  return <html>,
    <head>,
      <title>, $self->title, </title>,
      $self->content('styles'),
    </head>,
    <body>,
      $inner,
    </body>,
  </html>;
}

__PACKAGE__->meta->make_immutable();
