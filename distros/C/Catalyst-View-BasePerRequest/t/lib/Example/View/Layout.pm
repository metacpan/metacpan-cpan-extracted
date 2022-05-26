package Example::View::Layout;

use Moose;

extends 'Catalyst::View::BasePerRequest';

has title => (is=>'ro', required=>1, default=>'Missing Title');

sub render {
  my ($self, $c, $inner) = @_;
  return "
    <html>
      <head>
        <title>@{[ $self->title ]}</title>
        @{[ $self->content('css') ]}
      </head>
      <body>$inner: @{[ $c->stash->{stash_var} ]}</body>
    </html>";
}

__PACKAGE__->config(content_type=>'text/html');
__PACKAGE__->meta->make_immutable();
