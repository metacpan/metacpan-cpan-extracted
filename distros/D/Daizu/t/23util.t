#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Encode qw( encode );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Util qw(
    trim trim_with_empty_null like_escape pgregex_escape
    url_encode url_decode
    validate_number validate_uri validate_mime_type
    validate_date w3c_datetime db_datetime rfc2822_datetime parse_db_datetime
    db_row_exists db_row_id db_select db_select_col
    db_insert db_update db_replace db_delete transactionally
    wc_file_data guess_mime_type wc_set_file_data
    mint_guid load_class
    add_xml_elem xml_attr xml_croak
    branch_id daizu_data_dir
);

init_tests(107);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;
my $wc = $cms->live_wc;

# trim
is(trim(undef), undef, 'trim: undef gives undef');
is(trim(" \n\t"), '', 'trim: only whitespace gives empty string');
is(trim("\n\t  foo \t\n"), 'foo', 'trim: removes whitespace');
is(trim('foo'), 'foo', 'trim: is idempotent');

# trim_with_empty_null
is(trim_with_empty_null(undef), undef,
   'trim_with_empty_null: undef gives undef');
is(trim_with_empty_null(" \n\t"), undef,
   'trim_with_empty_null: only whitespace gives undef');
is(trim_with_empty_null("\n\t  foo \t\n"), 'foo',
   'trim_with_empty_null: removes whitespace');
is(trim_with_empty_null('foo'), 'foo', 'trim_with_empty_null: is idempotent');

# like_escape
is(like_escape(undef), undef, 'like_escape: undef gives undef');
is(like_escape(q{ foo ' % \ _ }), q{ foo ' \% \\\\ \_ },
   'like_escape: correct escaping');

# pgregex_escape
is(pgregex_escape(undef), undef, 'pgregex_escape: undef gives undef');
is(pgregex_escape(q{ foo ' / . ^ $ + * ? () [] \ } . '{'),
   q{ foo ' / \. \^ \$ \+ \* \? \(\) \[\] \\\\ \\} . '{',
   'pgregex_escape: correct escaping');

# url_encode
is(url_encode(''), '', 'url_encode: empty string');
is(url_encode(q{ foo bar % %%25 \ * ' " /, ` ~ = }),
   q{+foo+bar+%25+%25%2525+%5C+%2A+%27+%22+/,+%60+%7E+%3D+},
   'url_encode: printable chars');
is(url_encode("\x00\x01\x02 \x08\x09\x0A\x0B\x0C\x0D \x1B \x1E\x1F \x7F"),
   '%00%01%02+%08%09%0A%0B%0C%0D+%1B+%1E%1F+%7F',
   'url_encode: non-printable chars');
my $utf8_text = "caf\xE9 \x{2014} \x{99Ac} \x{149B0}";
my $binary_utf8_text = $utf8_text;
$binary_utf8_text = encode('UTF-8', $binary_utf8_text, Encode::FB_CROAK);
is(url_encode($utf8_text), 'caf%C3%A9+%E2%80%94+%E9%A6%AC+%F0%94%A6%B0',
   'url_encode: utf-8 input');
is(url_encode($binary_utf8_text),
   'caf%C3%83%C2%A9+%C3%A2%C2%80%C2%94+%C3%A9%C2%A6%C2%AC+' .
   '%C3%B0%C2%94%C2%A6%C2%B0',
   'url_encode: utf-8 input as binary');

# url_decode
is(url_decode(''), '', 'url_decode: empty string');
is(url_decode(q{+foo+bar+%25+%25%2525+%5c+%2A+%27+%22+%2F/,+%60+%7E+%3d+}),
   q{ foo bar % %%25 \ * ' " //, ` ~ = },
   'url_decode: printable chars');
is(url_decode('%00%01%02+%08%09%0A%0B%0C%0D+%1B+%1E%1F+%7F'),
   "\x00\x01\x02 \x08\x09\x0A\x0B\x0C\x0D \x1B \x1E\x1F \x7F",
   'url_decode: non-printable chars');
is(url_decode(' +%20 + %20%20'), '        ', 'url_decode: various spaces');
{
    my $got = url_decode('caf%C3%A9+%E2%80%94+%E9%A6%AC+%F0%94%A6%B0');
    is($got, $utf8_text, 'url_decode: utf-8 URL encoded');
    ok(utf8::is_utf8($got), 'url_decode: output marked as utf-8');
    $got = url_decode('caf%C3%83%C2%A9+%C3%A2%C2%80%C2%94+%C3%A9%C2%A6%C2%AC+' .
                      '%C3%B0%C2%94%C2%A6%C2%B0');
    is($got, $binary_utf8_text, 'url_decode: utf-8 double encoded');
    ok(utf8::is_utf8($got), 'url_decode: output marked as utf-8');
}

# validate_number
is(validate_number(''), undef, 'validate_number: empty string');
is(validate_number('0'), 0, 'validate_number: 0');
is(validate_number('9854230'), 9854230, 'validate_number: 9854230');
is(validate_number('9854A230'), undef, 'validate_number: 9854A230');
is(validate_number(' 1 '), undef, "validate_number: ' 1 '");

# validate_uri
is(validate_uri(undef), undef, 'validate_uri: undef');
is(validate_uri(''), undef, 'validate_uri: empty string');
is(validate_uri('http://localhost:123/blah'), 'http://localhost:123/blah',
   'validate_uri: normal HTTP URI');
is(validate_uri(" \thttp://localhost:123/blah\r\n"),
   'http://localhost:123/blah',
   'validate_uri: same with excess whitespace');
is(validate_uri('tag:example.com,2006:13'),
   'tag:example.com,2006:13',
   'validate_uri: tag URI');
is(validate_uri('xyz'), undef, 'validate_uri: xyz');
is(validate_uri('foo://auth/foo'), 'foo://auth/foo',
   'validate_uri: foo://auth/foo');
is(validate_uri('foo://auth#foo'), 'foo://auth#foo',
   'validate_uri: foo://auth#foo');
is(validate_uri('foo://auth'), 'foo://auth', 'validate_uri: foo://auth');
is(validate_uri('foo:///foo'), 'foo:///foo', 'validate_uri: foo:///foo');
is(validate_uri('foo:////foo'), undef, 'validate_uri: foo:////foo');

# validate_mime_type
is(validate_mime_type(undef), undef, 'validate_mime_type: undef');
is(validate_mime_type(''), undef, 'validate_mime_type: empty string');
is(validate_mime_type('foo'), undef, 'validate_mime_type: foo');
is(validate_mime_type('foo/bar'), 'foo/bar', 'validate_mime_type: foo/bar');
is(validate_mime_type('FOo/bAR'), 'foo/bar', 'validate_mime_type: FOo/bAR');
is(validate_mime_type('application/xhtml+html'), 'application/xhtml+html',
   'validate_mime_type: application/xhtml+html');

# validate_date
is(validate_date(undef), undef, 'validate_date: undef');
is(validate_date('foo'), undef, 'validate_date: foo');
{
    my $dt = validate_date('2006-08-13T21:01:23Z');
    isa_ok($dt, 'DateTime', 'validate_date: valid, isa DateTime');
    is($dt->ymd . $dt->hms, '2006-08-1321:01:23',
       'validate_date: valid, right value');
    $dt = validate_date(' 2006-08-13t21:01:23z ');
    is($dt->ymd . $dt->hms, '2006-08-1321:01:23',
       'validate_date: valid but not canonical, right value');
    $dt = validate_date('2006-08-13T21:01:23.123Z');
    is($dt->ymd . $dt->hms, '2006-08-1321:01:23',
       'validate_date: valid with nanoseconds, right value');
    is($dt->nanosecond, 123_000_000,
       'validate_date: valid with nanoseconds, right nanoseconds');
}

# w3c_datetime
is(w3c_datetime(undef), undef, 'w3c_datetime: undef');
is(w3c_datetime('2006-08-13T21:01:23Z'), '2006-08-13T21:01:23Z',
   'w3c_datetime: string');
is(w3c_datetime(validate_date('2006-08-13T21:01:23Z')), '2006-08-13T21:01:23Z',
   'w3c_datetime: DateTime');

# db_datetime
is(db_datetime(undef), undef, 'db_datetime: undef');
is(db_datetime('2006-08-13T21:01:23Z'),
   '2006-08-13 21:01:23+0000',
   'db_datetime: string');
is(db_datetime(validate_date('2006-08-13T21:01:23Z')),
   '2006-08-13 21:01:23+0000',
   'db_datetime: DateTime');
is(db_datetime(validate_date('2006-08-13T21:01:23.864325Z')),
   '2006-08-13 21:01:23.864325000+0000',
   'db_datetime: DateTime');

# rfc2822_datetime
is(rfc2822_datetime(undef), undef, 'rfc2822_datetime: undef');
is(rfc2822_datetime('2006-08-13T21:01:23Z'),
   'Sun, 13 Aug 2006 21:01:23 +0000',
   'rfc2822_datetime: string');
is(rfc2822_datetime(validate_date('2006-08-13T21:01:23Z')),
   'Sun, 13 Aug 2006 21:01:23 +0000',
   'rfc2822_datetime: DateTime');
# This one is from the RSS 'profile' document.
is(rfc2822_datetime(validate_date('2006-02-09T23:59:45Z')),
   'Thu, 09 Feb 2006 23:59:45 +0000',
   'rfc2822_datetime: DateTime');


# parse_db_datetime
is(w3c_datetime(parse_db_datetime('2006-07-11 13:58:48'), 1),
   '2006-07-11T13:58:48Z', 'parse_db_datetime: to the second');
is(w3c_datetime(parse_db_datetime('2006-07-20 23:45:20.349116'), 1),
   '2006-07-20T23:45:20.349116Z', 'parse_db_datetime: fraction of a second');


# db_row_exists
ok(db_row_exists($db, 'branch'), 'db_row_exists: no criteria');
ok(!db_row_exists($db, 'live_revision'), 'db_row_exists: empty table');
ok(db_row_exists($db, 'branch', path => 'trunk'), 'db_row_exists: path=trunk');
ok(!db_row_exists($db, 'branch', path => 'foo'), 'db_row_exists: path=foo');
ok(db_row_exists($db, 'branch', path => 'trunk', id => 1),
   'db_row_exists: path=trunk id=1');

# db_row_id
is(db_row_id($db, 'branch', path => 'trunk'), 1, 'db_row_id: path=trunk');
{
    my $id = db_row_id($db, 'wc_file',
        path => 'foo.com/blog/2006/fish-fingers/article-1.html',
        name => 'article-1.html',
        deleted => 0,
        image_width => undef,
    );
    my ($path) = $db->selectrow_array(q{
        select path from wc_file where id = ?
    }, undef, $id);
    is($path, 'foo.com/blog/2006/fish-fingers/article-1.html',
       'db_row_id: multiple criteria, including bool and null');

    $id = db_row_id($db, 'wc_file', path => 'non-existant path');
    is($id, undef, 'db_row_id: not found, no string match');

    $id = db_row_id($db, 'wc_file',
        path => 'foo.com/blog/2006/fish-fingers/article-1.html',
        name => 'article-1.html',
        deleted => 1,
        image_width => undef,
    );
    is($id, undef, 'db_row_id: not found, bool wrong');

    $id = db_row_id($db, 'wc_file',
        wc_id => $wc->id,
        path => 'example.com/fractal.png',
        name => 'fractal.png',
        image_width => undef,
    );
    is($id, undef, 'db_row_id: not found, not null');
}

# db_select
{
    my ($expected) = $db->selectrow_array(q{
        select max(revnum) from revision
    });
    my $got = db_select($db, revision => {}, 'max(revnum)');
    is($got, $expected, 'db_select: max(revnum)');
}
{
    my ($exp_wd, $exp_ht) = $db->selectrow_array(q{
        select image_width, image_height
        from wc_file
        where wc_id = ?
          and path = 'example.com/fractal.png'
    }, undef, $wc->id);
    my ($got_exists, $got_wd, $got_ht) = db_select($db, wc_file => {
        wc_id => $wc->id,
        path => 'example.com/fractal.png',
    }, qw( 1 image_width image_height ));
    is($got_exists, 1, 'db_select: image exists');
    is($got_wd, $exp_wd, 'db_select: image_width');
    is($got_ht, $exp_ht, 'db_select: image_height');
    ($got_exists, $got_wd, $got_ht) = db_select($db, wc_file => {
        wc_id => $wc->id,
        path => 'non-existant-file',
    }, qw( 1 image_width image_height ));
    is($got_exists, undef, 'db_select: image does not exist');
}

# db_select_col
{
    my @revnums = db_select_col($db, revision => {}, 'revnum');
    my $latest_revnum = $cms->ra->get_latest_revnum;
    is(scalar @revnums, $latest_revnum, 'db_select_col: num revisions');
    @revnums = sort { $a <=> $b } @revnums;
    is($revnums[0], 1, 'db_select_col: first revnum');
    is($revnums[-1], $latest_revnum, 'db_select_col: last revnum');

    my @names = db_select_col($db, 'person',
        { id => 1, username => 'geoff' },
        'username',
    );
    is(scalar @names, 1, 'db_select_col: num names');
    is($names[0], 'geoff', 'db_select_col: correct name');
}

# db_insert

# db_update

# db_replace
eval {
    transactionally($db, sub {
        my $file = $wc->file_at_path('foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg');

        # Replace a row which doesn't already exist.
        db_replace($db, 'wc_property',
            { file_id => $file->{id}, name => 'foo' },
            value => 'bar',
        );
        ok(db_row_exists($db, 'wc_property',
            file_id => $file->{id},
            name => 'foo',
            value => 'bar',
        ), 'db_replace: insert');

        # Replace an existing row with a new one.
        db_replace($db, 'wc_property',
            { file_id => $file->{id}, name => 'dc:title' },
            value => 'new title',
        );
        ok(db_row_exists($db, 'wc_property',
            file_id => $file->{id},
            name => 'dc:title',
            value => 'new title',
        ), 'db_replace: update');

        die "--rollback--\n";
    });
};
die $@ unless $@ eq "--rollback--\n";

# db_delete

# wc_file_data
{
    my ($file_id) = db_row_id($db, 'wc_file',
        path => 'example.com/type-set-later.gif',
        wc_id => $wc->id,
    );
    assert(defined $file_id);

    my $data = wc_file_data($db, $file_id);
    is(ref $data, 'SCALAR', 'wc_file_data: returns reference');
    ok(!utf8::is_utf8($$data), 'wc_file_data: binary data');
    like($$data, qr/\AGIF89a\x0B\x00\x09\x00\xF1/, 'wc_file_data: right data');

    # Now do same thing, but for a file which doesn't contain its own data
    # but simply points to the copy in the live WC.
    my ($file2_id) = db_row_id($db, 'wc_file',
        path => 'example.com/type-set-later.gif',
        data => undef,
    );
    assert(defined $file2_id);
    assert($file2_id != $file_id);

    my $data2 = wc_file_data($db, $file2_id);
    is(ref $data2, 'SCALAR', 'wc_file_data: indirect, returns reference');
    ok(!utf8::is_utf8($$data2), 'wc_file_data: indirect, binary data');
    like($$data2, qr/\AGIF89a\x0B\x00\x09\x00\xF1/,
         'wc_file_data: indirect, right data');

    # Should get the same data both times.
    is($$data, $$data2, 'wc_file_data: same data both times');
}

# guess_mime_type
{
    open my $fh, '<', file(qw( t data fractal.png )) or die $!;
    my $data = do { local $/; <$fh> };
    is(guess_mime_type(\$data, 'fractal.png'), 'image/png',
       'guess_mime_type: fractal.png');

    $data = q{
        /* A CSS stylesheet */
        body { color: black; background: white; }
    };
    is(guess_mime_type(\$data, 'test.css'), 'text/css',
       'guess_mime_type: CSS stylesheet');
}

# wc_set_file_data

# mint_guid
{
    my ($id, $uri) = mint_guid($cms, 1, 'non-existant', 3);
    like($uri, qr/\Atag:example1.com,2006:\d+\z/, 'mint_guid: dir, right tag');
    ok(db_row_exists($db, file_guid =>
        id => $id,
        uri => $uri,
        is_dir => 1,
        old_uri => undef,
        custom_uri => 0,
        first_revnum => 3,
        last_changed_revnum => 3,
    ), 'mint_guid: directory, right record');
    db_delete($db, file_guid => $id);

    ($id, $uri) = mint_guid($cms, 0, 'example.com/dir/foo/bar', 5);
    like($uri, qr/\Atag:example3.com,2006:\d+\z/, 'mint_guid: file, right tag');
    ok(db_row_exists($db, file_guid =>
        id => $id,
        uri => $uri,
        is_dir => 0,
        old_uri => undef,
        custom_uri => 0,
        first_revnum => 5,
        last_changed_revnum => 5,
    ), 'mint_guid: file, right record');
    db_delete($db, file_guid => $id);
}

# load_class

# add_xml_elem

# xml_attr

# xml_croak

# branch_id
is(branch_id($db, 123), 123, 'branch_id: arbitrary number returned as-is');
is(branch_id($db, 'trunk'), 1, 'branch_id: trunk is branch 1');

# daizu_data_dir
{
    use Path::Class qw( file );
    assert(defined $INC{'Daizu.pm'});
    my $expected = file($INC{'Daizu.pm'})->dir->subdir('Daizu')
                                              ->subdir('xml')->absolute;
    my $got = daizu_data_dir('xml');
    isa_ok($got, 'Path::Class::Dir', 'daizu_data_dir: object not string');
    is($got, $expected, 'daizu_data_dir: right path');
    ok((-d $got), 'daizu_data_dir: directory exists');
}

# vi:ts=4 sw=4 expandtab filetype=perl
