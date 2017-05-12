use Test::More tests => 5;

use_ok( "CGI::Wiki::Formatter::Pod" );

my $formatter = CGI::Wiki::Formatter::Pod->new;
isa_ok( $formatter, "CGI::Wiki::Formatter::Pod" );

my $pod = "A L<TestLink>";
my $html = $formatter->format($pod);
like( $html, qr/<A HREF="wiki.cgi\?node=TestLink">/,
      "links to other wiki page" );

$formatter = CGI::Wiki::Formatter::Pod->new(
                                        node_prefix => "wiki-pod.cgi?node=" );
isa_ok( $formatter, "CGI::Wiki::Formatter::Pod" );
$html = $formatter->format($pod);
like( $html, qr/<A HREF="wiki-pod.cgi\?node=TestLink">/,
      "...still works when we redefine node prefix" );
