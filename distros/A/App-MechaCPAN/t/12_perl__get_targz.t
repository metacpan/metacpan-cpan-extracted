use strict;
use FindBin;
use Test::More;

require q[./t/helper.pm];

if( $^O eq 'MSWin32' )
{
  plan skip_all => 'Cannot build perl on Win32';
}

my %tests = (
  '5.12' => qr/perl-5[.]12[.]5[.]tar/,
);

foreach my $test ( keys %tests )
{
  like(
    (App::MechaCPAN::Perl::_get_targz($test))[0], $tests{$test},
    "Got a good version for '$test'"
  );
}

done_testing;
