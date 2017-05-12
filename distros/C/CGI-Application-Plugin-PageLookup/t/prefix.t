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
	plan tests => 1+7 * @handles;
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {prefix=>'blah_'};

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

       $dbh->do("create table blah_pages (pageId varchar(255), lang varchar(2), internalId int, home TEXT, path TEXT)");
       $dbh->do("create table blah_structure (internalId int, template varchar(20), changefreq varchar(20))");
       $dbh->do("create table blah_lang (lang varchar(2))");
 
       $dbh->do("insert into  blah_pages (pageId, lang, internalId, home, path) values('test1', 'en', 0, 'HOME', 'PATH')");
       $dbh->do("insert into  blah_pages (pageId, lang, internalId, home, path) values('test2', 'en', 1, 'HOME1', 'PATH1')");
       $dbh->do("insert into  blah_pages (pageId, lang, internalId, home, path) values('en/404', 'en', 2, 'HOME1', 'PATH1')");
       $dbh->do("insert into  blah_lang (lang) values('en')");
       $dbh->do("insert into  blah_structure(internalId, template) values(0,'t/templ/test.tmpl')");
       $dbh->do("insert into  blah_structure(internalId, template) values(1,'t/templ/test.tmpl')");
       $dbh->do("insert into  blah_structure(internalId, template) values(2,'t/templ/testN.tmpl')");


{
        my $app = TestApp->new(QUERY => CGI->new(""), PARAMS=>$params);
        isa_ok($app, 'CGI::Application');

        response_like(
                $app,
                qr{^Encoding: utf-8|Content-Type: text/html; charset=utf-8$},
                "Hello World: basic_test",
                'TestApp, blank query',
        );
}

{
my $html=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME
  <p>
  My Path is set to PATH
  </body>
  </html>
EOS
;

        local $params->{pageid} = 'test1';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Encoding: utf-8|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test1'
        );
}

{
my $html=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1
  </body>
  </html>
EOS
;

        local $params->{pageid} = 'test2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Encoding: utf-8|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test2'
        );
}
        drop_tables($dbh);
}

sub drop_tables {
	my $dbh = shift;

	$dbh->do("drop table blah_pages");
       $dbh->do("drop table blah_structure");
       $dbh->do("drop table blah_lang");
}


