package Bing::Search::Role::ImageRequest::Offset;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';
requires 'Image_Count';

has 'Image_Offset' => (
   is => 'rw',
   isa => 'Num',
   predicate => 'has_Image_Offset'
);

before 'Image_Offset' => sub { 
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 1000 && $param >= 0 ) { 
      croak "Image.Offset value of $param must be between 0 and 1,000.";      
   }
   if( $self->Image_Count + $param > 1000 ) { 
      croak "The sum of Image.Count and Web.Offset may not exceed 1,000.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Image_Offset ) { 
      my $hash = $self->params;
      $hash->{'Image.Offset'} = $self->Image_Count;
      $self->params( $hash );
   }
};

1;
