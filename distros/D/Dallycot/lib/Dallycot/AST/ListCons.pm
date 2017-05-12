package Dallycot::AST::ListCons;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Compose lambdas into a new lambda

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

my $FunctionURI = Dallycot::Value::URI->new("http://www.dallycot.net/ns/core/1.0#list-cons");

sub execute {
  my ( $self, $engine ) = @_;

  my(@streams) = @$self;

  my $value = pop @streams;
  while(@streams) {
    $value = Dallycot::AST::Apply->new(
      $FunctionURI,
      [ (pop @streams), $value ],
      {}
    );
  }
  return $engine->execute($value);
}

1;
