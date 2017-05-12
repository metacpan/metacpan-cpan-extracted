#!perl  

use strict;
use warnings;
use Test::More;
use Test::Database;
use Test::Differences;
use lib qw(t/lib);

# get all available handles
my @handles;

BEGIN {
        @handles  = Test::Database->handles({dbd=>'SQLite'},{dbd=>'mysql'});

        # plan the tests
        plan tests => 2 + 33 * @handles;

        use_ok( 'HTML::Template' );
        use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {remove=>['template','pageId','priority','lastmod','changefreq','internalId'],notfound_stuff=>1,xml_sitemap_base_url=>'http://xml/'};

sub response_like {
        my ($app, $header_re, $body_re, $comment) = @_;

        local $ENV{CGI_APP_RETURN_ONLY} = 1;
        my $output = $app->run;
        my ($header, $body) = split /\r\n\r\n/m, $output;
        $header =~ s/\r\n/|/g;
        like($header, $header_re, "$comment (header match)");
	if ($body =~ /(\<\?xml version\=\"1\.0\" encoding\=\"UTF\-8\"\?\>.+\<\/urlset>)$/s) {
		return $1;
	}
        eq_or_diff($body,      $body_re,       "$comment (body match)");
}

# run the tests
for my $handle (@handles) {
       diag "Testing with " . $handle->dbd();    # mysql, SQLite, etc.

       # let $handle do the connect()
       my $dbh = $handle->dbh();
       drop_tables($dbh) if $ENV{DROP_TABLES};
       $params->{'::Plugin::DBH::dbh_config'}=[$dbh];

       $dbh->do("create table cgiapp_pages (pageId varchar(255), lang varchar(2), internalId int, home TEXT, path TEXT)");
       $dbh->do("create table cgiapp_structure (internalId int, template varchar(20), lastmod DATE, changefreq varchar(20), priority decimal(3,1))");
       $dbh->do("create table cgiapp_lang (lang varchar(2), collation varchar(2))");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test1', 'en', 0, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test2', 'en', 1, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/test1', 'de', 0, 'HEIMAT', 'Stra&szlig;e')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/test2', 'de', 1, 'HEIMAT1', 'Stra&szlig;e1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/notfound', 'en', 4000, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/notfound', 'de', 4000, 'HEIMAT', 'Stra&szlig;e3')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('de','DE')");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(0,'t/templ/testL.tmpl', '2009-08-11', 'daily', 0.8)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(1,'t/templ/testL.tmpl', '2007-08-11', 'yearly', 0.7)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(4000,'t/templ/testNL.tmpl', '2009-08-11', 'never', NULL)");


{
        my $app = TestApp->new(QUERY => CGI->new(""), PARAMS=>$params);
        isa_ok($app, 'CGI::Application');

        response_like(
                $app,
                qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                "Hello World: basic_test",
                'TestApp, blank query',
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME
  <p>
  My Path is set to PATH
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'en/test1';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test1'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'en/test2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test2'
        );
}


{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HEIMAT
  <p>
  My Path is set to Stra&szlig;e
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'de/test1';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test1'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HEIMAT1
  <p>
  My Path is set to Stra&szlig;e1
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'de/test2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test2'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME
  <p>
  My Path is set to PATH

  My error message for you: en/test3
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'en/test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Status: 404\|Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HEIMAT
  <p>
  My Path is set to Stra&szlig;e3

  My error message for you: de/test3
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'de/test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Status: 404\|Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}

{
my $html=<<EOS
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

   <url>
      <loc>http://xml/en/test1</loc>
      <lastmod>2009-08-11</lastmod>
      <changefreq>daily</changefreq>
      <priority>0.800000000000000044</priority>
   </url>

   <url>
      <loc>http://xml/de/test1</loc>
      <lastmod>2009-08-11</lastmod>
      <changefreq>daily</changefreq>
      <priority>0.800000000000000044</priority>
   </url>

   <url>
      <loc>http://xml/en/test2</loc>
      <lastmod>2007-08-11</lastmod>
      <changefreq>yearly</changefreq>
      <priority>0.699999999999999956</priority>
   </url>

   <url>
      <loc>http://xml/de/test2</loc>
      <lastmod>2007-08-11</lastmod>
      <changefreq>yearly</changefreq>
      <priority>0.699999999999999956</priority>
   </url>

</urlset>
EOS
;

        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'xml_sitemap'}));
        my $body = response_like(
                $app,
                qr{^Encoding: utf-8|Content-Type: text/xml; charset=utf-8$},
                $html,
                'TestApp, xml_sitemap'
        );
	use XML::LibXML;
	my $parser = XML::LibXML->new();
	my $got = $parser->parse_string($body);
	my $expected = $parser->parse_string($html);
	my $xpc = XML::LibXML::XPathContext->new();
	$xpc->registerNs('x', $got->getDocumentElement->getNamespaces->getValue);

	ok(scalar(@{$xpc->findnodes('/x:urlset/x:url',$got)}) == scalar(@{$xpc->findnodes('/x:urlset/x:url',$expected)}), "number of pages");
	for(my $i = 1; $i <= 4; $i++) {
		my $text = $xpc->findnodes("/x:urlset/x:url[$i]/x:loc/text()", $got)->[0]->toString;
		ok($text eq $xpc->findnodes("/x:urlset/x:url[x:loc/text()='$text']/x:loc/text()", $expected)->[0]->toString, "loc[$i]");
		ok($xpc->findnodes("/x:urlset/x:url[$i]/x:changefreq/text()", $got)->[0]->toString eq $xpc->findnodes("/x:urlset/x:url[x:loc/text()='$text']/x:changefreq/text()", $expected)->[0]->toString, "changefreq[$i]");
		ok(abs($xpc->findnodes("/x:urlset/x:url[$i]/x:priority/text()", $got)->[0]->toString - $xpc->findnodes("/x:urlset/x:url[x:loc/text()='$text']/x:priority/text()", $expected)->[0]->toString) < 0.000000001, "priority[$i]");
		ok($xpc->findnodes("/x:urlset/x:url[$i]/x:lastmod/text()", $got)->[0]->toString eq $xpc->findnodes("/x:urlset/x:url[x:loc/text()='$text']/x:lastmod/text()", $expected)->[0]->toString, "lastmod[$i]");
	}
}
	drop_tables($dbh);
}

sub drop_tables {
	my $dbh=shift;
	$dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_lang");
}


