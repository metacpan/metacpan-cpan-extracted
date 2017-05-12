package Bing::Search::Role::WebRequest::Count;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Web_Count' => (
   is => 'rw',
   predicate => 'has_Web_Count',
   clearer => 'clear_Web_Count'
);


before 'Web_Count' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 50 && $param >= 1 ) { 
      croak "Web.Count value of $param must be between 1 and 50.";      
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Web_Count ) { 
      my $hash = $self->params;
      $hash->{'Web.Count'} = $self->Web_Count;
      $self->params( $hash );
   }
};

1;
