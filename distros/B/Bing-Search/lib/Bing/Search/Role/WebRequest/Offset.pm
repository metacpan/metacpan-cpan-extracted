package Bing::Search::Role::WebRequest::Offset;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';
requires 'Web_Count';

has 'Web_Offset' => (
   is => 'rw',
   isa => 'Num',
   predicate => 'has_Web_Offset'
);

before 'Web_Offset' => sub { 
   my( $self, $param ) = @_;

   return unless $param;
   unless( $param <= 1000 && $param >= 0 ) { 
      croak "Web.Offset value of $param must be between 0 and 1,000.";      
   }
   if( $self->Web_Count + $param > 1000 ) { 
      croak "The sum of Web.Count and Web.Offset may not exceed 1,000.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Web_Offset ) { 
      my $hash = $self->params;
      $hash->{'Web.Offset'} = $self->Web_Offset;
      $self->params( $hash );
   }
};

1;
