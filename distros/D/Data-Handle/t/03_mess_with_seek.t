use strict;
use warnings;

use Test::More tests => 3;

use Test::Fatal;
use Data::Handle;

use lib 't/lib';
use Data;

my $fh = do { no strict; \*{'Data::DATA'} };
seek $fh, 10, 1;

my ( $handle, $e );

isnt(
  $e = exception {
    $handle = Data::Handle->new('Data'),;
  },
  undef,
  'Fails is somebody has already seeked'
);

isa_ok( $e, 'Data::Handle::Exception::BadFilePos', 'Expected Exception Type' );
isa_ok( $e, 'Data::Handle::Exception',             'Expected Exception Type' );
