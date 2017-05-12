#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Util qw( db_row_id update_all_file_urls );

init_tests(114);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;
my $wc = $cms->live_wc;

# Clean up in case we've already run this.
{
    $db->do("delete from url");
    $db->do("delete from working_copy where id = 3");
    $db->do("select setval('working_copy_id_seq', 2)");
}

# $generator->base_url
test_base_url($wc, 'top-level', undef);
test_base_url($wc, 'foo.com', 'http://foo.com/');
test_base_url($wc, 'foo.com/_index.html', 'http://foo.com/');
test_base_url($wc, 'foo.com/_hide', undef);
test_base_url($wc, 'foo.com/_hide/readme.txt', undef);
test_base_url($wc, 'foo.com/blog', 'http://foo.com/blog/');
test_base_url($wc, 'example.com/fractal.png',
              'http://www.example.com/fractal.png');
test_base_url($wc, 'foo.com/blog/2006/fish-fingers/article-1.html',
              'http://foo.com/blog/2006/03/article-1/');
test_base_url($wc, 'foo.com/blog/2006/strawberries/article-4.html',
              'http://foo.com/blog/custom/url');
test_base_url($wc, 'foo.com/blog/2006',
              'http://foo.com/blog/2006/');
test_base_url($wc, 'foo.com/blog/2006/strawberries',
              'http://foo.com/blog/2006/strawberries/');
test_base_url($wc, 'foo.com/blog/2006/strawberries/article-5',
              'http://foo.com/blog/2006/06/article-5/');
test_base_url($wc, 'foo.com/blog/2006/strawberries/article-5/_index.html',
              'http://foo.com/blog/2006/06/article-5/');
test_base_url($wc, 'foo.com/blog/2006/strawberries/article-5/extra1.txt',
              'http://foo.com/blog/2006/06/article-5/extra1.txt');
test_base_url($wc, 'foo.com/blog/2006/strawberries/article-5/subdir',
              'http://foo.com/blog/2006/06/article-5/subdir/');
test_base_url($wc, 'foo.com/blog/2006/strawberries/article-5/subdir/extra2.txt',
              'http://foo.com/blog/2006/06/article-5/subdir/extra2.txt');

# Daizu::Gen->urls
my $file = $wc->file_at_path('example.com/dir');
my @url = $file->generator->urls_info($file);
is(scalar @url, 0, 'urls: Gen: random dir, no URLs');

$file = $wc->file_at_path('example.com');
@url = $file->generator->urls_info($file);
is(scalar @url, 0, 'urls: Gen: top-level dir, no URLs');

$file = $wc->file_at_path('foo.com');
@url = $file->generator->urls_info($file);
is(scalar @url, 1, 'urls: Gen: sitemap dir, one URL');
is($url[0]{url}, 'http://foo.com/sitemap.xml.gz',
   'urls: Gen: sitemap dir, url');
is($url[0]{method}, 'xml_sitemap', 'urls: Gen: sitemap dir, method');
is($url[0]{argument}, '', 'urls: Gen: sitemap dir, argument');
is($url[0]{type}, 'application/xml', 'urls: Gen: sitemap dir, type');
is($url[0]{generator}, 'Daizu::Gen', 'urls: Gen: sitemap dir, generator');

$file = $wc->file_at_path('foo.com/doc/Util.pm');
@url = $file->generator->urls_info($file);
is(scalar @url, 2, 'urls: Gen: perl docs, extra URL for source code');
# the 'article pages' URLs always come first.
is($url[0]{url}, 'http://foo.com/doc/Util.html',
   'urls: Gen: perl docs, HTML url');
is($url[0]{method}, 'article', 'urls: Gen: perl docs, HTML method');
is($url[0]{argument}, '', 'urls: Gen: perl docs, HTML argument');
is($url[0]{type}, 'text/html', 'urls: Gen: perl docs, HTML type');
is($url[0]{generator}, 'Daizu::Gen', 'urls: Gen: perl docs, HTML generator');
is($url[1]{url}, 'http://foo.com/doc/Util.pm',
   'urls: Gen: perl docs, POD url');
is($url[1]{method}, 'unprocessed', 'urls: Gen: perl docs, POD method');
is($url[1]{argument}, '', 'urls: Gen: perl docs, POD argument');
is($url[1]{type}, 'text/x-perl', 'urls: Gen: perl docs, POD type');
is($url[1]{generator}, 'Daizu::Gen', 'urls: Gen: perl docs, POD generator');

$file = $wc->file_at_path('foo.com/blog');
@url = $file->generator->urls_info($file);
is(scalar @url, 10, 'urls: Gen::Blog: blog dir, right number of URLs');

is($url[0]{url}, 'http://foo.com/blog/',
   'urls: Gen::Blog: blog dir, homepage, url');
is($url[0]{method}, 'homepage',
   'urls: Gen::Blog: blog dir, homepage, method');
is($url[0]{argument}, '',
   'urls: Gen::Blog: blog dir, homepage, argument');
is($url[0]{type}, 'text/html',
   'urls: Gen::Blog: blog dir, homepage, type');
is($url[0]{generator}, 'Daizu::Gen::Blog',
   'urls: Gen::Blog: blog dir, homepage, generator');

is($url[1]{url}, 'http://foo.com/blog/feed.atom',
   'urls: Gen::Blog: blog dir, feed, url');
is($url[1]{method}, 'feed',
   'urls: Gen::Blog: blog dir, feed, method');
is($url[1]{argument}, 'atom snippet 14',
   'urls: Gen::Blog: blog dir, feed, argument');
is($url[1]{type}, 'application/atom+xml',
   'urls: Gen::Blog: blog dir, feed, type');
is($url[1]{generator}, 'Daizu::Gen::Blog',
   'urls: Gen::Blog: blog dir, feed, generator');

my %year_urls = (2 => 2003, 4 => 2005, 6 => 2006);
for (sort { $a <=> $b } keys %year_urls) {
    my $year = $year_urls{$_};
    is($url[$_]{url}, "http://foo.com/blog/$year/",
       "urls: Gen::Blog: blog dir, $year, url");
    is($url[$_]{method}, 'year_archive',
       "urls: Gen::Blog: blog dir, $year, method");
    is($url[$_]{argument}, $year,
       "urls: Gen::Blog: blog dir, $year, argument");
    is($url[$_]{type}, 'text/html',
       "urls: Gen::Blog: blog dir, $year, type");
    is($url[$_]{generator}, 'Daizu::Gen::Blog',
       "urls: Gen::Blog: blog dir, $year, generator");
}

my %month_urls = (
    3 => [ 2003, 1 ],
    5 => [ 2005, 5 ],
    7 => [ 2006, 3 ],
    8 => [ 2006, 5 ],
    9 => [ 2006, 6 ],
);
for (sort { $a <=> $b } keys %month_urls) {
    my ($year, $month) = @{$month_urls{$_}};
    is($url[$_]{url}, sprintf('http://foo.com/blog/%d/%02d/', $year, $month),
       "urls: Gen::Blog: blog dir, $year/$month, url");
    is($url[$_]{method}, 'month_archive',
       "urls: Gen::Blog: blog dir, $year/$month, method");
    is($url[$_]{argument}, sprintf('%d %02d', $year, $month),
       "urls: Gen::Blog: blog dir, $year/$month, argument");
    is($url[$_]{type}, 'text/html',
       "urls: Gen::Blog: blog dir, $year/$month, type");
    is($url[$_]{generator}, 'Daizu::Gen::Blog',
       "urls: Gen::Blog: blog dir, $year/$month, generator");
}

# PictureArticle URLs.
$file = $wc->file_at_path('foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg');
@url = $file->generator->urls_info($file);
is(scalar @url, 3, 'urls: PictureArticle: number');
is($url[0]{url}, 'http://foo.com/blog/2005/05/wasp-on-holly-leaf/',
   'urls: PictureArticle: page url');
is($url[0]{method}, 'article', 'urls: PictureArticle: page method');
is($url[0]{argument}, '', 'urls: PictureArticle: page argument');
is($url[0]{type}, 'text/html', 'urls: PictureArticle: page type');
is($url[0]{generator}, 'Daizu::Gen::Blog',
   'urls: PictureArticle: page generator');
is($url[1]{url},
   'http://foo.com/blog/2005/05/wasp-on-holly-leaf/wasp-on-holly-leaf.jpg',
   'urls: PictureArticle: picture url');
is($url[1]{method}, 'unprocessed', 'urls: PictureArticle: picture method');
is($url[1]{argument}, '', 'urls: PictureArticle: picture argument');
is($url[1]{type}, 'image/jpeg', 'urls: PictureArticle: picture type');
is($url[1]{generator}, 'Daizu::Gen', 'urls: PictureArticle: picture generator');
is($url[2]{url},
   'http://foo.com/blog/2005/05/wasp-on-holly-leaf/wasp-on-holly-leaf-thm.jpg',
   'urls: PictureArticle: thumbnail url');
is($url[2]{method}, 'scaled_image', 'urls: PictureArticle: thumbnail method');
is($url[2]{argument}, '300 300', 'urls: PictureArticle: thumbnail argument');
is($url[2]{type}, 'image/jpeg', 'urls: PictureArticle: thumbnail type');
is($url[2]{generator}, 'Daizu::Gen',
   'urls: PictureArticle: thumbnail generator');

# $file->permalink
is($wc->file_at_path('foo.com/blog/2006/fish-fingers/article-2.html')
      ->permalink,
   'http://foo.com/blog/2006/03/article-2/',
   'permalink: foo.com/blog/2006/fish-fingers/article-2.html');
is($wc->file_at_path('foo.com/doc/Util.pm')->permalink,
   'http://foo.com/doc/Util.html',
   'permalink: foo.com/doc/Util.pm');
is($wc->file_at_path('foo.com/blog/foo.txt')->permalink,
   'http://foo.com/blog/foo.txt',
   'permalink: foo.com/blog/foo.txt');
{
    my @url = $wc->file_at_path('foo.com/_hide/readme.txt')->permalink;
    is(scalar @url, 0, 'permalink: foo.com/_hide/readme.txt');
}


# Daizu::Util::update_all_file_urls
my $url_changes = update_all_file_urls($cms, $wc->id);
is(scalar keys %{$url_changes->{update_redirect_maps}}, 0,
   'update_all_file_urls: no redirect changes');
is(scalar keys %{$url_changes->{update_gone_maps}}, 0,
   'update_all_file_urls: no gone changes');


# Daizu::File->update_urls_in_db
my $url_wc = Daizu::Wc->checkout($cms, 'trunk', 43);
assert($url_wc->id == 3);
update_all_file_urls($cms, $url_wc->id);

my %dup;
$url_wc->update(44);
my $foo_bar_id = db_row_id($db, 'wc_file', wc_id => $url_wc->id, path => 'example.com/swap-urls/bar');
my $bar_foo_id = db_row_id($db, 'wc_file', wc_id => $url_wc->id, path => 'example.com/swap-urls/foo');
$url_changes = Daizu::File->new($cms, $foo_bar_id)->update_urls_in_db(\%dup);
is(scalar keys %{$url_changes->{url_activated}}, 0,
   'update_urls_in_db: r44, foo-bar, none activated');
$url_changes = Daizu::File->new($cms, $bar_foo_id)->update_urls_in_db(\%dup);
is(scalar keys %{$url_changes->{url_activated}}, 1,
   'update_urls_in_db: r44, bar-foo, one activated');
is((keys %{$url_changes->{url_activated}})[0],
    'http://www.example.com/swap-urls/foo',
    'update_urls_in_db: r44, bar-foo, foo activated');
is(scalar keys %{$url_changes->{update_redirect_maps}}, 1,
   'update_urls_in_db: r44, only one');
like((keys %{$url_changes->{update_redirect_maps}})[0],
     qr/example.com-redirect.map$/,
     'update_urls_in_db: r44, right one');
is(scalar keys %dup, 0, 'update_urls_in_db: r44, no dups');


sub test_base_url
{
    my ($wc, $path, $expected_url) = @_;
    my $file = $wc->file_at_path($path);
    assert($file);
    my $gen = $file->generator;
    assert($gen);
    is($gen->base_url($file), $expected_url, "generator->base_url: $path");
}

# vi:ts=4 sw=4 expandtab filetype=perl
