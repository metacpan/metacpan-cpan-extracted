use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 3;
}
use Data::Stag;
use strict;

eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    for (1..3) {
        skip("XML::Parser::PerlSAX not installed",1);
    }
    exit 0;
}


my $xml =<<EOM
<a>
 <b>foo</b>

 <c></c>
 <d>0</d>
 <e>
   0
 </e>
 <f>




 </f>
</a>
EOM
  ;

my $s = Data::Stag->from('xmlstr', $xml);
# ROUNDTRIP
$s = Data::Stag->from('xmlstr', $s->xml);
print $s->xml;
#print $s->itext;
print $s->sxpr;
print "\n\n";
my $ok = 0;
$s->iterate(sub {
                my $n = shift;
                if ($n->element eq 'c' &&
                    defined $n->data &&
                    $n->data eq '') {
                    $ok = 1;
                }
                return;
            });
ok($ok);

$ok = 0;
$s->iterate(sub {
                my $n = shift;
                if ($n->element eq 'd' &&
                    defined $n->data &&
                    $n->data eq '0') {
                    $ok = 1;
                }
                return;
            });
ok($ok);

my $x = Data::Stag->from('sxprstr', '(a (c (d 4)(b 1)))');
print $x->xml;
my ($b) = $x->findnode_b;
print $b->xml;
$b->free;
print $x->xml;
$x = Data::Stag->from('xmlstr',  $x->xml);
ok(1);

$x = Data::Stag->from('xmlstr', '<set><gene></gene></set>');
print $x->xml;
