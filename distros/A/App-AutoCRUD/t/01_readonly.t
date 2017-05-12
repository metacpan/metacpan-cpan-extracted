use strict;
use warnings;

use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use App::AutoCRUD;
use FindBin;
use DBI;
use Encode;

my $sqlite_path = "$FindBin::Bin/data/"
                . "Chinook_Sqlite_AutoIncrementPKs_empty_tables.tst_sqlite";

# connect to an in-memory copy of the database
my $in_memory_dbh_copy = sub  {
  my $connect_options = {
    RaiseError     => 1,
    sqlite_unicode => 1,
  };
  my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", "", "", $connect_options);
  $dbh->sqlite_backup_from_file($sqlite_path);
  return $dbh;
};


# setup config
my $config = {
  app => { name     => "Demo",
           title    => "AutoCRUD demo application",
           readonly => 1,
         },
  datasources => {
    Chinook => {
      dbh     => {connect => $in_memory_dbh_copy},
     },
   },
};


# instantiate the app
my $crud = App::AutoCRUD->new(config => $config);
my $app  = $crud->to_app;

# start testing
test_psgi $app, sub {
  my $cb = shift;

  # homepage
  my $res = $cb->(GET "/home");
  like $res->content, qr/readonly/i,      "Home page displays 'readonly'";

  # list
  $res = $cb->(GET "/Chinook/table/MediaType/list?");
  unlike $res->content, qr/update|delete|insert/i,   "no update links in list";

  # id
  $res = $cb->(GET "/Chinook/table/Album/id/1");
  unlike $res->content, qr/update|delete|insert/i,   "no update links in record";

  $res = $cb->(POST "/Chinook/table/Album/update", {'set.Title'     => 'foobar',
                                                    'where.AlbumId' => 1});
  is $res->code, 500;
  like $res->content, qr(readonly),        "update forbidden - readonly";

  $res = $cb->(POST "/Chinook/table/Album/delete", {'where.AlbumId' => 1});
  is $res->code, 500;
  like $res->content, qr(readonly),        "delete forbidden - readonly";

  $res = $cb->(POST "/Chinook/table/Album/update", {'set.Title'     => 'foobar',
                                                    'where.AlbumId' => 1});
  is $res->code, 500;
  like $res->content, qr(readonly),        "update forbidden - readonly";

  $res = $cb->(POST "/Chinook/table/Album/insert", {});
  is $res->code, 500;
  like $res->content, qr(readonly),        "insert forbidden - readonly";

};

# signal end of tests
done_testing;


