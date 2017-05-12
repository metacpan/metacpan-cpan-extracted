package Algorithm::BestChoice::Option;

use Moose;

has matcher => qw/is ro required 1 isa Algorithm::BestChoice::Matcher/, handles => [qw/ match /];
has ranker => qw/is ro required 1 isa Algorithm::BestChoice::Ranker/, handles => [qw/ rank /];
has value => qw/is ro required 1/;

1;
