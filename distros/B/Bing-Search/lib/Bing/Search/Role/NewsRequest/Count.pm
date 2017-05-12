package Bing::Search::Role::NewsRequest::Count;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'News_Count' => (
   is => 'rw',
   predicate => 'has_News_Count',
   clearer => 'clear_News_Count'
);


before 'News_Count' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 15 && $param >= 1 ) { 
      croak "News.Count value of $param must be between 1 and 15.";      
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_News_Count ) { 
      my $hash = $self->params;
      $hash->{'News.Count'} = $self->News_Count;
      $self->params( $hash );
   }
};

1;
