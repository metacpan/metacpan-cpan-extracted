#!perl

use Test::Cmd;
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

my $test_prog = './atonal-util';
my $tc        = Test::Cmd->new(
  interpreter => $^X,
  prog        => $test_prog,
  verbose     => 0,            # TODO is there a standard ENV to toggling?
  workdir     => '',
);

# These may just confirm existing bad behavior, or duplicate tests from
# Music::AtonalUtil, or probably are otherwise incomplete. With the
# switch to Test::Cmd some tests were fiddled with to avoid ' in the
# arguments. Trailing whitespace in atonal-util output is ignored by
# most of these tests.
my @tests = (
  { args     => '--sd=16 adjacent_interval_content 0 3 6 10 12',
    expected => ['01220000'],
  },
  { args => 'basic 0 4 7',
    expected =>
      [ '0,3,7', '001110', "3-11\tMajor and minor triad", "0,4,7\thalf_prime" ],
  },
  { args => 'basic c e g',
    expected =>
      [ '0,3,7', '001110', "3-11\tMajor and minor triad", "0,4,7\thalf_prime" ],
  },
  { args     => 'basic --ly --tension=cope 0 1 2',
    expected => [ 'c,cis,d', '210000', '3-1', '1.800  0.800  1.000' ],
  },
  { args => '--rs=_ basic c e g',
    expected =>
      [ '0_3_7', '001110', "3-11\tMajor and minor triad", "0_4_7\thalf_prime" ],
  },
  { args     => 'beats2set --scaledegrees=16 x..x ..x. ..x. x...',
    expected => ['0,3,6,10,12'],
  },
  { args     => 'circular_permute 0 1 2',
    expected => [ '0 1 2', '1 2 0', '2 0 1' ],
  },
  { args     => 'combos 440 880',
    expected => [
      "440.00+880.00 = 1320.00\t(88 error -1.49)",
      "880.00-440.00 = 440.00\t(69 error 0.00)"
    ],
  },
  { args     => 'combos c g',
    expected => [
      "130.81+196.00 = 326.81\t(64 error 2.82)",
      "196.00-130.81 = 65.18\t(36 error 0.22)"
    ],
  },
  { args     => 'complement 0,1,2,3,4,5,7,8,9,10,11',
    expected => ['6'],
  },
  { args     => 'equivs 0 1 2 3 4 5 6 7 8 9 10 11',
    expected => ['0 1 2 3 4 5 6 7 8 9 10 11'],
  },
  { args     => 'findall --fn=5 --root=0 c e g b a',
    expected => ["5-27\tTi(0)\t0,11,9,7,4"],
  },
  { args     => 'findin --pitchset=4-23 --root=2 0 2 7 9',
    expected => ["-\tTi(2)\t2,0,9,7"],
  },
  { args     => 'forte2pcs 9-3',
    expected => ['0,1,2,3,4,5,6,8,9'],
  },
  { args     => 'freq2pitch 440',
    expected => ["440.00\t69"],
  },
  { args     => 'freq2pitch --cf=422.5 440',
    expected => ["440.00\t70"],
  },
  { args     => 'half_prime_form c b g',
    expected => ['0,4,5'],
  },
  { args     => 'interval_class_content c fis b',
    expected => ['100011'],
  },
  { args     => 'intervals2pcs --pitch=2 3 4 7',
    expected => ['2,5,9,4'],
  },
  { args     => 'invariance_matrix 0 2 4',
    expected => [ '0,2,4', '2,4,6', '4,6,8' ],
  },
  { args     => 'invert 1 2 3',
    expected => ['11,10,9'],
  },
  # TODO how get ' through Test::Cmd?
  # { args      => q{ly2pitch c'},
  #   expected => ['60'],
  # },
  { args     => 'ly2struct --tempo=120 --relative=c c4 r8',
    expected => [ "\t{ 131, 500 },\t/* c4 */", "\t{ 0, 250 },\t/* r8 */" ],

  },
  { args     => 'multiply --factor=2 1 2 3',
    expected => ['2 4 6'],
  },
  { args     => 'normal_form e g c',
    expected => ['0,4,7'],
  },
  { args     => 'notes2time 1',
    expected => ['4s'],
  },
  { args     => 'notes2time --ms --tempo=120 1',
    expected => ['2000'],
  },
  { args     => 'notes2time --ms --tempo=160 c4*2/3 c c',
    expected => [ '250', '250', '250', '= 750' ],
  },
  { args     => 'notes2time --fraction=2/3 c4. d8 e4',
    expected => [ '1s', '333ms', '666ms', '= 2s' ],
  },
  { args     => 'pcs2forte 4 6 3 7',
    expected => ['4-3'],
  },
  { args     => 'pcs2intervals 3 4 7',
    expected => ['1,3'],
  },
  { args     => 'pitch2freq 60',
    expected => ["60\t261.63"],
  },
  # TODO need to check these numbers manually
  { args     => q{pitch2freq --cf=422.5 a},
    expected => ["57\t211.25"],
  },
  { args     => 'pitch2intervalclass 4',
    expected => ['4'],
  },
  { args     => 'pitch2intervalclass 8',
    expected => ['4'],
  },
  { args     => 'pitch2ly 72',
    expected => [q{c''}],
  },
  { args     => 'prime_form 0 4 7',
    expected => ['0,3,7'],
  },
  { args     => 'recipe --file=t/rules 0 11 3',
    expected => ['4,8,7'],
  },
  { args     => 'retrograde 1 2 3',
    expected => ['3,2,1'],
  },
  { args     => 'rotate --rotate=3 1 2 3 4',
    expected => ['2,3,4,1'],
  },
  { args     => 'set2beats --scaledegrees=16 4-z15',
    expected => ['xx..x.x.........'],
  },
  { args     => 'set_complex 0 2 7',
    expected => [ '0,2,7', '10,0,5', '5,7,0' ],
  },
  { args => 'subsets 3-1',
    # NOTE might false alarm if permutation module changes ordering; if
    # so, sort the output?
    expected => [ '0,1', '0,2', '1,2', ],
  },
  { args     => 'tcs 7-4',
    expected => ['7 5 4 4 3 3 4 3 3 4 4 5'],
  },
  { args     => 'tcis 7-4',
    expected => ['2 4 4 4 5 4 5 6 5 4 4 2'],
  },
  { args     => 'tension g b d f',
    expected => ["1.000  0.100  0.700\t0.2,0.1,0.7"],
  },
  { args     => 'time2notes 1234',
    expected => ['c4*123/100'],
  },
  { args     => 'transpose --transpose=7 0 6 11',
    expected => ['7,1,6'],
  },
  { args     => 'transpose_invert --transpose=3 1 2 3',
    expected => ['2,1,0'],
  },
  { args     => 'whatscalesfit c d e f g a b',
    expected => [
      'C  Major                     c     d     e     f     g     a     b',
      'D  Dorian                    d     e     f     g     a     b     c',
      'E  Phrygian                  e     f     g     a     b     c     d',
      'F  Lydian                    f     g     a     b     c     d     e',
      'G  Mixolydian                g     a     b     c     d     e     f',
      'A  Aeolian                   a     b     c     d     e     f     g',
      'B  Locrian                   b     c     d     e     f     g     a',
      'A  Melodic minor     DSC     g     f     e     d     c     b     a',
    ],
  },
);

# TODO
for my $test (@tests) {
  $tc->run( args => $test->{args} );
  $deeply->(
    [ map { s/\s+$//r } split "\n", $tc->stdout ],
    $test->{expected}, "$test_prog $test->{args}"
  );
  is( $tc->stderr, "", "$test_prog $test->{args} emits no stderr" );
}

# Custom tests for things that do not fit the above model well

$tc->run( args => 'fnums' );
my @fnums = $tc->stdout;
$fnums[0] =~ s/\s+$//;
is( $fnums[0], "3-1\t0,1,2           \t210000", 'first forte number' );
is( scalar @fnums, 208, 'forte numbers count' );

$tc->run( args => '--help' );
ok( $tc->stderr =~ m/^Usage/, 'help emits to stderr' );

$tc->run( args => 'invariants 3-9' );
$deeply->(
  [ map { s/\s+$//r } split "\n", $tc->stdout ],
  [ 'T(0)   [ 0,2,7    ] ivars [ 0,2,7    ] 3-9',
    'T(2)   [ 2,4,9    ] ivars [ 2        ]',
    'T(5)   [ 5,7,0    ] ivars [ 7,0      ]',
    'T(7)   [ 7,9,2    ] ivars [ 7,2      ]',
    'T(10)  [ 10,0,5   ] ivars [ 0        ]',
    'Ti(0)  [ 0,10,5   ] ivars [ 0        ]',
    'Ti(2)  [ 2,0,7    ] ivars [ 2,0,7    ] 3-9',
    'Ti(4)  [ 4,2,9    ] ivars [ 2        ]',
    'Ti(7)  [ 7,5,0    ] ivars [ 7,0      ]',
    'Ti(9)  [ 9,7,2    ] ivars [ 7,2      ]',
  ],
  'invariences'
);
$deeply->(
  [ map { s/\s+$//r } split "\n", $tc->stderr ],
  ['[0,2,7] icc 010020'], 'invarients stderr'
);

$tc->run( args => 'variances', stdin => "5-1\n0 1 2 3 5\n" );
$deeply->(
  [ map { s/\s+$//r } split "\n", $tc->stdout ],
  [ '0,1,2,3', '4,5', '0,1,2,3,4,5' ], 'variances'
);

$tc->run( args => 'zrelation', stdin => "8-z15\n0,1,2,3,5,6,7,9\n" );
is( $tc->stdout, "1\n", 'zrelation yes' );

$tc->run( args => 'zrelation', stdin => "9-2\n0 1 2 3 4 5 6 8 9\n" );
is( $tc->stdout, "0\n", 'zrelation no' );

plan tests => 8 + @tests * 2;
