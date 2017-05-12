package Dallycot::Util;
our $AUTHORITY = 'cpan:JSMITH';

use utf8;
use strict;
use warnings;

use Exporter 'import';

use Promises qw(deferred);
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(
  maybe_promise
);

sub maybe_promise {
  my ($p) = @_;

  if ( blessed $p) {
    if ( $p->can('promise') ) {
      return $p->promise;
    }
    elsif ( $p->can('then') ) {
      return $p;
    }
  }

  my $d = deferred;
  $d->resolve($p);
  return $d->promise;
}

1;
