package Bing::Search::Role::VideoRequest::Count;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Video_Count' => (
   is => 'rw',
   predicate => 'has_Video_Count',
);


before 'Video_Count' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 50 && $param >= 1 ) { 
      croak "Video.Count value of $param must be between 1 and 50.";      
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Video_Count ) { 
      my $hash = $self->params;
      $hash->{'Video.Count'} = $self->Video_Count;
      $self->params( $hash );
   }
};

1;
