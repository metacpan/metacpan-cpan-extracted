package # hide from PAUSE
  PPM::Reps;
use strict;
use warnings;
our $VERSION = 0.1;

use base qw(Exporter);
our (@EXPORT_OK, $reps);
@EXPORT_OK = qw($reps);

$reps = {
         crazy56 => {
                     location => 'http://crazyinsomniac.perlmonk.org/perl/ppm',
                     desc => 'crazyinsomniac Perl 5.6 repository',
                     PerlV         => 5.6,
                    },
         crazy58 => {
                     location => 'http://crazyinsomniac.perlmonk.org/perl/ppm/5.8',
                     desc => 'crazyinsomniac Perl 5.8 repository',
                     PerlV         => 5.8,
              },
         uwinnipeg56 => {
                         location => 'http://theoryx5.uwinnipeg.ca/ppmpackages',
                         desc => 'uwinnipeg Perl 5.6 repository',
                         PerlV => 5.6,
              },
         uwinnipeg58 => {
                         location => 'http://theoryx5.uwinnipeg.ca/ppms',
                         desc => 'uwinnipeg Perl 5.8 repository',
                         PerlV => 5.8,
              },
         AS58 => {
                  location => 'http://ppm.activestate.com/BuildStatus/5.8-A.html',
                  desc => 'ActiveState default Perl 5.8 repository',
                  PerlV => 5.8,
                 },
         AS56 => {
                  location => 'http://ppm.activestate.com/BuildStatus/5.6-A.html',
                  desc => 'ActiveState default Perl 5.6 repository',
                  PerlV  => 5.6,
                 },
         bribes56 => {
                      location => 'http://www.bribes.org/perl/ppm',
                      desc => 'www.bribes.org Perl 5.6 repository',
                      PerlV  => 5.6,
              },
         bribes58 => {
                      location => 'http://www.bribes.org/perl/ppm',
                      desc => 'www.bribes.org Perl 5.8 repository',
                      PerlV  => 5.8,
                     },
        };

1;
