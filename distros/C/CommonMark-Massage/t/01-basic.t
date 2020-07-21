#!perl

use Test::More tests => 6;

use CommonMark::Massage;

my $parser = CommonMark::Parser->new;
ok( $parser, "got a parser" );
$parser->feed("Hello world");
my $doc = $parser->finish;
ok( $doc, "got a doc");
isa_ok( $doc, "CommonMark::Node", "doc");

# Verify the AST.
my $res = $doc->reveal;
my $exp = <<EOD;
ENTR NODE_DOCUMENT
ENTR NODE_PARAGRAPH
ENTR NODE_TEXT
EXIT NODE_PARAGRAPH
EXIT NODE_DOCUMENT
EOD
is( $res, $exp, "AST" );

# Check standard HTML rendering.
is( $doc->render_html, "<p>Hello world</p>\n", "html" );

# Now turn literals to uppercase.
$doc->massage( { NODE_TEXT => \&shout } );

# Verify.
is( $doc->render_html, "<p>HELLO WORLD</p>\n", "HTML" );

sub shout {
    my ( $doc, $node, $enter ) = @_;
    $node->set_literal( uc $node->get_literal ) if $enter;
}
