#!perl

use Test::Cmd;
use Test::Most;

my $deeply = \&eq_or_diff;

my $test_prog = './vov';
my $tc        = Test::Cmd->new(
  interpreter => $^X,
  prog        => $test_prog,
  verbose     => 0,            # TODO is there a standard ENV to toggling?
  workdir     => '',
);

# NOTE XXX TODO FIXME the * in the command arguments may fail, and
# certainly only work by accident. Need to figure out how to get shell
# metachars through Test::Cmd; the * here (should, in theory) not match
# anything and thus per POSIX shell behavior (unless zsh) pass the * on
# through unadulterated, unless you create say an i* filename in the
# root directory of this distribution. With this in mind...
my @tests = (
  { args     => 'I',
    expected => [q{c e g}],
  },
  { args     => 'I6',
    expected => [q{e g c}],
  },
  { args     => 'I64',
    expected => [q{g c e}],
  },
  { args     => '--raw I',
    expected => [q{0 4 7}],
  },
  { args     => 'II',
    expected => [q{d fis a}],
  },
  { args     => '--flats bII6',
    expected => [q{f aes des}],
  },
  { args     => '--natural II',
    expected => [q{d f a}],
  },
  { args     => '--minor --natural I',
    expected => [q{c dis g}],
  },
  { args     => '--flats III',
    expected => [q{e aes b}],
  },
  { args     => 'V7',
    expected => [q{g b d f}],
  },
  { args     => 'V65',
    expected => [q{b d f g}],
  },
  { args     => 'V43',
    expected => [q{d f g b}],
  },
  { args     => 'V2',
    expected => [q{f g b d}],
  },
  { args     => '--natural vii',
    expected => [q{b d f}],
  },
  # XXX VII is tricky; this is what I intuit should happen without the
  # --natural flag involved, though it does break out of the mode.
  # XXX also must test inversions of VII and whatnot
  { args     => 'vii*',
    expected => [q{b d f}],
  },
  # { args => 'vii',
  #   expected => [q{b d fis}],
  # },
  # { args => 'VII',
  #   expected => [q{b dis fis}],
  # },
  # XXX oh also bvii is bad, that diminishes itself, which I would only
  # expect to happen to bvii*

  # and now transpositions
  { args     => '--transpose=g I',
    expected => [q{g b d}],
  },
  { args     => '--transpose=7 I',
    expected => [q{g b d}],
  },
  { args     => '--flats --transpose=g i',
    expected => [q{g bes d}],
  },
  { args     => '--transpose=b --mode=locrian i',
    expected => [q{b d f}],
  },
  { args     => '--transpose=b --mode=locrian II',
    expected => [q{c e g}],
  },
  { args     => '--transpose=b --mode=locrian Vb',
    expected => [q{a c f}],
  },
  { args     => 'I V7/IV IV V',
    expected => [ q{c e g}, q{c e g b}, q{f a c}, q{g b d} ],
  },
  { args     => '--factor=7 IV',
    expected => [q{f a c e}],
  },
  { args     => '--outputtmpl=%{vov} I',
    expected => [q{I}],
  },
  { args     => '--outputtmpl=x%{chord}x I13g',
    expected => [q{xa c e g b d fx}],
  },
  { args     => '--flats i7**',
    expected => [q{c ees g bes}],
  },
  { args     => 'I+',
    expected => [q{c e gis}],
  },
  { args     => 'i*',
    expected => [q{c dis fis}],
  },
  # XXX think about what I* would mean...major 3rd but dim 5th? or throw
  # exception for unknown chord?
  #{ args => 'I*',
  #  expected => [q{c ? fis}],
  #},
);

plan tests => @tests * 2;

for my $test (@tests) {
  $tc->run( args => $test->{args} );
  $deeply->(
    [ map { s/\s+$//r } $tc->stdout ],
    $test->{expected}, "$test_prog $test->{args}"
  );
  is( $tc->stderr, "", "$test_prog $test->{args} emits no stderr" );
}
