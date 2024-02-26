use strict;
use warnings qw(all);
use 5.022;

use Test2::V0;

use Config::Structured;

like(
  warning {
    my $conf = Config::Structured->new(
      structure => {
        _config => {
          isa => 'Str'
        }
      },
      config => {
        _config => 'hello world',
      }
    );
    $conf->_config
  },
  qr/\[Config::Structured\] Reserved word '_config' used as config node name: ignored/,
  'Reserved word used'
);

ok(
  no_warnings {
    my $conf = Config::Structured->new(
      structure => {
        config => {
          isa => 'Str'
        }
      },
      config => {
        config => 'hello world',
      }
    );
    $conf->config
  },
  'No reserved word used'
);

done_testing;
