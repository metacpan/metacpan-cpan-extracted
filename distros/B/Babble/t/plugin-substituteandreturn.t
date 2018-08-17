use strictures 2;
use Test::More;
use Babble::Plugin::SubstituteAndReturn;
use Babble::Match;

my $sr = Babble::Plugin::SubstituteAndReturn->new;

my @cand = (
  [ 'my $foo = $bar =~ s/baz/quux/r;',
    'my $foo = (map { (my $__B_001 = $_) =~ s/baz/quux/; $__B_001 } $bar)[0];', ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $sr->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
