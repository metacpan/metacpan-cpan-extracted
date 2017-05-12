use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use AnyEvent;
use Promises backend => ['AnyEvent'];

use Scalar::Util qw(blessed);

use Dallycot;
use Dallycot::Compiler;
use Dallycot::Parser;
use Dallycot::Processor;

BEGIN {
  require Dallycot::Library;
  Dallycot::Library->libraries;
}

BEGIN { use_ok 'Dallycot::Compiler' };

my $parser = Dallycot::Parser->new;

my $result;

$result = compile(<<'EOD');
even?(n) :> n mod 2 = 0;
evens := Y((f, s) :> (
  (even?(s')) : [ s', f(f, s...) ]
  (         ) :       f(f, s...)
))
EOD

$result = compile(<<'EOD');
uses "http://www.dallycot.net/ns/core/1.0#";
uses "http://www.dallycot.net/ns/math/1.0#";
uses "http://www.dallycot.net/ns/streams/1.0#";

primes[50]
EOD

done_testing();

sub compile {
  my($stmt) = @_;

  my $parse = $parser -> parse($stmt);

  my $model = Dallycot::Compiler -> new;
  my $root = $model -> compile(@$parse);
  return $model -> as_turtle();
}
