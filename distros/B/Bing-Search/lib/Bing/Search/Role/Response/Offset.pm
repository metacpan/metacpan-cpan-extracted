package Bing::Search::Role::Response::Offset;
use Moose::Role;

has 'Offset' => ( is => 'rw', isa => 'Num' );

1;
