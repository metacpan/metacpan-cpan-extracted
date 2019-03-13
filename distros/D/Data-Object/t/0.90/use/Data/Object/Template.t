use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Template

=abstract

Data-Object Template Class

=synopsis

  use Data::Object::Template;

  my $template = Data::Object::Template->new;

  $template->render($string, $vars);

=description

Data::Object::Template provides methods for rendering templates and
encapsulates the behavior of L<Template::Tiny>.

=cut

use_ok "Data::Object::Template";

ok 1 and done_testing;
