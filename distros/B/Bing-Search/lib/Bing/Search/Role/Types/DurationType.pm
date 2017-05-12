package Bing::Search::Role::Types::DurationType;
use Moose::Role;
use DateTime::Duration;
use Moose::Util::TypeConstraints;

subtype 'Bing::Search::DurationType'
   => as class_type('DateTime::Duration');

coerce 'Bing::Search::DurationType'
   => from 'Num'
   => via { 
      DateTime::Duration->new( seconds => $_ ) 
   };

1;
