use strictures 2;
use Test::More;
use Babble::Plugin::PackageBlock;
use Babble::Match;

my $pb = Babble::Plugin::PackageBlock->new;

my @cand = (
  [ 'package Foo::Bar { 42 }',
    '{ package Foo::Bar; 42 }', ],
  [ 'package Foo::Bar v1.2.3 { 42 }',
    '{ package Foo::Bar v1.2.3; 42 }', ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $pb->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
