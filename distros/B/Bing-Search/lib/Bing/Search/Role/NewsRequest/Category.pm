package Bing::Search::Role::NewsRequest::Category;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'News_Category' => (
   is => 'rw',
   predicate => 'has_News_Category',
   clearer => 'clear_News_Category'
);


before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_News_Category ) { 
      my $hash = $self->params;
      $hash->{'News.Category'} = $self->News_Category;
      $self->params( $hash );
   }
};

1;
