use Test;
use Chart::Sequence;
use strict;

my $has_pf = eval "require XML::SAX::ParserFactory";
my $skip = $has_pf ? 0 : "No XML::SAX::ParserFactory";

my $s;

my @tests = (
sub {
    $s = Chart::Sequence->new;

    ok UNIVERSAL::isa( $s, "Chart::Sequence" );
},

sub {
    $s->name( "Foo" );
    ok $s->name, "Foo", "name";
},

sub {
    $s->messages( [ Foo => "Bar" ], [ Baz => "Bat" ] );
    ok int $s->messages, 2, "messages";
},

sub {
    return skip "sequence has no messages", 1 unless $s->messages;
    ok $s->messages_ref->[0]->from, "Foo", "message 0 from";
},

sub {
    return skip "sequence has no messages", 1 unless $s->messages;
    ok $s->messages_ref->[0]->to, "Bar", "message 0 to";
},

sub {
    ok int $s->nodes, 4, "nodes";
},

sub {
    $s = Chart::Sequence->new(
        Name     => "Foo",
        Nodes    => [qw( A B C )],
        Messages => [
            [ A => B => "Message 1" ],
            [ B => A => "Ack 1"     ],
            [ B => C => "Message 2" ],
        ],
    );

    ok UNIVERSAL::isa( $s, "Chart::Sequence" );
},

sub {
    return skip "sequence has no messages", 1 unless $s->messages;
    ok $s->messages_ref->[0]->from, "A", "message 0 from";
},

sub {
    return skip "sequence has no messages", 1 unless $s->messages;
    ok $s->messages_ref->[0]->to, "B", "message 0 to";
},

sub {
    ok int $s->nodes, 3, "nodes";
},

sub {
    return skip $skip, 1 if $skip;
    $s = Chart::Sequence->new(
        Name     => "Foo",
        SeqML    => \<<'END_SEQML',
<sequence
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
    <name>Message 1</name>
    <from>A</from>
    <to>B</to>
  </message>
  <message>
    <name>Ack 1</name>
    <from>B</from>
    <to>A</to>
  </message>
  <message>
    <name>Message 2</name>
    <from>B</from>
    <to>C</to>
  </message>
</sequence>
END_SEQML
    );

    ok UNIVERSAL::isa( $s, "Chart::Sequence" );
},

sub {
    return skip $skip, 1 if $skip;
    return skip"sequence has no messages", 1 unless $s->messages;
    ok $s->messages_ref->[0]->from, "A", "message 0 from";
},

sub {
    return skip $skip, 1 if $skip;
    return skip"sequence has no messages", 1 unless $s->messages;
    ok $s->messages_ref->[0]->to, "B", "message 0 to";
},

sub {
    return skip $skip, 1 if $skip;
    ok int $s->nodes, 3, "nodes";
},


);


plan tests => 0+@tests;

$_->() for @tests;
