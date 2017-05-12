package Bing::Search::Role::Result::DisplayUrl;
use Moose::Role;
use Moose::Util::TypeConstraints;

requires 'data';
requires '_populate';


has 'DisplayUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);


before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $display = delete $data->{DisplayUrl};
   $self->DisplayUrl( $display ) if $display;;
};


1;
