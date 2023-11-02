use Test::More;
use strict;
use warnings;

use File::Basename;
use File::Spec;
use Dancer2::Plugin::LiteBlog::Article;


# Testing root

eval { Dancer2::Plugin::LiteBlog::Article->new() };
like( $@, qr/Missing required/, "failed to create without basedir") ;

eval { Dancer2::Plugin::LiteBlog::Article->new( basedir => 'nonexisting') };
like( $@, qr/Not a valid/, "failed to create with invalid basedir") ;

my $page;
my $localdir = File::Spec->catfile(dirname(__FILE__), 'articles', 'some-test-article');
eval { $page = Dancer2::Plugin::LiteBlog::Article->new( basedir => $localdir ); };
like( $@, qr{not valid: content.md}, "invalid article basedir prevents instanciation");


# Testing a blog post under a category
$localdir = File::Spec->catfile(dirname(__FILE__), 'articles','tech','first-article' );
my $article = Dancer2::Plugin::LiteBlog::Article->new( basedir => File::Spec->catfile($localdir));
is($article->category, 'tech', "This article is under the 'tech' category");
ok(!$article->is_page, "Flag is_page works");

# Testing meta
ok($article->meta, "meta initialized correctly"); 
like($article->meta->{'title'}, qr/A super Tech Blog Post/, 'title looks good');
is_deeply($article->meta->{'tags'}, [qw(perl dancer blog)], "tags looks ok");

like ($article->content, qr/<p>.*Welcome to your Liteblog site/s, "content has been rendered as HTML");

like ($article->permalink, qr{/blog/tech/first-article}, "permalink looks good");


like $article->published_time, qr/\d{10}/, "published_time is calculated";
like $article->published_date, qr/\d+ \w+, \d{4}/, "published_date is correctly formatted";

subtest "article's image meta should be transformed to permalink" => sub {
    my $dir = File::Spec->catfile(dirname(__FILE__), 'articles','tech','first-article' );
    my $a = Dancer2::Plugin::LiteBlog::Article->new( 
        basedir => $dir,
        base_path => '/articles',
    );
    is $a->meta->{'image'}, 'featured.jpg', "the 'image' entry is set in the meta data";
    is $a->image, '/articles/tech/first-article/featured.jpg',
        "the 'image' accessor returns the correct permalink";

    # a regular page, with an absolute image set.
    $dir = File::Spec->catfile(dirname(__FILE__), 'articles','contact' );
    my $page = Dancer2::Plugin::LiteBlog::Article->new( 
        basedir => $dir, base_path => '' ); # mounted at the site's root
    is $page->meta->{'image'}, '/images/liteblog.jpg',
        "page's meta image is an absolute path";
    is $page->image, '/images/liteblog.jpg',
        "page's image accessor returns the 'image' meta field unchanged";
};

subtest "Article created on a category page is not working" => sub {
    my $dir = File::Spec->catfile(dirname(__FILE__), 'articles','tech' );
    my $a;
    eval { $a = Dancer2::Plugin::LiteBlog::Article->new( 
        basedir => $dir,
        base_path => '/',
    ); };

    is $a, undef, "undef is returned as the article isn't valid";
    like $@, qr{Basedir '$dir' is not valid}, 
        "An exception is thrown to describe the problem";

    done_testing;
};


# End of tests
done_testing;
