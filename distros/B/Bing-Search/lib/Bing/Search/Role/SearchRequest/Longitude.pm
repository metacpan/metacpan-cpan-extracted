package Bing::Search::Role::SearchRequest::Longitude;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'Longitude' => (
   is => 'rw',
   lazy_build => 1
);

sub _build_SearchResult_Longitude { } 

before 'Longitude' => sub { 
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 180 && $param >= -180 ) { 
      die 'Longitude must be between -180 and 180.';
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Longitude ) { 
      my $hash = $self->params;
      $hash->{Longitude} = $self->Longitude;
      $self->params( $hash );
   }
};

1;
