use Test::More;
use strict;
use warnings;

use File::Basename;
use File::Spec;

use Dancer2::Plugin::LiteBlog::Blog;

my $localdir = File::Spec->catfile(dirname(__FILE__), 'articles');
my $blog = new Dancer2::Plugin::LiteBlog::Blog( root => $localdir );

is (scalar(@{$blog->elements}), 2, "only 2 posts successfully found");
is ($blog->elements->[0]->slug, 'first-article', "first post is ok");
is ($blog->elements->[0]->category, 'tech', "first post category is ok");
is ($blog->elements->[1]->category, 'page', "2nd post category is ok");
is ($blog->elements->[1]->title, 'Contact', "2nd post title is ok");

eval { $blog = Dancer2::Plugin::LiteBlog::Blog->new( root => File::Spec->catfile($localdir, 'tech')) };

my $list;
eval { $list = $blog->elements };
like ($@, qr/No meta file/, "Exception triggered when no blog-meta is found");

$blog = new Dancer2::Plugin::LiteBlog::Blog( root => $localdir );
my $a;
eval { $blog->find_article(); };
like $@, qr/Required param 'path' missing/, "path must be passed to find_article";

$a = $blog->find_article(category => 'tech', path => 'first-article' );
is $a->title, 'A super Tech Blog Post', "find_article works for a tech article";
$a = $blog->find_article(category => 'tech', path => '/first-article' );
is $a->title, 'A super Tech Blog Post', "find_article works with '/'";


subtest 'select articles' => sub {
    my $pages = $blog->select_articles();
    is scalar(@$pages), 1, "found 1 page";
    is $pages->[0]->slug, 'contact', "contact page found"; 

    my $articles = $blog->select_articles(
        limit => 3,
        category => 'tech',
    );
    is scalar(@$articles), 2, "Found 2 tech articles";

    done_testing();
};


done_testing;
