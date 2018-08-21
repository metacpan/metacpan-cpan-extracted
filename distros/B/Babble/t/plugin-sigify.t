use strictures 2;
use Test::More;
use Babble::Plugin::Sigify;
use Babble::Match;

my $sigify = Babble::Plugin::Sigify->new;

my @cand = (
  [ join("\n",
      'sub foo {',
      '  my ($bar, $baz) = @_;',
      '  warn $bar;',
      '  return $baz;',
      '}'),
    join("\n",
      'sub foo ($bar, $baz) {',
      '  warn $bar;',
      '  return $baz;',
      '}'),
   ],
   [ 'my $foo = sub { my ($bar) = @_; return $bar + 1 }',
     'my $foo = sub ($bar) { return $bar + 1 }' ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $sigify->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
