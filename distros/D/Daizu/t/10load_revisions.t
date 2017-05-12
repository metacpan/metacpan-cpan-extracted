#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Util qw( db_row_exists db_row_id db_select );
use Daizu::Revision qw( file_guid );

init_tests(140);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;

# Clean up in case we've already run this.
{
    $db->do("delete from file_path");
    $db->do("delete from file_guid");
    $db->do("delete from revision");
    $db->do("delete from branch where path <> 'trunk'");
}

my $trunk_id = db_row_id($db, 'branch', path => 'trunk');
ok(defined $trunk_id, "branch 'trunk' found");

my $latest_rev = $cms->ra->get_latest_revnum;

# This shouldn't do anything, if the target revision is too big.
eval { $cms->load_revision(9999) };
ok($@, 'fails to load non-existant revision');
is(max_revnum_loaded($cms), undef, 'no revisions loaded yet');

load_upto_revnum($cms, 1);

# Test custom GUIDs are created at the right time.
{
    # These two files alwsays have the same custom GUIDs starting from r12
    my @always_custom = (
        'example.com/custom-guid-1'   => 'http://guid.org/always',
        'example.com/custom-guid-dir' => 'http://guid.org/always2',
    );

    # No custom GUIDs defined yet
    load_upto_revnum($cms, 11);
    test_custom_guids($cms, $trunk_id, 11);

    # Some custom GUIDs are added on newly created files
    load_upto_revnum($cms, 12);
    test_custom_guids($cms, $trunk_id, 12, @always_custom);

    # Another custom GUID is added on a file which already existed
    my $guid = file_guid($db, $trunk_id, 'example.com/custom-guid-2', 12);
    assert(defined $guid && !$guid->{custom_uri});
    my $orig_uri = $guid->{uri};
    load_upto_revnum($cms, 13);
    test_custom_guids($cms, $trunk_id, 13,
        @always_custom,
        'example.com/custom-guid-2'   => 'http://guid.org/sometimes',
    );

    # One is changed to a different custom URI
    load_upto_revnum($cms, 14);
    test_custom_guids($cms, $trunk_id, 14,
        @always_custom,
        'example.com/custom-guid-2'   => 'http://guid.org/changed',
    );

    # A custom GUID is removed
    load_upto_revnum($cms, 15);
    test_custom_guids($cms, $trunk_id, 15, @always_custom);
    $guid = file_guid($db, $trunk_id, 'example.com/custom-guid-2', 15);
    assert(defined $guid);
    ok(!$guid->{custom_uri}, "GUID reverted to being non-custom");
    is($guid->{uri}, $orig_uri, "GUID URI reverted to original value");
}

{
    my $r = $cms->load_revision;
    is($r, $latest_rev, 'claims to have loaded up to latest revision');
    is(max_revnum_loaded($cms), $latest_rev, 'has loaded up to latest rev');

    my ($num_revisions) = $db->selectrow_array(q{
        select count(*) from revision
    });
    is($num_revisions, $latest_rev, "all revisions have 'revision' records");
}

# revision.committed_at
{
    my $time = db_select($db, 'revision', { revnum => 33 }, 'committed_at');
    is($time, '2006-09-09 11:02:09.805202', 'revision.committed_at for r33');
    $time = db_select($db, 'revision', { revnum => 34 }, 'committed_at');
    is($time, '2006-09-09 11:09:31.876657', 'revision.committed_at for r34');
}

# file_guid.first_revnum and file_guid.last_changed_revnum
{
    my ($guid_id) = db_select($db, 'file_path',
        { path => 'example.com/initially-empty.png' },
        'guid_id',
    );
    assert(defined $guid_id);
    my ($first, $last) = db_select($db, file_guid => $guid_id,
                                   qw( first_revnum last_changed_revnum ));
    is($first, 33, 'file_guid.first_revnum');
    is($last, 34, 'file_guid.last_changed_revnum');
}


# Check that the right branches have been created, and keep their IDs
# for later.  They should have been created by this point.
my $tag_id = db_row_id($db, 'branch', path => 'tags/before-copies');
ok(defined $tag_id, "branch 'tags/before-copies' found");
my $branch_id = db_row_id($db, 'branch', path => 'branches/frob/quux');
ok(defined $branch_id, "branch 'branches/frob/quux' found");
my $tag2_id = db_row_id($db, 'branch', path => 'tags/renamed-tag');
ok(defined $tag2_id, "branch 'tags/renamed-tag' found");

# Check that there aren't any excess branches.
{
    my ($num_branches) = $db->selectrow_array(q{
        select count(*)
        from branch
    });
    is($num_branches, 4, 'no extra branches created');
}


# Tests that the right GUIDs and file paths exist.
test_guid_paths($cms, 1,
    [ $trunk_id,  'example.com', 1,  undef ],
    [ $tag_id,    'example.com', 3,  22    ],
    [ $tag2_id,   'example.com', 23, undef ],
    [ $branch_id, 'example.com', 6,  7     ],
    [ $branch_id, 'renamed.org', 8,  undef ],
);

test_guid_paths($cms, 0,
    [ $trunk_id,  'example.com/foo.html',       1,  6     ],
    [ $trunk_id,  'example.com/recovered.html', 9,  undef ],
    [ $tag_id,    'example.com/foo.html',       3,  22    ],
    [ $tag2_id,   'example.com/foo.html',       23, undef ],
    [ $branch_id, 'example.com/foo.html',       6,  7     ],
    [ $branch_id, 'renamed.org/foo.html',       8,  undef ],
);

test_guid_paths($cms, 0,
    [ $trunk_id,  'example.com/foo.html', 7, undef ],
);

test_guid_paths($cms, 0,
    [ $trunk_id,  'example.com/bar.html', 2,  3     ],
    [ $trunk_id,  'example.com/baz.html', 4,  4     ],
    [ $trunk_id,  'example.com/bax.html', 5,  undef ],
    [ $tag_id,    'example.com/bar.html', 3,  22    ],
    [ $tag2_id,   'example.com/bar.html', 23, undef ],
    [ $branch_id, 'example.com/bax.html', 6,  7     ],
    [ $branch_id, 'renamed.org/bax.html', 8,  undef ],
);

test_guid_paths($cms, 0,
    [ $trunk_id,  'example.com/foo_copy.html', 4, undef ],
    [ $branch_id, 'example.com/foo_copy.html', 6, 7     ],
    [ $branch_id, 'renamed.org/foo_copy.html', 8, undef ],
);

test_guid_paths($cms, 1,
    [ $trunk_id,  'example.com/things', 10, 10 ],
);

for (1 .. 3) {
    test_guid_paths($cms, 0,
        [ $trunk_id, "example.com/things/$_", 10, 10 ],
    );
}

test_guid_paths($cms, 0,
    [ $trunk_id,  'example.com/custom-guid-1', 12, undef ],
);

test_guid_paths($cms, 0,
    [ $trunk_id,  'example.com/custom-guid-2', 12, undef ],
);

test_guid_paths($cms, 1,
    [ $trunk_id,  'example.com/custom-guid-dir', 12, undef ],
);


# Test standard GUID minting.
for ([ 'top-level', 1 ],
     [ 'example.com', 2 ],
     [ 'example.com/foo.html', 2 ],
     [ 'example.com/dir', 3 ],
     [ 'example.com/dir/file', 3 ])
{
    my ($path, $entity_num) = @$_;
    my $guid_id = db_select($db, 'file_path',
        { branch_id => $trunk_id, path => $path, last_revnum => undef },
        'guid_id',
    );
    my ($guid, $custom) = db_select($db, file_guid => $guid_id,
        'uri', 'custom_uri',
    );
    ok(!$custom, "$path shouldn't have custom GUID URI");
    is($guid, "tag:example$entity_num.com,2006:$guid_id",
       "$path has correct GUID URI");
}


sub max_revnum_loaded
{
    my ($cms) = @_;
    my ($max_revnum) = $cms->db->selectrow_array(q{
        select max(revnum) from revision
    });
    return $max_revnum;
}

sub load_upto_revnum
{
    my ($cms, $revnum) = @_;
    my $r = $cms->load_revision($revnum);
    is($r, $revnum, "claims to have loaded up to revision $revnum");
    is(max_revnum_loaded($cms), $revnum, "has loaded up to revision $revnum");
}

sub test_custom_guids
{
    my ($cms, $trunk_id, $revnum, %uri) = @_;

    while (my ($path, $custom_uri) = each %uri) {
        my $guid = file_guid($cms->db, $trunk_id, $path, $revnum);
        assert(defined $guid);
        ok($guid->{custom_uri}, "custom URI defined (r$revnum $path)");
        is($guid->{uri}, $custom_uri, "correct custom URI (r$revnum $path)");
    }

    my ($num_custom_guids) = $db->selectrow_array(q{
        select count(*)
        from file_guid
        where custom_uri
    });
    is($num_custom_guids, (scalar keys %uri),
       "no extra custom GUIDs in r$revnum");
}

# Each item in @path should be an array ref with the following entries:
#    0 - ID number of the branch
#    1 - path
#    2 - start revnum
#    3 - end revnum, or undef if it comes up to the latest revision
sub test_guid_paths
{
    my ($cms, $is_dir, @path) = @_;
    assert(@path);

    my $db = $cms->db;
    my $name = "(r$path[0][2] $path[0][1])";

    my $guid = file_guid($db, $path[0][0], $path[0][1], $path[0][2]);
    ok(defined $guid, "found GUID ID $name");
    my $guid_id = $guid->{id};

    ok(db_row_exists($db, file_path =>
        guid_id => $guid_id,
        branch_id => $path[0][0],
        path => $path[0][1],
        first_revnum => $path[0][2],
    ), "confirmed GUID ID $name");

    ok(db_row_exists($db, file_guid =>
        id => $guid_id,
        is_dir => ($is_dir ? 't' : 'f'),
    ), "correct is_dir $name");

    for (@path) {
        my $path_name = "b$_->[0] r$_->[2]-" .
                        (defined $_->[3] ? $_->[3] : '') .
                        " $_->[1]";
        ok(db_row_exists($db, file_path =>
            guid_id => $guid_id,
            branch_id => $_->[0],
            path => $_->[1],
            first_revnum => $_->[2],
            last_revnum => $_->[3],
        ), "GUID $guid_id: $path_name");
    }

    my ($num_guid_paths) = $db->selectrow_array(q{
        select count(*)
        from file_path
        where guid_id = ?
    }, undef, $guid_id);
    is($num_guid_paths, scalar @path, "no extra paths $name");
}

# vi:ts=4 sw=4 expandtab filetype=perl
