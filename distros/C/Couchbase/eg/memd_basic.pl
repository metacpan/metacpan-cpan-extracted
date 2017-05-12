use strict;
use warnings;
use blib;
use Getopt::Long;
use Data::Printer;
use v5.10;

use Couchbase::Bucket;
use Couchbase::Document;

GetOptions('U|connstr=s' => \(my $CONNSTR = "couchbase://"));

my $cb = Couchbase::Bucket->new($CONNSTR);

say("Creating a document (locally)");
my $doc = Couchbase::Document->new("doc_id", {some=>"value"});

say("Saving it to the cluster");
$cb->upsert($doc);

say("Result: ");
p $doc->as_hash;

say("Get it back: (as a new document)");
$doc = Couchbase::Document->new("doc_id");
$cb->get($doc);
p $doc->as_hash;


say("Updating a document:");
$doc->value->{email} = 'foo@bar.com';
$cb->replace($doc);
p $doc->as_hash;

say("Get a non-existent document..");
$doc = Couchbase::Document->new("dontexist");
$cb->get($doc);
p $doc->as_hash;


say("I can also store things as plain bytes");
open(my $fh, "<", "/dev/urandom") or die "Couldn't open /dev/urandom";
read($fh, my $randbytes = "", 32) or die "Couldn't read!";
close($fh);
$doc = Couchbase::Document->new(
    "bytes", $randbytes,
    { format => COUCHBASE_FMT_RAW }
);
$cb->upsert($doc);
$cb->get($doc);
p $doc->as_hash;

say("And also as Storable");
$doc = Couchbase::Document->new(
    "storable",
    \12345,
    { format => COUCHBASE_FMT_STORABLE }
);
$cb->upsert($doc);
$cb->get($doc);
p $doc->as_hash;


say("You can perform efficient batch operations:");
my $batch = $cb->batch();
my @ids = (qw(foo bar baz));
$batch->upsert(Couchbase::Document->new($_, {$_=>$_})) for @ids;
$batch->wait_all();

$batch = $cb->batch();
say("You can get them back");
$batch->get(Couchbase::Document->new($_)) for @ids;
while (($doc = $batch->wait_one)) {
    p $doc->as_hash;
}
