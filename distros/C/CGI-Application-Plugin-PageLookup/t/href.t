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
        plan tests => 2 + 9 * @handles;

        use_ok( 'HTML::Template' );
        use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {remove=>['template','pageId','internalId','changefreq'], 
	template_params=>{global_vars=>1},
	objects=>{
		href=>'CGI::Application::Plugin::PageLookup::Href'
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

       $dbh->do("create table cgiapp_pages (pageId varchar(255), lang varchar(2), internalId int)");
       $dbh->do("create table cgiapp_structure (internalId int, template varchar(20), changefreq varchar(20))");
       $dbh->do("create table cgiapp_lang (lang varchar(2), collation varchar(2), english TEXT, german TEXT, french TEXT, first TEXT, second TEXT, third TEXT)");
 
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/href', 'en', 0)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/first', 'en', 1)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/second', 'en', 2)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/third', 'en', 3)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('fr/bleu', 'fr', 0)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('fr/premier', 'fr', 1)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('fr/seconde', 'fr', 2)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('fr/troisieme', 'fr', 3)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('de/blau', 'de', 0)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('de/erste', 'de', 1)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('de/zweite', 'de', 2)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('de/dritte', 'de', 3)");
$dbh->do("insert into  cgiapp_lang (lang, collation, english, german, french, first, second, third) values('en','GB','English', 'German', 'French', 'My first webpage', 'My second even better webpage', 'My web page to beat all webpages')");
$dbh->do("insert into  cgiapp_lang (lang, collation, english, german, french, first, second, third) values('fr','FR','Anglais', 'Allemand', 'Fran&ccedil;ais', 'Mes page web premi&egrave;re', 'Mon deuxi&egrave;me encore meilleur site web', 'Ma page web &agrave; battre toutes les pages Web')");
$dbh->do("insert into  cgiapp_lang (lang, collation, english, german, french, first, second, third) values('de','DE','Englisch', 'Deutsch', 'Franz&ouml;sisch', 'Meine erste Webseite', 'Meine zweite noch besser Webseite', 'Meine Seite zu schlagen alle Webseiten')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(0,'t/templ/testH.tmpl', 'daily')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(1,'t/templ/testJ.tmpl', 'daily')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(2,'t/templ/testJ.tmpl', 'daily')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(3,'t/templ/testJ.tmpl', 'daily')");

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
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
<body>

	<ul>
		<li><a href="en/href">Englisch</a></li>
		<li><a href="de/blau">Deutsch</a></li>
		<li><a href="fr/bleu">Franz&ouml;sisch</a></li>
		<li><a href="de/erste">Meine erste Webseite</a></li>
		<li><a href="de/zweite">Meine zweite noch besser Webseite</a></li>
		<li><a href="de/dritte">Meine Seite zu schlagen alle Webseiten</a></li>
	</ul>
</body>
</html>
EOS
;
	local $params->{pageid}='de/blau';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, German'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
<body>

	<ul>
		<li><a href="en/href">English</a></li>
		<li><a href="de/blau">German</a></li>
		<li><a href="fr/bleu">French</a></li>
		<li><a href="en/first">My first webpage</a></li>
		<li><a href="en/second">My second even better webpage</a></li>
		<li><a href="en/third">My web page to beat all webpages</a></li>
	</ul>
</body>
</html>
EOS
;

	local $params->{pageid}='en/href';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, English'
        );
}


{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr-FR">
<body>

	<ul>
		<li><a href="en/href">Anglais</a></li>
		<li><a href="de/blau">Allemand</a></li>
		<li><a href="fr/bleu">Fran&ccedil;ais</a></li>
		<li><a href="fr/premier">Mes page web premi&egrave;re</a></li>
		<li><a href="fr/seconde">Mon deuxi&egrave;me encore meilleur site web</a></li>
		<li><a href="fr/troisieme">Ma page web &agrave; battre toutes les pages Web</a></li>
	</ul>
</body>
</html>
EOS
;

	local $params->{pageid}='fr/bleu';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, French'
        );
	
}
	drop_tables($dbh);

}

sub drop_tables {
	my $dbh = shift;
	$dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_lang");
}
