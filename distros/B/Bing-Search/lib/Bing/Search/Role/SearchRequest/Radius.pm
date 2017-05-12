package Bing::Search::Role::SearchRequest::Radius;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Radius' => (
   is => 'rw',
   isa => 'Num',
   lazy_build => 1
);

sub _build_Radius { }

around 'Radius' => sub { 
   my $next = shift;
   my ($self, $param) = @_;
   if( $param <= 0 ) {
      carp "Radius of $param makes no sense, setting to 0.";
      $param = 0;
   }
   if( $param >= 250 ) { 
      carp "Radius of $param exceeds maximum radius of 250, setting to 250.";
      $param = 250;
   }
   $self->$next( $param );
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Radius ) { 
      my $hash = $self->params;
      $hash->{Radius} = $self->Radius;
      $self->params( $hash );
   }
};

1;
