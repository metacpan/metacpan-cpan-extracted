#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::Test qw( init_tests test_cmp_guids test_cmp_urls );
use Daizu::Publish qw(
    file_changes_between_revisions
    do_publishing_url_updates
);
use Daizu::Util qw(
    w3c_datetime
    db_row_id db_select update_all_file_urls
);

init_tests(102);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;

# Find the GUID IDs of some files for testing against.
# Keys is short name which is only used in this script.  Value is GUID ID.
# These are all looked up in the trunk.
my %guid;
{
    # Revision number it first existed in and path of each one.
    my %guids_to_look_up = (
        bar => [ 2, 'example.com/bar.html' ],
        example_dir => [ 1, 'example.com' ],
        foo => [ 1, 'example.com/foo.html' ],
        foo_2 => [ 7, 'example.com/foo.html' ],
        foo_copy => [ 4, 'example.com/foo_copy.html' ],
    );
    while (my ($name, $info) = each %guids_to_look_up) {
        my ($revnum, $path) = @$info;
        my $guid_id = db_select($db, 'file_path',
            { branch_id => 1, first_revnum => $revnum, path => $path },
            'guid_id',
        );
        assert(defined $guid_id);
        $guid{$name} = $guid_id;
    }
}


# _is_article
is(Daizu::Publish::_is_article({ 'daizu:type' => " article\n" }), 1,
   '_is_article: daizu:type=article');
is(Daizu::Publish::_is_article({ 'daizu:type' => " widget\n" }), 0,
   '_is_article: daizu:type=widget');
is(Daizu::Publish::_is_article({ 'daizu:frob' => 'foobar' }), 0,
   '_is_article: daizu:type missing');
is(Daizu::Publish::_is_article(undef), 0, '_is_article: no props');

# _file_path
{
    my $mock_wc = { branch_id => 1, branch_path => 'trunk' };
    is(Daizu::Publish::_file_path($db, $mock_wc, $guid{bar}, 3),
       'trunk/example.com/bar.html', '_file_path: bar in r3');
    is(Daizu::Publish::_file_path($db, $mock_wc, $guid{bar}, 4),
       'trunk/example.com/baz.html', '_file_path: bar in r4');
    is(Daizu::Publish::_file_path($db, $mock_wc, $guid{bar}, $_),
       'trunk/example.com/bax.html', "_file_path: bar in r$_")
        for 5, 17;
}

# _file_data_hash
is(Daizu::Publish::_file_data_hash($cms->ra, 'trunk/example.com/bar.html', 3),
   'zBYevSWysnre2QDWIBovkdXFh1k', '_file_data_hash: small text file');
is(Daizu::Publish::_file_data_hash($cms->ra, 'trunk/foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg', 34),
   '2z+WGSB+Y3uvKXRlECky3G5UxEk', '_file_data_hash: large image file');
is(Daizu::Publish::_file_data_hash($cms->ra, 'trunk/example.com/swap-urls/foo', 44),
   '2jmj7l5rSw0yVb/vlWAYkK/YBwk', '_file_data_hash: empty file');

# _issued_at
{
    my $dt = Daizu::Publish::_issued_at($db, $guid{bar},
        { 'dcterms:issued' => '2005-06-10T16:23:00Z' });
    check_date('_issued_at: from property', $dt, '2005-06-10T16:23:00Z');
    $dt = Daizu::Publish::_issued_at($db, $guid{bar},
        { 'dcterms:issued' => 'something invalid' });
    check_date('_issued_at: bad property', $dt, '2006-07-11T13:58:47.564353Z');
    $dt = Daizu::Publish::_issued_at($db, $guid{bar}, {});
    check_date('_issued_at: no property', $dt, '2006-07-11T13:58:47.564353Z');
}


# This is a bit yucky, but we really have no choice but to delete the live
# working copy and then recreate it.  And to do that we need to delete any
# other working copies, because they might refer to it.
$db->do("delete from working_copy where id <> 1");
$db->do("delete from working_copy where id = 1");
$db->do("select setval('working_copy_id_seq', 1, false)");
my $wc = Daizu::Wc->checkout($cms, 'trunk', 3);
assert($wc->id == 1);
update_all_file_urls($cms, $wc->id);

my $msg = 'r3-r4';
$wc->update(4);
my $changes = file_changes_between_revisions($cms, 3, 4);
test_file_changes($msg, $changes, 2, qw( bar foo_copy ));
my $ch = $changes->{$guid{bar}};
is($ch->{_status}, 'M', "$msg: bar, _status");
ok(exists $ch->{_content}, "$msg: bar, _content");
$ch = $changes->{$guid{foo_copy}};
is($ch->{_status}, 'A', "$msg: foo_copy, _status");
ok(!exists $ch->{_path}, "$msg: foo_copy, _path");
ok(!exists $ch->{_content}, "$msg: foo_copy, _content");


$msg = 'r6-r7';
$wc->update(7);
$changes = file_changes_between_revisions($cms, 6, 7);
test_file_changes($msg, $changes, 2, qw( foo foo_2 ));
$ch = $changes->{$guid{foo}};
is($ch->{_status}, 'D', "$msg: foo, _status");
$ch = $changes->{$guid{foo_2}};
is($ch->{_status}, 'A', "$msg: foo_2, _status");


$msg = 'r25-r26';
$wc->update(25);
update_all_file_urls($cms, $wc->id);
$wc->update(26);

# Daizu::Gen->url_updates_for_file_change
my $file_id = db_row_id($db, 'wc_file', wc_id => 1, path => 'example.com');
assert(defined $file_id);
my $file = Daizu::File->new($cms, $file_id);
for my $prop (qw( daizu:url daizu:generator )) {
    my $propmsg = "$msg: url_updates_for_file_change, $prop";
    my $update = $file->generator->url_updates_for_file_change(
        $wc->id, $guid{example_dir}, $file_id, 'M', { $prop => undef });
    is(scalar @$update, 11, "$propmsg, num files");
    test_cmp_guids($db, $wc->id, $propmsg, $update,
        'example.com/bad-image.png',
        'example.com/bax.html',
        'example.com/custom-guid-1',
        'example.com/custom-guid-2',
        'example.com/custom-guid-dir',
        'example.com/dir',
        'example.com/dir/file',
        'example.com/foo.html',
        'example.com/foo_copy.html',
        'example.com/fractal.png',
        'example.com/recovered.html',
    );
}

$changes = file_changes_between_revisions($cms, 25, 26);
test_file_changes($msg, $changes, 1, qw( example_dir ));
$ch = $changes->{$guid{example_dir}};
is($ch->{_status}, 'M', "$msg: example_dir, _status");
ok(exists $ch->{'daizu:url'}, "$msg: example_dir, daizu:url changed");

my $url_updates = do_publishing_url_updates($cms, $changes);
is(scalar keys %{$url_updates->{$_}}, 0, "$msg: $_ empty")
    for qw( update_redirect_maps
            update_gone_maps
            url_deactivated
            url_changed );
test_cmp_urls($msg, [ keys %{$url_updates->{url_activated}} ], qw(
    http://www.example.com/bad-image.png
    http://www.example.com/bax.html
    http://www.example.com/custom-guid-1
    http://www.example.com/custom-guid-2
    http://www.example.com/dir/file
    http://www.example.com/foo.html
    http://www.example.com/foo_copy.html
    http://www.example.com/fractal.png
    http://www.example.com/recovered.html
));

# Bring the live WC right up to date for any later tests.
$wc->update;
update_all_file_urls($cms, $wc->id);


sub test_file_changes
{
    my ($desc, $changes, $num, @guid_names) = @_;
    assert(defined $changes && ref($changes) eq 'HASH');

    is(scalar keys %$changes, $num, "$desc: num changes");

    while (my ($guid_id, $ch) = each %$changes) {
        # _status
        my $stat = $ch->{_status};
        like($stat, qr/^(?:[AMD])$/, "$desc: status");

        # _old_article and _new_article
        like($ch->{_old_article}, qr/^(?:[01])$/, "$desc: _old_article");
        like($ch->{_new_article}, qr/^(?:[01])$/, "$desc: _new_article");

        # _old_issued and _new_issued
        if ($stat eq 'A') {
            is($ch->{_old_issued}, undef, "$desc: _old_issued");
            isa_ok($ch->{_new_issued}, 'DateTime', "$desc: _new_issued");
        }
        elsif ($stat eq 'M') {
            if (exists $ch->{'dcterms:issued'}) {
                isa_ok($ch->{_old_issued}, 'DateTime', "$desc: _old_issued");
                isa_ok($ch->{_new_issued}, 'DateTime', "$desc: _new_issued");
            }
            else {
                is($ch->{_old_issued}, undef, "$desc: _old_issued");
                is($ch->{_new_issued}, undef, "$desc: _new_issued");
            }
        }
        elsif ($stat eq 'D') {
            isa_ok($ch->{_old_issued}, 'DateTime', "$desc: _old_issued");
            is($ch->{_new_issued}, undef, "$desc: _new_issued");
        }

        assert(!exists $ch->{_content_maybe});  # should be gone by now

        like($ch->{_generator}, qr/^[-:a-zA-Z0-9]+$/, "$desc: _generator");
    }

    ok(exists $changes->{$guid{$_}}, "$desc: file '$_' changed")
        for @guid_names;
}

sub check_date
{
    my ($desc, $got, $expected) = @_;
    SKIP: {
        isa_ok($got, 'DateTime', "$desc: right type")
            or skip 'not DateTime object', 1;
        is(w3c_datetime($got, 1), $expected, "$desc: right value");
    };
}

# vi:ts=4 sw=4 expandtab filetype=perl
