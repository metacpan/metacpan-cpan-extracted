#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::TTProvider;
use Daizu::Test qw( init_tests get_nav_menu_carefully test_menu_item );

init_tests(59);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $wc = $cms->live_wc;

my $homepage_file = $wc->file_at_path('foo.com/_index.html');
my $docidx_file = $wc->file_at_path('foo.com/doc/_index.html');
my $subidx_file = $wc->file_at_path('foo.com/doc/subdir/_index.html');
my $a_file = $wc->file_at_path('foo.com/doc/subdir/a.html');
assert(defined $_)
    for $homepage_file, $docidx_file, $subidx_file, $a_file;


# article_template_overrides() and article_template_variables()
{
    my $gen = $homepage_file->generator;
    my ($url_info) = $gen->urls_info($homepage_file);
    isa_ok($gen->article_template_overrides($homepage_file, $url_info), 'HASH',
           'Daizu::Gen->article_template_overrides');

    my $var = $gen->article_template_variables($homepage_file, $url_info);
    isa_ok($var, 'HASH', 'Daizu::Gen->article_template_variables');
    is(scalar keys %$var, 0, 'vars: homepage, no vars');

    ($url_info) = $gen->urls_info($subidx_file);
    $var = $gen->article_template_variables($subidx_file, $url_info);
    isa_ok($var, 'HASH', 'vars: subidx, type');
    is(scalar keys %$var, 1, 'vars: subidx, right num');
    assert(exists $var->{head_meta});
    my $meta = $var->{head_meta};
    is($meta->[0]{name}, 'description', 'vars: subidx, description name');
    is($meta->[0]{content},
       "I've added a description to this article.  Just for a bit of" .
       " variety really,\n" .
       "& for an extra chance to check that descriptions show up in the" .
       " right places.\n" .
       "Plus this one gives me a chance to check that that ampersand," .
       " and \x{2018}UTF-8\x{2019}\n" .
       "characters, show up in descriptions.  Also that relatively prolix" .
       " descriptive\n" .
       "verbiage doesn't look completely ridiculous when displayed on an" .
       " article's\npage.",
       'vars: subidx, description value');
    is($meta->[1]{name}, 'keywords', 'vars: subidx, keywords name');
    is($meta->[1]{content}, 'Tag 1, tag 2, Tag 3',
       'vars: subidx, keywords value');
}


# Daizu::Gen->navigation_menu
my $menu = get_nav_menu_carefully($homepage_file);
is(scalar @$menu, 3, 'navigation_menu: homepage: children');
test_menu_item($menu->[0], 'homepage, 0', 0, 'about.html', 'About Foo.com');
test_menu_item($menu->[1], 'homepage, 1', 0, 'blog/', 'Foo Blog');
test_menu_item($menu->[2], 'homepage, 2', 0, 'doc/',
               "Title for \x{2018}doc\x{2019} index page");

$menu = get_nav_menu_carefully($docidx_file);
is(scalar @$menu, 1, 'navigation_menu: docidx: one item');
test_menu_item($menu->[0], 'docidx, 0', 2, undef,
               "Title for \x{2018}doc\x{2019} index page");
test_menu_item($menu->[0]{children}[0], 'docidx, 0.0', 0,
               'Util.html', 'Daizu::Util - various utility functions');
test_menu_item($menu->[0]{children}[1], 'docidx, 0.1', 0,
               'subdir/', 'Subdir index');

$menu = get_nav_menu_carefully($subidx_file);
test_menu_item($menu->[0], 'subidx, 0', 1,
               '../', "Title for \x{2018}doc\x{2019} index page");
test_menu_item($menu->[0]{children}[0], 'subidx, 0.0', 3,
               undef, 'Subdir index');
test_menu_item($menu->[0]{children}[0]{children}[0], 'subidx, 0.0.0', 0,
               'a.html', 'First article');
test_menu_item($menu->[0]{children}[0]{children}[1], 'subidx, 0.0.1', 0,
               'q.html', 'Middle article');
test_menu_item($menu->[0]{children}[0]{children}[2], 'subidx, 0.0.2', 0,
               'z.html', 'Last article');

$menu = get_nav_menu_carefully($a_file);
test_menu_item($menu->[0], 'afile, 0', 1,
               '../', "Title for \x{2018}doc\x{2019} index page");
test_menu_item($menu->[0]{children}[0], 'afile, 0.0', 3,
               './', 'Subdir index');
test_menu_item($menu->[0]{children}[0]{children}[0], 'afile, 0.0.0', 0,
               undef, 'First article');
test_menu_item($menu->[0]{children}[0]{children}[1], 'afile, 0.0.1', 0,
               'q.html', 'Middle article');
test_menu_item($menu->[0]{children}[0]{children}[2], 'afile, 0.0.2', 0,
               'z.html', 'Last article');

# vi:ts=4 sw=4 expandtab filetype=perl
