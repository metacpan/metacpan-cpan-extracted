use strict;
use warnings;
use Data::Dumper;
use Storable::CouchDB;
use Test::More tests =>8;

BEGIN {


  use_ok('LWP');
  use_ok('Storable::CouchDB');
  my $s = Storable::CouchDB->new;

  ok("sprintf $s->retrieve('doc')"); #undef if not exists
  ok("sprintf $s->store('doc1' => 'data');");

  ok('sprintf $s->store("doc2" => {"my" => "data"});');
  ok('sprintf $s->store("doc3" => ["my", "data"]);');

  ok("sprintf $s->store('doc4' => undef);");
  ok("sprintf $s->delete('doc');");


  my $browser = LWP::UserAgent->new();
  my $seite = "http://127.0.0.1:5984";

 #    $seite = $browser->get($seite);
#  ok($seite->is_success,"couch is there");


     $seite = "http://127.0.0.1:5984";

      $seite = $browser->get($seite);

#  ok($seite->is_success,"default user is there on couch on table");





}

1;

__DATA__
