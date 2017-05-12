# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
use Encode;
use utf8;

BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "foo" });
ok $couch->create_table;
my $id = $couch->post({ text => 'UTF-8文字列が入ります' });
my $obj = $couch->get($id);
is $obj->{text} => 'UTF-8文字列が入ります';
ok utf8::is_utf8($obj->{text});

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
