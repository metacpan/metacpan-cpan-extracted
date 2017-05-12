
use strict;
use warnings;

use Test::More tests => 8;

use Test::Fatal;
use Data::Handle;

use lib 't/lib';
use Data;

my $handle;
my $e;

is(
  $e = exception {
    $handle = Data::Handle->new('Data');
  },
  undef,
  "->new on a valid package with an Data works"
);

isnt(
  $e = exception {
    $handle = Data::Handle->new('Data_Not_There');
  },
  undef,
  "->new on a valid package with an Data_Not_There asplodes"
);

isa_ok( $e, 'Data::Handle::Exception' );
diag( "\n\n** This is an example Exception, isn't it pretty?\n\n" . $e );

$handle = Data::Handle->new('Data');

seek $handle, -9, 0;

my $buffer;

read $handle, $buffer, 8, 0;

is( $buffer, '__DATA__', 'seek and read work properly on new instances' );

is(
  do {
    $handle = Data::Handle->new('Data');
    local $/ = undef;
    scalar <$handle>;
  },
  qq{Hello World.\n\n\nThis is a test file.\n},
  'Slurp contents works'
);

my ( $left,       $right );
my ( $leftreader, $rightreader );

is(
  $e = exception {

    $leftreader  = Data::Handle->new('Data');
    $rightreader = Data::Handle->new('Data');

    while ( !eof($leftreader) ) {
      $left  .= <$leftreader>;
      $right .= <$rightreader>;
    }

  },
  undef,
  'Dual Reading lives'
);

is( $left,            $right,            'Left and Right dual-read outputs are the same' );
is( tell $leftreader, tell $rightreader, 'Left and right dual-read are at the same position after reading' );
