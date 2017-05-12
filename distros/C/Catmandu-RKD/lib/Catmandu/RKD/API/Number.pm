package Catmandu::RKD::API::Number;

use Moo;
use LWP::UserAgent;

use Catmandu::Sane;

use Catmandu::RKD::API::Search;

has artist_id => (is => 'ro', required => 1);

has results  => (is => 'lazy');

sub _build_results {
    my $self = shift;
    my $template = 'https://rkd.nl/opensearch-eac-cpf?q=kunstenaarsnummer:%s';
    my $url = sprintf($template, $self->artist_id);
    my $search = Catmandu::RKD::API::Search->new(url => $url);
    return $search->results;
}

1;