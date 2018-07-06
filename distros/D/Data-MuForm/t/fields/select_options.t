use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test1;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'Select', options => [ 1 => 'aref1', 2 => 'aref2', 3 => 'aref3' ] );
    has_field 'bar' => ( type => 'Select', options => [ { value => 1, label => 'href1' }, { value => 2, label => 'href2' } ] );
    has_field 'jix' => ( type => 'Select', options => [[ 'daref1', 'daref2', 'daref3' ]] );

}

my $form = MyApp::Form::Test1->new;
ok( $form );

my $expected = [{ value => 1, label => 'aref1', order => 0 }, { value => 2, label => 'aref2', order => 1 }, { value => 3, label => 'aref3', order => 2 }];
is_deeply( $form->field('foo')->options, $expected, 'got expected options for arrayref options' );

$expected = [ { value => 1, label => 'href1', order => 0 }, { value => 2, label => 'href2', order => 1 }];
is_deeply( $form->field('bar')->options, $expected, 'got expected options for arrayref of hashref options' );

$expected = [{ value => 'daref1', label => 'daref1', order => 0 }, { value => 'daref2', label => 'daref2', order => 1 }, { value => 'daref3', label => 'daref3', order => 2 }];
is_deeply( $form->field('jix')->options, $expected, 'got expected options for double arrayref options' );

{
    package MyApp::Form::Test2;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'Select' );
    sub options_foo {
       [ 1 => 'aref1', 2 => 'aref2', 3 => 'aref3' ]
    }
    has_field 'bar' => ( type => 'Select' );
    sub options_bar {
        [ { value => 1, label => 'href1' }, { value => 2, label => 'href2' } ]
    }
    has_field 'jix' => ( type => 'Select' );
    sub options_jix {
        [[ 'daref1', 'daref2', 'daref3' ]]
    }

    has_field 'mox' => ( type => 'Select' );
    sub options_mox {
       ( 1 => 'array1', 2 => 'array2', 3 => 'array3' )
    }

}

$form = MyApp::Form::Test2->new;
ok( $form );

$expected = [{ value => 1, label => 'aref1', order => 0 }, { value => 2, label => 'aref2', order => 1 }, { value => 3, label => 'aref3', order => 2 }];
is_deeply( $form->field('foo')->options, $expected, 'got expected options for arrayref options' );

$expected = [ { value => 1, label => 'href1', order => 0 }, { value => 2, label => 'href2', order => 1 }];
is_deeply( $form->field('bar')->options, $expected, 'got expected options for arrayref of hashref options' );

$expected = [{ value => 'daref1', label => 'daref1', order => 0 }, { value => 'daref2', label => 'daref2', order => 1 }, { value => 'daref3', label => 'daref3', order => 2 }];
is_deeply( $form->field('jix')->options, $expected, 'got expected options for double arrayref options' );

$expected = [{ value => 1, label => 'array1', order => 0 }, { value => 2, label => 'array2', order => 1 }, { value => 3, label => 'array3', order => 2 }];
is_deeply( $form->field('mox')->options, $expected, 'got expected options for array from sub' );

{
    package MyApp::Form::Test3;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'Select' );
    sub options_foo {
       [ 1 => 'aref1', 2 => 'aref2', 3 => 'aref3' ]
    }
    has_field 'bar' => ( type => 'Select' );
    sub options_bar {
        [ { value => 1, label => 'href1', 'data-org' => 1, attributes => { 'data-field' => 1 } },
          { value => 2, label => 'href2', 'data-org' => 1, attributes => { 'data-field' => 2 } }
        ]
    }
}

$form = MyApp::Form::Test3->new;
ok( $form );

my $rendered_select = $form->field('bar')->render;
unlike( $rendered_select, qr/attributes/, 'no "attributes" string in rendering' );


done_testing;
