package Dallycot::AST::PropertyLit;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A property literal or name

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  my ( $ns, $prop ) = @$self;

  if ( !defined $prop ) {
    $d->resolve( Dallycot::Value::String->new( $ns, '' ) );
  }
  elsif ( $engine->has_namespace($ns) ) {
    my $nshref = $engine->get_namespace($ns);
    $d->resolve( Dallycot::Value::URI->new( $nshref . $prop ) );
  }
  else {
    $d->reject("Undefined namespace '$ns'");
  }

  return $d->promise;
}

1;
