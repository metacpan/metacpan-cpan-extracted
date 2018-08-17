use strictures 2;
use Test::More;
use Babble::Plugin::DefinedOr;
use Babble::Match;

my $do = Babble::Plugin::DefinedOr->new;

my @cand = (
  [ 'my $x = $y // $z;',
    'my $x = (map +(defined($_) ? $_ : $z), $y)[0];', ],
  [ 'my $x = ($y //= $z);',
    'my $x = ((map +(defined($_) ? $_ : $_ = $z), $y)[0]);', ],
  [ 'my $x; my $y = 3; $x //= $y; say $x;',
    'my $x; my $y = 3; defined($_) or $_ = $y for $x; say $x;', ],
  [ 'my $x; my $y = 3; $x //= $y if $z; say $x;',
    'my $x; my $y = 3; do { defined($_) or $_ = $y for $x } if $z; say $x;', ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $do->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
