package Bing::Search::Role::SearchRequest::Version;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'Version' => (
   is => 'rw',
   isa => 'Str',
   lazy_build => 1
);

sub _build_has_Version { '2.1' }

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Version ) { 
      my $hash = $self->params;
      $hash->{Version} = $self->Version;
      $self->params( $hash );
   }
};

1;
