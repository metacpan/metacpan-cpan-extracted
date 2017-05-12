#!/usr/bin/perl
use warnings;
use strict;

# Tests for checking out and updating working copies in the database.

use Test::More;
use DBI;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Wc;
use Daizu::Util qw( db_row_id );

init_tests(59);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;

# Clean up in case we've already run this.
{
    $db->do("delete from wc_file");
    $db->do("delete from working_copy");
    $db->do("select setval('working_copy_id_seq', 1, false)");
}

my $live_wc = Daizu::Wc->checkout($cms, 'trunk', $cms->ra->get_latest_revnum);
isa_ok($live_wc, 'Daizu::Wc', 'Daizu::Wc->checkout');
is($live_wc->id, $cms->{live_wc_id}, '$live_wc->id');

my $trunk_id = db_row_id($db, 'branch', path => 'trunk');
my $latest_rev = $cms->ra->get_latest_revnum;
count_rows($db, working_copy => 1, qq{
    branch_id = $trunk_id and current_revision = $latest_rev
}, 'first working copy created');

{
    my $got_live_wc = $cms->live_wc;
    isa_ok($got_live_wc, 'Daizu::Wc', '$cms->live_wc');
    is($got_live_wc->id, $live_wc->id, '$cms->live_wc->id');
}

# Check out a second working copy, but update it in stages from the first
# revision to the latest one.
my $other_wc = Daizu::Wc->checkout($cms, 'trunk', 1);
count_rows($db, working_copy => 1, qq{
    branch_id = $trunk_id and current_revision = 1
}, 'second working copy created');
for (1 .. $cms->ra->get_latest_revnum) {
    $other_wc->update($_);
    if ($_ == 5) {
        count_rows($db, working_copy => 1, qq{
            branch_id = $trunk_id and current_revision = 5
        }, 'second working copy updated to r5');
    }
}
count_rows($db, working_copy => 2, qq{
    branch_id = $trunk_id and current_revision = $latest_rev
}, 'second working copy completely updated');


# Check standard property loading.
{
    my ($file_id) = db_row_id($db, 'wc_file',
        path => 'foo.com/blog/2006/fish-fingers/article-1.html',
        wc_id => $live_wc->id,
    );
    count_rows($db, wc_property => 5, qq{
        file_id = $file_id and
        not modified and
        not deleted and
        (
            (name = 'dcterms:issued'  and value = '2006-03-12T08:32:45Z') or
            (name = 'daizu:tags'      and value = 'foo\\n')               or
            (name = 'dc:title'        and value = 'Article 1')            or
            (name = 'daizu:type'      and value = 'article')              or
            (name = 'svn:mime-type'   and value = 'text/html')
        )
    }, 'properties stored in wc_property');

    # file_at_path
    my $file_obj = $live_wc->file_at_path(
        'foo.com/blog/2006/fish-fingers/article-1.html',
    );
    isa_ok($file_obj, 'Daizu::File', '$live_wc->file_at_path');
    is($file_obj->{id}, $file_id, '$live_wc->file_at_path: right file ID');
}


# Check that binary data is loaded correctly, both for the content of files
# and the values of properties.  The test data is the same for both checks.
test_binary_data($live_wc, 'checkout wc');
test_binary_data($other_wc, 'update wc');


# Check custom properties have been loaded correctly.
count_rows($db, wc_file => 6, q{
    content_type = 'image/png'
}, 'svn:mime-type property custom loaded');
count_rows($db, tag => 4, q{
    tag in ('foo', 'bar', 'baz', 'quux')
}, 'daizu:tags property created all necessary tags correctly');
{
    my ($file_id) = db_row_id($db, 'wc_file',
        path => 'example.com/foo.html',
        wc_id => $live_wc->id,
    );
    ok(defined $file_id, 'found foo.html');
    count_rows($db, wc_file_tag => 3, qq{
        tag in ('foo', 'bar', 'quux') and
        file_id = $file_id
    }, 'daizu:tags property linked correct tags to foo.html');
}


# Check author information derived from daizu:author properties.
test_authors($db, 'foo.com');
test_authors($db, 'foo.com/blog/2003');
test_authors($db, 'foo.com/blog/2003/very-old-article.html', 'geoff');
test_authors($db, 'foo.com/blog/2006/parsnips/article-3.html');
test_authors($db, 'foo.com/blog/2006/strawberries/article-4.html',
             'alice', 'bob');
test_authors($db, 'foo.com/author-test.txt', 'geoff');


# Check automatic values for issued_at and modified_at
count_rows($db, wc_file => 2, q{
    path = 'example.com/initially-empty.png' and
    issued_at = '2006-09-09 11:02:09.805202'
}, 'initially-empty.png has correct automatic issued_at');
count_rows($db, wc_file => 2, q{
    path = 'example.com/initially-empty.png' and
    modified_at = '2006-09-09 11:09:31.876657'
}, 'initially-empty.png has correct automatic modified_at');


# Check image_width and image_height.
count_rows($db, wc_file => 2, q{
    path = 'example.com/fractal.png' and
    image_width = 320 and
    image_height = 304
}, 'fractal.png has correct image size recorded');
count_rows($db, wc_file => 2, q{
    path = 'example.com/initially-empty.png' and
    image_width = 64 and
    image_height = 91
}, 'initially-empty.png has correct image size recorded');
count_rows($db, wc_file => 2, q{
    path = 'example.com/type-set-later.gif' and
    image_width = 11 and
    image_height = 9
}, 'type-set-later.gif has correct image size recorded');
count_rows($db, wc_file => 2, q{
    path <> 'example.com/fractal.png' and
    path <> 'example.com/initially-empty.png' and
    path <> 'example.com/type-set-later.gif' and
    image_width is not null and
    image_height is not null
}, 'no other files have image size recorded');


sub count_rows
{
    my ($db, $table, $expected, $where, $description) = @_;
    my ($count) = $db->selectrow_array(qq{
        select count(*)
        from $table
        where $where
    });
    is($count, $expected, $description);
}

sub test_authors
{
    my ($db, $path, @expected) = @_;

    my $sth = $db->prepare(q{
        select p.username, fa.pos
        from file_author fa
        inner join person p on p.id = fa.person_id
        where fa.file_id = ?
    });

    for my $wc_id (1, 2) {
        my $msg = "authors: $path: wc$wc_id";
        my ($file_id) = $db->selectrow_array(q{
            select id
            from wc_file
            where wc_id = ?
              and path = ?
        }, undef, $wc_id, $path);
        assert(defined $file_id);
        $sth->execute($file_id);

        my $n = 1;
        while (my ($username, $pos) = $sth->fetchrow_array) {
            is($pos, $n, "$msg, pos=$n");
            my $exp_user = $expected[$n - 1];
            is($username, $exp_user, "$msg, person=$exp_user");
            ++$n;
        }

        is($n - 1, scalar @expected, "$msg, number");
    }
}

sub test_binary_data
{
    my ($wc, $wc_name) = @_;

    my $expected_start = "GIF89a\x0B\x00\x09\x00\xF1\x01\x00\xB7\x19\x19";
    my $expected_length = 104;

    my $msg = "file data, $wc_name";
    my $file_1 = $live_wc->file_at_path('example.com/type-set-later.gif');
    my $file_data = $file_1->data;
    is(length($$file_data), $expected_length, "$msg: length");
    is(substr($$file_data, 0, 16), $expected_start, "$msg: bytes");

    $msg = "property data, $wc_name";
    my $file_2 = $live_wc->file_at_path('example.com/binary-property.txt');
    my $property_data = $file_2->property('binary-data');

    SKIP: {
        skip 'binary property values corrupted by bug in Subversion Perl API', 3
            if length $property_data == 7;

        is(length($property_data), $expected_length, "$msg: length");
        is(substr($property_data, 0, 16), $expected_start, "$msg: bytes");

        is($$file_data, $property_data,
           "file and property data, $wc_name: match");
    }
}

# vi:ts=4 sw=4 expandtab filetype=perl
