package Bing::Search::Role::SearchRequest::UILanguage;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'UILanguage' => (
   is => 'rw',
   isa => 'Str',
   lazy_build => 1
);

sub _build_UILanguage { }

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_UILanguage) { 
      my $hash = $self->params;
      $hash->{UILanguage} = $self->UILanguage;
      $self->params( $hash );
   }
};

1;
