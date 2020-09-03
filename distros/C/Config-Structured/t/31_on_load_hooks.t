use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 1;
use Test::Warn;

use Config::Structured;

use experimental qw(signatures);

warning_is {
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
}
"Directory '/data/tmp' does not exist at /paths/tmp (load)", 'on_access hook runs';
