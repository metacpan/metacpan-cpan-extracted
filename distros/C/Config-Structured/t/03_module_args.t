use v5.26;
use warnings;

use Test2::V0;

use Config::Structured;

like(
  dies {
    my $conf = Config::Structured->new(config => {});
  },
  qr/structure is a required parameter/,
  "Unspecified structure"
);

like(
  dies {
    my $conf = Config::Structured->new(structure => {});
  },
  qr/config is a required parameter/,
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
