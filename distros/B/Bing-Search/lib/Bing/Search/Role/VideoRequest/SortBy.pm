package Bing::Search::Role::VideoRequest::SortBy;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Video_SortBy' => (
   is => 'rw',
   lazy_build => 1
);

sub _build_Video_SortBy { }

before 'Video_SortBy' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param =~ /Date|Relevance/ ) { 
      croak "SortBy option $param is not valid.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Video_SortBy ) { 
      my $hash = $self->params;
      $hash->{'Video.SortBy'} = $self->Video_SortBy;
      $self->params( $hash );
   }
};

1;
