package Bing::Search::Role::SearchRequest::Adult;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Adult' => (
   is => 'rw',
   lazy_build => 1
);

sub _build_Adult { } 

before 'Adult' => sub { 
   my $self = shift;
   return unless @_;
    my $param = shift;
   unless( $param =~ /off|moderate|strict/i ) { 
      croak "In setting 'Adult', valid options are: off, moderate, strict.  Got $param";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Adult ) { 
      my $hash = $self->params;
      $hash->{Adult} = $self->Adult;
      $self->params( $hash );
   }
};

1;
