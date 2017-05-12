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
        plan tests => 2 + 11 * @handles;

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
		loop=>'CGI::Application::Plugin::PageLookup::Loop'
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
       $dbh->do("create table cgiapp_lang (lang varchar(2), collation varchar(2))");
 
	$dbh->do("create table cgiapp_values (lang varchar(2), internalId int, param varchar(20), value TEXT)");
	$dbh->do("create table cgiapp_loops (lang varchar(2), internalId int, loopName varchar(20), lineage varchar(255), rank int, param varchar(20), value TEXT)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/loop1', 'en', 0)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/loop2', 'en', 1)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/loop3', 'en', 2)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId) values('en/loop4', 'en', 3)");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(0,'t/templ/testL1.tmpl', 'daily')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(1,'t/templ/testL1.tmpl', 'daily')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(2,'t/templ/testL1.tmpl', 'daily')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(3,'t/templ/testL1.tmpl', 'daily')");

# First menu test
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 0, 'href1', '')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 0, 'atitle1', 'Home page')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 1, 'href1', '/aboutus')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 1, 'atitle1', 'About us')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 2, 'href1', '/products')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 2, 'atitle1', 'Our products')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 3, 'href1', '/contactus')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 3, 'atitle1', 'Contact us')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 4, 'href1', '/sitemap')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 1, 'menu', '', 4, 'atitle1', 'Sitemap')");

# Second menu test
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 0, 'href1', '')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 0, 'atitle1', 'Home page')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 1, 'href1', '/aboutus')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 1, 'atitle1', 'About us')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 2, 'href1', '/products')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 2, 'atitle1', 'Our products')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 3, 'href1', '/contactus')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 3, 'atitle1', 'Contact us')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 4, 'href1', '/sitemap')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'menu', '', 4, 'atitle1', 'Sitemap')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'submenu1', '2', 0, 'href2', '/wodgets')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'submenu1', '2', 0, 'atitle2', 'Finest wodgets')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'submenu1', '2', 1, 'href2', '/bladgers')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'submenu1', '2', 1, 'atitle2', 'Exquisite bladgers')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'submenu1', '2', 2, 'href2', '/spodges')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 2, 'submenu1', '2', 2, 'atitle2', 'Cheap spodges')");

# Third menu test
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 0, 'href1', '')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 0, 'atitle1', 'Home page')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 1, 'href1', '/aboutus')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 1, 'atitle1', 'About us')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 2, 'href1', '/products')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 2, 'atitle1', 'Our products')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 3, 'href1', '/contactus')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 3, 'atitle1', 'Contact us')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 4, 'href1', '/sitemap')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'menu', '', 4, 'atitle1', 'Sitemap')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu1', '2', 0, 'href2', '/wodgets')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu1', '2', 0, 'atitle2', 'Finest wodgets')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu1', '2', 1, 'href2', '/bladgers')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu1', '2', 1, 'atitle2', 'Exquisite bladgers')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu1', '2', 2, 'href2', '/spodges')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu1', '2', 2, 'atitle2', 'Cheap spodges')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu2', '2,1', 0, 'href3', '/bladgers/runcible')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu2', '2,1', 0, 'atitle3', 'Runcible bladgers')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu2', '2,1', 1, 'href3', '/bladgers/extendible')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu2', '2,1', 1, 'atitle3', 'Extendible bladgers')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu2', '2,1', 2, 'href3', '/bladgers/goldplated')");
$dbh->do("INSERT INTO cgiapp_loops (lang, internalId, loopName, lineage, rank, param, value) VALUES ('en', 3, 'submenu2', '2,1', 2, 'atitle3', 'Gold-plated bladgers')");

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
<body>

</body>
</html>
EOS
;
	local $params->{pageid} = 'en/loop1';
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
<body>

    <ul>
    
        <li>
                <a href="/en/">Home page</a>
                
        </li>
    
        <li>
                <a href="/en/aboutus/">About us</a>
                
        </li>
    
        <li>
                <a href="/en/products/">Our products</a>
                
        </li>
    
        <li>
                <a href="/en/contactus/">Contact us</a>
                
        </li>
    
        <li>
                <a href="/en/sitemap/">Sitemap</a>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;

	local $params->{pageid} = 'en/loop2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, menu'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
<body>

    <ul>
    
        <li>
                <a href="/en/">Home page</a>
                
        </li>
    
        <li>
                <a href="/en/aboutus/">About us</a>
                
        </li>
    
        <li>
                <a href="/en/products/">Our products</a>
                
                <ul>
                
                        <li>
                                <a href="/en/wodgets/">Finest wodgets</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/bladgers/">Exquisite bladgers</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/spodges/">Cheap spodges</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/contactus/">Contact us</a>
                
        </li>
    
        <li>
                <a href="/en/sitemap/">Sitemap</a>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;

	local $params->{pageid} = 'en/loop3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, submenu'
        );
}


{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
<body>

    <ul>
    
        <li>
                <a href="/en/">Home page</a>
                
        </li>
    
        <li>
                <a href="/en/aboutus/">About us</a>
                
        </li>
    
        <li>
                <a href="/en/products/">Our products</a>
                
                <ul>
                
                        <li>
                                <a href="/en/wodgets/">Finest wodgets</a>
                                
                        </li>
                
                        <li>
                                <a href="/en/bladgers/">Exquisite bladgers</a>
                                
                                <ul>
                                
                                <li>
                                        <a href="/en/bladgers/runcible/">Runcible bladgers</a>
                                </li>
                                
                                <li>
                                        <a href="/en/bladgers/extendible/">Extendible bladgers</a>
                                </li>
                                
                                <li>
                                        <a href="/en/bladgers/goldplated/">Gold-plated bladgers</a>
                                </li>
                                
                                </ul>
                                
                        </li>
                
                        <li>
                                <a href="/en/spodges/">Cheap spodges</a>
                                
                        </li>
                
                </ul>
                
        </li>
    
        <li>
                <a href="/en/contactus/">Contact us</a>
                
        </li>
    
        <li>
                <a href="/en/sitemap/">Sitemap</a>
                
        </li>
    
    </ul>

</body>
</html>
EOS
;

	local $params->{pageid} = 'en/loop4';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, subsubmenu'
        );
}

	drop_tables($dbh);
}

sub drop_tables {
	my $dbh = shift;
	$dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_lang");
       $dbh->do("drop table cgiapp_values");
       $dbh->do("drop table cgiapp_loops");
}

