package Bing::Search::Role::VideoRequest::Offset;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';
requires 'Video_Count';

has 'Video_Offset' => (
   is => 'rw',
   isa => 'Num',
   predicate => 'has_Video_Offset'
);

before 'Video_Offset' => sub { 
   my( $self, $param ) = @_;
   unless( $param <= 1000 && $param >= 0 ) { 
      croak "Video.Offset value of $param must be between 0 and 1,000.";      
   }
   if( $self->Video_Count + $param > 1000 ) { 
      croak "The sum of Video.Count and Web.Offset may not exceed 1,000.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Video_Offset ) { 
      my $hash = $self->params;
      $hash->{'Video.Offset'} = $self->Video_Count;
      $self->params( $hash );
   }
};

1;
