package Bing::Search::Role::MobileWebRequest::Offset;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';
requires 'MobileWeb_Count';

has 'MobileWeb_Offset' => (
   is => 'rw',
   isa => 'Num',
   predicate => 'has_MobileWeb_Offset'
);

before 'MobileWeb_Offset' => sub { 
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 1000 && $param >= 0 ) { 
      croak "MobileWeb.Offset value of $param must be between 0 and 1,000.";      
   }
   if( $self->MobileWeb_Count + $param > 1000 ) { 
      croak "The sum of MobileWeb.Count and MobileWeb.Offset may not exceed 1,000.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_MobileWeb_Offset ) { 
      my $hash = $self->params;
      $hash->{'MobileWeb.Offset'} = $self->MobileWeb_Count;
      $self->params( $hash );
   }
};

1;
