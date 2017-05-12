package Bing::Search::Role::NewsRequest::Offset;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';
requires 'News_Count';

has 'News_Offset' => (
   is => 'rw',
   isa => 'Num',
   predicate => 'has_News_Offset'
);

before 'News_Offset' => sub { 
   my( $self, $param ) = @_;
   return unless $param;
   if( $param <= 0 ) { 
      croak "Offset must be positive.";
   }

};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_News_Offset ) { 
      my $hash = $self->params;
      $hash->{'News.Offset'} = $self->News_Count;
      $self->params( $hash );
   }
};

1;
