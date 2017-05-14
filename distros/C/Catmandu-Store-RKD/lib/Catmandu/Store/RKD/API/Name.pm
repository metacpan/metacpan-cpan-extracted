package Catmandu::Store::RKD::API::Name;

use Moo;
use LWP::UserAgent;

use Catmandu::Sane;

use Catmandu::Store::RKD::API::Search;

has name_to_search => (is => 'ro', required => 1);

has results  => (is => 'lazy');

sub _build_results {
    my $self = shift;
    my $template = 'http://opendata.rkd.nl/opensearch/artists/eac-cpf?q=naamdeel:(%s)';
    my $url = sprintf($template, $self->name_to_search);
    my $search = Catmandu::Store::RKD::API::Search->new(url => $url);
    return $search->results;
}

1;