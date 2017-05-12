package Bing::Search::Role::SearchRequest::Query;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'Query' => (
   is => 'rw',
   isa => 'Str',
   lazy_build => 1
);

sub _build_Query { }

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Query ) { 
      my $hash = $self->params;
      $hash->{Query} = $self->Query;
      $self->params( $hash );
   }
};

1;
