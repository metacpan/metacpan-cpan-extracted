package Bing::Search::Role::TranslationRequest::SourceLanguage;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';

has 'Translation_SourceLanguage' => (
   is => 'rw',
   predicate => 'has_Translation_SourceLanguage'
);

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Translation_SourceLanguage ) { 
      my $hash = $self->params;
      $hash->{'Translation.SourceLanguage'} = $self->Translation_SourceLanguage;
      $self->params( $hash );
   }
};

1;
