use Test;
use Chart::Sequence::SAXBuilder;
use strict;

my $has_pf = eval "require XML::SAX::ParserFactory";
my $skip = $has_pf ? 0 : "No XML::SAX::ParserFactory";

$XML::SAX::ParserPackage = "XML::SAX::PurePerl";

sub t {
    my $doc = pop;
    XML::SAX::ParserFactory->parser(
        Handler => Chart::Sequence::SAXBuilder->new( @_ ),
    )->parse_string( $doc );
}

my $doc = q{<sequence
  xmlns="http://slaysys.com/Chart-Sequence/seqml/0.1"
>
  <node>
    <name>A</name>
  </node>
  <node>
    <name>B</name>
  </node>
  <node>
    <name>C</name>
  </node>
  <message>
    <from>A</from>
    <to>B</to>
  </message>
  <message>
    <from>B</from>
    <to>C</to>
  </message>
</sequence>};

my $s;

my @tests = (
sub {
    return skip $skip, 1 if $skip;
    $s = t $doc;
    ok int @$s, 1, "sequences";
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    ok int $s->[0]->nodes, 3, "nodes";
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has no nodes", 1 unless $s->[0]->nodes;
    ok( ($s->[0]->nodes)[0]->name, "A", "node 1 name" );
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has <2 no nodes ", 1 unless $s->[0]->nodes >= 2;
    ok( ($s->[0]->nodes)[1]->name, "B", "node 2 name" );
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has <3 nodes ", 1 unless $s->[0]->nodes >= 3;
    ok( ($s->[0]->nodes)[2]->name, "C", "node 3 name" );
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    ok int $s->[0]->messages, 2, "messages";
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has no messages", 1 unless $s->[0]->messages;
    ok( ($s->[0]->messages)[0]->number, 0, "message 0: number" );
},
sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has no messages", 1 unless $s->[0]->messages;
    ok( ($s->[0]->messages)[0]->from, "A", "message 0: from" );
},
sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has no messages", 1 unless $s->[0]->messages;
    ok( ($s->[0]->messages)[0]->to, "B", "message 0: to" );
},

sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has <2 messages", 1 unless $s->[0]->messages >= 2;
    ok( ($s->[0]->messages)[1]->number, 1, "message 1: number" );
},
sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has <2 messages", 1 unless $s->[0]->messages >= 2;
    ok( ($s->[0]->messages)[1]->from, "B", "message 1: from" );
},
sub {
    return skip $skip, 1 if $skip;
    return skip "no sequences", 1 unless @$s;
    return skip "seq. 0 has <2 messages", 1 unless $s->[0]->messages >= 2;
    ok( ($s->[0]->messages)[1]->to, "C", "message 1: to" );
},
);

plan tests => 0+@tests;

$_->() for @tests;
