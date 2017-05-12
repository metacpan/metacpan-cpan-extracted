package Bing::Search::Role::TranslationRequest::TargetLanguage;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';

has 'Translation_TargetLanguage' => (
   is => 'rw',
   predicate => 'has_Translation_TargetLanguage'
);

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Translation_TargetLanguage ) { 
      my $hash = $self->params;

      $hash->{'Translation.TargetLanguage'} = $self->Translation_TargetLanguage;
      $self->params( $hash );
   }
};

1;
