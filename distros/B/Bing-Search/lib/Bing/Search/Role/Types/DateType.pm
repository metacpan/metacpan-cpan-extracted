package Bing::Search::Role::Types::DateType;
use Moose::Role;
use DateTime::Format::DateParse;
use Moose::Util::TypeConstraints;

subtype 'Bing::Search::DateType'
   => as class_type('DateTime');

coerce 'Bing::Search::DateType'
   => from 'Str'
   => via { 
      DateTime::Format::DateParse->parse_datetime( $_ ) 
   };

1;
