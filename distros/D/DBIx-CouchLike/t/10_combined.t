# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;
do_sql($dbh);

my $couch_p = DBIx::CouchLike->new({ dbh => $dbh, table => "page" });
my @v = $couch_p->view('all/list');
is_deeply( \@v => [
    { 'value' => '1', 'id' => '/', 'key' => '/' },
    { 'value' => '1', 'id' => '/foo.html', 'key' => '/foo.html' }
]);

my $p = $couch_p->get('/');
DBI->trace(0);
$couch_p->put($p);
DBI->trace(0);

@v = $couch_p->view('all/list');
is_deeply( \@v => [
    { 'value' => '1', 'id' => '/', 'key' => '/' },
    { 'value' => '1', 'id' => '/foo.html', 'key' => '/foo.html' }
]);


$dbh->commit unless $ENV{DSN};
$dbh->disconnect;

sub do_sql {
    my $dbh = shift;
    my $sqls =<<'_END_OF_SQL_';
CREATE TABLE page_data (id text not null primary key, value text);
INSERT INTO "page_data" VALUES('/','{"foo":"bar"}');
INSERT INTO "page_data" VALUES('/foo.html','{"foo":"baz"}');
INSERT INTO "page_data" VALUES('_design/all','{"views":{"list":{"map":" sub { my($o,$e)=@_; $e->( $o->{_id}, 1 ) } "}}}');
CREATE TABLE page_map (design_id text not null, id text not null, key text not null, value text );
INSERT INTO "page_map" VALUES('_design/all/list','/','/','1');
INSERT INTO "page_map" VALUES('_design/all/list','/foo.html','/foo.html','1');
CREATE INDEX page_map_idx  ON page_map (design_id, key);
_END_OF_SQL_

    for my $sql ( split /\n/, $sqls ) {
        $dbh->do($sql);
    }
};
