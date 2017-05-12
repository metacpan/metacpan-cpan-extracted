package Bing::Search::Role::SearchRequest::AppId;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'AppId' => (
   is => 'rw',
   isa => 'Str',
   default => '70960FEFD7F90995151FCF92D6422BEB644AACE2',
   required => 1
);

before 'build_request' => sub { 
   my $self = shift;
   my $hash = $self->params;
   $hash->{AppId} = $self->AppId;
   $self->params( $hash );
};

1;
