package Bing::Search::Role::PhonebookRequest::Offset;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';
requires 'Phonebook_Count';

has 'Phonebook_Offset' => (
   is => 'rw',
   isa => 'Num',
   predicate => 'has_Phonebook_Offset'
);

before 'Phonebook_Offset' => sub { 
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param <= 1000 && $param >= 0 ) { 
      croak "Phonebook.Offset value of $param must be between 0 and 1,000.";      
   }
   if( $self->Phonebook_Count + $param > 1000 ) { 
      croak "The sum of Phonebook.Count and Phonebook.Offset may not exceed 1,000.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Phonebook_Offset ) { 
      my $hash = $self->params;
      $hash->{'Phonebook.Offset'} = $self->Phonebook_Count;
      $self->params( $hash );
   }
};

1;
