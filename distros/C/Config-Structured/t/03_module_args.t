use strict;
use warnings qw(all);
use 5.022;

use Test2::V0;

use Config::Structured;

like(
  dies {
    my $conf = Config::Structured->new(config => {});
  },
  qr/Attribute \(_structure_v\), passed as \(structure\), is required/,
  "Unspecified structure"
);

like(
  dies {
    my $conf = Config::Structured->new(structure => {});
  },
  qr/Attribute \(_config_v\), passed as \(config\), is required/,
  "Unspecified config"
);

ok(
  no_warnings {
    my $conf = Config::Structured->new(
      structure => {
        element => {
          isa => 'Str'
        }
      },
      config => {
        element => 'hello world',
      },
      hooks => undef,
    );
    $conf->element;
  },
  "Undefined hooks"
);

done_testing;
