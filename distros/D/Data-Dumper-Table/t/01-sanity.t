#!perl -T

use 5.018;
use utf8;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::Dumper::Table' );
}

my $x = [qw(one two three)];

my $y = Tabulate [
    { foo => $x, bar => 2 },
    { foo => 3, bar => { apple => q(or'ange) } },
    $x,
    [
        { bar => q(baz), flibble => q(quux), flobble => undef() },
        { bar => q(baz2), flobble => qr/foo/ }
    ]
];

my $want = <<'WANT';
ARRAY(1) [0] HASH(2)
             -----------------------------
             'bar' => '2'
             'foo' => ARRAY(3) [0] 'one'
                               [1] 'two'
                               [2] 'three'
         [1] HASH(4)
             ------------------------------
             'bar' => HASH(5)
                      ---------------------
                      'apple' => 'or\'ange'
             'foo' => '3'
         [2] -> ARRAY(3)
         [3] ARRAY<HASH>(6)
              'bar'  | 'flibble' | 'flobble'
             --------+-----------+-------------
              'baz'  | 'quux'    | undef()
              'baz2' | -         | /(?^u:foo)/
WANT

chomp $want;

$y = "$y";

$y =~ s/\s+$//smg;

# diag('got');
# diag(join "\n", map { "`$_'"} split /\n/, $y);
# diag('want');
# diag(join "\n", map { "`$_'"} split /\n/, $want);
# diag('huh?');

ok($y eq $want, "Basic sanity");
