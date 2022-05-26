package Example::View::Layout;

use Moose;

extends 'Catalyst::View::BasePerRequest';

has title => (is=>'ro', required=>1, default=>'Missing Title');

sub render {
  my ($self, $c, $inner) = @_;
  return "<h1>@{[ $self->title ]}</h1><br>$inner<br>@{[ $self->content('foot') ]} "; #    $self->block(foot=>+{required=>1, default=>'Down Down'})
}

__PACKAGE__->config(content_type=>'text/html');
__PACKAGE__->meta->make_immutable();
