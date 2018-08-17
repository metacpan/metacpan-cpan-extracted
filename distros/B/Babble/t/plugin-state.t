use strictures 2;
use Test::More;
use Babble::Plugin::State;
use Babble::Match;

my $st = Babble::Plugin::State->new;

my @cand = (
  [ 'my $foo = sub { my ($x) = @_; state $y; return 3; };',
    'my $foo = do { my $y; sub { my ($x) = @_; do { no warnings qw(void); $y }; return 3; } };' ],
  [ 'my $foo = sub { my ($x) = @_; state Foo ($y, $z) :Meh; return 3; };',
    'my $foo = do { my Foo ($y, $z) :Meh; sub { my ($x) = @_; do { no warnings qw(void); ($y, $z) }; return 3; } };' ],
  [ 'my $foo = sub { state $x = 3 };',
    'my $foo = do { my ($__B_001); my $x; sub { ($__B_001 ? $x : ++$__B_001 and $x = 3) } };' ],
);

push @cand, map {
  (my $orig = $_->[0]) =~ s/^my \$foo = sub/sub foo/;
  s/^my \$foo = do //, s/sub {/sub foo {/ for (my $expect = $_->[1]);
  [ $orig, $expect ],
} @cand;

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $st->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
