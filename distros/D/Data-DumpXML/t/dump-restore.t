use strict;
use Data::DumpXML qw(dump_xml);
use Data::DumpXML::Parser;

my $obj = bless { foo => 33, bar => "<>" }, "Obj";

my @tests = (
   [1..10],
   [\1],
   [\\\\\\1],
   [undef],
   [bless[], "Foo"],
   [$obj, $obj, \$obj, [$obj, $obj]],
   [\$obj->{foo}, $obj, $obj],
   [{"\0" => "\1"}],
   [bless [], 'Class&<>"'],   # funny class name
   [join("", map chr, 0.255)],
   ["ære våre børn"],
   #[bless["ære våre børn"], "fårepølse"],  # high-bit class names are mangled
);


print "1.." . (@tests + 3) . "\n";
my $testno = 1;
for (@tests) {
   my $xml1 = dump_xml(@$_);
   #print $xml1;

   my $restore = Data::DumpXML::Parser->new->parse($xml1);
   my $xml2 = dump_xml(@$restore);

   unless ($xml1 eq $xml2) {
       print $xml1;
       print $xml2;
       print "not ";
   }
   print "ok " . $testno++ . "\n";
}


#print $xml;

print "Testing Blesser...\n";
my $xml = dump_xml($obj);
my $thistest = $testno++;
my $p = Data::DumpXML::Parser->new(Blesser => sub {
				       my($o, $c) = @_;
				       print "not " unless ref($o) eq "HASH"
                                                       and $o->{foo} == 33
					               and $c eq "Obj";
				       print "ok $thistest\n";
				       bless $o, $c . "::Bar";
				   });
my $res = $p->parse($xml);

print "not " unless ref($res->[0]) eq "Obj::Bar";
print "ok " . $testno++ . "\n";

# Test with namespace prefixes
$xml = do { local $Data::DumpXML::NS_PREFIX="dump"; dump_xml($obj) };
#print $xml;
$p = Data::DumpXML::Parser->new();
$res = $p->parse($xml);
print "not " unless ref($res->[0]) eq "Obj" && $res->[0]{foo} eq 33;
print "ok " . $testno++ . "\n";
