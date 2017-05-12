package Bing::Search::Role::SearchRequest::Market;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'Market' => (
   is => 'rw',
   isa => 'Str',
   lazy_build => 1
);

sub _build_Market { }

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Market ) { 
      my $hash = $self->params;
      $hash->{Market} = $self->Market;
      $self->params( $hash );
   }
};

1;
