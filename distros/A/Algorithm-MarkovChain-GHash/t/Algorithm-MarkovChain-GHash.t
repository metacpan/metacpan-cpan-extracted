#!perl -w
use Test::More tests => 15;

# hacky, but allows all backend to be tested with exactly the same
# tests - avoids syncing pain

my $class = $0;
$class =~ s{ ^t/  }{}x;
$class =~ s{ \.t$ }{}x;
$class =~ s{ - }{::}gx;

require_ok($class);

my $mc = $class->new;
isa_ok($mc, $class);

for (qw( new seed spew increment_seen get_options longest_sequence
         sequence_known random_sequence )) {
    can_ok($mc, $_)
}

$mc->seed(symbols => ['a', 'b' ]);

is_deeply({ $mc->get_options('a') }, { b => 1 }, "known options" );

is( $mc->longest_sequence, 1,  "longest sequence" );
is( $mc->random_sequence, 'a', "single random sequence" );
ok( $mc->sequence_known('a'),  "sequence known" );

is_deeply([ $mc->spew(stop_at_terminal => 1,
                      complete => [ 'a' ]) ],
          [ 'a', 'b' ],
          "complete known");

