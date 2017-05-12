package Bing::Search::Role::PhonebookRequest::SortBy;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Phonebook_SortBy' => (
   is => 'rw',
   lazy_build => 1
);

sub _build_Phonebook_SortBy { }

before 'Phonebook_SortBy' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param =~ /Default|Distance|Relevance/ ) { 
      croak "SortBy option $param is not valid.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Phonebook_SortBy ) { 
      my $hash = $self->params;
      $hash->{'Phonebook.SortBy'} = $self->Phonebook_SortBy;
      $self->params( $hash );
   }
};

1;
