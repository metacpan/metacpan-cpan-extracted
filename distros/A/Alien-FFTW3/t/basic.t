use strict;
use warnings;

use Test::More tests=>3;
use Text::ParseWords qw/shellwords/;

BEGIN { use_ok( 'Alien::FFTW3' ); }

my %libs = map { $_=>1 } shellwords( Alien::FFTW3->libs );
ok(defined($libs{'-lfftw3'}),'libfftw3 defined');

my $p = Alien::FFTW3->precision();
ok( (ref $p eq 'HASH') && ((keys %$p) >= 1), 'precision() returned a useful hash ref');
