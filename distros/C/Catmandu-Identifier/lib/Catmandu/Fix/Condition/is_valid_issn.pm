package Catmandu::Fix::Condition::is_valid_issn;

our $VERSION = '0.13';

use Catmandu::Sane;
use Moo;
use Business::ISSN;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var, $parser) = @_;
    "(is_value(${var}) && Business::ISSN->new(${var}) && Business::ISSN->new(${var})->is_valid)";
}

=head1 NAME

Catmandu::Fix::Condition::is_valid_issn - condition on validity of issn numbers

=head1 SYNOPSIS

   if is_valid_issn(issn_field)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
