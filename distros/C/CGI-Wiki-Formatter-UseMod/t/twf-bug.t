use strict;
use Test::More tests => 1;
use CGI::Wiki::Formatter::UseMod;

my $formatter = CGI::Wiki::Formatter::UseMod->new;

my $foo = "x";
$foo .= "" if $foo =~ /x/;

my $html = $formatter->format("test");
is( $html, "<p>test</p>\n", "Text::WikiFormat bug avoided" );
