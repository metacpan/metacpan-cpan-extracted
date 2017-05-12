use strict;
use Test::More;

require q[./t/helper.pm];

local $SIG{__WARN__} = sub { };

for my $s (qw/perl install deploy/)
{
  is( App::MechaCPAN::main( '--diag-run', $s ), 0, "Ran $s with diag-run" );
}

done_testing;
