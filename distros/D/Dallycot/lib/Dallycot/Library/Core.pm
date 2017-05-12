package Dallycot::Library::Core;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Core library of useful functions

use strict;
use warnings;

use utf8;

use Dallycot::Library;

ns 'http://www.dallycot.net/ns/core/1.0#';

uses 'http://www.dallycot.net/ns/loc/1.0#';

define nest => <<'EOD';
y-combinator(
  (self, function, count) :> (
    (count > 3) : function . function . function . self(self, function, count-3)
    (count = 3) : function . function . function
    (count = 2) : function . function
    (count = 1) : function
    (         ) : { () }/1
  )
)
EOD

define 'list-cons' => <<'EOD';
y-combinator(
  (self, first, second) :> (
    (?first) : [ first', self(self, first..., second)]
    (      ) : second
  )
)
EOD

define
  length => (
  hold    => 0,
  arity   => 1,
  options => {},
  ),
  sub {
  my ( $engine, $options, $thing ) = @_;

  $thing->calculate_length($engine);
  };

1;
