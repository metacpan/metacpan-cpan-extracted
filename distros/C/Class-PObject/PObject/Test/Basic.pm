package Class::PObject::Test::Basic;

# Basic.pm,v 1.14 2005/02/20 18:05:00 sherzodr Exp

use strict;
#use diagnostics;
use Test::More;
use Class::PObject;
use Class::PObject::Test;
use vars ('$VERSION', '@ISA');
use overload;

@ISA = ('Class::PObject::Test');
$VERSION = '1.03';


BEGIN {
    plan(tests => 204);
    use_ok("Class::PObject")
}


sub run {
    my $self = shift;

    pobject 'PO::Author' => {
        columns     => ['id', 'name', 'url', 'email'],
        driver      => $self->{driver},
        serializer  => 'storable',
        tmap        => {
            name => 'VARCHAR(40)'
        }
    };
    ok(1);


    pobject 'PO::Article' => {
        columns     => ['id', 'title', 'author', 'content', 'rating'],
        #driver      => $self->{driver},
        serializer  => 'storable'
    };
    ok(1);

    ####################
    #
    # 2. Testing pobject_init() method
    #
    {
        package PO::Author;
        use Test::More;
        *pobject_init = sub {
            $_[0]->set_datasource($self->{datasource});
            ok(ref($_[0]) eq 'PO::Author')
        };

        package PO::Article;
        use Test::More;
        *pobject_init = sub {
            $_[0]->set_datasource($self->{datasource});
            $_[0]->set_driver( $self->{driver} );
            ok(ref($_[0]) eq 'PO::Article');
        };
    }

    #
    # Setting datasrource on PO::Article
    #
    #PO::Article->set_datasource( $self->{datasource} );

    ################
    #
    # Testing for the values of @ISA
    #
    ok($PO::Author::ISA[0] eq "Class::PObject::Template");
    ok($PO::Article::ISA[0] eq "Class::PObject::Template");


    ####################
    #
    # 3. Creating new objects
    #
    my $author1 = new PO::Author();
    ok(ref $author1);

    my $author2 = new PO::Author();
    ok(ref $author2);

    my $author3 = new PO::Author(name=>"Geek", email=>'sherzodr@cpan.org');
    ok(ref $author3);


    my $article1 = new PO::Article();
    ok(ref $article1);

    my $article2 = new PO::Article();
    ok(ref $article2);

    my $article3 = new PO::Article();
    ok(ref $article3);


    ################
    #
    # Testing if our object is a 'Class::PObject::Template'
    #
    ok($author1->isa('Class::PObject::Template') && $author2->isa('Class::PObject::Template') &&
                                                    $article1->isa('Class::PObject::Template'));

    ################
    #
    # Testing if driver of the object is of "Class::PObject::Driver::$driver":
    #
    ok($author1->__driver()->isa("Class::PObject::Driver::" . $self->{driver}));

    ################
    #
    # Testing if overloading is applicable
    # to these particular objects
    #
    ok(overload::Overloaded($author1));
    ok(overload::Overloaded($author2));
    ok(overload::Overloaded($author3));
    ok(overload::Overloaded($article1));
    ok(overload::Overloaded($article2));
    ok(overload::Overloaded($article3));

    ####################
    #
    # 4. Test columns(), __props() and __driver() methods
    #
    ok(ref($author1) eq 'PO::Author');
    ok(ref($author1->columns) eq 'HASH');
    ok(ref($author1->__props) eq 'HASH');
    ok(ref($author1->__driver) eq 'Class::PObject::Driver::' . $self->{driver});


    ####################
    #
    # 5. Test if accessor methods have been created successfully
    #
    ok($author1->can('id') && $author2->can('name') && $author3->can('email'));
    ok($author1->name ? 0 : 1);
    #ok(1);


    ok($article1->can('id') && $article2->can('title') && $article3->can('author'));
    #exit;

    ####################
    #
    # 6. Checking if accessor methods function as expected
    #
    $author1->name("Sherzod Ruzmetov");
    $author1->url('http://author.handalak.com/');
    $author1->email('sherzodr@cpan.org');

    my $name = $author1->name();
    ok($name->isa("Class::PObject::Type"));
    ok($name eq "Sherzod Ruzmetov");

    ok($author1->name eq "Sherzod Ruzmetov");
    ok($author1->email eq 'sherzodr@cpan.org');

    $author1->name(undef);

    ok($author1->name ? 0 : 1);
    #ok($author1->{_is_new} == 1);
    ok(1);
    #exit;

    $author2->name("Hilola Nasyrova");
    $author2->url('http://hilola.handalak.com/');
    $author2->email('some@email.com');

    ok($author2->name eq "Hilola Nasyrova");
    ok($author2->email eq 'some@email.com');
    ok($author2->{_is_new} == 1);

    $article1->title("Class::PObject rules!");
    $article1->content("This is the article about Class::PObject and how great this library is");
    $article1->rating(0);

    ok($article1->title eq "Class::PObject rules!");
    ok($article1->rating == 0);


    ####################
    #
    # 7. Testing save()
    #
    my $author1_id = undef;
    ok($author1_id = $author1->save);

    my $author2_id = undef;
    ok($author2_id = $author2->save);

    my $author3_id = undef;
    ok($author3_id = $author3->save);

    $article1->author($author1_id);

    my $article1_id = undef;
    print $article1->dump;
    ok($article1_id = $article1->save);

    ok($article1_id == $article1->id);
    ok($article1    == $article1_id);

    undef($author1);
    undef($author2);
    undef($article1);

    #
    # 'undef'ining 'datasource' class attribute.
    # Since this attribuate was defined inside pobject_init() earlier,
    # we need to check whether will it be redefined when load() is called
    #
    {
        no strict 'refs';
        ${"PO::Article::props"}->{datasource} = undef;
        ${"PO::Author::props"}->{datasource}  = undef;
    }


    ####################
    #
    # 8. Testing load() and integrity of the object
    #

    $article1 = PO::Article->load($article1_id);
    ok($article1);

    ok($article1->title eq "Class::PObject rules!");
    ok(defined $article1->rating);
    ok($article1->rating == 0);

    $author1 = PO::Author->load($article1->author);
    ok($author1);

    ok($author1->{_is_new} == 0);
    ok($author1->email eq 'sherzodr@cpan.org');
    ok($author1->name ? 0 : 1);
    ok($author1->url eq 'http://author.handalak.com/');

    ####################
    #
    # 9. Checking if object properties can be updated
    #
    $author1->url('http://sherzodr.handalak.com/');
    $author1->name("Sherzod Ruzmetov");
    ok($author1->save);

    $author1 = undef;
    $author1 = PO::Author->load($author1_id);
    ok($author1);

    ok($author1->name eq "Sherzod Ruzmetov");
    ok($author1->email eq "sherzodr\@cpan.org");
    ok($author1->url   eq 'http://sherzodr.handalak.com/');

    ####################
    #
    # 10. load()ing pobject in array context
    #
    my @authors = PO::Author->load();
    ok(@authors == 3);
    for ( @authors ) {
        printf("[%d] - %s <%s>\n", $_->id, $_->name, $_->email)
    }
    @authors = undef;



    ################
    #
    # FIX: if load(0) was treated the same way as load()
    #
    my $author4 = PO::Author->load(0);
    ok(!$author4);

    ####################
    #
    # 11. Loading object(s) in array context with terms
    #
    @authors = PO::Author->load({id=>$author1_id});
    for ( @authors ) {
        ok($_->name eq "Sherzod Ruzmetov");
        ok($_->email eq "sherzodr\@cpan.org")
    }


    ####################
    #
    # 12. Checking count()
    #
    ok(PO::Author->count == 3);

    ok(PO::Author->count({name=>"Doesn't exist!"}) == 0);

    ok(PO::Author->count({email=>'sherzodr@cpan.org', name=>"Sherzod Ruzmetov"}) == 1);

    ok(PO::Author->count({email=>'sherzodr@cpan.org'}) == 2);


    ####################
    #
    # 13. Checking more complex terms
    #
    @authors = PO::Author->load({email=>'sherzodr@cpan.org', name=>"Sherzod Ruzmetov"});
    ok(@authors == 1);
    ok($authors[0]->id == $author1_id);
    ok($authors[0]->url eq 'http://sherzodr.handalak.com/', $authors[0]->url);

    @authors = undef;
    @authors = PO::Author->load({url=>'http://hilola.handalak.com/', name=>"Bogus"});
    ok(@authors == 0);


    @authors = PO::Author->load({url=>'http://hilola.handalak.com/'});
    ok(@authors == 1);


    ####################
    #
    # 14. Checking load(undef, \%args) syntax
    #
    @authors = PO::Author->load(undef, {'sort' => 'name'});
    ok(@authors == 3);

    ok($authors[0]->name eq "Geek");
    ok($authors[1]->name eq "Hilola Nasyrova");
    ok($authors[2]->name eq "Sherzod Ruzmetov");





    @authors = ();
    @authors = PO::Author->load(undef, {'sort' => 'email'});
    ok(@authors == 3);

    ok($authors[0]->email eq 'sherzodr@cpan.org');
    ok($authors[1]->email eq 'sherzodr@cpan.org');





    # same as above, but with explicit 'direction'
    @authors = ();
    @authors = PO::Author->load(undef, {'sort' => 'email', direction=>'asc'});
    ok(@authors == 3);

    ok($authors[0]->email eq 'sherzodr@cpan.org');
    ok($authors[1]->email eq 'sherzodr@cpan.org');
    ok($authors[2]->email eq 'some@email.com');







    @authors = ();
    @authors = PO::Author->load(undef, {'sort'=>'name', direction=>'desc'});
    ok(@authors == 3);

    ok($authors[0]->name eq "Sherzod Ruzmetov");
    ok($authors[1]->name eq "Hilola Nasyrova");
    ok($authors[2]->name eq "Geek");




    @authors = ();
    @authors = PO::Author->load(undef, {'sort'=>'id', direction=>'desc', limit=>1});
    ok(@authors == 1);

    ok($authors[0]->name eq "Geek");



    # same as above, but with explicit 'offset'
    @authors = ();
    @authors = PO::Author->load(undef, {'sort'=>'id', direction=>'desc', limit=>1, offset=>0});
    ok(@authors == 1);

    ok($authors[0]->name eq "Geek");



    @authors = ();
    @authors = PO::Author->load(undef, {'sort'=>'id', direction=>'desc', offset=>1, limit=>1});
    ok(@authors == 1);

    ok($authors[0]->name eq "Hilola Nasyrova");



    $author1 = PO::Author->load(undef, {'sort'=>'id', direction=>'desc', limit=>1});
    ok($author1);
    ok($author1->name eq "Geek");



    ####################
    #
    # 15. Checking load(\%terms, \%args) syntax
    #
    @authors = ();
    @authors = PO::Author->load({name=>"Sherzod Ruzmetov"}, {'sort'=>'name'});
    ok(@authors == 1);
    ok($authors[0]->email eq 'sherzodr@cpan.org');







    @authors = ();
    @authors = PO::Author->load({email=>'sherzodr@cpan.org'}, {'sort'=>'name'});
    ok(@authors == 2);

    ok($authors[0]->name eq "Geek");
    ok($authors[1]->name eq "Sherzod Ruzmetov");




    @authors = ();
    @authors = PO::Author->load({email=>'sherzodr@cpan.org'}, {'sort'=>'name', direction=>'desc'});
    ok(@authors == 2);

    ok($authors[0]->name eq "Sherzod Ruzmetov");
    ok($authors[1]->name eq "Geek");




    @authors = PO::Author->load({email=>'sherzodr@cpan.org'}, {'sort'=>'name', direction=>'asc', limit=>1});
    ok(@authors == 1);

    ok($authors[0]->name eq "Geek");



    $author3 = undef;
    $author3 = PO::Author->load({email=>'sherzodr@cpan.org'}, {'sort'=>'name', direction=>'asc', limit=>1});
    ok($author3);
    ok($author3->name eq "Geek");


    @authors = PO::Author->load({email=>'sherzodr@cpan.org'}, {'sort'=>'name', limit=>1, offset=>1});
    ok(@authors == 1);

    ok($authors[0]->name eq "Sherzod Ruzmetov");


    ###################
    #
    # Checking the iterator
    #
    my $iterator = PO::Author->fetch(undef, {'sort'=>'name'});
    #die $iterator->dump;
    ok( $iterator->size == 3);
    #die $iterator->size;
    ok(ref $iterator eq "Class::PObject::Iterator");
    $author1 = $iterator->next();
    ok(ref $author1 eq "PO::Author");
    ok( $author1->name eq "Geek");

    $author2 = $iterator->next();
    ok( ref $author2 eq "PO::Author");
    ok( $author2->name eq "Hilola Nasyrova");

    ok( $iterator->size == 1);

    # trying to iterate through the list. We should
    # have only one object left, since we already called next() two times:
    while ( my $author = $iterator->next ) {
        ok( $author->name eq "Sherzod Ruzmetov" );
    }

    # now we need to reset the pointers:
    $iterator->reset();

    while ( my $author = $iterator->next ) {
        ok( ref $author eq "PO::Author");
    }


    ####################
    #
    # Cleaning up all the objects so that for the next 'make test'
    # can start with brand new scratch board
    #

    $iterator->reset();
    my $author = $iterator->next;

    # removing author named 'Geek':
    ok($author->remove, $author->errstr);

    ok(PO::Author->count == 2, "count: " . PO::Author->count);

    # again trying to remove the author 'Geek'. This should have no
    # effect, since it's been removed in previous query
    ok(PO::Author->remove_all({name=>"Geek"}));
    # we still should have two objects in total in our database
    ok(PO::Author->count == 2, "count: " . PO::Author->count);
    ok(PO::Author->remove_all);
    ok(PO::Author->count == 0);

    ok(PO::Article->remove_all);
    ok(PO::Article->count == 0);

    ok(PO::Article->drop_datasource);
    ok(PO::Author->drop_datasource);
}









1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Test::Basic - Class::PObject's basic test suit

=head1 SYNOPSIS

    # inside t/*.t files:
    use Class::PObject::Test::Basic;
    $t = new Class::PObject::Test::Basic($drivername, $datasource);
    $t->run() # running the tests

=head1 DESCRIPTION

This library is particularly useful for Class::PObject driver authors. It provides
a convenient way of testing your newly created PObject driver to see if it functions
properly, as well as helps you to write test scripts with literally couple of lines
of code.

This same class is also used by L<Class::PObject|Class::PObject>'s standard test scripts

Class::PObject::Test::Basic is a subclass of L<Class::PObject::Test|Class::PObject::Test>.

=head1 NATURE  OF TESTS

This test suite tests the driver's ability to perform most of the functionality
as discussed in Class::PObject's L<manual|Class::PObject>.

=head1 SEE ALSO

L<Class::PObject::Test::Types>,
L<Class::PObject::Test::HAS_A>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
