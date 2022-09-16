use strictures 2;
use Test::More;
use Babble::Plugin::Ellipsis;
use Babble::Match;

my $el = Babble::Plugin::Ellipsis->new;

my @cand = (
  # just ellipsis
  [ 'sub foo {...}',
    q|sub foo {die 'Unimplemented'}|, ],
  # partial ellipsis
  [ 'sub foo { f; ...; g; }',
    q|sub foo { f; die 'Unimplemented'; g; }|, ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $el->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
