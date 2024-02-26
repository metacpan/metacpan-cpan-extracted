use strict;
use warnings qw(all);
use 5.022;

use Test2::V0;

use Config::Structured;

use experimental qw(signatures);

my $conf;
like(
  warning {
    $conf = Config::Structured->new(
      structure => {
        paths => {
          tmp => {
            isa => 'Str'
          }
        },
        activities => {
          something => {
            isa => 'Num'
          }
        }
      },
      config => {
        paths => {
          tmp => '/data/tmp'
        },
        activities => {
          something => 0
        }
      },
      hooks => {
        '/paths/tmp' => {
          on_access => sub ($path, $value) {
            warn("Directory '$value' does not exist at $path (access)");
          }
        }
      }
    );
    $conf->activities->something;
    $conf->paths->tmp;
  },
  qr{Directory '/data/tmp' does not exist at /paths/tmp \(access\)},
  'on_access hook runs'
);

like(
  warnings {
    $conf->paths->tmp;
    $conf->paths->tmp;
  },
  [(qr{Directory '/data/tmp' does not exist at /paths/tmp \(access\)}) x 2],
  "on_access hook runs twice"
);

done_testing;
