package Catmandu::Fix::Condition::is_live_orcid;

our $VERSION = '0.10';

use Catmandu::Sane;
use Moo;
use WWW::ORCID;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(is_value(${var}) && WWW::ORCID::API::Pub->new->get_bio(${var})->{'orcid-profile'})";
}

=head1 NAME

Catmandu::Fix::Condition::is_live_orcid - test if the ORCID can be resolved

=head1 SYNOPSIS

   if is_live_orcid(orcid)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;