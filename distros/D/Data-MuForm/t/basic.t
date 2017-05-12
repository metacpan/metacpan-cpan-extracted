use strict;
use warnings;
use Test::More;
use Data::Dumper;

use_ok('Data::MuForm');

{

   package My::Form;
   use Moo;
   use Data::MuForm::Meta;
   extends 'Data::MuForm';

   has '+name'         => ( default  => 'testform_' );
   has '+skip_fields_without_input' => ( default => 1 );

   has_field 'optname' => ( label     => 'First' );
   has_field 'reqname' => ( required => 1 );
   has_field 'somename';
   has_field 'my_selected' => ( type => 'Checkbox' );
   has_field 'must_select' => ( type => 'Checkbox', required => 1 );

   sub field_list
   {
      return [
         fruit => 'Select',
         optname => { label => 'Second' }
      ];
   }

   sub options_fruit
   {
      return (
         1 => 'apples',
         2 => 'oranges',
         3 => 'kiwi',
      );
   }
}

my $form = My::Form->new;

is( $form->num_fields, 6, 'got six fields' );
is( $form->field('optname')->label, 'Second', 'got second optname field' );
is( $form->field('fruit')->num_options, 3, 'right number of options' );

# process with empty params
ok( !$form->process, 'Empty data' );

is_deeply( $form->value, {}, 'empty values hashref');
ok( ! $form->validated, 'form did not validate' );
is( $form->ran_validation, 0, 'ran_validation correct' );

$form->clear;
ok( ! $form->field('somename')->has_input, 'field no input after clear' );
ok( ! $form->field('somename')->has_value, 'no has_value after clear' );

# now try some good params
my $good = {
   reqname     => 'hello',
   optname     => 'not req',
   fruit       => 2,
   must_select => 1,
};

$form->process( params => $good );
my $field = $form->field('must_select');
is( $field->input, 1, 'field has right input' );
ok( ! $field->has_errors, 'must_select field no errors' );

ok( ! $form->field('reqname')->has_errors, 'reqname field no errors' );
ok( ! $form->field('optname')->has_errors, 'optname field no errors' );
ok( ! $form->field('fruit')->has_errors, 'fruit field no errors' );
ok( $form->validated, 'Good data' );


is( $form->field('somename')->value, undef, 'no value for somename' );
ok( !$form->field('somename')->has_value, 'predicate no value' );
my $fif = {
   reqname     => 'hello',
   optname     => 'not req',
   fruit       => 2,
   must_select => 1,
   my_selected => 0,
   somename => '',
};
is_deeply( $form->fif, $fif, 'fif is correct with missing field' );

$good->{somename} = 'testing';
$form->process($good);

is( $form->field('somename')->value,'testing', 'use input for extra data' );

is( $form->field('my_selected')->value, 0,         'correct value for unselected checkbox' );

ok( !$form->process( {} ), 'empty params no validation second time' );
is( $form->num_errors, 0, 'form doesn\'t have errors with empty params' );

my $bad_1 = {
   reqname => '',
   optname => 'not req',
   fruit   => 4,
};

$form->process($bad_1);

ok( !$form->validated, 'bad 1' );
ok( $form->field('fruit')->has_errors, 'fruit has error' );
ok( $form->field('reqname')->has_errors, 'reqname has error' );
ok( $form->field('must_select')->has_errors, 'must_select has error' );
ok( !$form->field('optname')->has_errors, 'optname has no error' );
is( $form->field('fruit')->id,    "fruit", 'field has id' );
is( $form->field('fruit')->label, 'Fruit', 'field label' );

ok( !$form->process( {} ), 'no leftover params' );
is( $form->num_errors, 0, 'no leftover errors' );
ok( !$form->field('reqname')->has_errors, 'no leftover error in field' );
ok( !$form->field('optname')->fif, 'no lefover fif values' );

my $init_values = {
   reqname => 'Starting Perl',
   optname => 'Over Again'
};

$form = My::Form->new( init_values => $init_values );
is( $form->field('optname')->value, 'Over Again', 'value with init_obj' );
ok( $form->has_init_values );

# non-posted params
$form->process( init_values => $init_values, params => {} );
ok( !$form->validated, 'form did not validate' );

my $init_obj_plus_defaults = {
   'fruit' => undef,
   'must_select' => undef,
   'my_selected' => undef,
   'optname' => 'Over Again',
   'reqname' => 'Starting Perl',
   'somename' => undef,
};
is_deeply( $form->value, $init_obj_plus_defaults, 'value with empty params' );

my $expected_fif = {
    reqname => 'Starting Perl',
    optname => 'Over Again',
    my_selected => '',
    fruit => '',
    must_select => '',
    somename => '',
};

$fif = $form->fif;
is_deeply( $fif, $expected_fif, 'get right fif with init_values' );

# make sure that checkbox is 0 in values
my $params = {
   reqname => 'Starting Perl',
   optname => 'Over Again',
   must_select => 1,
};

ok( $form->process($params), 'form validates with params' );
#my %init_obj_value = (%$init_values, fruit => undef );
#is_deeply( $form->value, \%init_obj_value, 'value init obj' );

my $expected_value = {
   reqname => 'Starting Perl',
   optname => 'Over Again',
   must_select => 1,
   my_selected => 0,
   fruit => undef,
};

is_deeply( $form->value, $expected_value, 'value init obj' );
$fif->{must_select} = 1;
$fif->{my_selected} = 0;
is_deeply( $form->fif, $fif, 'get right fif with init_values' );


if ( !$form->process( params => { bar => 1, } ) )
{
   # On some versions, the above process() returned false, but
   # error_fields did not return anything.
   my @fields = $form->all_error_fields;
   if ( is( scalar @fields, 1, "there is an error field" ) )
   {
        my @errors = $fields[0]->all_errors;
        is( scalar @errors, 1, "there is an error" );
        is( $errors[0], "'Must select' field is required", "error messages match" );
   }
   else
   {
        fail("there is an error");
        fail("error messages match");
   }
}

done_testing;
