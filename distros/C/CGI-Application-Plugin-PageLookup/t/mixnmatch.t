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
        plan tests => 1 + 11 * @handles;

        use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {remove=>['template','pageId','internalId','changefreq','check2'], 
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

       $dbh->do("create table cgiapp_pages (pageId varchar(255), lang varchar(2), internalId int, title TEXT, check2 INT)");
       $dbh->do("create table cgiapp_structure (internalId int, template varchar(20), lastmod DATE, changefreq varchar(20), priority decimal(3,1), lineage varchar(255), rank int)");
       $dbh->do("create table cgiapp_lang (lang varchar(2), collation varchar(2))");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/doglist', 'en', 11, 'Dog List', 22)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hundliste', 'de', 11, 'Hund Liste', 22)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/rabbit', 'en', 0, 'Rabbit', 0)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/dog', 'en', 1, 'Dog', 1)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/cow', 'en', 2, 'Cow', 2)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/cow/fresian', 'en', 4, 'Fresian Cow', 3)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/cow/jersey', 'en', 5, 'Jersey Cow', 4)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/dog/terrier', 'en', 6, 'Terrier', 5)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/dog/scenthound', 'en', 7, 'Scenthound', 6)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/dog/gundog', 'en', 8, 'Gundog', 7)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/dog/terrier/airedale', 'en', 9, 'Airedale Terrier', 8)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/dog/gundog/ariege', 'en', 10, 'Ariege Pointer', 9)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('en/pig', 'en', 3, 'Pig', 10)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/kaninchen', 'de', 0, 'Kaninchen', 11)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hund', 'de', 1, 'Hund', 12)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/kuh', 'de', 2, 'Kuh', 13)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/schwein', 'de', 3, 'Schwein', 14)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/kuh/fresisch', 'de', 4, 'Fresisches Kuh', 15)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/kuh/vonjersey', 'de', 5, 'Kuh von Jersey', 16)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hund/terrier', 'de', 6, 'Terrier', 17)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hund/schweisshund', 'de', 7, 'Schweisshund', 18)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hund/jagdhund', 'de', 8, 'Jagdhund', 19)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hund/terrier/airedale', 'de', 9, 'Airedale Terrier', 20)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, title, check2) values('de/hund/jagdhund/ariege', 'de', 10, 'Braque de l&rsquo;Ari&egrave;ge', 21)");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('de','DE')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(0,'t/templ/testM2a.tmpl', 'daily', 1, '', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(1,'t/templ/testM2a.tmpl', 'daily', 1, '', 1)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(2,'t/templ/testM2a.tmpl', 'daily', 1, '', 2)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(3,'t/templ/testM2a.tmpl', 'daily', 1, '', 3)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(4,'t/templ/testM2a.tmpl', 'daily', 1, '2', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(5,'t/templ/testM2a.tmpl', 'daily', 1, '2', 1)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(6,'t/templ/testM2a.tmpl', 'daily', 1, '1', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(7,'t/templ/testM2a.tmpl', 'daily', 1, '1', 1)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(8,'t/templ/testM2a.tmpl', 'daily', 1, '1', 2)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(9,'t/templ/testM2a.tmpl', 'daily', 1, '1,0', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(10,'t/templ/testM2a.tmpl', 'daily', 1, '1,2', 0)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq, priority, lineage, rank) values(11,'t/templ/mix.tmpl', 'daily', 1, '', 4)");

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
                <a href="/en/rabbit/">Rabbit - 0</a>
                
        </li>
    
        <li>
                <a href="/en/dog/">Dog - 1</a>
                
                <ul>
                
                        <li>
                                <a href="/en/dog/terrier/">Terrier - 5</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/en/dog/terrier/airedale/">Airedale Terrier - 8</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                        <li>
                                <a href="/en/dog/scenthound/">Scenthound - 6</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/dog/gundog/">Gundog - 7</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/en/dog/gundog/ariege/">Ariege Pointer - 9</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/cow/">Cow - 2</a>
                
                <ul>
                
                        <li>
                                <a href="/en/cow/fresian/">Fresian Cow - 3</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/cow/jersey/">Jersey Cow - 4</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/pig/">Pig - 10</a>
                
        </li>
    
        <li>
                <a href="/en/doglist/">Dog List - 22</a>
                
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
                <a href="/de/kaninchen/">Kaninchen - 11</a>
                
        </li>
    
        <li>
                <a href="/de/hund/">Hund - 12</a>
                
                <ul>
                
                        <li>
                                <a href="/de/hund/terrier/">Terrier - 17</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/de/hund/terrier/airedale/">Airedale Terrier - 20</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                        <li>
                                <a href="/de/hund/schweisshund/">Schweisshund - 18</a>
                                
                        </li>
                
                        <li>
                                <a href="/de/hund/jagdhund/">Jagdhund - 19</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/de/hund/jagdhund/ariege/">Braque de l&rsquo;Ari&egrave;ge - 21</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/de/kuh/">Kuh - 13</a>
                
                <ul>
                
                        <li>
                                <a href="/de/kuh/fresisch/">Fresisches Kuh - 15</a>
                                
                        </li>
                
                        <li>
                                <a href="/de/kuh/vonjersey/">Kuh von Jersey - 16</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/de/schwein/">Schwein - 14</a>
                
        </li>
    
        <li>
                <a href="/de/hundliste/">Hund Liste - 22</a>
                
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



{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
<header>
	<title>Dog List</title>
</header>
<body>

    <ul>
    
        <li>
                <a href="/en/dog/terrier/">Terrier - 5</a>
                
                <ul>
                
                        <li>
                                <a href="/en/dog/terrier/airedale/">Airedale Terrier</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/dog/scenthound/">Scenthound - 6</a>
                
        </li>
    
        <li>
                <a href="/en/dog/gundog/">Gundog - 7</a>
                
                <ul>
                
                        <li>
                                <a href="/en/dog/gundog/ariege/">Ariege Pointer</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;


	local $params->{pageid} = 'en/doglist';
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
	<title>Hund Liste</title>
</header>
<body>

    <ul>
    
        <li>
                <a href="/de/hund/terrier/">Terrier - 17</a>
                
                <ul>
                
                        <li>
                                <a href="/de/hund/terrier/airedale/">Airedale Terrier</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/de/hund/schweisshund/">Schweisshund - 18</a>
                
        </li>
    
        <li>
                <a href="/de/hund/jagdhund/">Jagdhund - 19</a>
                
                <ul>
                
                        <li>
                                <a href="/de/hund/jagdhund/ariege/">Braque de l&rsquo;Ari&egrave;ge</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;


	local $params->{pageid} = 'de/hundliste';
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
}


