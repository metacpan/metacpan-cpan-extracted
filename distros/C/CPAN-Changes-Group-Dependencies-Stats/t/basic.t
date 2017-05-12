use strict;
use warnings;

use Test::More tests => 53;
use Test::Differences;

# ABSTRACT: Basic comparison

use CPAN::Changes::Group::Dependencies::Stats;

{
  my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
    old_prereqs => {},
    new_prereqs => {},
  );

  eq_or_diff $diff->changes, [], 'No prereqs';
}
for my $phase (qw (  runtime build configure test develop )) {
  note "Beginning: $phase basics ]---";
  {
    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      new_prereqs => { $phase => { requires => { Moose => 0 } } },
      old_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: +1"], 'Simple add dep';
  }
  {

    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      new_prereqs => { $phase => { requires => { Moose => 0 }, recommends => { Moose => 1 } } },
      old_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: +1 (recommends: +1)"], 'Simple add recommends';
  }
  {

    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      new_prereqs => { $phase => { requires => { Moose => 0 }, suggests => { Moose => 1 } } },
      old_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: +1 (suggests: +1)"], 'Simple add suggests';
  }
  {
    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      new_prereqs => { $phase => { requires => { Moose => 0 }, suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } } },
      old_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: +1 (recommends: +1, suggests: +1)"], 'Simple add suggests+add recommends';
  }
  {
    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      new_prereqs => { $phase => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } } },
      old_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: (recommends: +1, suggests: +1)"], 'Simple add suggests+add recommends-requires';
  }

  note "Ending: $phase basics ]---";
  note "Beginning: $phase remove basics ]---";
  {
    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      old_prereqs => { $phase => { requires => { Moose => 0 } } },
      new_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: -1"], 'Simple remove dep';
  }
  {

    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      old_prereqs => { $phase => { requires => { Moose => 0 }, recommends => { Moose => 1 } } },
      new_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: -1 (recommends: -1)"], 'Simple remove recommends';
  }
  {

    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      old_prereqs => { $phase => { requires => { Moose => 0 }, suggests => { Moose => 1 } } },
      new_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: -1 (suggests: -1)"], 'Simple remove suggests';
  }
  {
    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      old_prereqs => { $phase => { requires => { Moose => 0 }, suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } } },
      new_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: -1 (recommends: -1, suggests: -1)"], 'Simple remove suggests+remove recommends';
  }
  {
    my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
      old_prereqs => { $phase => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } } },
      new_prereqs => {},
    );

    eq_or_diff $diff->changes, ["$phase: (recommends: -1, suggests: -1)"], 'Simple remove suggests+remove recommends-requires';
  }

  note "Ending: $phase remove basics ]---";
}
{
  my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
    old_prereqs => {
      runtime   => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } },
      develop   => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } },
      configure => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } },
      build     => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } },
      test      => { suggests => { Moose => 2 }, recommends => { 'Moose' => 1 } },
    },
    new_prereqs => {},
  );

  eq_or_diff $diff->changes, [
    "build: (recommends: -1, suggests: -1)",
    "configure: (recommends: -1, suggests: -1)",
    "develop: (recommends: -1, suggests: -1)",
    "runtime: (recommends: -1, suggests: -1)",
    "test: (recommends: -1, suggests: -1)",

    ],
    'Mulitremove';
}
{
  use utf8;
  my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
    old_prereqs => {
      runtime   => { suggests   => { Moose   => 2 }, recommends => { 'Moose' => 1 } },
      develop   => { suggests   => { Moose   => 2 }, recommends => { 'Moose' => 1 } },
      configure => { suggests   => { Moose   => 2 }, recommends => { 'Moose' => 1 } },
      build     => { recommends => { 'Moose' => 1 } },
      test      => { suggests   => { Moose   => 2 }, recommends => { 'Moose' => 1 } },
    },
    new_prereqs => {
      runtime   => { suggests   => { Moose   => 3 }, recommends => { 'Moose' => 0 } },
      develop   => { suggests   => { Moose   => 4 }, recommends => { 'Moose' => 0 } },
      configure => { recommends => { 'Moose' => 1 } },
      build     => { suggests   => { Moose   => 2 }, recommends => { 'Moose' => 1 } },
      test      => { suggests   => { Moose   => 2 }, recommends => { 'Moose' => 1 } },
    },
  );

  eq_or_diff $diff->changes,
    [
    "build: (suggests: +1)",
    "configure: (suggests: -1)",
    "develop: (recommends: \x{2193}1, suggests: \x{2191}1)",
    "runtime: (recommends: \x{2193}1, suggests: \x{2191}1)",
    ],
    'Mulitmix';

}
