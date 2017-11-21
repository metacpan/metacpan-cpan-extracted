package App::JESP::Colorizer;
$App::JESP::Colorizer::VERSION = '0.015';
use Moose;

has 'jesp' => ( is => 'ro' , isa => 'App::JESP', required => 1);

use Term::ANSIColor qw//;

=head2 colored

Returns a colored text only in an interactive environment.

=cut

sub colored{
  my ($self, $text, $ansi_color_def) = @_;
  if( $self->jesp->interactive() ){
    return Term::ANSIColor::colored($text, $ansi_color_def);
  }
  return $text;
}

__PACKAGE__->meta->make_immutable();
