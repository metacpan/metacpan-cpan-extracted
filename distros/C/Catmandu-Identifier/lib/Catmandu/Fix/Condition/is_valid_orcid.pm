package Catmandu::Fix::Condition::is_valid_orcid;

use Catmandu::Sane;
use Moo;
use WWW::ORCID;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;

    "(is_value(${var}) && ${var} =~/^(\\d{4})-(\\d{4})-(\\d{4})-(\\d{3}[0-9X])\$/)";
}

=head1 NAME

Catmandu::Fix::Condition::is_valid_orcid - checks of a field looks like an ORCID

=head1 SYNOPSIS

   # Checks is a field looks like an ORCID
   if is_valid_orcid(orcid)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;