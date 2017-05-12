package Class::PObject::Test::HAS_A;

# HAS_A.pm,v 1.5 2003/11/06 01:21:10 sherzodr Exp

use strict;
#use diagnostics;
use Test::More;
use vars ('$VERSION', '@ISA');

BEGIN {
    plan(tests => 37);
    use_ok("Class::PObject");
    use_ok("Class::PObject::Test")
}

@ISA = ('Class::PObject::Test');
$VERSION = '1.00';


sub run {
    my $self = shift;

    pobject 'PO::Author' => {
        columns        => ['id', 'name'],
        driver      => $self->{driver},
        datasource  => $self->{datasource},
        serializer  => 'storable'
    };
    ok(1);

    pobject 'PO::Article' => {
        columns        => ['id', 'title', 'author'],
        driver        => $self->{driver},
        datasource    => $self->{datasource},
        serializer    => 'storable',
        tmap          => {
            author        => 'PO::Author'
        }
    };
    ok(1);

    ################
    #
    # Creating a new Author
    #
    my $author = new PO::Author();

    ################
    #
    # Is Segmentation fault still persistent?
    #
    ok($author->name ? 0 : 1 );
    ok($author->id ?   0 : 1 );
    

    ################
    #
    # Filling in details of the author
    #
    $author->name("Sherzod Ruzmetov");
    ok($author->name eq "Sherzod Ruzmetov");
    ok(my $author_id = $author->save, $author->errstr);

    $author = undef;

    ################
    #
    # Creating new article
    #
    my $article = new PO::Article();
    #print $article->dump;

    ################
    #
    # Is segmentation fault problem fixed?
    #
    ok(!$article->id);
    
    ok($article->title ? 0 : 1);
    #print $article->dump;
    TODO: {
        #local $TODO = "Still not sure why this one keeps failing";
        ok($article->author ? 0 : 1, $article->author . " is empty")
    }


    ################
    #
    # Filling in details of the article
    #
    $article->title("Class::PObject now supports type-mapping");

    $author = PO::Author->load($author_id);
    #print $article->dump;
    $article->author( $author );
    #print $article->dump;
    #print $author->dump;

    ok($article->author->name eq "Sherzod Ruzmetov",    $article->author->name);
    ok(ref($article->author) eq "PO::Author",                ref($article->author));
    ok(my $article_id = $article->save(),                $article->errstr );

    #print $article->dump;

    $article = $author = undef;

    $article = PO::Article->load($article_id);
    ok($article);

    #print $article->dump;

    $author = $article->author;
    ok($article->title eq "Class::PObject now supports type-mapping", $article->title);
    ok($author->name eq "Sherzod Ruzmetov",    $article->author->name);
    ok(ref ($author) eq "PO::Author",                ref($article->author));

    $article->author($author->id);

    ok($article->save == $article_id, $article->errstr);
    
    #print $article->dump;
    $article = undef;

    $article = PO::Article->load({author=>$author});
    ok($article, "article: $article");

    #print $article->dump;

    ok($article->title eq "Class::PObject now supports type-mapping");
    ok($article->author->name eq "Sherzod Ruzmetov",    ''.$article->author->name);
    ok(ref($article->author) eq "PO::Author",                ref($article->author));

    ok($article->save == $article_id, $article->errstr);

    $article = undef;

    my $result = PO::Article->fetch({author=>$author});
    ok($article = $result->next);

    #print $article->dump;

    ok($author = $article->author);
    #print $article->dump;
    ok($article->title eq "Class::PObject now supports type-mapping");
    ok($author->name eq "Sherzod Ruzmetov",    ''.$article->author->name);
    ok(ref($author) eq "PO::Author",                ref($article->author));

    #print Dumper($article);
    #print Dumper($author);

    ################
    # FIX:
    # If we created another article, but didn't assign any value to its
    # author field, when we access author(), it used to return the Author object
    # from the previous article's author.
    my $article2 = new PO::Article();
    $article2->title("Is this annoying bug fixed?");
    ok($article2->columns()->{author} ? 0 : 1, "Author shouldn't be set yet");
    ok($article2->author ? 0 : 1, "Author shouldnt' be set yet");



    ok(PO::Article->count() == 1);
    ok(PO::Article->count({author=>$author}) == 1);
    ok(PO::Article->remove_all);
    ok(PO::Article->count({author=>$author}) == 0);

    ok(PO::Article->drop_datasource);
    ok(PO::Author->drop_datasource);
}

1;
__END__

=head1 NAME

Class::PObject::Test::HAS_A - Class::PObject't has-a relationship test suit

=head1 SYNOPSIS

    # inside t/*.t files:
    use Class::PObject::Test::HAS_A;
    $t = new Class::PObject::Test::HAS_A($drivername, $datasource);
    $t->run() # running the tests

=head1 DESCRIPTION

F<HAS_A.pm> is a test suit similar to L<Class::PObject::Test::Basic|Class::PObject::Test::Basic>,
but concentrates on objects' has-a relationships - extended type-mapping feature.

=head1 SEE ALSO

L<Class::PObject::Test::Basic>,
L<Class::PObject::Test::Types>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
