use strictures 2;
use Test::More;
use Babble::Plugin::SKT;
use Babble::Match;

my $skt = Babble::Plugin::SKT->new;

my $g = Babble::Grammar->new;

$skt->extend_grammar($g);

my @cand = (
  [ 'foo(); try { bar() }; baz();',
    'foo(); { local $@; eval { bar() } }; baz();' ],
  [ 'foo(); try { bar() } catch { warn "Argh: $@"; } baz();',
    'foo(); { local $@; unless (eval { bar(); 1 }) { warn "Argh: $@"; } } baz();' ],
  [ 'use Syntax::Keyword::Try; foo(); try { bar() }; baz();',
    ' foo(); { local $@; eval { bar() } }; baz();' ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = $g->match(Document => $from);
  $skt->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
