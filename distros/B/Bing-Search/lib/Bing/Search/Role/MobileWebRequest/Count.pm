package Bing::Search::Role::MobileWebRequest::Count;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'MobileWeb_Count' => (
   is => 'rw',
   predicate => 'has_MobileWeb_Count',
   clearer => 'clear_MobileWeb_Count'
);


before 'MobileWeb_Count' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 15 && $param >= 1 ) { 
      croak "MobileWeb.Count value of $param must be between 1 and 15.";      
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_MobileWeb_Count ) { 
      my $hash = $self->params;
      $hash->{'MobileWeb.Count'} = $self->MobileWeb_Count;
      $self->params( $hash );
   }
};

1;
