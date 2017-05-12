#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use t::app::Main;
use t::lib::Utils;
use DateTime;

eval "use DBIx::Class::Result::Validation";
if ($@)
{
  plan skip_all => "This test is about compatibility with component Result::Validation but you don't install it";
  exit;
}
plan tests => 2;

my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({ add_drop_table => 1 });
populate_database($schema);

my @rs = $schema->resultset('ValidCd')->search({'title' => 'Bad'});
my $cd = $rs[0];
my $rh_result = {'artistid' => $cd->artistid(),'cdid' => $cd->cdid(),'title' => $cd->title, 'date' => undef, 'last_listen' => undef};
is_deeply( $cd->get_column_data, $rh_result, "column_data return all column value of object");

$cd->add_result_error("key 1", "comment 1 to key 1");
$cd->add_result_error("key 1", "comment 2 to key 1");
$cd->add_result_error("key 2", "comment 1 to key 2");
$rh_result->{'result_errors'} = {'key 1' => ["comment 1 to key 1","comment 2 to key 1"],'key 2' => ["comment 1 to key 2"]};
is_deeply( $cd->get_column_data, $rh_result, "column_data return all column value of object with result_errors column");


