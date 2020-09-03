use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 3;
use Test::Warn;

use Config::Structured;

use experimental qw(signatures);

my $conf;
warnings_like {
  $conf = Config::Structured->new(
    structure => {
      core => {
        assets => {
          isa => 'Str'
        },
        logs => {
          isa => 'Str'
        },
        tmp => {
          isa => 'Str'
        },
      },
      auxiliary => {
        assets => {
          isa => 'Str'
        },
        tmp => {
          isa => 'Str'
        }
      }
    },
    config => {
      core => {
        assets => '/data/assets',
        logs   => '/data/logs',
        tmp    => '/data/tmp',
      },
      auxiliary => {
        assets => '/aux/assets',
        tmp    => '/aux/tmp',
      }
    },
    hooks => {
      '/core/*' => {
        on_load => sub ($path, $value) {
          warn("Directory '$value' does not exist at $path (load)");
        },
        on_access => sub ($path, $value) {
          warn("Touched a core dir");
        }
      },
      '/*/tmp' => {
        on_access => sub ($path, $value) {
          warn("Touched a tmp dir");
        }
      }
    }
  );
  $conf->core;
  $conf->auxiliary->assets;
}
[(qr{Directory '/data/\w+' does not exist at /core/\w+ \(load\)}) x 3,], 'on_load wildcard hook runs';

warning_is {$conf->auxiliary->tmp} "Touched a tmp dir", "on_access wildcard hook runs";

warnings_like {$conf->core->tmp} [(qr{Touched a (tmp|core) dir}) x 2], "on_access wildcard hooks run";
