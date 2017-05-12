package App::CSE::Colorizer;
$App::CSE::Colorizer::VERSION = '0.012';
use Moose;

has 'cse' => ( is => 'ro' , isa => 'App::CSE', required => 1);

use Term::ANSIColor qw//;

=head2 colored

Returns a colored text only in an interactive environment.

=cut

sub colored{
  my ($self, $text, $ansi_color_def) = @_;
  if( $self->cse->interactive() ){
    return Term::ANSIColor::colored($text, $ansi_color_def);
  }
  return $text;
}

__PACKAGE__->meta->make_immutable();
