package Couchbase::Test::Views;
use strict;
use warnings;
use base qw(Couchbase::Test::Common);
use Test::More;
use Couchbase::Bucket;
use Couchbase::Constants;
use Data::Dumper;
use Class::XSAccessor {
    accessors => [ qw(cbo) ]
};

use constant {
    DESIGN_NAME => "blog"
};

my $DESIGN_JSON = {
    _id => "_design/blog",
    language => "javascript",
    views => {
        recent_posts => {
            map => 'function(doc) ' .
            '{ if (doc.date && doc.title) ' .
            '{ emit(doc.date, doc.title); } }'
        }
    }
};

sub setup_client :Test(startup)
{
    my $self = shift;
    $self->mock_init();
    $self->cbo($self->make_cbo);
}

sub TV01_create_ddoc :Test(no_plan) {

    my $self = shift;
    my $o = $self->cbo;
    my $ret = $o->design_put($DESIGN_JSON);
    ok($ret->is_ok, "Design doc put did not return errors");

    my $design = $o->design_get(DESIGN_NAME);
    is($design->path, '_design/blog', "Have path");
    is($design->http_code, 200, "Have HTTP 200");
    ok($design->is_ok, "Overall object OK");
    is_deeply($design->value, $DESIGN_JSON, "Got back view");
}

sub TV02_create_invalid_ddoc :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;

    eval {
        $o->design_put("blah");
    }; like($@, '/path/');

    my $ret = $o->design_put({
        _id => "_design/meh",
        views => {
            foo => "blehblehbleh"
        }
    });

    is($ret->http_code, 400, "Got error for invalid view");
    #is($ret->errinfo->{error}, "invalid_design_document");
    ok($ret->errinfo->{error});
}

sub TV03_view_query :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;

    # First, load up the keys
    my @docs = map {
        Couchbase::Document->new($_->[0], $_->[1])
    } ([ "bought-a-cat" => {
            title => "bought-a-cat",
            body => "I went to the pet store earlier and brought home a little kitty",
            date => "2009/01/30 18:04:11"
        }],
        [ "biking" => {
            title => "Biking",
            body => "My biggest hobby is mountainbiking. The other day..",
            date => "2009/01/30 18:04:11"
        }],
        [ "hello-world" => {
            title => "Hello World",
            body => "Well hello and welcome to my new blog...",
            date => "2009/01/15 15:52:20"
        }]
    );

    # See if we can slurp the view
    my $res = $o->view_slurp(["blog", "recent_posts"], stale => "false");

    my @errors = ();
    foreach my $id (map $_->{id}, @{ $res->value }) {
        my $doc = Couchbase::Document->new($id);
        $o->remove($doc);
        if (!$doc->is_ok) {
            push @errors, $doc;
        }
    }

    ok(!@errors);
    # Need persistence to a single node for views:
    my $batch = $o->batch();
    $batch->upsert($_, { persist_to => 1} ) for @docs;
    $batch->wait_all;

    @errors = ();
    foreach my $doc (@docs) {
        push @errors, $doc if not $doc->is_ok;
    }
    ok(!@errors);
    @errors = ();

    $res = $o->view_slurp(["blog", "recent_posts"], stale => "false");
    isa_ok($res, 'Couchbase::View::Handle');

    my %rkeys = map { $_->{id}, 1 } @{ $res->value };
    my %dkeys = map { $_->id, 1 } @docs;
    is_deeply(\%rkeys, \%dkeys, "Got back the same rows");

    %rkeys = ();
    # Try with the view iterator
    my $iter = $o->view_iterator(["blog", "recent_posts"]);
    my $rescount = 0;
    while (my $row = $iter->next) {
        $rescount++;
        $rkeys{$row->id} = 1;
    }
    is_deeply(\%rkeys, \%dkeys, "View Iterator");
}

sub TV04_vq_errors :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;

    my $res = $o->view_slurp(["nonexist", "nonexist"]);
    isa_ok($res, 'Couchbase::View::Handle');
    ok(!$res->is_ok);
    is($res->http_code, 404);

    my $path_re = '/path/i';

    eval {
        $res = $o->view_slurp();
    }; like($@, $path_re);

    eval {
        $res = $o->view_slurp([]);
    }; like($@, $path_re);

    eval {
        $res = $o->view_slurp([undef, undef]);
    }; like($@, $path_re);

    # Test with invalid view parameters
    $res = $o->view_slurp(["blog", "recent_posts"], group_level=>'hello');
    is($res->http_code, 400);
}

sub TV05_empty_rows :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $res = $o->view_slurp(['blog', 'recent_posts'], limit => 0);
    is_deeply($res->value, [], "No rows");

    $res = $o->view_iterator(['blog', 'recent_posts'], limit => 0);
    ok(!$res->next);
    is($res->info->http_code, 200);
}

sub TV051_include_docs :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $res = $o->view_slurp(['blog', 'recent_posts'], include_docs => 1);
    is(scalar @{$res->rows}, $res->count, "Got all rows");
    foreach my $row (@{$res->rows}) {
        if (!$row->doc) {
            fail("Expected document with include_docs!");
        }
    }
    ok(1, "Got docs");
}

sub TV06_iterator :Test(no_plan) {
    my $self = shift;

    my $iter;
    {
        my $o = $self->make_cbo();
        $iter = $o->view_iterator(['blog', 'recent_posts']);
    }
    ok($iter->next, "Iterator keeps object in scope");

    $iter->stop();

    $iter = $self->cbo->view_iterator(['blog', 'recent_posts']);
    my $count = 0;
    while ((my $row = $iter->next)) {
        $count++;
    }
    ok($iter->count, "Can get count");
    is($iter->count, $count, "Got the exact number of rows");


    # Create a rather long view/design document, so that
    # we can guarantee to get a split buffer.

    my $mapfn = <<EOF;
function (doc) {
    if (doc.tv06_iterator) {
        emit(doc.tv06_iterator);
    }
}
EOF

    my $d_json = {
        _id => '_design/tv06',
        language => 'javascript',
        views => {
            tv06 => {
                map => $mapfn
            }
        }
    };

    my $o = $self->cbo;
    my $rv = $o->design_put($d_json);
    ok($rv->is_ok);

    my @docs = ();
    foreach my $i (0..2000) {
        push @docs, Couchbase::Document->new("key-tv06-$i", { tv06_iterator => $i});
    }
    my $batch = $o->batch;
    $batch->upsert($_) for @docs;
    $batch->wait_all;

    # Make sure there are no store errors
    my @errs = grep { !$_->is_ok } @docs;
    ok(!@errs, "No store errors");

    # Now, query the view
    $iter = $o->view_iterator(['tv06', 'tv06'], stale => 'false');
    # Do we have a count?

    my %rkeys;
    my @kv_errors = ();
    my @rows;
    $count = 0;
    do {
        @rows = $iter->next;
        $count += scalar(@rows);
        my $doc = Couchbase::Document->new("foo", "bar");
        $o->upsert($doc);
        push @kv_errors, $doc unless $doc->is_ok;
    } while (@rows);

    ok(!@kv_errors, "No errors during async handle usage");
    ok($iter->count, "Have count");
    is($count, $iter->count, "Got expected number of rows");
}

sub TV07_synopsis :Test(no_plan) {
    my $self = shift;
    my $client = $self->cbo;

    my $ddoc = {
        '_id' => '_design/blog',
        language => 'javascript',
        views => {
            'recent-posts' => {
                map => 'function(d) { if(d.date) { emit(d.date, d.title); }}'
            }
        }
    };

    my $rv = $client->design_put($ddoc);
    if (!$rv->is_ok) {
        # check for possible errors here..
    }

    # Now, let's load up some documents

    my @posts = (
        Couchbase::Document->new("i-like-perl" => {
            title => "Perl is cool",
            date => "4/26/2013"
        }),
        Couchbase::Document->new("couchbase-and-perl" => {
            title => "Couchbase is super fast",
            date => "4/26/2013"
        })
    );

    # This is a convenience around set_multi. It encodes values into JSON
    my $batch = $client->batch;
    $batch->upsert($_, { persist_to => 1 }) for @posts;
    $batch->wait_all;

    # Now, query the view. We use stale = 'false' to ensure consistency

    $rv = $client->view_slurp(['blog', 'recent-posts'], stale => 'false');
    ok($rv->is_ok, $rv->errstr);

    # Now dump the rows to the screen
    # OK, this is test code. We can't dump to screen, but we can ensure that
    # this works "in general"
    ok($rv->value->[0]->{id});
}

1;
