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
        plan tests => 1 + 7 * @handles;

        use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {remove=>['template','pageId','internalId','changefreq'], 
	template_params=>{case_sensitive=>1},
	objects=>{
		loop=>'CGI::Application::Plugin::PageLookup::Menu'
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

       $dbh->do("create table cgiapp_pages (pageId varchar(255), lang varchar(2), internalId int, title TEXT)");
       $dbh->do("create table cgiapp_structure (internalId int, template varchar(20), lastmod DATE, changefreq varchar(20), priority decimal(3,1), lineage varchar(255), rank int)");
       $dbh->do("create table cgiapp_lang (lang varchar(2), collation varchar(2))");
#$dbh->do("create table cgiapp_values (lang, internalId, param, value)");
#$dbh->do("create table cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/rabbit', 'en', 0, 'Rabbit')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/dog', 'en', 1, 'Dog')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/cow', 'en', 2, 'Cow')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/cow/fresian', 'en', 4, 'Fresian Cow')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/cow/jersey', 'en', 5, 'Jersey Cow')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/dog/terrier', 'en', 6, 'Terrier')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/dog/scenthound', 'en', 7, 'Scenthound')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/dog/gundog', 'en', 8, 'Gundog')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/dog/terrier/airedale', 'en', 9, 'Airedale Terrier')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/dog/gundog/ariege', 'en', 10, 'Ariege Pointer')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('en/pig', 'en', 3, 'Pig')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/kaninchen', 'de', 0, 'Kaninchen')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/hund', 'de', 1, 'Hund')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/kuh', 'de', 2, 'Kuh')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/schwein', 'de', 3, 'Schwein')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/kuh/fresisch', 'de', 4, 'Fresisches Kuh')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/kuh/vonjersey', 'de', 5, 'Kuh von Jersey')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/hund/terrier', 'de', 6, 'Terrier')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/hund/schweisshund', 'de', 7, 'Schweisshund')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/hund/jagdhund', 'de', 8, 'Jagdhund')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/hund/terrier/airedale', 'de', 9, 'Airedale Terrier')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title) values('de/hund/jagdhund/ariege', 'de', 10, 'Braque de l&rsquo;Ari&egrave;ge')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('de','DE')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(0,'t/templ/testM.tmpl', 'daily', 1, '', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(1,'t/templ/testM.tmpl', 'daily', 1, '', 1)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(2,'t/templ/testM.tmpl', 'daily', 1, '', 2)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(3,'t/templ/testM.tmpl', 'daily', 1, '', 3)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(4,'t/templ/testM.tmpl', 'daily', 1, '2', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(5,'t/templ/testM.tmpl', 'daily', 1, '2', 1)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(6,'t/templ/testM.tmpl', 'daily', 1, '1', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(7,'t/templ/testM.tmpl', 'daily', 1, '1', 1)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(8,'t/templ/testM.tmpl', 'daily', 1, '1', 2)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(9,'t/templ/testM.tmpl', 'daily', 1, '1,0', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(10,'t/templ/testM.tmpl', 'daily', 1, '1,2', 0)");

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
<header>
	<title>Rabbit</title>
</header>
<body>

    <ul>
    
        <li>
                <a href="/en/rabbit/">Rabbit</a>
                
        </li>
    
        <li>
                <a href="/en/dog/">Dog</a>
                
                <ul>
                
                        <li>
                                <a href="/en/dog/terrier/">Terrier</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/en/dog/terrier/airedale/">Airedale Terrier</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                        <li>
                                <a href="/en/dog/scenthound/">Scenthound</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/dog/gundog/">Gundog</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/en/dog/gundog/ariege/">Ariege Pointer</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/cow/">Cow</a>
                
                <ul>
                
                        <li>
                                <a href="/en/cow/fresian/">Fresian Cow</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/cow/jersey/">Jersey Cow</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/pig/">Pig</a>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;

	local $params->{pageid} = 'en/rabbit';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, just structure'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
<header>
	<title>Kaninchen</title>
</header>
<body>

    <ul>
    
        <li>
                <a href="/de/kaninchen/">Kaninchen</a>
                
        </li>
    
        <li>
                <a href="/de/hund/">Hund</a>
                
                <ul>
                
                        <li>
                                <a href="/de/hund/terrier/">Terrier</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/de/hund/terrier/airedale/">Airedale Terrier</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                        <li>
                                <a href="/de/hund/schweisshund/">Schweisshund</a>
                                
                        </li>
                
                        <li>
                                <a href="/de/hund/jagdhund/">Jagdhund</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/de/hund/jagdhund/ariege/">Braque de l&rsquo;Ari&egrave;ge</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/de/kuh/">Kuh</a>
                
                <ul>
                
                        <li>
                                <a href="/de/kuh/fresisch/">Fresisches Kuh</a>
                                
                        </li>
                
                        <li>
                                <a href="/de/kuh/vonjersey/">Kuh von Jersey</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/de/schwein/">Schwein</a>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;

	local $params->{pageid} = 'de/kaninchen';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, just structure'
        );
}

        drop_tables($dbh);
}

sub drop_tables {
	my $dbh = shift;

	$dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_lang");
#       $dbh->do("drop table cgiapp_values");
#       $dbh->do("drop table cgiapp_loops");
}


