#!perl

use strict;
use warnings;
use No::Worries::String qw(string_escape);
use Test::More tests => 5;

use Config::Generator::XML qw(*);

sub good () {
    my($xml, @elements, $string);

    $xml = <<EOF;
<!-- foo -->
<a x="0+0">
  <!--
    multi
    line
  -->
  <b y="1">bar</b>
</a>
EOF
    @elements = xml_parse($xml);
    $string = "";
    foreach my $element (@elements) {
        $string .= xml_string($element);
    }
    is($string, $xml, "xml_parse() + xml_string()");
    $string = "";
    $string .= xml_string(xml_comment("foo"));
    $string .= xml_string(xml_element("a", { x => "0+0" },
        xml_comment("multi\nline"),
        xml_element("b", { y => 1 }, "bar"),
    ));
    is($string, $xml, "xml_comment() + xml_element()");
}

sub bad ($) {
    my($xml) = @_;

    eval { xml_parse($xml) };
    ok($@ ne "", "invalid: " . string_escape($xml));
}

good();
foreach my $xml ("", "<a>b<c/>d</a>", , "<a>b\nc</a>") {
    bad($xml);
}
