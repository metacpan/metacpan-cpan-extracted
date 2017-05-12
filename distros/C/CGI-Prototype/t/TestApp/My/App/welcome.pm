package My::App::welcome;
use base My::App;

sub respond_per_page {
  my $self = shift;
  if ($self->param('first') and $self->param('last')) {
    return $self->name_to_page('thanks');
  }

  return $self;
}

1;
