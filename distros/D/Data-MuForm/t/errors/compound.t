use strict;
use warnings;
use Test::More;

# shows behavior of required flag in compound fields
{
    package MyApp::Form::User;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'userform' );

    has_field 'name';
    has_field 'email';
    has_field 'address' => ( type => 'Compound' );
    has_field 'address.city' => ( required => 1 );
    has_field 'address.state' => ( required => 1 );

}

my $form = MyApp::Form::User->new;
my $params = {
    name => 'John Doe',
    email => 'jdoe@gmail.com',
};

# no errors if compound subfields are required but missing
# and compound field is not required
$form->process( params => $params );
ok( $form->validated, 'no errors in form' );
$DB::single=1;
# error if one field is entered and not the other
# and compound field is not required
$form->process( params => { %$params, 'address.city' => 'New York' } );
ok( $form->has_errors, 'error with one field filled' );

# errors if compound subfields are required & compound is required
$form->field('address')->required(1);
$form->process( params => $params );
ok( $form->has_errors, 'errors in form' );

# tests that errors are propagated up the tree, and aren't duplicated
{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';
    use Data::MuForm::Types ('PositiveInt');

    has_field 'name';
    has_field 'comp1' => ( type => 'Compound' );
    has_field 'comp1.comment';
    has_field 'comp1.comp2' => ( type => 'Compound' );
    has_field 'comp1.comp2.one';
    has_field 'comp1.comp2.two' => ( type => 'Text', apply => [PositiveInt] );

}

$form = MyApp::Form::Test->new;
ok( $form );
$form->process;
$params = {
    name => 'test',
    'comp1.comment' => 'This is a test',
    'comp1.comp2.one' => 1,
    'comp1.comp2.two' => 'abc',
};

$form->process( params => $params );
ok( $form->has_errors, 'form has errors' );
$DB::single=1;
is( $form->num_errors, 1, 'right number of errors' );
done_testing;
