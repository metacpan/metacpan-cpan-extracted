package AI::Categorizer::Document::Text;

use strict;
use AI::Categorizer::Document;
use base qw(AI::Categorizer::Document);

#use Params::Validate qw(:types);
#use AI::Categorizer::ObjectSet;
#use AI::Categorizer::FeatureVector;

### Constructors

sub parse {
  my ($self, %args) = @_;
  $self->{content} = { body => $args{content} };
}

1;
