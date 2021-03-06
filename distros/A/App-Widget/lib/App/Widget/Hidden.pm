
######################################################################
## $Id: Hidden.pm 3668 2006-03-11 20:51:13Z spadkins $
######################################################################

package App::Widget::Hidden;
$VERSION = (q$Revision: 3668 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Widget;
@ISA = ( "App::Widget" );

use strict;

=head1 NAME

App::Widget::Hidden - An HTML hidden field

=head1 SYNOPSIS

   $name = "first_name";

   # official way
   use App;
   $context = App->context();
   $w = $context->widget($name);
   # OR ...
   $w = $context->widget($name,
      class => "App::Widget::Hidden",
   );

   # internal way
   use App::Widget::Hidden;
   $w = App::Widget::Hidden->new($name);

=cut

=head1 DESCRIPTION

This class is a <input type=hidden> HTML element.

=cut

sub html {
    my $self = shift;
    my ($name, $value, $html_value, $html);
    $name = $self->{name};
    $value = $self->get_value();
    $html_value = $self->html_escape($value);
    $html = "<input type=\"hidden\" name=\"${name}\" value=\"$html_value\" />";
    $html;
}

1;

