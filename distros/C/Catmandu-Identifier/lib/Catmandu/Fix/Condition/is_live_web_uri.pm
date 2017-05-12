package Catmandu::Fix::Condition::is_live_web_uri;

use Catmandu::Sane;
use Moo;
use Data::Validate::URI;
use LWP::Simple;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(is_value(${var}) && Data::Validate::URI::is_web_uri(${var}) && LWP::Simple::head(${var}))";
}

=head1 NAME

Catmandu::Fix::Condition::is_live_web_uri - check of a field contains an HTTP or HTTPS URI which is available online

=head1 SYNOPSIS

   if is_live_web_uri(uri_field)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;