use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 4;
use Test::Warn;

use Config::Structured;

my $conf = Config::Structured->new(
  structure => {labels => {isa => 'ArrayRef[Str]'},},
  config    => {labels => [qw(a b c)],}
);
is(ref($conf->labels), 'ARRAY', 'Conf value is array');

warning_is {
  $conf = Config::Structured->new(
    structure => {bad => {isa => 'not a valid type'}},
    config    => {bad => 'abc'},
  );
}
{carped => q{[Config::Structured] Invalid typeconstraint 'not a valid type'. Skipping typecheck},},
  'Invalid typeconstraint not caught';

is($conf->bad, 'abc', 'Bad typeconstraint value');

warning_is {
  $conf = Config::Structured->new(
    structure => {authz => {isa => 'HashRef'}},
    config    => {authz => 'authz value'},
  );
}
{carped => q{[Config::Structured] Value '"authz value"' does not conform to type 'HashRef' for node /authz},},
  'Incorrect typeconstraint not caught';
