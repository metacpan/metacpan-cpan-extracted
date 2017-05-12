package Bing::Search::Role::NewsRequest::LocationOverride;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'News_LocationOverride' => (
   is => 'rw',
   predicate => 'has_News_LocationOverride',
   clearer => 'clear_News_LocationOverride'
);


before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_News_LocationOverride ) { 
      my $hash = $self->params;
      $hash->{'News.LocationOverride'} = $self->News_LocationOverride;
      $self->params( $hash );
   }
};

1;
