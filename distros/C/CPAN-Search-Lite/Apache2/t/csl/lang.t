#!/usr/bin/perl
use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil qw(t_cmp t_write_perl_script);
use Apache::TestRequest qw(GET);
use CPAN::Search::Lite::Util qw(%chaps);
use CPAN::Search::Lite::Lang qw(%langs load);
use FindBin;
use lib "$FindBin::Bin/../lib";
use TestCSL qw($expected);
my $pages = {};
my $chaps_desc = {};

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
my @langs = keys %langs;

plan tests => 9 * scalar @langs;

my $result;

for my $lang (@langs) {
    unless ($pages->{$lang}) {
        my $rc = load(lang => $lang, pages => $pages, 
                      chaps_desc => $chaps_desc);
        die "Cannot load '$lang'" unless ($rc == 1);
    }
    for my $chap (qw(2 10 22)) {
        my $query = "wanted=$chap;data=chaps_desc";
        my $result = GET "/TestCSL__lang?$query",
            'Accept-Language' => $lang;
        my $content = $result->content;
        ok t_cmp($content, $chaps_desc->{$lang}->{$chap}, 
                 "testing $lang for chaps_desc -> $chap");
    }
    for my $text (qw(title Problems)) {
        my $query = "wanted=$text;data=pages";
        my $result = GET "/TestCSL__lang?$query",
            'Accept-Language' => $lang;
        my $content = $result->content;
        ok t_cmp($content, $pages->{$lang}->{$text}, 
                 "testing $lang for pages -> $text");
    }
    my $hash_element = 'list';
    for my $text(keys %{$pages->{$lang}->{$hash_element}}) {
        my $query = "wanted=$text;data=pages;hash_element=$hash_element";
        my $result = GET "/TestCSL__lang?$query",
            'Accept-Language' => $lang;
        my $content = $result->content;
        ok t_cmp($content, $pages->{$lang}->{$hash_element}->{$text},
                 "testing $lang for pages -> $hash_element -> $text");
    }
}

