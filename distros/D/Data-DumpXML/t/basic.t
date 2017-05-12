print "1..6\n";

use strict;
use Data::DumpXML qw(dump_xml);

my $xml;

$xml = remove_space(dump_xml(33));
print "not " unless $xml =~ m,<data><str>33</str></data>,;
print "ok 1\n";

$xml = remove_space(dump_xml(\33));
print "not " unless $xml =~ m,<data><ref><str>33</str></ref></data>,;
print "ok 2\n";

$xml = remove_space(dump_xml({"\1" => "\0"}));
print "not " unless $xml =~ m,<data><ref><hash><key encoding="base64">AQ==</key><str encoding="base64">AA==</str></hash></ref></data>,;
print "ok 3\n";

my $undef = undef;
my $ref1 = \$undef;
bless $ref1, "undef-class";
my $ref2 = \$ref1;
bless $ref2, "ref-class";
$xml = remove_space(dump_xml(bless {ref => $ref2}, "Bar"));
print "not " unless $xml =~ m,<data><ref><hash class="Bar"><key>ref</key><ref><ref class="ref-class"><undef class="undef-class"/></ref></ref></hash></ref></data>,;
print "ok 4\n";

my @a = (1..3);
my $a = \$a[1];
$xml = remove_space(dump_xml($a, \@a));
print "not " unless $xml =~ m,<data><ref><str id="r1">2</str></ref><ref><array><str>1</str><alias ref="r1"/><str>3</str></array></ref></data>,;
print "ok 5\n";

# test escaping 
$xml = remove_space(dump_xml(["&", "<>", "]]>"]));
print "not " unless $xml =~ m,<data><ref><array><str>&amp;</str><str>&lt;></str><str>]]&gt;</str></array></ref></data>,;
print "ok 6\n";

#------------

sub remove_space
{
    my $xml = shift;
    $xml =~ s/>\s+</></g;
    $xml =~ s/\s+xmlns="[^"]*"//;
    $xml;
}
