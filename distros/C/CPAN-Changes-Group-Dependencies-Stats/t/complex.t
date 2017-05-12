use strict;
use warnings;

use Test::More tests => 1;
use Test::Differences;

# ABSTRACT: Complex comparison

use CPAN::Changes::Group::Dependencies::Stats;
{
  my $diff = CPAN::Changes::Group::Dependencies::Stats->new(
    old_prereqs => {
      runtime => { requires => { Moose => '>= 4.0, <= 5.0' } },
    },
    new_prereqs => {
      runtime => { requires => { Moose => '>= 3.0, <= 5.0' } },
    },
  );

  eq_or_diff $diff->changes, ["runtime: ~1"], 'Complex deps changed.';
}
