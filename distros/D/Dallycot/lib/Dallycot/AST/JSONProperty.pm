package Dallycot::AST::JSONProperty;
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

  return $engine->execute($self->[1])->then(sub {
    my($value) = @_;

    return ($self->[0], $value);
  });
}

1;
