#!perl

use Test::Cmd;
use Test::Most;    # plan calculated down at bottom

my $deeply = \&eq_or_diff;

my $test_prog = './canonical';
my $tc        = Test::Cmd->new(
  interpreter => $^X,
  prog        => $test_prog,
  verbose     => 0,            # TODO is there a standard ENV to toggling?
  workdir     => '',
);

# Tests via only command line arguments, as this form of invocation is
# handled differently from the data-in-on-stdin case, below.
my @arg_only_tests = (
  # exact mode tests
  { args     => '--relative=c exact --transpose=7 0 4 7',
    expected => [qw{g b d}],
  },
  { args     => 'exact --transpose=7 c e g',
    expected => [qw{g b d'}],
  },
  { args     => 'exact --transpose=g c e g',
    expected => [qw{g b d'}],
  },
  { args     => '--raw exact --transpose=g c e g',
    expected => [qw{55 59 62}],
  },
  { args     => '--relative=c exact --contrary c f g e a c',
    expected => [qw{c g f gis dis c}],
  },
  { args     => '--raw exact --retrograde 1 2 3',
    expected => [qw{3 2 1}],
  },
  { args     => '--flats exact --transpose=1 c e g',
    expected => [qw{des f aes}],
  },

  # modal tests - mostly just copied from Music-Canon/t/Music-
  # Canon.t cases.
  { args     => '--relative=c modal --contrary  0 13',
    expected => [qw{c x}],
  },
  { args     => '--relative=c modal --contrary --undef=q 0 8',
    expected => [qw{c q}],
  },
  { args     => 'modal --contrary --retrograde --raw 0 2 4 5 7 9 11 12 14 16 17 19',
    expected => [qw{-19 -17 -15 -13 -12 -10 -8 -7 -5 -3 -1 0}],
  },
  { args     => '--rel=c modal --flats --sp=c --ep=bes --output=1,4,1,4 c cis d',
    expected => [qw{bes x b}],
  },
  { args     => '--rel=c modal --flats --sp=c --ep=aes --output=2,1,4,1 c cis d',
    expected => [qw{aes a bes}],
  },
  { args     => '--rel=c modal --flats --sp=c --ep=b --output=4,1,4,2 c cis d',
    expected => [qw{b des ees}],
  },
  { args =>
      '--rel=c modal --chrome=-1 --flats --sp=c --ep=b --output=4,1,4,2 c cis d',
    expected => [qw{b c ees}],
  },
  { args =>
      '--rel=c modal --chrome=1 --flats --sp=c --ep=b --output=4,1,4,2 c cis d',
    expected => [qw{b d ees}],
  },
  # rhythmic foo
  { args =>
      '--rel=c modal --chrome=1 --flats --sp=c --ep=b --output=4,1,4,2 c8.. cis32 d4',
    expected => [qw{b8.. d32 ees4}],
  },
  { args     => '--relative=c modal --retrograde c16 d8. e4 f g',
    expected => [qw{g4 f e d8. c16}],
  },
  # transpositions tricky
  { args     => 'modal --transpose=3 --flats --input=minor --output=minor g f ees',
    expected => [qw{bes a g}],
  },
);

# Only the first column is considered when the notes arrive via stdin
# (this allows the subsequent columns to bear other data, such as
# lyrics, cat photos, etc.) Multicolumn output will also be enabled if
# the --map flag is used.
my @stdin_tests = (
  # Either "no remaining arguments" or "ultimate argument is a -" should
  # be supported.
  { args => '--rel=c modal --chrome=1 --flats --sp=c --ep=b --output=4,1,4,2',
    # TODO is newline portable to e.g. Win32, or is $/ or such necessary?
    stdin    => join( "\n", qw{c cis d} ),
    expected => [qw{b d ees}],
  },
  { args => 'modal --rel=c --chrome=1 --flats --sp=c --ep=b --output=4,1,4,2 -',
    # also how is trailing-newline vesus no-EOF-EOL case handled?
    stdin    => join( "\n", qw{c cis d} ) . "\n",
    expected => [qw{b d ees}],
  },
  # if multicolumn, not-first-column data should be unchanged
  { args  => 'exact --transpose=c',
    stdin => join( "\n", "0 4. f", "2 8 p", "4 4 ff" ),
    expected => [ "c 4. f", "d 8 p", "e 4 ff" ],
  },
  { args  => 'exact --transpose=c --retrograde',
    stdin => join( "\n", "0 4. f", "2 8 p", "4 4 ff" ),
    expected => [ "e 4 ff", "d 8 p", "c 4. f" ],
  },
  # Hindemith overtone ordering in G for something more complicated
  # (also complicated is how to run ' in commands through Test::Cmd
  # which here is dodged by supplying that input instead via stdin).
  { args  => q{--relative=g --contrary --retrograde exact},
    stdin => join( "\n",
      "g", "d'", "c", "e", "b", "bes", "ees", "a,", "f'", "aes,", "fis'", "cis" ),
    expected =>
      [ "cis", "gis", "fis'", "a,", "f'", "b,", "e", "dis", "ais", "d", "c", "g'" ],
  },
  # and also rhythmic alterations!
  { args  => q{--relative=g --contrary --retrograde exact},
    stdin => join( "\n",
      "g4",  "d'8.", "c16", "e4",   "b",    "bes",
      "ees", "a,",   "f'",  "aes,", "fis'", "cis" ),
    expected => [
      "cis4", "gis", "fis'", "a,",  "f'",  "b,",
      "e",    "dis", "ais",  "d16", "c8.", "g'4"
    ],
  },
  # Caught mapping
  { args =>
      '--map modal --contrary --retrograde --raw 0 2 4 5 7 9 11 12 14 16 17 19',
    expected => [
      "0 -19", "2 -17", "4 -15", "5 -13", "7 -12", "9 -10",
      "11 -8", "12 -7", "14 -5", "16 -3", "17 -1", "19 0",
    ]
  },
);

my @stderr_tests = (
  { args     => '--help',
    expected => qr/^Usage/,
  },
  { args     => 'exact --help',
    expected => qr/^Usage/,
  },
  { args     => 'modal --help',
    expected => qr/^Usage/,
  },
  { args     => 'exact',
    expected => qr/no notes/,
  },
  { args     => 'modal',
    expected => qr/no notes/,
  },
);

for my $test (@arg_only_tests) {
  $tc->run( args => $test->{args} );
  $deeply->(
    [ split ' ', $tc->stdout ],
    $test->{expected}, "ARGS: $test_prog $test->{args}"
  );
  is( $tc->stderr, "", "ARGS: $test_prog $test->{args} emits no stderr" );
}

for my $test (@stdin_tests) {
  $tc->run( args => $test->{args}, stdin => $test->{stdin} );
  $deeply->(
    [ split "\n", $tc->stdout ],
    $test->{expected}, "STDIN: $test_prog $test->{args}"
  );
  is( $tc->stderr, "", "STDIN: $test_prog $test->{args} emits no stderr" );
}

for my $test (@stderr_tests) {
  $tc->run( args => $test->{args} );
  is( length $tc->stdout, 0, "STDERR: $test_prog $test->{args} emits no stdout" );
  ok( $tc->stderr =~ $test->{expected},
    "STDERR: $test_prog $test->{args} pattern match $test->{expected}" );
}

plan tests => @arg_only_tests * 2 + @stdin_tests * 2 + @stderr_tests * 2;
