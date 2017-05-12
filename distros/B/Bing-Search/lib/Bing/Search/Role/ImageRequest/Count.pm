package Bing::Search::Role::ImageRequest::Count;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Image_Count' => (
   is => 'rw',
   predicate => 'has_Image_Count',
);


before 'Image_Count' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 50 && $param >= 1 ) { 
      croak "Image.Count value of $param must be between 1 and 50.";      
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Image_Count ) { 
      my $hash = $self->params;
      $hash->{'Image.Count'} = $self->Image_Count;
      $self->params( $hash );
   }
};

1;
