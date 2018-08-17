use strictures 2;
use Test::More;
use Babble::Plugin::PostfixDeref;
use Babble::Match;

my $pd = Babble::Plugin::PostfixDeref->new;

my @cand = (
  [ 'my $x = $foo->$*; my @y = $bar->baz->@*;',
    'my $x = (map $$_, $foo)[0]; my @y = (map @{$_}, $bar->baz);' ],
  [ 'my $x = ($foo->bar->$*)->baz->@*;',
    'my $x = (map @{$_}, ((map $$_, $foo->bar)[0])->baz);' ],
  [ 'my @val = $foo->@{qw(key names)};',
    'my @val = (map @{$_}{qw(key names)}, $foo);' ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $pd->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
