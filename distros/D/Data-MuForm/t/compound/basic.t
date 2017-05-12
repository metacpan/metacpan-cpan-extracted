use Test::More;

use lib 't/lib';

use_ok('MyApp::Field::Duration');
my $field = MyApp::Field::Duration->new( name => 'duration' );

ok( $field, 'get compound field');

my $input = {
      hours => 1,
      minutes => 2,
};

$field->input($input);

is_deeply( $field->input, $input, 'field input is correct');

is_deeply( $field->fif, $input, 'field fif is same');

{
   package Duration::Form;
   use Moo;
   use Data::MuForm::Meta;
   extends 'Data::MuForm';
   has '+field_namespace' => ( default => sub { ['MyApp::Field'] } );

   has_field 'name' => ( type => 'Text' );
   has_field 'duration' => ( type => 'Duration' );
   has_field 'duration.hours' => ( type => 'Text' );
   has_field 'duration.minutes' => ( type => 'Text' );

}

my $form = Duration::Form->new;
ok( $form, 'get compound form' );
is( scalar $form->all_sorted_fields, 2, 'two sorted fields' );
ok( $form->field('duration'), 'duration field' );
ok( $form->field('duration.hours'), 'duration.hours field' );
is( $form->num_fields, 2, 'right number of fields' );
is( $form->field('duration')->num_fields, 2, 'right number of fields in compound field' );

my $params = { name => 'Testing', 'duration.hours' => 2, 'duration.minutes' => 30 };
$form->process( params => $params );
ok( $form->validated, 'form validated' );
is( scalar $form->all_sorted_fields, 2, 'two sorted fields' );

my $fif = $form->fif;
is_deeply($fif, $params, 'get fif with right value');


is( $form->field('duration')->value->hours, 2, 'duration value is correct');
$form->process( params => { name => 'Testing', 'duration.hours' => 'abc', 'duration.minutes' => 'xyz' } );
ok( $form->has_errors, 'form does not validate' );
my @errors = $form->all_errors;
is( $errors[0], 'Invalid value for Duration: Hours', 'correct error message' );

{
   package Field::MyCompound;
   use Moo;
   use Data::MuForm::Meta;
   extends 'Data::MuForm::Field::Compound';

   has_field 'aaa';
   has_field 'bbb';
}


{
   package Form::TestValues;
   use Moo;
   use Data::MuForm::Meta;
   extends 'Data::MuForm';

   has_field 'compound' => ( type => '+Field::MyCompound', apply => [ { check => sub { $_[0]->{aaa} eq 'aaa'}, message => 'Must be "aaa"' } ] );
}
$form = Form::TestValues->new;
ok( $form, 'Compound form with separate fields declarations created' );


$params = {
    'compound.aaa' => 'aaa',
    'compound.bbb' => 'bbb',
};
$form->process( params => $params );
is_deeply( $form->values, { compound => { aaa => 'aaa', bbb => 'bbb' } }, 'Compound with separate fields - values in hash' );
is_deeply( $form->fif, $params, 'get fif from compound field' );
$form->process( params => { 'compound.aaa' => undef } );
ok( !$form->field( 'compound' )->has_errors, 'Not required compound with empty sub values is not checked');

{

    package Compound;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm::Field::Compound';
    use Types::Standard ('Int');

    has_field 'year' => (
        type         => 'Text',
        apply        => [ Int ],
        required     => 1,
    );

    has_field 'month' => (
        type         => 'Integer',
        range_start  => 1,
        range_end    => 12,
    );

    has_field 'day' => (
        type         => 'Integer',
        range_start  => 1,
        range_end    => 31,
    );

    sub default {
        return {
            year  => undef,
            month => undef,
            day   => undef
        };
    }
}

{

    package Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';
    has_field 'date' => ( type => '+Compound', required => 1 );
    has_field 'foo';
}

my $f = Form->new;
$f->process( { 'date.day' => '18', 'date.month' => '2', 'date.year' => '2010' } );
is_deeply( $f->field('date')->value, { year => 2010, month => 2, day => 18 }, 'correct value' );

$f = Form->new;
$f->process( { foo => 'testing' } );
is_deeply( $f->field('date')->value, { year => undef, month => undef, day => undef }, 'correct default' );

done_testing;
