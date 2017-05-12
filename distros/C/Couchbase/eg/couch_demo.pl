#!/usr/bin/perl
# This feature demonstrates several aspects of dealing with Couch using the
# Perl API

use strict;
use warnings;
use blib;
use Couchbase::Bucket;
use Data::Dumper::Concise;
use JSON;
use Carp qw(confess);
use Getopt::Long;


$SIG{__DIE__} = \&confess;

GetOptions('U|connstr=s' => \(my $CONNSTR = "couchbase:///default"),
	   'p|password=s' => \(my $Password = ""),
	   'create-view' => \my $CreateView,
	   'stale-false' => \my $StaleFalse,
	   'h|help' => \my $PrintHelp);

if ($PrintHelp) {
    print <<EOF;
    
Options:
-U --connstr CONNECTION_STRING
-p --password
   --create-view [ whether to create view ]
   --stale-false [ whether to refresh index ]
-h --help This message

EOF

    exit(0);
}


# Create the client
my $cbo = Couchbase::Bucket->new($CONNSTR, {
    password => $Password
});

# Create some sample data to work with
my @posts = (
    Couchbase::Document->new("bought-a-cat" => {
            title => "bought-a-cat",
            body => "I went to the pet store earlier and brought home a little kitty",
            date => "2009/01/30 18:04:11"
        }
    ),
    Couchbase::Document->new("biking" => {
            title => "Biking",
            body => "My biggest hobby is mountainbiking. The other day...",
            date => "2009/01/30 18:04:11"
        }
    ),
    Couchbase::Document->new("hello-world" => {
            title => "Hello World",
            body => "Well hello and welcome to my new blog...",
            date => "2009/01/15 15:52:20"
    })
);

foreach (0..100) {
    my $k = "Post_$_";
    push @posts, Couchbase::Document->new($k => {
	title => "Title_$k",
	body => "Body_$k",
	date => "2012/03/23 13:53:00",
	counter => rand(30000)

    });
}

my $batch = $cbo->batch();
$batch->upsert($_, { persist_to => 1 }) for @posts;
$batch->wait_all();

foreach my $doc (@posts) {
    die "Couldn't set doc: " .$doc->errstr unless $doc->is_ok;
}


#create a design doc
if ($CreateView) {
    my $design_json = {
        _id => "_design/blog",
        language => "javascript",
        views => {
            recent_posts => {
               "map" => 'function(doc) { if(doc.date&&doc.title) { emit(doc.date,doc.title); } }'
            }
        }
    };
    my $rv = $cbo->design_put($design_json);
    die "Couldn't set design" unless $rv->is_ok;
}

my $rows = $cbo->view_slurp("blog/recent_posts", limit => 10)->rows;
printf("view_slurp returned %d rows\n", scalar @$rows);

# More efficient to use an iterator, though.
my $iter = $cbo->view_iterator("blog/recent_posts");
while ((my $row = $iter->next)) {
    my $doc = Couchbase::Document->new($row->id);
    $cbo->get($doc);
    # Replace some of the values..
    $doc->value->{counter} += 20;
    $cbo->replace($doc);
    die "Couldn't replace!" unless $doc->is_ok;
}
