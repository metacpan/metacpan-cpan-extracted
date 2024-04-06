use v5.26;
use warnings;

use Test2::V0;

use Config::Structured;

use experimental qw(signatures);

like(
  warning {
    my $conf = Config::Structured->new(
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
          on_load => sub ($path, $value) {
            warn("Directory '$value' does not exist at $path (load)");
          }
        }
      }
    );
    $conf->activities->something;
    $conf->paths->tmp;
  },
  qr{Directory '/data/tmp' does not exist at /paths/tmp \(load\)},
  'on_access hook runs'
);

done_testing;
