package Bing::Search::Role::PhonebookRequest::Count;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Phonebook_Count' => (
   is => 'rw',
   isa => 'Str',
   lazy_build => 1
);

sub _build_Phonebook_Count { }

before 'Phonebook_Count' => sub { 
   my( $self, $param ) = @_;
   if( $param && $param <= 1 && $param >= 25 ) { 
      croak "Phonebook.Count must be between 1 and 25.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Phonebook_Count ) { 
      my $hash = $self->params;
      $hash->{'Phonebook.Count'} = $self->Phonebook_Count;
      $self->params( $hash );
   }
};

1;
