use v5.26;
use warnings;

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
  qr{Config::Structured invalid typeconstraint 'not a valid type' for cfg path /bad},
  'Invalid typeconstraint not caught'
);

is($conf->bad, undef, 'Bad typeconstraint value');

like(
  warning {
    $conf = Config::Structured->new(
      structure => {authz => {isa => 'HashRef'}},
      config    => {authz => 'authz value'},
    );
  },
  qr{Config::Structured value "authz value" does not conform to type 'HashRef' for cfg path /authz},
  'Incorrect typeconstraint not caught'
);

done_testing;
