# -*- Mode: CPerl -*-
use Test::More tests=>5;
use DDC::XS;

##-- +5: traverse
sub xtest {
  my ($class,@args) = @_;
  my $prefix = "DDC::XS";
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

