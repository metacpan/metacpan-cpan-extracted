package Bing::Search::Role::PhonebookRequest::LocId;
use Moose::Role;

requires 'build_request';
requires 'params';


has 'Phonebook_LocId' => (
   is => 'rw',
   isa => 'Str',
   lazy_build => 1
);

sub _build_Phonebook_LocId { }

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Phonebook_LocId ) { 
      my $hash = $self->params;
      $hash->{'Phonebook.LocId'} = $self->Phonebook_LocId;
      $self->params( $hash );
   }
};

1;
