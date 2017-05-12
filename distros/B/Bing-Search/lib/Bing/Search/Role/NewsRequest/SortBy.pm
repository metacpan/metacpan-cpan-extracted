package Bing::Search::Role::NewsRequest::SortBy;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'News_SortBy' => (
   is => 'rw',
   lazy_build => 1
);

sub _build_News_SortBy { }

before 'News_SortBy' => sub {
   my( $self, $param ) = @_;
   return unless $param;
   unless( $param =~ /Date|Relevance/ ) { 
      croak "SortBy option $param is not valid.";
   }
};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_News_SortBy ) { 
      my $hash = $self->params;
      $hash->{'News.SortBy'} = $self->News_SortBy;
      $self->params( $hash );
   }
};

1;
