use strict;
use FindBin;
use Test::More;

require q[./t/helper.pm];

if( $^O eq 'MSWin32' )
{
  plan skip_all => 'Cannot build perl on Win32';
}

is(
  App::MechaCPAN::main(
    'perl',
    "$FindBin::Bin/../test_dists/FakePerl-5.12.0.tar.gz"
  ),
  0,
  'Can install "perl" from a tar.gz'
);

done_testing;
