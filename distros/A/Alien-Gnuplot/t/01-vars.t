#===============================================================================
#
#         FILE: 01-vars.t
#
#  DESCRIPTION: Check variables match intended formats
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
#
#===============================================================================

use strict;
use warnings;

use Alien::Gnuplot;
use Test::More tests => 12;

my $exec = $Alien::Gnuplot::executable;
ok (defined $exec, 'executable defined');
ok (length ($exec), 'executable path not empty');

my $version = $Alien::Gnuplot::version;
ok (defined $version, 'version defined');
ok (length ($version), 'version not empty');
like ($version, qr/^[\d.]+$/, 'version looks like version string');

my $pl = $Alien::Gnuplot::pl;
ok (defined $pl, 'patch level defined');
ok (length ($pl), 'patch level not empty');
like ($pl, qr/^\d+$/, 'patch level looks like patch level string');

my @terms = @Alien::Gnuplot::terms;
ok (scalar @terms, 'terms not empty');

my %terms = %Alien::Gnuplot::terms;
is (scalar @terms, scalar keys %terms, '%terms has correct number of entries');

my @hues = @Alien::Gnuplot::colors;
ok (scalar @hues, 'colors not empty');

my %hues = %Alien::Gnuplot::colors;
is (scalar @hues, scalar keys %hues, '%colors has correct number of entries');
