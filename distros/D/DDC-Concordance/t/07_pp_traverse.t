# -*- Mode: CPerl -*-
use Test::More tests=>13;
use DDC::PP;

##-- +8: descendants
my $q = DDC::PP::CQWith->new(
			     DDC::PP::CQWith->new(DDC::PP::CQToken->new('a'), DDC::PP::CQToken->new('b')),
			     DDC::PP::CQWith->new(DDC::PP::CQToken->new('c'), DDC::PP::CQToken->new('d')),
			    );
my @d = @{$q->Descendants};
is(scalar(@d), 7, 'Descendants(): scalar');
is($d[0], $q, 'Descendants(): [0] == root');
is($d[1], $q->getDtr1, 'Descendants(): [1] == Dtr1');
is($d[2], $q->getDtr1->getDtr1, 'Descendants(): [2] == Dtr1.Dtr1');
is($d[3], $q->getDtr1->getDtr2, 'Descendants(): [3] == Dtr1.Dtr2');
is($d[4], $q->getDtr2, 'Descendants(): [4] == Dtr2');
is($d[5], $q->getDtr2->getDtr1, 'Descendants(): [4] == Dtr2.Dtr1');
is($d[6], $q->getDtr2->getDtr2, 'Descendants(): [4] == Dtr2.Dtr2');

##-- +5: traverse
sub xtest {
  my ($class,@args) = @_;
  my $prefix = "DDC::PP";
  my $q = "${prefix}::${class}"->new(@args);
  $q = $q->mapTraverse(sub {
			 my $nod = shift;
			 $nod->setExpanders(['x'])
			   if (UNIVERSAL::isa($nod,"${prefix}::CQTokInfl") && !@{$nod->getExpanders});
			 return $nod;
		       });
  return $q->toString;
}
like(xtest('CQTokExact','','foo'), qr/^\@'?foo'?$/, 'traverse : @foo');
like(xtest('CQTokInfl', '','foo'), qr/^'?foo'?\s*\|'?x'?$/,'traverse : foo');
like(xtest('CQTokInfl', '','foo',['-']), qr/^'?foo'?\s*\|'?-'?$/, 'traverse : foo|-');
like(xtest('CQTokSetInfl','',['bar','foo']), qr/^\{'?bar'?,'?foo'?\}\s*\|'?x'?$/,'traverse : {bar,foo}');
like(xtest('CQTokSetInfl','',['bar','foo'],['-']), qr/^\{'?bar'?,'?foo'?\}\s*\|'?-'?$/,'traverse : {bar,foo}|-');

print "\n";

