package Dallycot::AST::ForwardWalk;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Find the value associated with a property of a subject

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub step {
  my ( $self, $engine, $root ) = @_;

  return $engine->execute( $self->[0] )->then(
    sub {
      my ($prop_name) = @_;
      my $prop = $prop_name->value;

      return $root->type if $prop eq '@type';

      return $root->fetch_property( $engine, $prop )->then(
        sub {
          my (@results) = @_;

          if ( @results != 1 ) {
            return Dallycot::Value::Set->new(@results);
          }
          else {
            return @results;
          }
        }
      );
    }
  );
}

1;
