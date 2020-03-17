use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 1;

use Config::Structured;

my $conf = Config::Structured->new(
  structure => <<'END'
paths:
  tmp:
    isa: Str
    default: /tmp
END
  , config => <<'END'
{
}
END
);

is($conf->paths->tmp, '/tmp', 'Conf value from default');
