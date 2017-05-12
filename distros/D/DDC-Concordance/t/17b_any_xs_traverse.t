## -*- Mode: CPerl -*-
use Test::More;
use DDC::Any qw(:none);
#use lib qw(../lib);
no warnings 'once';

if (!DDC::Any->have_xs()) {
  plan skip_all => 'DDC::XS '.($DDC::XS::VERSION ? "v$DDC::XS::VERSION is too old" : 'not available');
} else {
  plan tests => 13;
}

##-- import
DDC::Any->import(':xs');

##-- +8: descendants
my $q = DDC::Any::CQWith->new(
			     DDC::Any::CQWith->new(DDC::Any::CQToken->new('a'), DDC::Any::CQToken->new('b')),
			     DDC::Any::CQWith->new(DDC::Any::CQToken->new('c'), DDC::Any::CQToken->new('d')),
			    );
my @d = @{$q->Descendants};
is(scalar(@d), 7, 'Descendants(): scalar');
is_deeply($d[0], $q, 'Descendants(): [0] ~ root');
is_deeply($d[1], $q->getDtr1, 'Descendants(): [1] ~ Dtr1');
is_deeply($d[2], $q->getDtr1->getDtr1, 'Descendants(): [2] ~ Dtr1.Dtr1');
is_deeply($d[3], $q->getDtr1->getDtr2, 'Descendants(): [3] ~ Dtr1.Dtr2');
is_deeply($d[4], $q->getDtr2, 'Descendants(): [4] ~ Dtr2');
is_deeply($d[5], $q->getDtr2->getDtr1, 'Descendants(): [4] ~ Dtr2.Dtr1');
is_deeply($d[6], $q->getDtr2->getDtr2, 'Descendants(): [4] ~ Dtr2.Dtr2');


##-- +5: traverse
sub xtest {
  my ($class,@args) = @_;
  my $prefix = "DDC::Any";
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
