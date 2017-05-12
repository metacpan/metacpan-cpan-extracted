package Bing::Search::Role::Response::AlterationOverride;
use Moose::Role;

has 'AlterationOverride' => ( is => 'rw', isa => 'Str' );

1;
