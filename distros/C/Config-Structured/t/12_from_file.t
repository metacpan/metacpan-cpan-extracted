use v5.26;
use warnings;

use Test2::V0;

use Config::Structured;

my $conf = Config::Structured->new(
  structure => {
    file_value => {
      isa => 'Str'
    }
  },
  config => {
    file_value => {
      source => 'file',
      ref    => 't/data/app_password'
    }
  }
);

is($conf->file_value, 'secure_password123', 'Conf value from referenced file');

done_testing;
