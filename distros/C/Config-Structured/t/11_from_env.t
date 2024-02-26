use strict;
use warnings qw(all);
use 5.022;

use Test2::V0;

use Config::Structured;

$ENV{APP_DB_PASSWORD} = 'secure_password123';

my $conf = Config::Structured->new(
  structure => <<'END'
file_value:
  isa: Str
END
  , config => <<'END'
{
  "file_value": {
    "source": "env",
    "ref": "APP_DB_PASSWORD"
  }
}
END
);

is($conf->file_value, 'secure_password123', 'Conf value from referenced file');

done_testing;
