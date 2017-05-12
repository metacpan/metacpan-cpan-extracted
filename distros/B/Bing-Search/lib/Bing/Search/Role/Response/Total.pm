package Bing::Search::Role::Response::Total;
use Moose::Role;

has 'Total' => ( is => 'rw', isa => 'Num' );

1;
