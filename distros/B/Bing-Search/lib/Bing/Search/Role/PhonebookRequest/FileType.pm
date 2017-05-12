package Bing::Search::Role::PhonebookRequest::FileType;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Phonebook_FileType' => (
   is => 'rw',
   isa => 'Str',
   predicate => 'has_Phonebook_FileType'
);

has '_supported_Phonebook_FileTypes' => (
   is => 'rw',
   isa => 'HashRef',
   default => sub { 
       return { map { $_ => 1 } qw( YP WP ) };
   }
);

around 'Phonebook_FileType' => sub { 
   my $next = shift;
   my( $self, $param ) = @_;
   my $supported = $self->_supported_Phonebook_FileTypes;
   if( $param ) {    
      if( exists $supported->{$param} ) { 
         $self->$next( $param );
      } else { 
         carp "Unsupported file type $param -- ignoring.";
      }
   }

};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Phonebook_FileType ) { 
      my $hash = $self->params;
      $hash->{'Phonebook.FileType'} = $self->Phonebook_FileType;
      $self->params( $hash );
   }
};

1;
