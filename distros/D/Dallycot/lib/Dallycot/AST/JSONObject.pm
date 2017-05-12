package Dallycot::AST::JSONObject;
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
    my(%properties) = @_;
    return Dallycot::Value::JSON->new(\%properties);
  });
}

1;
