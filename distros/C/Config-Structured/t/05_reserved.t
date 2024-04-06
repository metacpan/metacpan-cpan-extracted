use v5.26;
use warnings;

use Test2::V0;

use Config::Structured;

use experimental qw(signatures);

like(
  warning {
    Config::Structured->new(
      structure => {
        to_hash => {
          isa => 'HashRef'
        }
      },
      config => {
        to_hash => {key => 'value'}
      }
    )
  },
  qr/^Reserved token 'to_hash' found in structure definition. Skipping.../,
  'check use of to_hash'
);

like(
  warning {
    Config::Structured->new(
      structure => {
        reflect => {
          isa => 'Str'
        }
      },
      config => {
        reflect => 'mirror'
      }
    )
  },
  qr/^Reserved token 'reflect' found in structure definition. Skipping.../,
  'check use of reflect'
);

like(
  warning {
    Config::Structured->new(
      structure => {
        db => {
          isa => 'Str',
        },
        'db*' => {
          isa => 'Str'
        }
      },
      config => {
        db    => 'mariadb',
        'db*' => 'override',
      }
    )
  },
  qr/^Reserved token 'db[*]' found in structure definition. Skipping.../,
  'check use of end asterisk'
);

done_testing;
