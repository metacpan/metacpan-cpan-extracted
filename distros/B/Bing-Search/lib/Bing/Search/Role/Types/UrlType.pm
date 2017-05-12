package Bing::Search::Role::Types::UrlType;
use Moose::Role;
use Moose::Util::TypeConstraints;
use URI;

subtype 'Bing::Search::UrlType' 
   => as class_type('URI');

coerce 'Bing::Search::UrlType'
   => from 'Str'
   => via { URI->new( $_ ) };

1;
