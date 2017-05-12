package Bing::Search::Role::SearchRequest::Latitude;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'Latitude' => (
   is => 'rw',
   lazy_build => 1
);

sub _build_SearchResult_Latitude { } 

before 'Latitude' => sub { 
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 90 && $param >= -90 ) { 
      die 'Latitude must be between -90 and 90';
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Latitude ) { 
      my $hash = $self->params;
      $hash->{Latitude} = $self->Latitude;
      $self->params( $hash );
   }
};

1;
