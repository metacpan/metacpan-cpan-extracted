use strict;
use warnings;

use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use App::AutoCRUD;
use FindBin;
use DBI;
use JSON::MaybeXS;
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
  app => { name => "Demo",
           title => "AutoCRUD demo application",
         },
  datasources => {
    Chinook => {
      dbh     => {connect => $in_memory_dbh_copy},
      filters => {
        include => '^[^iI]', # for test -- include all tables except those
                             # that start with 'i' or 'I'
        exclude => 'mer$',   # for test -- exclude tables that end in 'mer'
       }
     },
   },
};


# instantiate the app
my $crud = App::AutoCRUD->new(config => $config);
my $app  = $crud->to_app;

# we will need a JSON decoder for testing. Since it uses in-memory
# unicode strings, utf8 must be turned off
my $json_obj = JSON::MaybeXS->new->utf8(0);

# start testing
test_psgi $app, sub {
  my $cb = shift;

  # homepage
  my $res = $cb->(GET "/home");
  like $res->content, qr/AutoCRUD demo application/, "Title from config";
  like $res->content, qr/Chinook/,                   "Home contains Chinook datasource";

  # schema page
  $res = $cb->(GET "/Chinook/schema/tablegroups");
  like   $res->content, qr/Artist/,       "Artist listed";
  like   $res->content, qr/Album/,        "Album listed";
  like   $res->content, qr/Track/,        "Track listed";
  unlike $res->content, qr/Invoice/i,     "no table starts with 'i'";
  unlike $res->content, qr/Customer/i,    "exclude table ending in 'mer'";

  # table description
  $res = $cb->(GET "/Chinook/table/MediaType/descr");
  like $res->content, qr(INTEGER\s+NOT\s+NULL),      "MediaTypeId datatype";

  # search form (display)
  $res = $cb->(GET "/Chinook/table/MediaType/search");
  like $res->content, qr(<span class="TN_label colname pk">MediaTypeId</span>),
                                                     "MediaTypeId present, pk detected";

  # search form (POST)
  $res = $cb->(POST "/Chinook/table/MediaType/search");
  is $res->code, 303,                                "redirecting POST search";
  like $res->header('location'), qr/^list\?/,        "redirecting to 'list'";

  # list
  $res = $cb->(GET "/Chinook/table/MediaType/list?");
  like $res->content, qr(records 1 - 5),             "found 5 records";
  like $res->content, qr(MPEG),                      "found MPEG";
  like $res->content, qr(AAC),                       "found AAC";
  $res = $cb->(GET "/Chinook/table/MediaType/list?Name=*MPEG*");
  like $res->content, qr(LIKE \?),                   "SQL LIKE";
  like $res->content, qr(records 1 - 2),             "found 2 records";
  like $res->content, qr(Protected MPEG),            "found Protected MPEG";

  # id
  $res = $cb->(GET "/Chinook/table/Album/id/1");
  like $res->content, qr(Album/update[^"]*">),       "update link";

  $res = $cb->(GET "/Chinook/table/Album/id/1.yaml");
  like $res->content, qr(AlbumId:\s*1),              "yaml view";

  $res = $cb->(GET "/Chinook/table/Album/id/1.json");
  like $res->content, qr("AlbumId"\s*:\s*1),         "json view";

  $res = $cb->(GET "/Chinook/table/Album/id/1.xml");
  like $res->content, qr(<row[^>]*AlbumId="1"),      "xml view";

  # TODO : test list outputs as xlsx,


  # test an update with special and accented characters
  my $new_title = q{il était une "bergère"};
  utf8::upgrade($new_title);
  $res = $cb->(POST "/Chinook/table/Album/update",
               {'where.AlbumId' => 1, 'set.Title'  => $new_title});
  $res = $cb->(GET "/Chinook/table/Album/id/1.json");
  my $data = $json_obj->decode($res->content);
  is($data->{row}{Title}, $new_title,                 "updated title");

  # update without a -where clause
  $res = $cb->(POST "/Chinook/table/Album/update", {'set.Title' => 'foobar'});
  is $res->code, 500;
  like $res->content, qr(without any '-where'),       "update without -where";

  # update with an empty -where clause
  $res = $cb->(POST "/Chinook/table/Album/update", {'set.Title'     => 'foobar',
                                                    'where.AlbumId' => ""});
  is $res->code, 500;
  like $res->content, qr(without any '-where'),       "update with empty -where";

  # delete without a -where clause
  $res = $cb->(POST "/Chinook/table/Album/delete");
  is $res->code, 500;
  like $res->content, qr(without any '-where'),       "delete without -where";

  # delete with an empty -where clause
  $res = $cb->(POST "/Chinook/table/Album/delete", {'where.AlbumId' => ""});
  is $res->code, 500;
  like $res->content, qr(without any '-where'),       "delete with empty -where";




  # TODO : test descr, update, insert, delete
};

# signal end of tests
done_testing;


