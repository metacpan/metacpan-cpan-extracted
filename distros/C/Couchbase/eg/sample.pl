#!/usr/bin/env perl
use strict;
use warnings;
use blib; # Needed for local tree
use Data::Printer; # To print out stuff
use Carp::Always; # Verbose stack traces
use Couchbase::Bucket;
use Couchbase::Document;
use Couchbase::Constants;
use Couchbase::BucketConfig;
use Getopt::Long;

GetOptions(
    'U|connstr=s' => \(my $CONNSTR='couchbase://localhost/default')
);

# Print the version of the library being used
print "=== Version Information ===\n";
print "Using libcouchbase " . p(Couchbase::lcb_version()) . "\n";
print "Using Perl Couchbase ". p($Couchbase::VERSION) . "\n";

sub run_default_example {
    print "\n=== Basic Key-Value Example ===\n";
    # Create a new bucket instance, using the connection string
    my $cb = Couchbase::Bucket->new($CONNSTR);

    # All operations require a Document. This is simple enough.
    # To create a document to retrieve (where the document does not have an
    # initial value), simply use the one argument form
    my $doc = Couchbase::Document->new("foo", "doo value");

    $cb->upsert($doc);

    # Then load it
    $cb->get($doc);

    # Check to see if it succeeded
    if (!$doc->is_ok()) {
        die("Couldn't load document!");
    }

    printf("Here's the document after it's been loaded:\n%s", p($doc->as_hash));

    # You can also use the same model to set documents. Either use the two-argument
    # Couchbase::Document constructor, or set the value explicitly
    $doc->value({
        name => "FOO",
        email => 'foo@bar.com',
        friends => [qw(bar baz blah gah)]
    });

    # And then upsert the document
    $cb->upsert($doc, { persist_to => 1 });

    # You can also modify the document:
    push @{ $doc->value->{friends} }, ('Barrack H. Obama', 'George W. Bush');
    $cb->replace($doc);

    # Performing batched operations is now simple as well. Simply initiate
    # a batch context using the Couchbase::Bucket::batch() method
    my $batch = $cb->batch();
    my @docs = map { Couchbase::Document->new("user:$_", { name => $_ }) } (qw(foo bar baz));

    # We can set them all like this:
    $batch->upsert($_) for @docs;
    $batch->wait_all();

    print "\n";
    foreach (@docs) {
        die("Couldn't upsert doc! " . $_->errstr) unless $_->is_ok;
        printf("Multi upset of %s ok with cas=0x%x\n", $_->id, $_->_cas);
    }
    # The various wait_* methods in the batch context actually perform the IO, while
    # the other methods merely _schedule_ the operations. The interface is exactly
    # the same as the non-batched methods.
}

sub run_views_example {
    printf("\n=== Views Example ===\n");
    # Here is an example of iterating through the documents of a view result
    my $cb = Couchbase::Bucket->new($CONNSTR);

    # Try iterating
    my $nrows = 0;
    my $viter = $cb->view_iterator("beer/brewery_beers");
    while (my $row = $viter->next) {
        $nrows++;
    }
    printf("\nIterated over %d view rows!\n", $nrows);

    printf("\nWill do a batch get for document IDs in the view results\n");
    my $batch = $cb->batch();
    my $rv = $cb->view_slurp(['beer', 'brewery_beers'], limit => 5);
    $batch->get(Couchbase::Document->new($_->id)) for @{$rv->rows};

    # Using the $batch->wait_one() sequence, you can _iterate_ over the batched
    # results as they are retrieved from the network. This allows your application
    # to handle the results more quickly, as well as save on memory and increase
    # application speed.
    while ((my $doc = $batch->wait_one)) {
        printf("Got result for document %s. OK=%d (%s)\n", $doc->id, $doc->is_ok, $doc->errstr);
    }
}

sub run_misc_example {
    printf("\n=== Other Features ===\n");
    my $cb = Couchbase::Bucket->new($CONNSTR);

    printf("Will show the settings hash:\n");
    p $cb->settings();

    # Alternate (non-JSON) format:
    my $doc_storable = Couchbase::Document->new("storable", \1,
                                                { format => COUCHBASE_FMT_STORABLE });
    $cb->upsert($doc_storable);
    $cb->get($doc_storable);

    # misc. methods
    $cb->touch($doc_storable);
    $cb->get_and_touch($doc_storable);

    # lock and unlock
    $cb->get_and_lock($doc_storable, { lock_duration => 5 });
    $cb->unlock($doc_storable);

    # Demonstrate ignore_cas
    my $doc = Couchbase::Document->new('foo', 'hello');
    $cb->upsert($doc);
    my $doc2 = $doc->copy();
    $doc2->_cas(0xdeadbeef);
    $cb->upsert($doc2);
    if (!$doc2->is_cas_mismatch) {
        die("Expected mismatch!");
    }
    $cb->upsert($doc2, { ignore_cas => 1 });
    if (!$doc2->is_ok) {
        die("ignore_cas not honored");
    }

    sub xfrm {
        my $h = ${$_[0]};
        $h = {} unless ref $h eq 'HASH';
        return 0 if exists $h->{name};
        $h->{name} = "Hello";
    }

    # Transform a loaded document
    $cb->transform($doc, \&xfrm);

    # Load a document by its ID and transform it
    my $newdoc = $cb->transform_id("foo", \&xfrm);

    print "\nFetching stats..\n";
    my $statsres =  $cb->stats();
    while (my ($server,$stats) = each %{$statsres->value}) {
        printf("Server %s is running Couchbase version %s and has performed a total of %d operations\n",
               $server, $stats->{version}, $stats->{cmd_total_ops});
    }

    print "\nGetting key stats (only works on keys without spaces) ..\n";
    p $cb->keystats("foo");

    p $cb->keystats('with space');

    printf("Bucket name is %s\n", $cb->bucket);

    printf("\nRunning OBSERVE command..\n");
    my $obsret = $cb->observe($doc);
    p $obsret;

    printf("\nPrinting cluster node information..\n");
    my $vbc = $cb->get_bucket_config;
    p $vbc->nodes;
}

run_default_example();
eval { run_views_example(); };
if ($@) {
    warn("Couldn't run views example: $@");
}

run_misc_example();
