use Test::More tests => 29;
use Basset::Template;
package Basset::Template;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
{#line 1132 escape_for_html
Test::More::is(Basset::Template->escape_for_html('&'), '&#38;', 'escapes &');
Test::More::is(Basset::Template->escape_for_html('a&'), 'a&#38;', 'escapes &');
Test::More::is(Basset::Template->escape_for_html('&b'), '&#38;b', 'escapes &');
Test::More::is(Basset::Template->escape_for_html('a&b'), 'a&#38;b', 'escapes &');

Test::More::is(Basset::Template->escape_for_html('"'), '&#34;', 'escapes "');
Test::More::is(Basset::Template->escape_for_html('a"'), 'a&#34;', 'escapes "');
Test::More::is(Basset::Template->escape_for_html('"b'), '&#34;b', 'escapes "');
Test::More::is(Basset::Template->escape_for_html('a"b'), 'a&#34;b', 'escapes "');

Test::More::is(Basset::Template->escape_for_html("'"), '&#39;', "escapes '");
Test::More::is(Basset::Template->escape_for_html("a'"), 'a&#39;', "escapes '");
Test::More::is(Basset::Template->escape_for_html("'b"), '&#39;b', "escapes '");
Test::More::is(Basset::Template->escape_for_html("a'b"), 'a&#39;b', "escapes '");

Test::More::is(Basset::Template->escape_for_html('<'), '&#60;', 'escapes <');
Test::More::is(Basset::Template->escape_for_html('a<'), 'a&#60;', 'escapes <');
Test::More::is(Basset::Template->escape_for_html('<b'), '&#60;b', 'escapes <');
Test::More::is(Basset::Template->escape_for_html('a<b'), 'a&#60;b', 'escapes <');

Test::More::is(Basset::Template->escape_for_html('>'), '&#62;', 'escapes >');
Test::More::is(Basset::Template->escape_for_html('a>'), 'a&#62;', 'escapes >');
Test::More::is(Basset::Template->escape_for_html('>b'), '&#62;b', 'escapes >');
Test::More::is(Basset::Template->escape_for_html('a>b'), 'a&#62;b', 'escapes >');

Test::More::is(Basset::Template->escape_for_html('&>'), '&#38;&#62;', 'escapes &>');
Test::More::is(Basset::Template->escape_for_html('<">'), '&#60;&#34;&#62;', 'escapes <">');
Test::More::is(Basset::Template->escape_for_html("&&'"), '&#38;&#38;&#39;', "escapes &&'");
Test::More::is(Basset::Template->escape_for_html('<&'), '&#60;&#38;', 'escapes <&');
Test::More::is(Basset::Template->escape_for_html(q('"'')), '&#39;&#34;&#39;&#39;', q(escapes '"''));

Test::More::is(Basset::Template->escape_for_html(), undef, 'escaped nothing returns undef');
Test::More::is(Basset::Template->escape_for_html(undef), undef, 'escaped undef returns nothing');
};
