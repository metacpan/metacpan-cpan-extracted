package Dallycot::AST::JSONArray;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Create JSON-LD graph from JSON

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use experimental qw(switch);

use Promises qw(deferred);

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->collect(@$self)->then(sub {
    my(@values) = @_;
    return \@values;
  });
}

1;
