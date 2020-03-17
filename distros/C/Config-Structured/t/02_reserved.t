use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 2;
use Test::Warn;

use Config::Structured;

warning_is {
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
}
{carped => '[Config::Structured] Reserved word \'_config\' used as config node name: ignored'}, 'Reserved word used';

warning_is {
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
}
undef, 'No reserved word used';
