# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
use Encode;
use Data::Dumper;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "foo", utf8 => 0 });
ok $couch->create_table;
is $couch->utf8 => 0;

my $text = 'UTF-8文字列が入ります';
ok !utf8::is_utf8($text);

my $id  = $couch->post({ text => $text });
my $obj = $couch->get($id);

is $obj->{text} => $text;
ok !utf8::is_utf8($obj->{text});

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
