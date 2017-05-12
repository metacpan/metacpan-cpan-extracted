package Bing::Search::Role::Result::OnTimeString;
use Moose::Role;
requires 'data';
requires '_populate';

has 'OnTimeString' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{OnTimeString};
   $self->OnTimeString( $item );
};

1;
