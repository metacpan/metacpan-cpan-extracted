package Bing::Search::Role::Result::TranslatedTerm;
use Moose::Role;
requires 'data';
requires '_populate';

has 'TranslatedTerm' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{TranslatedTerm};
   $self->TranslatedTerm( $item );
};

1;
