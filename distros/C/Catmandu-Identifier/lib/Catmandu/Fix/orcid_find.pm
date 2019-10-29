package Catmandu::Fix::orcid_find;

our $VERSION = '0.13';

use Catmandu::Sane;
use Moo;
use WWW::ORCID;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    "${var} = WWW::ORCID::API::Pub->new->search_bio(${var}) if is_hash_ref(${var});";
}

=head1 NAME

Catmandu::Fix::orcid_find - find ORCID id for an query

=head1 SYNOPSIS

   # Find ORCID bio for a query
   # query:
   #     q: "Johson"
   orcid_find(query)

   if exists(orcid.orcid-search-results.num-found)
    copy_field(orcid.orcid-search-results.orcid-search-result.0.orcid-profile.orcid-identifier.path,id)
   end

=head1 SEE ALSO

L<Catmandu::Fix>,
L<WWW::ORCID>

=cut

1;
