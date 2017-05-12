package MyMech;
use base 'WWW::Mechanize';

1;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

sub update_html {
  my ($self, $html) = @_;
  $self->WWW::Mechanize::update_html( $html );
}

