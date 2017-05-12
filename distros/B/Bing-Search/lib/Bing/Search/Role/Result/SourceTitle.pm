package Bing::Search::Role::Result::SourceTitle;
use Moose::Role;
requires 'data';
requires '_populate';

has 'SourceTitle' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{SourceTitle};
   $self->SourceTitle( $item );
};

1;
