package # Hide from CPAN
    SEWeeResults;
use Moose;

extends 'Data::SearchEngine::Results';

with (
    'Data::SearchEngine::Results::Faceted'
);

1;
