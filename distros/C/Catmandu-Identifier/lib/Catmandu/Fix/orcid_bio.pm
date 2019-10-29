package Catmandu::Fix::orcid_bio;

our $VERSION = '0.13';

use Catmandu::Sane;
use Moo;
use WWW::ORCID;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    "${var} = WWW::ORCID::API::Pub->new->get_bio(${var}) if is_string(${var}) && length(${var});";
}

=head1 NAME

Catmandu::Fix::orcid_bio - find an ORCID bio for an identifier

=head1 SYNOPSIS

   # Find an ORCID bio for an identifier
   # orid: '0000-0001-8390-6171'
   orcid_bio(orcid)

=head1 SEE ALSO

L<Catmandu::Fix>,
L<WWW::ORCID>

=cut

1;
