use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

if ( !&App::MechaCPAN::can_https )
{
  plan skip_all => 'Cannot test can_https without https';
}

my @all_methods = sort grep { $_ ne 'iosock' } map {@$_} values %$File::Fetch::METHODS;
diag "@all_methods";

{
  local $File::Fetch::BLACKLIST = [@all_methods];

  is( &App::MechaCPAN::can_https, '', 'Using only iosock fails' );
}

is( &App::MechaCPAN::can_https, 1, 'Reverting blacklist allows it to return to normal' );

done_testing;
