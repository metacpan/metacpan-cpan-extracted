use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 5;
use Test::Warn;

use Config::Structured;

my $conf = Config::Structured->new(
  structure => {
    labels => {
      isa => 'ArrayRef[Str]'
    },
    authz => {
      isa => 'Str'
    },
    other => {
      isa => 'Any'
    },
    bad => {
      isa => 'not a valid type'
    }
  },
  config => {
    labels => [qw(a b c)],
    authz  => {
      roles => {
        admin => [qw(APP admin)]
      }
    },
    other => [],
    bad   => 'abc'
  }
);

is(ref($conf->labels), 'ARRAY', 'Conf value is array');
warning_like {$conf->authz}{carped => qr/[[]Config::Structured\] Value 'HASH[(].*[)]' does not conform to type 'Str'/},
  'Conf value is not hash';

warning_is {$conf->other} undef, 'Conf value is any';

warning_like {$conf->bad}{carped => qr/\[Config::Structured\] Invalid typeconstraint '.*'. Skipping typecheck/}, 'Conf type is bad';
{
  local $SIG{__WARN__} = sub { };    # we've already checked this warning, so we suppress it for the next test
  is($conf->bad, 'abc', 'Bad typeconstraint value');
}
