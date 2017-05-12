#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::TTProvider;
use Daizu::Test qw(
    init_tests get_nav_menu_carefully test_menu_item
    test_cmp_guids test_cmp_urls
);
use Daizu::Util qw(
    parse_db_datetime
    db_delete transactionally
);

init_tests(213);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;
my $wc = $cms->live_wc;

my $blog_homepage_file = $wc->file_at_path('foo.com/blog');
my $blog_article_file = $wc->file_at_path('foo.com/blog/2006/fish-fingers/article-1.html');
my $blog_first_article_file = $wc->file_at_path('foo.com/blog/2003/very-old-article.html');
my $blog_last_article_file = $wc->file_at_path('foo.com/blog/non-html.pod');
my $blog_nonarticle_file = $wc->file_at_path('foo.com/blog/2006/strawberries/article-5/extra1.txt');
assert(defined $_)
    for $blog_homepage_file, $blog_article_file, $blog_first_article_file,
        $blog_last_article_file, $blog_nonarticle_file;

my $root_file_id = $blog_homepage_file->{id};
my $root_guid_id = $blog_homepage_file->{guid_id};


# article_template_overrides
{
    my $gen = $blog_homepage_file->generator;
    my ($url_info) = $gen->urls_info($blog_homepage_file);
    isa_ok($gen->article_template_overrides($blog_homepage_file, $url_info),
           'HASH',
           'Daizu::Gen::Blog->article_template_overrides');
}

# _nextprev_article
{
    sub call_nextprev {
        Daizu::Gen::Blog::_nextprev_article($db, $wc->id, $root_file_id, @_);
    }

    my $issued = parse_db_datetime('2003-01-01 00:00:00');
    my ($url, $type, $title) = call_nextprev($issued, '<');
    ok(!defined $url, '_nextprev_article: < first article');
    ($url, $type, $title) = call_nextprev($issued, '>');
    is($url, 'http://foo.com/blog/2005/05/wasp-on-holly-leaf/',
       '_nextprev_article: > first article, url');
    is($type, 'text/html', '_nextprev_article: > first article, type');
    is($title, 'A wasp on a leaf', '_nextprev_article: > first article, title');

    $issued = parse_db_datetime('2006-05-31 16:59:59');
    ($url, $type, $title) = call_nextprev($issued, '<');
    is($url, 'http://foo.com/blog/2006/03/article-2/',
       '_nextprev_article: < mid article, url');
    is($type, 'text/html', '_nextprev_article: < mid article, type');
    is($title, 'Article 2', '_nextprev_article: < mid article, title');
    ($url, $type, $title) = call_nextprev($issued, '>');
    # This one's ordering is ambiguous and resolved by order on wc_file.id.
    is($url, 'http://foo.com/blog/2006/06/article-5/',
       '_nextprev_article: > mid article, url');
    is($type, 'text/html', '_nextprev_article: > mid article, type');
    is($title, 'Article 5', '_nextprev_article: > mid article, title');

    $issued = parse_db_datetime('2006-06-02 00:00:00');
    ($url, $type, $title) = call_nextprev($issued, '<');
    is($url, 'http://foo.com/blog/custom/url',
       '_nextprev_article: < last article, url');
    is($type, 'text/html', '_nextprev_article: < last article, type');
    is($title, 'Article 4', '_nextprev_article: < last article, title');
    ($url, $type, $title) = call_nextprev($issued, '>');
    ok(!defined $url, '_nextprev_article: > last article');
}

# article_template_variables
{
    # Blog homepage.
    my $desc = 'homepage';
    my $links = get_head_links($blog_homepage_file, $desc, 1, undef,
                               'This is my test blog.');
    test_feed_link($links->[0], $desc);

    # Year archive page for 2003 (first year).
    $desc = 'year_archive 2003';
    $links = get_head_links($blog_homepage_file, $desc, 2,
                            'http://foo.com/blog/2003/');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: next", 'next',
                   'http://foo.com/blog/2005/',
                   'text/html', 'Articles for 2005');

    # Year archive page for 2005 (neither first nor last).
    $desc = 'year_archive 2005';
    $links = get_head_links($blog_homepage_file, $desc, 3,
                            'http://foo.com/blog/2005/');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: prev", 'prev',
                   'http://foo.com/blog/2003/',
                   'text/html', 'Articles for 2003');
    test_head_link($links->[2], "$desc: next", 'next',
                   'http://foo.com/blog/2006/',
                   'text/html', 'Articles for 2006');

    # Year archive page for 2006 (last year, most recent).
    $desc = 'year_archive 2006';
    $links = get_head_links($blog_homepage_file, $desc, 2,
                            'http://foo.com/blog/2006/');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: prev", 'prev',
                   'http://foo.com/blog/2005/',
                   'text/html', 'Articles for 2005');

    # Month archive page for 2003/01 (first month).
    $desc = 'month_archive 2003/01';
    $links = get_head_links($blog_homepage_file, $desc, 2,
                            'http://foo.com/blog/2003/01/');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: next", 'next',
                   'http://foo.com/blog/2005/05/',
                   'text/html', 'Articles for May' . chr(0xA0) . '2005');

    # Month archive page for 2006/03 (neither first nor last).
    $desc = 'month_archive 2006/03';
    $links = get_head_links($blog_homepage_file, $desc, 3,
                            'http://foo.com/blog/2006/03/');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: prev", 'prev',
                   'http://foo.com/blog/2005/05/',
                   'text/html', 'Articles for May' . chr(0xA0) . '2005');
    test_head_link($links->[2], "$desc: next", 'next',
                   'http://foo.com/blog/2006/05/',
                   'text/html', 'Articles for May' . chr(0xA0) . '2006');

    # Month archive page for 2003/01 (last month, most recent).
    $desc = 'month_archive 2006/06';
    $links = get_head_links($blog_homepage_file, $desc, 2,
                            'http://foo.com/blog/2006/06/');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: prev", 'prev',
                   'http://foo.com/blog/2006/05/',
                   'text/html', 'Articles for May' . chr(0xA0) . '2006');

    # First blog article.
    $desc = 'first article';
    $links = get_head_links($blog_first_article_file, $desc, 2, undef,
                            undef, 'bar, baz, foo');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: next", 'next',
                   'http://foo.com/blog/2005/05/wasp-on-holly-leaf/',
                   'text/html', 'A wasp on a leaf');

    # Blog article (neither first nor last).
    $desc = 'article';
    $links = get_head_links($blog_article_file, $desc, 3, undef,
                            undef, 'foo');
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: prev", 'prev',
                   'http://foo.com/blog/2005/05/wasp-on-holly-leaf/',
                   'text/html', 'A wasp on a leaf');
    test_head_link($links->[2], "$desc: next", 'next',
                   'http://foo.com/blog/2006/03/article-2/',
                   'text/html', 'Article 2');

    # Last blog article (most recent).
    $desc = 'last article';
    $links = get_head_links($blog_last_article_file, $desc, 2);
    test_feed_link($links->[0], $desc);
    test_head_link($links->[1], "$desc: prev", 'prev',
                   'http://foo.com/blog/custom/url',
                   'text/html', 'Article 4');
}


# navigation_menu
my $menu = get_nav_menu_carefully($blog_article_file);
# Blog homepage:
test_menu_item($menu->[0], 'blog_article, 0', 0, '../../../', 'Foo Blog');
# Year archives:
test_menu_item($menu->[1], 'blog_article, 1', 3, '../../',
               'Articles for 2006', '2006');
test_menu_item($menu->[2], 'blog_article, 2', 1, '../../../2005/',
               'Articles for 2005', '2005');
test_menu_item($menu->[3], 'blog_article, 3', 1, '../../../2003/',
               'Articles for 2003', '2003');
# Month archives:
test_menu_item($menu->[1]{children}[0], 'blog_article, 1.0', 0, '../',
               "Articles for March\x{A0}2006", 'March');
test_menu_item($menu->[1]{children}[1], 'blog_article, 1.1', 0, '../../05/',
               "Articles for May\x{A0}2006", 'May');
test_menu_item($menu->[1]{children}[2], 'blog_article, 1.2', 0, '../../06/',
               "Articles for June\x{A0}2006", 'June');
test_menu_item($menu->[2]{children}[0], 'blog_article, 2.0', 0,
               '../../../2005/05/', "Articles for May\x{A0}2005", 'May');
test_menu_item($menu->[3]{children}[0], 'blog_article, 3.0', 0,
               '../../../2003/01/', "Articles for January\x{A0}2003",
               'January');


# url_updates_for_file_change
my %not_article_changes = ( _new_article => 0, _old_article => 0 );
my %is_article_changes = ( _new_article => 1, _old_article => 1 );
my %was_article_changes = ( _new_article => 0, _old_article => 1 );
my %wasnt_article_changes = ( _new_article => 1, _old_article => 0 );
{

    # Blog directory.
    for ($blog_homepage_file) {
        my $gen = $_->generator;
        my $update = $gen->url_updates_for_file_change(
                        $wc->id, $_->{guid_id}, $_->{id}, 'M',
                        \%not_article_changes);
        is(scalar @$update, 0, 'url_updates_for_file_change: root file');
    }

    # Article published in 2006-03.
    for ($blog_article_file) {
        my $msg = 'url_updates_for_file_change: article';
        my $gen = $_->generator;

        # Deleted.
        my $update = $gen->url_updates_for_file_change(
                        $wc->id, $_->{guid_id}, undef, 'D',
                        \%was_article_changes);
        is(scalar @$update, 1, "$msg, del");
        is($update->[0], $root_guid_id, "$msg, del, 0");

        # Added, but month archive page already exists.
        $update = $gen->url_updates_for_file_change(
                        $wc->id, $_->{guid_id}, $_->{id}, 'A',
                        \%wasnt_article_changes);
        is(scalar @$update, 0, "$msg, month exists");

        # Added, month archive page doesn't exist (because I temporarily
        # deleted it).
        eval { transactionally($db, sub {
            db_delete($db, 'url',
                wc_id => $wc->id,
                guid_id => $root_guid_id,
                method => 'month_archive',
                argument => '2006 03',
            );
            my $update = $gen->url_updates_for_file_change(
                            $wc->id, $_->{guid_id}, $_->{id}, 'A',
                            \%wasnt_article_changes);
            is(scalar @$update, 1, "$msg, month missing");
            is($update->[0], $root_guid_id, "$msg, month missing, 0");
            die "--rollback--\n";
        }) };
        die $@ unless $@ eq "--rollback--\n";
    }

    # Files which may be associated with a blog article like '_index.html'.
    for ($wc->file_at_path('foo.com/blog/2006/strawberries/article-5/_index.html'))
    {
        my $msg = 'url_updates_for_file_change: _index article';
        my $gen = $_->generator;

        my $update = $gen->url_updates_for_file_change(
                        $wc->id, $_->{guid_id}, $_->{id}, 'M',
                        \%wasnt_article_changes);
        is(scalar @$update, 3, "$msg, num files");
        test_cmp_guids($db, $wc->id, $msg, $update,
            'foo.com/blog/2006/strawberries/article-5/extra1.txt',
            'foo.com/blog/2006/strawberries/article-5/subdir/extra2.txt',
            'foo.com/blog/2006/strawberries/article-5/subdir/syncolor.pl',
        );
    }

    # This shouldn't get the same treatment as an '_index' file.
    for ($blog_nonarticle_file) {
        my $msg = 'url_updates_for_file_change: non-article';
        my $gen = $_->generator;

        my $update = $gen->url_updates_for_file_change(
                        $wc->id, $_->{guid_id}, $_->{id}, 'M',
                        { 'daizu:type' => 'changed', %not_article_changes });
        is(scalar @$update, 0, "$msg, num files");
    }
}


# publishing_for_file_change
{
    # Blog directory.
    for ($blog_homepage_file) {
        my $gen = $_->generator;
        my $pub = $gen->publishing_for_file_change(
                        $wc->id, $_->{guid_id}, $_->{id}, 'M',
                        \%not_article_changes);
        is(scalar @$pub, 0, 'publishing_for_file_change: root file');
    }

    # Article published in 2006-06, the very latest one.
    for ($blog_last_article_file) {
        my $gen = $_->generator;
        my $msg = 'publishing_for_file_change: last article';

        # Adding or deletign a recent article.  It will appear on the homepage
        # and in the feed, so those will have to be republished as well as some
        # existing archive pages.  Also, the article before this one which
        # links to it.
        for my $status (qw( A D )) {
            my $msg_status = "$msg, $status";
            my ($file_id, $changes);
            if ($status eq 'A') {
                $file_id = $_->{id};
                $changes = { _new_issued => $_->issued_at, %wasnt_article_changes };
            }
            else {  # deleted
                $changes = { _old_issued => $_->issued_at, %was_article_changes };
            }
            my $pub = $gen->publishing_for_file_change(
                            $wc->id, $_->{guid_id}, $file_id, $status,
                            $changes);
            test_cmp_urls($msg_status, $pub,
                'http://foo.com/blog/',             # recent stuff
                'http://foo.com/blog/feed.atom',
                'http://foo.com/blog/2006/',        # archive pages
                'http://foo.com/blog/2006/06/',
                'http://foo.com/blog/custom/url',   # previous article
            );
        }
    }

    # Files which aren't articles never require extra publishing work.
    for ($blog_nonarticle_file) {
        my $gen = $_->generator;
        my $pub = $gen->publishing_for_file_change(
                        $wc->id, $_->{guid_id}, $_->{id}, 'A',
                        \%not_article_changes);
        is(scalar @$pub, 0, 'publishing_for_file_change: non-article');
    }
}


# publishing_for_url_change


# year_archive_title, year_archive_short_title,
# month_archive_title, month_archive_short_title
{
    my $gen = $blog_homepage_file->generator;

    my $title = $gen->year_archive_title('MOCK', 2006);
    is($title, 'Articles for 2006', 'year_archive_title');
    $title = $gen->year_archive_short_title('MOCK', 2006);
    is($title, '2006', 'year_archive_short_title');

    $title = $gen->month_archive_title('MOCK', 2006, 10);
    is($title, 'Articles for October' . chr(160) . 2006, 'month_archive_title');
    $title = $gen->month_archive_short_title('MOCK', 2006, 10);
    is($title, 'October', 'month_archive_short_title');
}


sub get_head_links
{
    my ($file, $desc, $num_links, $url, $description, $keywords) = @_;

    my $gen = $file->generator;
    my @url_info = $gen->urls_info($file);
    assert(@url_info);

    my $url_info;
    if (defined $url) {
        for (@url_info) {
            next unless $_->{url} eq $url;
            $url_info = $_;
            last;
        }
    }
    else {
        $url_info = $url_info[0];
    }
    assert(defined $url_info);

    my $vars = $gen->article_template_variables($file, $url_info);
    isa_ok($vars, 'HASH', "$desc: article_template_variables");
    my $expected_num = 1;
    ++$expected_num if defined $description || defined $keywords;
    is(scalar keys %$vars, $expected_num, "$desc: right num of vars");

    my $links = $vars->{head_links};
    isa_ok($links, 'ARRAY', "$desc: head_links");
    is(scalar @$links, $num_links, "$desc: right num of head_links");

    if (defined $description) {
        is($vars->{head_meta}[0]{name}, 'description',
           "$desc: description name");
        is($vars->{head_meta}[0]{content}, $description,
           "$desc: description vaule");
    }

    if (defined $keywords) {
        is($vars->{head_meta}[-1]{name}, 'keywords',
           "$desc: keywords name");
        is($vars->{head_meta}[-1]{content}, $keywords,
           "$desc: keywords vaule");
    }

    return $links;
}

sub test_feed_link
{
    my ($link, $desc) = @_;
    test_head_link($link, "$desc: feed link", 'alternate',
                   'http://foo.com/blog/feed.atom', 'application/atom+xml',
                   'Feed for Foo Blog');
}

sub test_head_link
{
    my ($link, $desc, $rel, $href, $type, $title) = @_;

    is($link->{rel}, $rel, "$desc: rel");
    is($link->{href}, $href, "$desc: href");
    is($link->{type}, $type, "$desc: type");
    is($link->{title}, $title, "$desc: title");
}

# vi:ts=4 sw=4 expandtab filetype=perl
