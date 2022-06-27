package Catmandu::Fix::Condition::is_web_uri;

our $VERSION = '0.15';

use Catmandu::Sane;
use Moo;
use Data::Validate::URI;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(is_value(${var}) && Data::Validate::URI::is_web_uri(${var}))";
}

=head1 NAME

Catmandu::Fix::Condition::is_web_uri - check of a field contains an HTTP or HTTPS URI

=head1 SYNOPSIS

   if is_web_uri(uri_field)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
