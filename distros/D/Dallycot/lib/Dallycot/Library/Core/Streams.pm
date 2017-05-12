package Dallycot::Library::Core::Streams;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Core library of useful streams and stream functions

use strict;
use warnings;

use utf8;
use Dallycot::Library;

use Dallycot::Library::Core       ();
use Dallycot::Library::Core::Math ();

ns 'http://www.dallycot.net/ns/streams/1.0#';

uses 'http://www.dallycot.net/ns/core/1.0#', 'http://www.dallycot.net/ns/loc/1.0#';

define 'set-first' => '(s, sh) :> [sh, s... ]';

define 'set-rest' => "(s, st) :> [ s', st ]";

define 'insert-after' => "(s, m) :> [ s', m, s... ]";

define downfrom => '(n) :> (n..0)';

# define downfrom => <<'EOD';
# y-combinator(
#   (self, n) :> (
#     (n > 0) : [ n, ff(ff, n - 1) ]
#     (n = 0) : [ 0 ]
#     (     ) : [   ]
#   )
# )
# EOD

define 'last' => <<'EOD';
y-combinator(
  (self, stream) :> (
    (?(stream...)) : self(self, stream...)
    (            ) : stream'
  )
)
EOD

1;
