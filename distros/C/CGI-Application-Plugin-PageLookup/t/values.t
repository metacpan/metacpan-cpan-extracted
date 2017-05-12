#!perl  

use strict;
use warnings;
use Test::More;
use Test::Database;
use Test::Differences;
use lib qw(t/lib);

# get all available handles
my @handles;
ok(1); # just keep the test suite happy if Test::Database does nothing


BEGIN {
	@handles = Test::Database->handles({dbd=>'SQLite'},{dbd=>'mysql'});

	# plan the tests
	plan tests => 1+15 * @handles;
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {remove=>['template','pageId','internalId','priority','lastmod','changefreq'],notfound_stuff=>1,xml_sitemap_base_url=>'http://xml/', 
	objects=>{
		test1=>'CGI::Application::Plugin::PageLookup::Value',
		test2=>'CGI::Application::Plugin::PageLookup::Value',
		test3=>'CGI::Application::Plugin::PageLookup::Value'
	}
};

sub response_like {
        my ($app, $header_re, $body_re, $comment) = @_;

        local $ENV{CGI_APP_RETURN_ONLY} = 1;
        my $output = $app->run;
        my ($header, $body) = split /\r\n\r\n/m, $output;
        $header =~ s/\r\n/|/g;
        like($header, $header_re, "$comment (header match)");
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
 $dbh->do("create table cgiapp_values (lang varchar(2), internalId int, param varchar(20), value TEXT)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test1', 'en', 0, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test2', 'en', 1, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/test1', 'de', 0, 'HEIMAT', 'Stra&szlig;e')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/test2', 'de', 1, 'HEIMAT1', 'Stra&szlig;e1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/notfound', 'en', 4000, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/notfound', 'de', 4000, 'HEIMAT', 'Stra&szlig;e3')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('de','DE')");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(0,'t/templ/testLO.tmpl', '2009-8-11', 'daily', 0.8)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(1,'t/templ/testLO.tmpl', '2007-8-11', 'yearly', 0.7)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(4000,'t/templ/testNLO.tmpl', '2009-8-11', 'never', NULL)");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('en',null, 'hop', 'Bunnies')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('en',null, 'skip', 'Happy')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('en',null, 'jump', 'Sky')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('de',null, 'hop', 'Hasen')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('de',null, 'skip', 'Gl&uuml;cklich')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('de',null, 'jump', 'Himmel')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('de',1, 'jump', 'Wolken')");
$dbh->do("insert into  cgiapp_values (lang, internalId, param, value) values('de',4000, 'jump', 'Blau')");

	
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

  test1: Bunnies
  test2: Happy
  test3: Sky
  </body>
  </html>
EOS
;

	local $params->{pageid}= 'en/test1';
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

  test1: Bunnies
  test2: Happy
  test3: Sky
  </body>
  </html>
EOS
;

	local $params->{pageid}= 'en/test2';
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

  test1: Hasen
  test2: Gl&uuml;cklich
  test3: Himmel
  </body>
  </html>
EOS
;

	local $params->{pageid}= 'de/test1';
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

  test1: Hasen
  test2: Gl&uuml;cklich
  test3: Wolken
  </body>
  </html>
EOS
;

	local $params->{pageid}= 'de/test2';
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

  test1: Bunnies
  test2: Happy
  test3: Sky

  </body>
  </html>
EOS
;

	local $params->{pageid}= 'en/test3';
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

  test1: Hasen
  test2: Gl&uuml;cklich
  test3: Blau

  </body>
  </html>
EOS
;

	local $params->{pageid}= 'de/test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Status: 404\|Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}

        drop_tables($dbh);
}

sub drop_tables {
	my $dbh = shift;

	$dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_values");
       $dbh->do("drop table cgiapp_lang");
}


