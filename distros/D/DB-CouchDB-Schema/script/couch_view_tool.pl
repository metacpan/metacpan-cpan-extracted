#! /usr/bin/env perl
use DB::CouchDB::Schema::Edit;
use Getopt::Long;
use Pod::Usage;

my $editor = DB::CouchDB::Schema::Edit->new();

#allow me to pas in my own connection info

my ($host,$port,$db);

my $opts = GetOptions (
    "host=s" => \$host,
    "port=i" => \$port,
    "db=s"   => \$db
);

if ($host && $db) {
    my %dbargs = (host => $host);
    $dbargs{port} = $port if $port;
    $dbargs{db} = $db if $db;
    $editor->schema(DB::CouchDB::Schema->new(%dbargs));
}

$editor->run();

