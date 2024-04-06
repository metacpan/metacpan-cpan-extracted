use v5.26;
use warnings;

use Test2::V0;

use Config::Structured;

$ENV{APP_PASSWORD} = 's3cret';

my $conf = Config::Structured->new(
  structure => {
    db => {
      user => {
        isa     => 'Str',
        default => 'tyrrminal',
      },
      pass => {
        isa => 'Str',
      },
      port => {
        isa => 'Str|Undef'
      }
    },
    email => {
      migration => {
        user => {
          isa     => 'Str',
          default => 'sqitch',
        },
      },
      from => {
        isa     => 'Str',
        default => 'mark@tyrrminal.dev'
      }
    }
  },
  config => {
    db => {
      pass => {
        source => 'env',
        ref    => 'APP_PASSWORD'
      }
    }
  }
);

my $expected = <<'END';
db =>
  pass => "s3cret"
  port => undef
  user => "tyrrminal"
email =>
  from => "mark@tyrrminal.dev"
  migration =>
    user => "sqitch"
END
is(
  $conf->to_hash, {
    db => {
      pass => "s3cret",
      port => undef,
      user => "tyrrminal"
    },
    email => {
      from      => 'mark@tyrrminal.dev',
      migration => {
        user => 'sqitch'
      }
    }
  },
  'test dump conf'
);

done_testing;
