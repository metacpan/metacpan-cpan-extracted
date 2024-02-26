use strict;
use warnings qw(all);
use 5.022;

use Test2::V0;

use Config::Structured;

my $conf = Config::Structured->new(
  structure => {labels => {isa => 'ArrayRef[Str]'},},
  config    => {labels => [qw(a b c)],}
);
is(ref($conf->labels), 'ARRAY', 'Conf value is array');

like(
  warning {
    $conf = Config::Structured->new(
      structure => {bad => {isa => 'not a valid type'}},
      config    => {bad => 'abc'},
    );
  },
  qr{\[Config::Structured\] Invalid typeconstraint 'not a valid type'. Skipping typecheck},
  'Invalid typeconstraint not caught'
);

is($conf->bad, 'abc', 'Bad typeconstraint value');

like(
  warning {
    $conf = Config::Structured->new(
      structure => {authz => {isa => 'HashRef'}},
      config    => {authz => 'authz value'},
    );
  },
  qr{\[Config::Structured\] Value '"authz value"' does not conform to type 'HashRef' for node /authz},
  'Incorrect typeconstraint not caught'
);

done_testing;
