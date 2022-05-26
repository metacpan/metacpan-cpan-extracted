package Example::TagsBaseView;

use Moose;
use HTML::Tags ();

extends 'Catalyst::View::BasePerRequest';

around flatten_rendered_for_response_body => sub {
  my ($orig, $self, @rendered) = @_;
  my @lines = HTML::Tags::to_html_string(@rendered);
  my $string = $self->$orig(@lines);
  return bless([ \$string ], 'XML::Tags::StringThing');
};

__PACKAGE__->config(content_type=>'text/html');
__PACKAGE__->meta->make_immutable();
