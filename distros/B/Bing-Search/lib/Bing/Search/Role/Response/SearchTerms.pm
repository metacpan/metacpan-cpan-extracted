package Bing::Search::Role::Response::SearchTerms;
use Moose::Role;

has 'SearchTerms' => ( is => 'rw', isa => 'Str' );

1;
