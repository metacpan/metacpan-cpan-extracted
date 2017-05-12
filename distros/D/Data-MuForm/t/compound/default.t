use strict;
use warnings;
use Test::More;

# tests that a 'default' hashref on a compound field works
{
    {
        package MyApp::Test::Compound;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'comp_foo' => ( type => 'Compound', default => { one => 1, two => 2, three => 3 } );
        has_field 'comp_foo.one';
        has_field 'comp_foo.two';
        has_field 'comp_foo.three';
    }

    my $form = MyApp::Test::Compound->new;
    ok( $form );
    $form->process;
    is( $form->field('comp_foo.one')->value, 1, 'value is one' );
    is_deeply( $form->field('comp_foo')->value, { one => 1, two => 2, three => 3 },
       'value for compound is correct' );
}


# tests that default object for a compound field works
# object provided by default_method
{
    {
        package MyApp::Foo;
        use Moo;
        has 'one' => ( is => 'ro', default => 1 );
        has 'two' => ( is => 'ro', default => 2 );
        has 'three' => ( is => 'ro', default => 3 );
    }
    {
        package MyApp::Test::Compound2;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'comp_foo' => ( type => 'Compound' );
        has_field 'comp_foo.one';
        has_field 'comp_foo.two';
        has_field 'comp_foo.three';
        sub default_comp_foo {
            return MyApp::Foo->new;
        }
    }

    my $form = MyApp::Test::Compound2->new;
    ok( $form );
    is( $form->field('comp_foo.one')->value, 1, 'value is one' );
    is( ref $form->field('comp_foo')->obj, 'MyApp::Foo', 'model saved' );
}

done_testing;
