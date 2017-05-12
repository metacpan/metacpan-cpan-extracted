package Catmandu::Fix::Condition::is_http_uri;

use Catmandu::Sane;
use Moo;
use Data::Validate::URI;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(is_value(${var}) && Data::Validate::URI::is_http_uri(${var}))";
}

=head1 NAME

Catmandu::Fix::Condition::is_http_uri - check of a field contains an HTTP URI

=head1 SYNOPSIS

   if is_http_uri(uri_field)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;