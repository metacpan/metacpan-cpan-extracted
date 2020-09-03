use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 2;
use Test::Warn;

use Config::Structured;

use experimental qw(signatures);

my $conf;
warning_is {
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
}
"Directory '/data/tmp' does not exist at /paths/tmp (access)", 'on_access hook runs';

warnings_are {
  $conf->paths->tmp;
  $conf->paths->tmp;
}
[("Directory '/data/tmp' does not exist at /paths/tmp (access)") x 2], "on_access hook runs twice"
